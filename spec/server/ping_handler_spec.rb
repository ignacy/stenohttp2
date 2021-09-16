# typed: false

require 'spec_helper'
require 'fileutils'

RSpec.describe Stenohttp2::Server::PingHandler do
  subject { described_class.new }

  before do
    FileUtils.mkdir_p('tmp/server')
    FileUtils.mkdir_p('tmp/client')
  end

  context '#waiting' do
    it 'begins in the ready state' do
      expect(subject).to be_waiting
    end
  end

  context 'ignored frames' do
    it 'ignores non ping frames' do
      frame = { type: :content }
      expect do
        subject.handle(frame)
      end.to_not change { subject.state }.from('waiting')
    end

    it 'ignores ping frames with ack flag ' do
      frame = { type: :ping, flags: [:ack] }
      expect do
        subject.handle(frame)
      end.to_not change { subject.state }.from('waiting')
    end
  end

  context 'recognizes identifiers' do
    before do
      stub_const("#{described_class}::IDENTIFIERS", ['client'])
    end

    it 'when client starts transmission' do
      frame = { type: :ping, flags: [], payload: 'client' }
      expect do
        subject.handle(frame)
      end.to change { subject.state }.from('waiting').to('reciving')
    end
  end

  context 'saves and finishes ' do
    before do
      stub_const("#{described_class}::IDENTIFIERS", ['client'])
    end

    it 'whole transmission' do
      expect do
        subject.handle({ type: :ping, flags: [], payload: 'client' })
        subject.handle({ type: :ping, flags: [], payload: '4u2' })
        subject.handle({ type: :ping, flags: [], payload: 'have' })
        subject.handle({ type: :ping, flags: [], payload: 'a' })
        subject.handle({ type: :ping, flags: [], payload: 'nice' })
        subject.handle({ type: :ping, flags: [], payload: 'day' })
      end.to change { subject.state }.to('responding')
    end
  end
end
