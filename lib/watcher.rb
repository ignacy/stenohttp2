# typed: true

require 'listen'
require_relative 'message'
require_relative 'protocol'

class Watcher
  def initialize(dir)
    @dir = dir
    @path = "/Users/ignacy/code/stenohttp2/#{@dir}"
  end

  def start
    puts "Listening on #{path} for *.message"
    listener = Listen.to(path) do |modified, added, _|
      new_file = added&.first || modified&.first
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
    message = Protocol.new.decompress_and_decode(numbers)
    puts "Received message: \n\t #{message} \n"
  rescue StandardError => ex
    puts "Could not read the data #{ex} [Message incomplete?]"
  end
end
