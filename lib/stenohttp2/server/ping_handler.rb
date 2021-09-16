# typed: ignore

module Stenohttp2
  module Server
    class PingHandler
      TIMESTAMP_FORMAT = '%Y-%m-%d-%H-%M'.freeze
      IDENTIFIERS = [
        ENV.fetch('SERVER_IDENTIFIER'),
        ::Stenohttp2::Client::Client::CLIENT_IDENTIFIER
      ].freeze

      attr_accessor :messages_left, :send_response, :payload

      # rubocop:disable Metrics/BlockLength
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
        end

        after_transition any => :consuming do |_hadler, _transition|
          handler.messages_left -= 1
        end

        state :waiting do
          def current_file
            nil
          end
        end

        state :reciving do
          def current_file
            new_message_file
          end
        end

        state :count_consumed do
          def current_file
            new_message_file
          end
        end

        state :consuming do
          def current_file
            new_message_file
          end
        end

        state :responding do
          def current_file
            nil
          end
        end
      end
      # rubocop:enable Metrics/BlockLength
      def initialize(server: true)
        @server = server
        @messages_left = 0
        @payload = nil
        super()
      end

      def handle(new_payload)
        payload = new_payload
        start_reciving and return if IDENTIFIERS.include?(payload)

        return unless reciving?

        consume_count and return unless count_consumed?

        if messages_left.positive?
          current_file.write(payload)
          consume_message
        elsif messages_left.zero?
          current_file.close
          ready_to_respond
        end
      end

      private

      # We serialize and write messages send through hidden chanel to files
      # which are timestampted for (one for every minute of conversation)
      def new_message_file
        timestamp = Time.now.strftime(TIMESTAMP_FORMAT)
        File.open("#{messages_dir}/#{timestamp}.message", 'a')
      end

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
