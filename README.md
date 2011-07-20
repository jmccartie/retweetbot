# RetweetBot

RetweetBot listens for certain keywords or hashtags and native retweets what it hears. It uses the Twitter streaming APIs and runs inside an EventMachine reactor. If Twitter is functioning properly, discovering matching tweets is near instant.

## Requirements

You will need to register an application at https://dev.twitter.com/apps to get the required oAuth credentials. These are used to make the retweets. Retweetbot also requires you give it a username and password. This is used to use Twitter's streaming API. Unfortunately, the streaming API does not support oAuth at this time.

# Installation

Add the necessary ENV variables to your application's environment:

* TWITTER_USERNAME (your twitter username that will be doing the retweeting)
* TWITTER_PASSWORD (password for the above account)
* CONSUMER_KEY (the consumer key for the app you made)
* CONSUMER_SECRET (consumer secret for the above key)
* ACCESS_TOKEN (token generated for your account to your app)
* ACCESS_TOKEN_SECRET (token secret for the above token)
* FILTER (what to look for [hashtags or keywords] ... ex: "#teamDigerati")
* FOLLOW (comma separated list of the user id's to limit the search ... ex: "1,14,140")

## Development

You can run either:

    ruby retweetbot.rb

Or since we've got a procfile, install foreman (````gem install foreman````) and run:

    foreman start

## Heroku Production Example

    heroku create --stack cedar
    git push heroku master
    heroku scale tweetscan=1

## License

RetweetBot is released under the MIT license.

# History

This project was originally created by [Patrick Hogan](https://github.com/pbhogan), forked and tweaked by [Jon McCartie](https://github.com/jmccartie), and then uploaded by [Team Digerati](https://github.com/lifechurch). Thanks for doing the heavy lifting, Patrick!

# Contributing

In the spirit of [free software](http://www.fsf.org/licensing/essays/free-sw.html), **everyone** is encouraged to help improve this project.

Here are some ways *you* can contribute:

* by using alpha, beta, and prerelease versions
* by reporting bugs
* by suggesting new features
* by writing or editing documentation
* by writing specifications
* by writing code (**no patch is too small**: fix typos, add comments, clean up inconsistent whitespace)
* by refactoring code
* by resolving issues
* by reviewing patches