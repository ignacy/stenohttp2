# typed: true

require 'listen'
require_relative 'framer'
require_relative 'compressor'
require_relative 'protocol'

class Watcher
  def initialize(dir)
    @dir = dir
    @path = "/Users/ignacy/code/stenohttp2/#{@dir}"
  end

  def start
    puts "Listening on #{path} for *.message"
    listener = Listen.to(path) do |modified, added, removed|
      new_file = added&.first
      if new_file
        decode_message(File.read(new_file)) if new_file.end_with?('message')
      end
    end
    listener.start
    sleep
  end

  private

  attr_reader :path

  # TODO: Tu powinna byc jedna abstrakcja
  def decode_message(data)
    numbers = data.split(/\s+/).reject(&:empty?).map(&:chomp)
    binaries = Framer.new.numbers_to_binary_string(numbers)
    decompressed = Compressor.decompress(binaries)
    message = Protocol.new.decode(decompressed)
    puts "Received message: #{message}"
  rescue StandardError
    puts 'Coudlnt read the data'
  end
end
