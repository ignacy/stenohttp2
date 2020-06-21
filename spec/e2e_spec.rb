# typed: false

require 'spec_helper'

RSpec.describe 'Cupher encode and split the message and assemble + decode it' do
  let(:secret) { 'Najlepsze kasztany sa na placu pigalle' }

  it 'should split message into 8bits' do
    message = Message.new(secret)

    decoded = Protocol.new.decompress_and_decode(message.parts)
    expect(decoded).to eq(secret)
  end
end
