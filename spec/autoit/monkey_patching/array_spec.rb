require 'spec_helper'

describe Array do
  context "when converting an empty array into a hash" do
    it "should return an empty hash" do
      h = [].to_h_from_kv
      h.should be_instance_of Hash
      h.should be_empty
    end
  end

  context "when converting an array with one duple into a hash" do
    it "should return a hash with one key-value entry of that duple" do
      k = 'key'
      v = 'value'
      h = [[k, v]].to_h_from_kv
      h.should be_instance_of Hash
      h.should have_exactly(1).items
      h.should include(k)
      h[k].should == v
    end
  end

  context "when converting an array with a single duple of nil key into a hash" do
    it "should return a hash with one nil-value entry of that duple" do
      k = nil
      v = 'value'
      h = [[k, v]].to_h_from_kv
      h.should be_instance_of Hash
      h.should have_exactly(1).items
      h.should include(k)
      h[k].should == v
    end
  end

  context "when converting an array with a single duple of nil value into a hash" do
    it "should return a hash with one key-value entry of that duple" do
      k = 'key'
      v = nil
      h = [[k, v]].to_h_from_kv
      h.should be_instance_of Hash
      h.should have_exactly(1).items
      h.should include(k)
      h[k].should == v
      h[k].should be_nil
    end
  end

  context "when converting an array with a single duple of Array-type key into a hash" do
    it "should return a hash with one Array-value entry of that duple" do
      k = ['k1', 'k2']
      v = 'value'
      h = [[k, v]].to_h_from_kv
      h.should be_instance_of Hash
      h.should have_exactly(1).items
      h.should include(k)
      h[k].should == v
    end
  end

  context "when converting an array with a single duple of Array-type value into a hash" do
    it "should return a hash with one key-Array entry of that duple" do
      k = 'key'
      v = ['v1', 'v2']
      h = [[k, v]].to_h_from_kv
      h.should be_instance_of Hash
      h.should have_exactly(1).items
      h.should include(k)
      h[k].should == v
    end
  end

  context "when converting an array with multiple duples into a hash" do
    it "should return a hash with the corresponding key-value entries" do
      a = [['k1', 'v1'],
           ['k2', 'v2'],
           ['k3', 'v3']]
      h = a.to_h_from_kv
      h.should be_instance_of Hash
      h.should have_exactly(a.size).items
      a.each do |k, v|
        h.should include(k)
        h[k].should == v
      end
    end
  end
end

