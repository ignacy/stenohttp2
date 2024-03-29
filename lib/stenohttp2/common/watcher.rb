# typed: ignore

require 'listen'

module Stenohttp2
  module Common
    class Watcher
      def initialize(dir)
        @path = File.expand_path(dir)
      end

      def start
        puts "Listening on #{path} for *.message"
        listener = Listen.to(path) do |modified, added, _|
          new_file = added&.first || modified&.first
          decode_message(File.read(new_file)) if new_file&.end_with?('message')
        end
        listener.start
        sleep
      end

      private

      attr_reader :path

      # TODO: Tu powinna byc jedna abstrakcja
      def decode_message(data)
        numbers = data.split(/\s+/).reject(&:empty?).map(&:chomp)
        message = Protocol.new.decompress_and_decode(numbers)
        puts "Received message: \n\t #{message} \n"
      rescue StandardError => e
        puts "Could not read the data #{e} [Message incomplete?]"
      end
    end
  end
end
