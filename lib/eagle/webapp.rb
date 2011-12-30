require 'rubygems'
require 'sinatra'
require 'sinatra/async'
require 'sinatra/settings'
require 'haml'
require 'rack-flash'
require 'eagle'
require 'socket'
require 'json'
require 'net/dns/resolver'

module Eagle
  class Application < Sinatra::Application
    register Sinatra::Async
    configure :development do
      register Sinatra::Settings
      enable :show_settings
    end
    use Rack::Session::Pool
    use Rack::Flash

    helpers do
      # quick and dirty helper to resolve IP addresses
      def resolve_ip(ip)
        Net::DNS::Resolver.start(ip, Net::DNS::PTR).answer[0].to_s.split(/\s+/)[4].sub(/\.$/, '') rescue "no reverse DNS"
      end

      # init eagle class and perform lookup
      def lookup(prefix)
        nil unless eagle = Eagle.new rescue nil
        eagle.find_prefix prefix
      end

      # return array of a specific type
      def collect(prefix, type)
        collection = Array.new
        lookup.prefix.each do |prefix|
          collection.push prefix[type]
        end
        collection
      end
    end

    aget '/' do
      body { haml :index }
    end

    # XXX: need a proper error handler for class init failure
    #       and missing form parameters
    get '/lookup' do
      nil unless params[:prefix]
      JSON.pretty_generate lookup(params[:prefix])
    end

    post '/lookup' do
      # default to prefix lookup for now
      nil unless params[:data]

      # default to prefix lookup for now
      #if params[:action] == 'prefix'
        @paths = lookup params[:prefix]
        haml :prefixes
      #end
    end

    get %r{/lookup/(aspath|communities|localpref|nexthop|origin_as)} do
      nil unless params[:prefix]
      JSON.pretty_generate collect(params[:prefix], params[:captures].first).uniq
    end
    
    aget %r{/css/(default|reset)\.css} do |css|
      content_type 'text/css', :charset => 'utf-8'
      body { sass :"#{css}" }
    end
  end
end
