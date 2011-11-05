require File.dirname(__FILE__) + '/spec_helper'

describe 'Bus Me Application' do

  before(:all) do
    set :sender_phone, '555-555-1212'
  end

  describe "Root view" do
    it "Should return the home page" do
      get '/'
      last_response.should be_ok
    end
  end

  describe "#route_et" do
    it "should return no bus stop found" do
      stub_request(:get, "http://12.233.207.166/rtt/public/utility/file.aspx?contenttype=SQLXML&Name=RoutePositionET.xml&platformno=10000").
        to_return(:status => 200, :body => fixture("no_platform.xml"))
      get '/eta/10000'
      last_response.should be_ok
      last_response.body.should == 'No bus stop found'
    end

    it "should return no arrivals for scope" do
      stub_request(:get, "http://12.233.207.166/rtt/public/utility/file.aspx?contenttype=SQLXML&Name=RoutePositionET.xml&platformno=15414").
        to_return(:status => 200, :body => fixture("no_arrivals.xml"))
      get '/eta/15414'
      last_response.should be_ok
      last_response.body.should == "No arrivals for next 30 minutes"
    end

    it "should return the time for the one arrival" do
      stub_request(:get, "http://12.233.207.166/rtt/public/utility/file.aspx?contenttype=SQLXML&Name=RoutePositionET.xml&platformno=10656").
        to_return(:status => 200, :body => fixture("one_arrival.xml"))
      get '/eta/10656'
      last_response.should be_ok
      last_response.body.should =="Route 2 -Destination Val Verde -ETA 20 min"
    end

    it "should return the time for the next arrival" do
      stub_request(:get, "http://12.233.207.166/rtt/public/utility/file.aspx?contenttype=SQLXML&Name=RoutePositionET.xml&platformno=10246").
        to_return(:status => 200, :body => fixture("route_et.xml"))
      get '/eta/10246'
      last_response.body.should == "Route 1-Destination Castaic-ETA 24 minutes Route 4-Destination LARC-ETA 19 minutes Route 6-Destination Shadow Pines-ETA 17 minutes Route 14-Destination Plum Cyn-ETA 11 minutes "
    end

  end
end

