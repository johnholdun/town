require 'rubygems'
require 'bundler/setup'
require 'sinatra/base'
require 'sinatra/assetpack'
require 'sinatra/reloader'
require 'active_support/all'
require 'haml'

Walls = File.read('walls.dat').split("\n").map{ |row| row.split('').map{ |cell| cell == '1' } }
Users = {}

class Town < Sinatra::Base
  use Rack::Session::Cookie

  set :root, File.dirname(__FILE__)

  before do
    if request.path != '/' and request.path =~ %r[/$]
      redirect request.path[0 .. -2]
      return
    end

    # if request.post? and (request.path == '/games' or request.path =~ %r[^/[^/]+/[^/]+/?$])
    #   request.body.rewind
    #   @request_payload = JSON.parse request.body.read rescue nil
    # end
  end

  register Sinatra::AssetPack

  configure :development do
    register Sinatra::Reloader
  end

  # assets do
  #   serve '/javascripts', from: 'assets/javascripts'
  #   serve '/stylesheets', from: 'assets/stylesheets'

  #   js :game, '/javascripts/game.js', [
  #     '/javascripts/vendor/underscore-1.6.min.js',
  #     '/javascripts/vendor/handlebars-v1.3.0.js',
  #     '/javascripts/main.js'
  #   ]

  #   js :editor, '/javascripts/editor-compiled.js', [
  #     '/javascripts/vendor/underscore-1.6.min.js',
  #     '/javascripts/vendor/haml.js',
  #     '/javascripts/editor.js'
  #   ]

  #   css :application, '/stylesheets/application.css', [
  #     '/stylesheets/*.css'
  #   ]

  #   js_compression :uglify
  #   css_compression :sass

  #   prebuild true
  # end

  set :views, 'views'
  set :env, ENV['RACK_ENV'] || 'development'
  layout :layout

  # configure do
  #   set :session_secret, ENV['COOKIE_SECRET']
  #   enable :sessions
  # end

  helpers do
    def snake_to_title string
      string = string.gsub /([A-Z])/, ' \1'
      string[0,1] = string[0,1].upcase
      string
    end
  end

  get '/' do
    File.read 'index.html'
  end

  post '/' do
    intent = {}
    (params['intent'] || {}).each do |k, v|
      intent[k.to_sym] = v.to_i
    end

    user = Users[params['id']] if params['id']
    unless user
      user = {
        id: SecureRandom.hex,
        location: { x: 66, y: 246 },
        viewport: { x: 63, y: 243 }
      }
      Users[user[:id]] = user
    end

    tryLocation = {
      x: user[:location][:x] + intent[:x].to_i,
      y: user[:location][:y] + intent[:y].to_i
    }

    passable = !Walls[tryLocation[:y]][tryLocation[:x]]
    if passable
      user[:location].update tryLocation
    end

    viewportWidth = 10
    viewportHeight = 8
    buffer = 3 # minimum tiles from player to edge of viewport

    if user[:location][:x] - user[:viewport][:x] < buffer
      user[:viewport][:x] = user[:location][:x] - buffer
    elsif user[:viewport][:x] + viewportWidth - user[:location][:x] <= buffer
      user[:viewport][:x] = user[:location][:x] + buffer - viewportWidth + 1
    end

    if user[:location][:y] - user[:viewport][:y] < buffer
      user[:viewport][:y] = user[:location][:y] - buffer
    elsif user[:viewport][:y] + viewportHeight - user[:location][:y] <= buffer
      user[:viewport][:y] = user[:location][:y] + buffer - viewportHeight + 1
    end

    user_entities = Users.values.map{ |user| { id: user[:id] }.merge user[:location] }

    {
      id: user[:id],
      viewport: user[:viewport],
      entities: user_entities
    }.to_json
  end
end