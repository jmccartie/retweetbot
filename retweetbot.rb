#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require 'logger'


module RetweetBot

  LOGGER = Logger.new(STDERR)
  LOGGER.level = Logger::DEBUG
  JSON_PARSER = Yajl::Parser.new(:symbolize_keys => true)


  class App

    def initialize
      raise "Twitter oAuth not authorized." unless twitter_client.authorized?
    end

    def start
      LOGGER.info "Listening to Twitter stream for #{config_data[:filter].join(', ')}."

      twitter_stream.each_item do |item|
        JSON_PARSER.parse(item) do |status|
          if status.has_key?(:text) and status[:user][:screen_name] != config_data[:twitter_username]
            LOGGER.info "@#{status[:user][:name]}: #{status[:text]}"
            twitter_client.retweet(status[:id])
          end
        end
      end

      twitter_stream.on_error do |message|
        LOGGER.fatal "Error: #{message}"
        EventMachine.stop
      end

      twitter_stream.on_reconnect do |timeout, retries|
        LOGGER.warn "Reconnecting in: #{timeout} seconds."
      end

      twitter_stream.on_max_reconnects do |timeout, retries|
        LOGGER.fatal "Failed after #{retries} failed reconnects."
        EventMachine.stop
      end
    end

    def stop
      twitter_stream.stop
    end

    private

    def twitter_stream
      @twitter_stream ||= Twitter::JSONStream.connect(
        :path => '/1/statuses/filter.json',
        :method  => 'POST',
        # :ssl => true, # Would be needed by OAuth
        # :oauth => twitter_stream_oauth, # Sadly, OAuth does not work on streaming API
        :auth    => config_data[:twitter_username] + ":" + config_data[:twitter_password],
        :filters => config_data[:filter]
      )
    end

    def twitter_client
      @twitter_client ||= TwitterOAuth::Client.new(
        :consumer_key => config_data[:consumer_key],
        :consumer_secret => config_data[:consumer_secret],
        :token => config_data[:access_token],
        :secret => config_data[:access_token_secret]
      )
    end

    def twitter_stream_oauth
      {
        :consumer_key => config_data[:consumer_key],
        :consumer_secret => config_data[:consumer_secret],
        :access_key => config_data[:access_token],
        :access_secret => config_data[:access_token_secret]
      }
    end

    def config_data
      @config_data ||= read_config_file
    end

    def read_config_file
      # config_dir  = File.expand_path("~/.retweetbot")
      config_dir  = File.dirname(__FILE__)
      config_path = File.join(config_dir, "config.json")
      config_file = File.new(config_path)
      JSON_PARSER.parse(config_file)
    end

  end # class RetweetBot

end # module RetweetBot


retweetbot = RetweetBot::App.new

EventMachine::run do
  retweetbot.start
  trap('TERM') do
    retweetbot.stop
    EventMachine.stop if EventMachine.reactor_running?
  end
end
