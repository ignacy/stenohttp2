# typed: ignore

module Stenohttp2
  module Server
    class PingHandler
      TIMESTAMP_FORMAT = '%Y-%m-%d-%H-%M'.freeze
      IDENTIFIERS = [
        ENV.fetch('SERVER_IDENTIFIER'),
        ::Stenohttp2::Client::Client::CLIENT_IDENTIFIER
      ].freeze

      def initialize(server: true)
        @server = server
        @reciving = false
        @current_file = nil
        @count_processed = false
        @messages_left = 0
        @send_response = false
      end

      def handle(payload)
        if IDENTIFIERS.include?(payload)
          @reciving = true
          @current_file = new_message_file
        elsif @reciving
          if !@count_processed
            # First ping has the message count
            @messages_left = payload.to_s.split('u').first.to_i
            @count_processed = true
          elsif @messages_left.positive?
            @current_file.write(payload)
            @messages_left -= 1
          elsif @messages_left.zero?
            @current_file.close
            @current_file = nil
            @reciving = false
            @send_response = true
          else
            puts "Ignoring #{payload}"
          end
        else
          puts "Not reciving / Ignoring #{payload}"
        end
      end

      def send_response?
        @send_response
      end

      attr_writer :send_response

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
