# Install the library
install.packages('twitterR')

# Load the library
library(twitteR)

source('~/public_git/referendum_ita_2016/twt_local_info_not_for_git.R')

# Replace square brakets and what contained in them with your credentials
## To obtain your keys see: https://fraba.github.io/digital_media_methods_sydney/ws02/ws02.html#get-twitter-api
twitter_auth_dict =
  list('consumer_key' = '[insert_consumer_key_here]',
       'consumer_secret' = '[insert_consumer_secret_here]',
       'access_token' = '[insert_access_token_here]',
       'access_token_secret' = '[insert_access_token_secret_here]')

# Setup connection with Twitter API by submitting your credentials
setup_twitter_oauth(twitter_auth_dict[['consumer_key']], twitter_auth_dict[['consumer_secret']],
                    twitter_auth_dict[['access_token']], twitter_auth_dict[['access_token_secret']])

# Seacrh something
searchTwitter('pizza')
