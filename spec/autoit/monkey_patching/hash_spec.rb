require 'spec_helper'

describe Hash do

  after(:all) do
    h2 = @h.to_h_from_kv
    h2.should be_instance_of Hash
    h2.should == @h
  end

  context "when converting an empty hash into a hash" do
    it "should return the same hash" do
      @h = {}
    end
  end

  context "when converting a hash with a single entry into a hash" do
    it "should return the same hash" do
      @h = { 'key' => 'value' }
    end
  end

  context "when converting a hash with a single entry of nil key into a hash" do
    it "should return the same hash" do
      @h = { nil => 'value' }
    end
  end

  context "when converting a hash with multiple entries into a hash" do
    it "should return the same hash" do
      @h = {
        'k1' => 'v1',
        'k2' => 'v2',
        'k3' => 'v3' }
    end
  end
end

