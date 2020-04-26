# typed: true
require 'openssl'
require 'base64'
require 'cgi'

require 'sorbet-runtime'

class Protocol
  extend T::Sig

  DEFAULT_KEY = "W\x11\x97\x8D\x7Ff3\xF0\xAB\xE2\x1A\x90\rk\x99\xDA"
  DEFAULT_IV = "\xE4\fZ[\xB1\xC5\xF5\x85\r\x96\x7F\x90cH\x9D\x81"

  sig { params(key: String, iv: String).void }
  def initialize(key: DEFAULT_KEY, iv: DEFAULT_IV)
    @key = key
    @iv = iv
  end

  sig { params(text: String).returns(String) }
  def encode(text)
    Encoder.new(key, iv).call(text)
  end

  private

  attr_reader :key, :iv

  class Encoder
    extend T::Sig

    sig { params(key: String, iv: String).void }
    def initialize(key, iv)
      @key = key
      @iv = iv
    end

    def call(text)
      data = cipher.update(text) + cipher.final
      data = iv.force_encoding('ASCII-8BIT') + data
      data = Base64.encode64(data)
      CGI.escape(data)
    end

    attr_reader :key, :iv

    def cipher
      @cipher ||= OpenSSL::Cipher::AES.new(128, :CBC).tap do |cipher|
        cipher.encrypt
        cipher.key = key
        cipher.iv = iv
      end
    end
  end
end
