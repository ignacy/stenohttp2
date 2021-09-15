# typed: true

require 'securerandom'
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

  # Send the encrypted message over the hidden channel.
  #
  # Calls to `sleep delay` look silly but they are important because
  # otherwise the whole message would be send at once which would be
  # very suspicious.
  #
  # The calls to `random_8_byte_string` are used to hide the message better.
  # If you look at the whole exchange it looks like this:
  #
  # e48ea076 <- top padding
  # a0eb400a
  # c158b6e7
  # ae419f7a <- here the message starts
  # 289bcdc7
  # a9121f02
  # b68c67cf
  # 4ec6ad36
  # d7aea416 <- here it ends
  # 96a83824 <- bottom padding
  # 142cf021
  def call
    add_padding
    sleep delay

    connection.ping(identifier)
    sleep delay

    connection.ping(encoded_message_size)
    sleep delay

    message.parts.each do |part|
      connection.ping(part)
      sleep delay
    end

    add_padding
  end

  private

  def add_padding
    number_of_random_messages_to_send.times do
      connection.ping(random_8_byte_string)
      sleep delay
    end
  end

  sig { returns(Integer) }
  def number_of_random_messages_to_send
    rand(10)
  end

  def encoded_message_size
    "#{number_of_message_frames}u#{SecureRandom.alphanumeric(8 - 1 - number_of_message_frames.to_s.size)}"
  end

  # We use random 8 bytes strings at the begining and at the end of the
  # communication to hide the message itself better
  sig { returns(String) }
  def random_8_byte_string
    SecureRandom.hex(4)
  end

  def number_of_message_frames
    @number_of_message_frames ||= message.parts.size
  end

  attr_reader :message, :identifier, :delay, :connection
end
