# Google+ Ruby Starter Project #

Welcome to developing on Google+. This is a simple starter project written in
Ruby which provides a minimal example of Google+ integration within a Sinatra
web application.

Once you've run the starter project and played with the features it provides,
this starter project provides a great place to start your experimentation into
the API.

## Prerequisites ##

Please make sure that all of these are installed before you try to run the
sample.

- Ruby 1.8.7+
- Ruby Gems 1.3.7+
- Are you on a Mac? If so, be sure you have XCode 3.2+
- A few gems (run 'sudo gem install <gem name>' to install)
-- sinatra
-- httpadapter
-- extlib
-- dm-sqlite-adapter
-- google-api-client

## Setup Authentication ##

This API uses OAuth 2.0. Learn more about Google APIs and OAuth 2.0 here:
http://code.google.com/apis/accounts/docs/OAuth2.html

Or, if you'd like to dive right in, follow these steps.
 - Visit https://code.google.com/apis/console/ to register your application.
 - From the "Project Home" screen, activate access to "Buzz API".
 - Click on "API Access" in the left column
 - Click the button labeled "Create an OAuth2 client ID"
 - Give your application a name and click "Next"
 - Select "Web Application" as the "Application type"
 - Under "Your Site or Hostname" select http:// as the protocol and enter
   "localhost" for the domain name
 - click "Create client ID"

Where to store your oAuth credentials ?
 1° copy credentials.yml.example to credentials.yml
    cd <project root>
    cp credentials.yml.example credentials.yml

 2° edit credentials.yml and use the credentials values you retrieved from the API Console:
   - oauth_client_id
   - oauth_client_secret
   - google_api_key


Or, include them in the command line as the first three arguments in that order.

## Running the Sample ##

I'm assuming you've checked out the code and are reading this from a local
directory. If not check out the code to a local directory.

1. Start up the embedded Sinatra web server

  $ ruby app.rb

2. Open your web browser and see your activities! Go to http://localhost:4567/

3. Be inspired and start hacking an amazing new web app!


Troubleshooting :
=================

* For development on 'localhost', make sure you select, in the API console, "http" for
    Redirect URIs
    javascript origins
  when creating the API access oAuth credentials for a new client.


* Make sure the 'Google+ API' service is activated in the API console "Services" section.
  Otherwise you will get an accessConfiguredError


* Make sure you have at least 1 public activity, otherwise the app will raise an error.
  Otherwise you will get a NPE on "activities['items']"



