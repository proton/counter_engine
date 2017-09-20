require "spec_helper"

RSpec.describe CounterEngine do
  it "has a version number" do
    expect(CounterEngine::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end
end
