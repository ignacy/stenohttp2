require 'openssl'
require 'sorbet-runtime'

module Stenohttp2
  module Common
    class CipherBuilder
      extend T::Sig

      DEFAULT_SALT = "\xCA|k\xC3Qw(\xB1E\xF3<\xA7\xCC\x96$\x8A".freeze # OpenSSL::Random.random_bytes(16)
      DEFAULT_PASSWORD = 'this is a secret'.freeze # don't try this at home
      CIPHER_TYPE = 'AES-256-CFB'.freeze

      class << self
        def encryptor
          new(encryptor: true).build
        end

        def decryptor
          new(encryptor: false).build
        end
      end

      sig { params(encryptor: T::Boolean).void }
      def initialize(encryptor: true)
        @encryptor = encryptor
      end

      sig { returns(OpenSSL::Cipher) }
      def build
        cipher = OpenSSL::Cipher.new(CIPHER_TYPE)
        encryptor ? cipher.encrypt : cipher.decrypt
        cipher.key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(
          DEFAULT_PASSWORD, DEFAULT_SALT, 20_000, cipher.key_len
        )
        cipher
      end

      private

      attr_reader :encryptor
    end
  end
end
