# typed: true

require 'fileutils'
require_relative '../client/client'
require_relative './server'

class PingHandler
  SERVER_MESSAGES_DIR = 'tmp/server'.freeze
  CLIENT_MESSAGES_DIR = 'tmp/client'.freeze

  def initialize(server: true)
    @server = server
    @reciving = false
    @current_file = nil
    @send_response = false
    FileUtils.mkdir_p(messages_dir)
  end

  def handle(payload)
    if payload == Server::SERVER_IDENTIFIER || payload == Client::CLIENT_IDENTIFIER
      if @reciving
        @current_file.close
        @current_file = nil
        @reciving = false
        @send_response = true
      else
        @current_file = new_message_file
        @reciving = true
      end
    elsif @reciving
      @current_file.write(payload)
    else
      puts "Ignoring #{payload}"
    end
  end

  def send_response?
    @send_response
  end

  def send_response=(val)
    @send_response = val
  end

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
