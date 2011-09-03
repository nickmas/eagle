require 'rubygems'
require 'active_record'
require 'sinatra/activerecord'

# establish database connection
set :database, 'postgres://localhost/newapp' if !ENV['DATABASE_URL']
puts "#{database.connection.inspect.to_s}\n\n"