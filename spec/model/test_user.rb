require File.join(File.dirname(__FILE__), "helper")

HUMAN_ID = 'human@googlewave.com'
ROBOT_ID = 'robot@appspot.com'
URL = 'http://googlewave.com'

describe Rave::Models::User do
  
  before :each do
  end
  
  describe "robot?()" do
    it "should return false for a human user" do
      human = Rave::Models::User.new(:id => HUMAN_ID)
      human.robot?.should be_false
    end
    
    it "should return true for a robot" do
      robot = Rave::Models::User.new(:id => ROBOT_ID)
      robot.robot?.should be_true
    end
  end

  describe "url()" do
    it "Should be the :url passed in the constructor" do
      user = Rave::Models::User.new(:url => URL)
      user.url.should == URL
    end

    it "should default to an empty string" do
      user = Rave::Models::User.new()
      user.url.should == ''
    end
  end

  describe "name()" do
    it "should return the name passed in the constructor" do
      user = Rave::Models::User.new(:id => HUMAN_ID, :name => 'fred')
      user.name.should == 'fred'
    end

    it "should default to the ID" do
      user = Rave::Models::User.new(:id => HUMAN_ID)
      user.name.should == HUMAN_ID
    end
  end

  describe "id()" do
    it "should return the ID passed in the constructor" do
      user = Rave::Models::User.new(:id => HUMAN_ID)
      user.id.should == HUMAN_ID
    end
  end
end