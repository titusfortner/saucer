require "spec_helper"

RSpec.describe Saucer do
  it "has a version number" do
    expect(Saucer::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end
end
