require 'openssl'
require 'base64'
require 'cgi'

module Stenohttp2
  module Common
    class Protocol
      def encode(text)
        Encrypter.new.call(text)
      end

      def decode(text)
        Decrypter.new.call(text)
      end

      def decompress_and_decode(message)
        decode(message.join.strip)
      end

      class Encrypter
        def call(text)
          encrypted = cipher.update(text) + cipher.final
          CGI.escape(Base64.strict_encode64(encrypted))
        end

        def cipher
          @cipher ||= OpenSSL::Cipher.new('AES-256-CFB').tap do |cipher|
            cipher.encrypt
            cipher.key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(
              ENV.fetch('DEFAULT_PASSWORD'),
              ENV.fetch('DEFAULT_SALT'),
              20_000,
              cipher.key_len
            )
          end
        end
      end

      class Decrypter
        def call(text)
          data = Base64.strict_decode64(CGI.unescape(text))

          cipher.update(data) + cipher.final
        end

        def cipher
          @cipher ||= OpenSSL::Cipher.new('AES-256-CFB').tap do |cipher|
            cipher.decrypt
            cipher.key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(
              ENV.fetch('DEFAULT_PASSWORD'),
              ENV.fetch('DEFAULT_SALT'),
              20_000,
              cipher.key_len
            )
          end
        end
      end
    end
  end
end
