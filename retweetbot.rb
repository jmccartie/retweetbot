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

    CONFIG = {
      twitter_username: ENV['TWITTER_USERNAME'],
      twitter_password: ENV['TWITTER_PASSWORD'],
      consumer_key: ENV['CONSUMER_KEY'],
      consumer_secret: ENV['CONSUMER_SECRET'],
      access_token: ENV['ACCESS_TOKEN'],
      access_token_secret: ENV['ACCESS_TOKEN_SECRET'],
      filter: ENV['FILTER'],
      follow: ENV['FOLLOW']
    }

    def initialize
      raise "Twitter oAuth not authorized." unless twitter_client.authorized?
    end

    def start
      welcome = "Listening to Twitter stream for #{CONFIG[:filter].join(', ')}."
      welcome << " (but only from #{CONFIG[:follow].count} users)" unless CONFIG[:follow].nil?
      LOGGER.info welcome

      twitter_stream.each_item do |item|
        JSON_PARSER.parse(item) do |status|
          if status.has_key?(:text) and status[:user][:screen_name] != CONFIG[:twitter_username] and CONFIG[:follow].include?(status[:user][:id])
            LOGGER.info "@#{status[:user][:name]}: #{status[:text]}"
            result = twitter_client.retweet(status[:id])
            LOGGER.warn "ERROR: #{result[:errors]}" if result.has_key?(:errors)
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
        :method  => 'POST',
        # :ssl => true, # Would be needed by OAuth
        # :oauth => twitter_stream_oauth, # Sadly, OAuth does not work on streaming API
        :auth    => CONFIG[:twitter_username] + ":" + CONFIG[:twitter_password],
        :filters => CONFIG[:filter]
      )
    end

    def twitter_client
      @twitter_client ||= TwitterOAuth::Client.new(
        :consumer_key => CONFIG[:consumer_key],
        :consumer_secret => CONFIG[:consumer_secret],
        :token => CONFIG[:access_token],
        :secret => CONFIG[:access_token_secret]
      )
    end

    def twitter_stream_oauth
      {
        :consumer_key => CONFIG[:consumer_key],
        :consumer_secret => CONFIG[:consumer_secret],
        :access_key => CONFIG[:access_token],
        :access_secret => CONFIG[:access_token_secret]
      }
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
