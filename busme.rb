# encoding: utf-8
require 'sinatra'
require 'connexionz'
require 'haml'
require 'twilio-ruby'

use Rack::Session::Pool

set :account_sid, ENV['TWILIO_SID']
set :account_token, ENV['TWILIO_TOKEN']
set :from_phone, ENV['TWILIO_PHONE']


post '/sms_incoming' do
  sms_message = get_et_info(10246)

  @client = Twilio::REST::Client.new settings.account_sid, settings.account_token
  @client.account.sms.messages.create(
      :from => settings.from_phone,
        :to => '+16615551234',
        :body => sms_message
  )
end

def get_et_info(platform)

  @client = Connexionz::Client.new({:endpoint => "http://12.233.207.166"})

  @platform_info = @client.route_position_et(:platformno => platform)

  if @platform_info.route_position_et.platform.nil?
    sms_message = "No bus stop found"
  else
    name = @platform_info.route_position_et.platform.name
    arrival_scope = @platform_info.route_position_et.content.max_arrival_scope
    sms_message = ""
    eta = ""
    if @platform_info.route_position_et.platform.route.nil?
      sms_message = "No arrivals for next #{arrival_scope} minutes"
    elsif @platform_info.route_position_et.platform.route.is_a?(Array)
      @platforms = @platform_info.route_position_et.platform.route
      @platforms.each do |platform|
        if platform.destination.is_a?(Array)
          platform.destination.each do |dest|
            sms_message += "#{platform.route_no}-#{dest.name}"
            sms_message += "-ETA:#{multi_eta(dest.trip)} "
          end
        else
        sms_message += "#{platform.route_no}-#{platform.destination.name}"
        sms_message += "-ETA:#{multi_eta(platform.destination.trip)} "
        end
      end
    else
      route_no = @platform_info.route_position_et.platform.route.route_no
      destination = @platform_info.route_position_et.platform.route.destination.name
      eta = multi_eta(@platform_info.route_position_et.platform.route.destination.trip)
      sms_message = "#{route_no}-#{destination}-ETA:#{eta}"
    end
  end
  sms_message.rstrip
end

def multi_eta(eta)
  multi_eta = ""
  arr_eta = []
  if eta.is_a?(Array)
    eta.each do |mult_eta|
      arr_eta.push(mult_eta.eta)
      multi_eta = arr_eta.join(',')
    end
  else
    multi_eta = eta.eta
  end
  multi_eta
end

##################
### WEB ROUTES ###
##################
get '/' do
  haml :root
end

get '/eta/:name' do
   #matches "GET /sc/19812"
   get_et_info(params[:name])
end

