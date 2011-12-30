require 'sinatra'
require 'haml'
require 'sass'
require 'socket'
require 'json'
require 'net/dns/resolver'

module Eagle
  class WebApplication < Sinatra::Base
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

    get '/' do
      haml :index
    end

    get '/eagle.css' do
      content_type 'text/css', :charset => 'utf-8'
      sass :eagle
    end

    get '/eagle.js' do
      content_type 'text/javascript', :charset => 'utf-8'
     File.read File.join('public', 'eagle.js')
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
  end
end
