# typed: ignore

module Stenohttp2
  module Server
    class PingHandler
      TIMESTAMP_FORMAT = '%Y-%m-%d-%H-%M'.freeze
      IDENTIFIERS = [
        ENV.fetch('SERVER_IDENTIFIER'),
        ::Stenohttp2::Client::Client::CLIENT_IDENTIFIER
      ].freeze

      attr_accessor :messages_left, :send_response, :payload, :file

      state_machine :state, initial: :waiting do
        event :start_reciving do
          transition waiting: :reciving
        end

        event :consume_count do
          transition reciving: :count_consumed
        end

        event :consume_message do
          transition %i[count_consumed consuming] => :consuming
        end

        event :ready_to_respond do
          transition any => :responding
        end

        event :done do
          transition any => :waiting
        end

        after_transition any => :count_consumed do |handler, _transition|
          handler.messages_left = handler.payload.to_s.split('u').first.to_i
          handler.file = File.open(handler.file_name, 'a')
        end

        before_transition any => :consuming do |handler, _transition|
          handler.file = File.open(handler.file_name, 'a') if handler.file.nil?
          handler.messages_left -= 1
        end
      end

      def initialize(server: true)
        @server = server
        @messages_left = 0
        @file = nil
        @payload = nil
        super()
      end

      # rubocop:disable Metrics/AbcSize
      def handle(frame)
        # We are only interested in PING farmes without ACK flag
        # because the ones with ACK include just the repeated contend
        return unless frame[:type] == :ping && !frame[:flags].include?(:ack)

        self.payload = frame[:payload]

        start_reciving and return if IDENTIFIERS.include?(payload)

        return if waiting?

        consume_count and return unless count_consumed?

        if messages_left.positive?
          file.write(payload)
          consume_message
        elsif messages_left.zero?
          file.close
          ready_to_respond
        end
      end
      # rubocop:enable Metrics/AbcSize

      def file_name
        "#{messages_dir}/#{Time.now.strftime(TIMESTAMP_FORMAT)}.message"
      end

      private

      def messages_dir
        @server ? server_dir : client_dir
      end

      def server_dir
        @server_dir ||= ENV.fetch('SERVER_DIR')
      end

      def client_dir
        @client_dir ||= ENV.fetch('CLIENT_DIR')
      end
    end
  end
end
