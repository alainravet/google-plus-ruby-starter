#####!/usr/bin/ruby1.8

# Copyright:: Copyright 2011 Google Inc.
# License:: All Rights Reserved.
# Original Author:: Bob Aman
# Maintainer:: Daniel Dobson
# Maintainer:: Jenny Murphy
# Starter project for Google+ using Sinatra

require 'rubygems'
require 'sinatra'
require 'google/api_client'
require 'httpadapter/adapters/net_http'
require 'pp'

use Rack::Session::Pool, :expire_after => 86400 # 1 day

# Configuration
# See README.TXT for getting API id and secret

if (ARGV.size < 3)
  set :oauth_client_id, 'oauth_client_id'
  set :oauth_client_secret, 'oauth_client_secret'
  set :google_api_key, 'google_api_key'

  if (settings.oauth_client_id == 'oauth_client_id' ||
    settings.oauth_client_secret == 'oauth_client_secret' ||
    settings.oauth_client_secret == 'google_api_key')
    
    puts 'Usage: ruby app.rb <oauth_client_id> <oauth_client_secret> <google_api_key>'
    puts 'See README.TXT for getting API key, id and secret.  Server terminated.'
    exit(0)
  end
else
  # If the api keys are specified on the command line, grab them
  set :oauth_client_id, ARGV[0]
  set :oauth_client_secret, ARGV[1]
  set :google_api_key, ARGV[2]
end

# Configuration that you probably don't have to change
set :oauth_scopes, 'https://www.googleapis.com/auth/plus.me'

class TokenPair
  @refresh_token
  @access_token
  @expires_in
  @issued_at

  def update_token!(object)
    @refresh_token = object.refresh_token
    @access_token = object.access_token
    @expires_in = object.expires_in
    @issued_at = object.issued_at
  end

  def to_hash
    return {
      :refresh_token => @refresh_token,
      :access_token => @access_token,
      :expires_in => @expires_in,
      :issued_at => Time.at(@issued_at)
    }
  end
end

# At the beginning of any request, make sure the OAuth token is available.
# If it's not available, kick off the OAuth 2 flow to authorize.
before do
  unless request.path_info == '/style.css'
    # Create an unauthenticated client for requests that do not require us to
    #   be authenticated
#    @unauthenticated_client = Google::APIClient.new
#    @unauthenticated_plus = @unauthenticated_client.discovered_api('plus', 'v1')

    @client = Google::APIClient.new(
      :authorization => :oauth_2,
      :host => 'www.googleapis.com',
      :http_adapter => HTTPAdapter::NetHTTPAdapter.new
    )

    @client.authorization.client_id = settings.oauth_client_id
    @client.authorization.client_secret = settings.oauth_client_secret
    @client.authorization.scope = settings.oauth_scopes
    @client.authorization.redirect_uri = to('/oauth2callback')
    @client.authorization.code = params[:code] if params[:code]
    if session[:token]
      # Load the access token here if it's available
      @client.authorization.update_token!(session[:token].to_hash)
    end

    @plus = @client.discovered_api('plus', 'v1')
    unless @client.authorization.access_token || request.path_info =~ /^\/oauth2/
      redirect to('/oauth2authorize')
    end
  end
end

get '/style.css' do
  send_file 'style.css', :type => :css
end

# Part of the OAuth flow
get '/oauth2authorize' do
  <<OUT
<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
  <title>Google+ API Ruby Starter App</title>
  <link rel="stylesheet" href="style.css" type="text/css"/>
</head>
<body>
<header><h1>Google+ API Ruby Starter App</h1></header>
<div class="box">
<a class='login' href='#{@client.authorization.authorization_uri.to_s}'>Connect Me!</a>
</div>
</body>
</html>
OUT
end

# Part of the OAuth flow
get '/oauth2callback' do
  @client.authorization.fetch_access_token!
  unless session[:token]
    token_pair = TokenPair.new
    token_pair.update_token!(@client.authorization)
    # Persist the token here
    session[:token] = token_pair
    p token_pair
  end
  redirect to('/')
end

# The method you're probably actually interested in.
get '/' do
  # Fetch a known public activity
  status, headers, body = @client.execute(
    @plus.activities.get,
    'activityId' => 'z12gtjhq3qn2xxl2o224exwiqruvtda0i'
  )
  public_activity = JSON.parse(body[0])

  # Fetch my profile
  status, headers, body = @client.execute(
    @plus.people.get,
    'userId' => 'me'
  )
  profile = JSON.parse(body[0])

  # Fetch my activities
  status, headers, body = @client.execute(
    @plus.activities.list,
    'userId' => 'me', 'collection' => 'public'
  )
  activities = JSON.parse(body[0])

  # Fetch an arbitrary public activity by ID
  
  output = <<TOPOUT
<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
  <title>ES API Starter App</title>
  <link rel="stylesheet" href="style.css" type="text/css"/>
</head>
<body>
<header><h1>Google+ API Starter App</h1></header>

<div class="largerbox">
  <p>Your OAuth 2.0 token is in the rack session.</p>

  <p class="logout"><a href="clearsession">Logout</a> by deleting this token.</p>

  <section class="activity">
      <h3>A Specific Public Activity</h3>
      <dl>
          <dt>ID</dt>
          <dd>
              <a href="#{public_activity['url']}">#{public_activity['id']}</a>
          </dd>
          <dt>Content</dt>
          <dd>
              #{public_activity['object']['content']}
          </dd>
      </dl>
  </section>
</div>
<div class="box">
  <section class="me">
    <h3>Your Profile</h3>
    <dl>
      <dt>Image</dt>
      <dd><a href="#{profile['url']}">
        <img width="100" src="#{profile['image']['url']}?sz=100"/></a>
      </dd>
      <dt>ID</dt>
      <dd>#{profile['id']}</dd>
      <dt>Name</dt>
      <dd><a href="#{profile['url']}">#{profile['displayName']}</a>
      </dd>
    </dl>
  </section>
</div>
<div class="largerbox">
  <section class="activity">
    <h3>Your Public Activity</h3>
    <table>
      <thead>
      <tr>
        <th>ID</th>
        <th>Content</th>
      </tr>
      </thead>
      <tbody>
TOPOUT

  activities['items'].each { |i|
  # Print the Person ID, their name
    output += "<tr><td><a href=\"#{i['url']}\">#{i['id']}</td>"
    output += "<td>#{i['object']['content']}</td></tr>"
  }

  output += <<BOTTOMOUT
      </tbody>
    </table>
  </section>
</div>
</body>
</html>
BOTTOMOUT

  #render the final output
  output
end

# Clears the token saved in the session
get '/clearsession' do
  session.delete(:token)
  redirect to('/')
end
