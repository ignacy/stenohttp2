# typed: ignore
module Stenohttp2
  module Server
    class StreamHandler
      def initialize(stream)
        @stream = stream
      end

      # rubocop:disable Metrics/AbcSize
      def setup
        log = Stenohttp2::Logger.new(stream.id)
        req = T.let({}, T.untyped)
        buffer = ''

        stream.on(:headers) do |h|
          req = Hash[*h.flatten]
          log.info "request headers: #{h}"
        end

        stream.on(:data) do |d|
          buffer << d
        end

        stream.on(:half_close) do
          log.info 'client closed its end of the stream... responding'
          response = Response.new(stream)
          response.build

          # Stream data to show this works
          stream.data(response.content[0...5], end_stream: false)
          stream.data(response.content[5...-1])
        end
      end
      # rubocop:enable Metrics/AbcSize

      private

      class Response
        def initialize(stream)
          @content = File.read(File.join('public', 'index.html'))
          @stream = stream
        end

        # We need this to be writable :reek:Attribute
        attr_accessor :content

        def build
          stream.headers(
            {
              ':status' => '200',
              'content-length' => content.bytesize.to_s,
              'content-type' => 'text/html'
            },
            end_stream: false
          )
        end

        private

        attr_reader :stream
      end

      attr_reader :stream
    end
  end
end
