# typed: true

require 'fileutils'

module Stenohttp2
  module Server
    class PingHandler
      SERVER_MESSAGES_DIR = 'tmp/server'.freeze
      CLIENT_MESSAGES_DIR = 'tmp/client'.freeze

      def initialize(server: true)
        @server = server
        @reciving = false
        @current_file = nil
        @count_processed = false
        @messages_left = 0
        @send_response = false
        FileUtils.mkdir_p(messages_dir)
      end

      def handle(payload)
        if [Server::SERVER_IDENTIFIER, Client::CLIENT_IDENTIFIER].include?(payload)
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

      def new_message_file
        timestamp = Time.now.strftime('%Y-%m-%d-%H-%M')
        File.open("#{messages_dir}/#{timestamp}.message", 'a')
      end

      def messages_dir
        if @server
          SERVER_MESSAGES_DIR
        else
          CLIENT_MESSAGES_DIR
        end
      end
    end
  end
end