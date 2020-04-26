# typed: false

require 'spec_helper'

RSpec.describe Protocol do
  subject { described_class.new }

  it "encodes the message" do
    expect(subject.encode("hello")).to_not eq("hello")

  end
end
