require 'bundler'
Bundler.require

require 'eagle'

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
        eagle = Eagle.new rescue nil
        return nil unless eagle

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
      return nil unless params[:prefix]
      JSON.pretty_generate lookup(params[:prefix])
    end

    post '/lookup' do
      # default to prefix lookup for now
      return nil unless params[:data]

      # default to prefix lookup for now
      #if params[:action] == 'prefix'
        @paths = lookup params[:prefix]
        haml :prefixes
      #end
    end

    get %r{/lookup/(aspath|communities|localpref|nexthop|origin_as)} do
      JSON.pretty_generate collect(params[:prefix], params[:captures].first).uniq
      return nil unless params[:prefix]
    end
    
    aget %r{/css/(default|reset)\.css} do |css|
      content_type 'text/css', :charset => 'utf-8'
      body { sass :"#{css}" }
    end
  end
end
