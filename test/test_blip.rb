require File.join(File.dirname(__FILE__), "helper")

describe Rave::Models::Blip do
  
  before :all do
    @class = Rave::Models::Blip
  end
  
  describe "root?()" do
    
    it "should return true if a blip has no parent blip id" do
      blip = Blip.new
      blip.parent_blip_id.should be_nil
      blip.root?.should be_true
      blip = Blip.new(:parent_blip_id => "parent_blip")
      blip.parent_blip_id.should_not be_nil
      blip.root?.should be_false
    end
    
  end
  
end