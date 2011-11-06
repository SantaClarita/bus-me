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
      last_response.body.should =="2-Val Verde-ETA:20"
    end

    it "should return the time for multiple trips" do
      stub_request(:get, "http://12.233.207.166/rtt/public/utility/file.aspx?contenttype=SQLXML&Name=RoutePositionET.xml&platformno=10656").
        to_return(:status => 200, :body => fixture("multi_trip.xml"))
      get '/eta/10656'
      last_response.should be_ok
      last_response.body.should =="2-Val Verde-ETA:5,20"
    end

    it "should return the time for the next arrival" do
      stub_request(:get, "http://12.233.207.166/rtt/public/utility/file.aspx?contenttype=SQLXML&Name=RoutePositionET.xml&platformno=10246").
        to_return(:status => 200, :body => fixture("route_et.xml"))
      get '/eta/10246'
      last_response.body.should == "1-Castaic-ETA:24 4-LARC-ETA:19 6-Shadow Pines-ETA:17 14-Plum Cyn-ETA:11"
    end

    it "should return the time for multiple arrivals on same route" do
      stub_request(:get, "http://12.233.207.166/rtt/public/utility/file.aspx?contenttype=SQLXML&Name=RoutePositionET.xml&platformno=19444").
        to_return(:status => 200, :body => fixture("multi_eta.xml"))
      get '/eta/19444'
      last_response.body.should == "1-Castaic-ETA:3,6 1-Whites Cyn-ETA:10 3-Magic Mtn-ETA:18 3-Seco Canyon-ETA:6 4-LARC-ETA:7 4-Newhall Metrolink-ETA:11 5-Stevenson Ranch-ETA:17 6-Shadow Pines-ETA:20"
    end
  end

  describe "/sms_incoming" do
    before do
      set :from_phone, '+16615551212'
      set :account_token, 'abc123'
      set :account_sid, 'xyz987'
      stub_request(:get, "http://12.233.207.166/rtt/public/utility/file.aspx?contenttype=SQLXML&Name=RoutePositionET.xml&platformno=10246").
        to_return(:status => 200, :body => fixture("route_et.xml"))
     stub_request(:post, "https://xyz987:abc123@api.twilio.com/2010-04-01/Accounts/xyz987/SMS/Messages.json").
         with(:body => {"From"=>"+16615551212", "To"=>"+16615551234", "Body"=>"1-Castaic-ETA:24 4-LARC-ETA:19 6-Shadow Pines-ETA:17 14-Plum Cyn-ETA:11"},
              :headers => {'Accept'=>'application/json', 'Content-Type'=>'application/x-www-form-urlencoded', 'User-Agent'=>'twilio-ruby/3.4.2'}).
         to_return(:status => 200, :body => fixture("twilio_return.json"), :headers => {})
    end

    it "should send a text message" do
      post '/sms_incoming', :AccountSid => 'xyz987', :From => '+16615551234', :To => '+16615551212', :Body => '10246'
      last_response.body.should == "1-Castaic-ETA:24 4-LARC-ETA:19 6-Shadow Pines-ETA:17 14-Plum Cyn-ETA:11"
    end

    it "should return no AccountSid" do
      post '/sms_incoming', :AccountSid => 'abc123', :From => '+1661555124', :To => '+16615551212', :Body => '10246'
      last_response.body.should == "Invalid AccountSid"
    end
  end

end

