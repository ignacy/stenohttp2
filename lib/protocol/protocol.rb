# typed: true
require 'openssl'
require 'base64'
require 'cgi'

require 'sorbet-runtime'

class Protocol
  extend T::Sig

  DEFAULT_SALT = OpenSSL::Random.random_bytes(16)
  DEFAULT_PASSWORD = 'this is a secret'

  sig { params(text: String).returns(String) }
  def encode(text)
    Encrypter.new.call(text)
  end

  sig { params(text: String).returns(String) }
  def decode(text)
    Decrypter.new.call(text)
  end

  private

  class Encrypter
    extend T::Sig

    def call(text)
      encrypted = cipher.update(text) + cipher.final
      CGI.escape(Base64.strict_encode64(encrypted))
    end

    def cipher
      @cipher ||= OpenSSL::Cipher.new('aes256').tap do |cipher|
        cipher.encrypt
        cipher.key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(
          Protocol::DEFAULT_PASSWORD,
          Protocol::DEFAULT_SALT,
          20_000,
          cipher.key_len
        )
        cipher
      end
    end
  end

  class Decrypter
    extend T::Sig

    def call(text)
      data = Base64.strict_decode64(CGI.unescape(text))

      cipher.update(data) + cipher.final
    end

    def cipher
      @cipher ||= OpenSSL::Cipher.new('aes256').tap do |cipher|
        cipher.decrypt
        cipher.key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(
          Protocol::DEFAULT_PASSWORD,
          Protocol::DEFAULT_SALT,
          20_000,
          cipher.key_len
        )
        cipher
      end
    end
  end
end
