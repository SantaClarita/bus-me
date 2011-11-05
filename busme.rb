# encoding: utf-8
require 'sinatra'
require 'connexionz'
require 'haml'

use Rack::Session::Pool

def get_et_info(platform)

  @client = Connexionz::Client.new({:endpoint => "http://12.233.207.166"})

  @platform_info = @client.route_position_et({:platformno => platform})

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
        sms_message += "Route #{platform.route_no}-Destination #{platform.destination.name}-ETA #{platform.destination.trip.eta } minutes "
      end
    else
      route_no = @platform_info.route_position_et.platform.route.route_no
      destination = @platform_info.route_position_et.platform.route.destination.name
      if @platform_info.route_position_et.platform.route.destination.trip.is_a?(Array)
        @platform_info.route_position_et.platform.route.destination.trip.each do |mult_eta|
          eta += "#{mult_eta.eta} min "
        end
      else
        eta = "#{@platform_info.route_position_et.platform.route.destination.trip.eta} min"
      end
      sms_message = "Route #{route_no} " + "-Destination #{destination} " + "-ETA #{eta}"
    end
  end
  sms_message
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

