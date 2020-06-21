# typed: true

require 'securerandom'
require_relative './message'
require 'sorbet-runtime'

class Sender
  extend T::Sig

  sig do
    params(
      message: Message,
      connection: T.any(HTTP2::Server, HTTP2::Client),
      identifier: String,
      delay: Float
    ).void
  end
  def initialize(message:, connection:, identifier:, delay: 0)
    @message = message
    @connection = connection
    @identifier = identifier
    @delay = delay
  end

  def call
    (1..number_of_random_messages_to_send).each do |_i|
      connection.ping(random_8_byte_string)
    end
    connection.ping(identifier)
    connection.ping(number_of_message_frames.to_s(2).rjust(8, '0'))
    message.parts.each do |part|
      connection.ping(part)
      sleep delay
    end
    connection.ping(random_8_byte_string)
  end

  private

  def number_of_random_messages_to_send
    rand(10)
  end

  def random_8_byte_string
    SecureRandom.hex(4)
  end

  def number_of_message_frames
    @number_of_message_frames ||= message.parts.size
  end

  attr_reader :message, :identifier, :delay, :connection
end
