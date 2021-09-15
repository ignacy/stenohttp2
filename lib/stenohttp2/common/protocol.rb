# typed: true
require 'openssl'
require 'base64'
require 'cgi'
require 'sorbet-runtime'

require_relative './cipher_builder'

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

      sig { params(message: Array).returns(String) }
      def decompress_and_decode(message)
        decode(message.join.strip)
      end

      class Encrypter
        extend T::Sig

        sig { params(text: String).returns(String) }
        def call(text)
          encrypted = cipher.update(text) + cipher.final
          CGI.escape(Base64.strict_encode64(encrypted))
        end

        def cipher
          @cipher ||= ::Stenohttp2::Common::CipherBuilder.encryptor
        end
      end

      class Decrypter
        extend T::Sig

        sig { params(text: String).returns(String) }
        def call(text)
          data = Base64.strict_decode64(CGI.unescape(text))

          cipher.update(data) + cipher.final
        end

        def cipher
          @cipher ||= ::Stenohttp2::Common::CipherBuilder.decryptor
        end
      end
    end
  end
end
