# typed: true
require 'openssl'
require 'base64'
require 'cgi'

require 'sorbet-runtime'

module Stenohttp2
  module Common
    class Protocol
      extend T::Sig

      sig { params(text: String).returns(String) }
      def encode(text)
        Encrypter.new.call(text)
      end

      sig { params(text: String).returns(String) }
      def decode(text)
        Decrypter.new.call(text)
      end

      def decompress_and_decode(message)
        decode(message.join.strip)
      end

      class Encrypter
        extend T::Sig

        def call(text)
          encrypted = cipher.update(text) + cipher.final
          CGI.escape(Base64.strict_encode64(encrypted))
        end

        def cipher
          @cipher ||= OpenSSL::Cipher.new('AES-256-CFB').then do |cipher|
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
        extend T::Sig

        def call(text)
          data = Base64.strict_decode64(CGI.unescape(text))

          cipher.update(data) + cipher.final
        end

        def cipher
          @cipher ||= OpenSSL::Cipher.new('AES-256-CFB').then do |cipher|
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
