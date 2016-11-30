# Install the library
install.packages('twitterR')

# Load the library
library(twitteR)

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

# Search something
search_results <- searchTwitter('trump', lang='en', n=100)
## search_results is a list. Each element of the list contained an object of class `tweet`. 
## Let's see what a tweet contains with 
search_results[[1]]

# FOR LOOP 
## Let's store our tweets contained in the list into a data.frame
tweet_df <- data.frame()
for (tweet in search_results) {
  # `rbind`` is a function to bind two dataframes by rows (to bind by columns use `cbind``)
  # rbind(dataframe1, dataframe2)
  # IMPORTANT: the two dataframes must have the same number of columns defined by the same column names
  tweet_df <- rbind(tweet_df, 
                    data.frame(text = tweet$text,
                               user = tweet$screenName,
                               tweet_id  = tweet$id,
                               url_to_tweet = paste0('https://twitter.com/statuses/', tweet$id),
                               stringsAsFactors = FALSE)
  )
}

# Let's remove the emoticons (they create problems when conducting a text analysis)
tweet_df <- data.frame()
for (tweet in search_results) {
  # `rbind`` is a function to bind two dataframes by rows (to bind by columns use `cbind``)
  # rbind(dataframe1, dataframe2)
  # IMPORTANT: the two dataframes must have the same number of columns defined by the same column names
  tweet_df <- rbind(tweet_df, 
                    data.frame(text = iconv(tweet$text, "latin1", "ASCII", sub=""),
                               user = tweet$screenName,
                               tweet_id  = tweet$id,
                               url_to_tweet = paste0('https://twitter.com/statuses/', tweet$id),
                               stringsAsFactors = FALSE)
  )
}

# Let's try to estimate the sentiment of each tweet
## To do this we use the package tm, which is the package of reference for text analysis in R
## The package has a plugin to conduct a simple sentiment analysis
install.packages(c('tm', 'tm.plugin.sentiment'))
library(tm)
library(tm.plugin.sentiment)

# To work with the package tm we need to create a an object of class `Corpus` from our vector of tweets
tweet_corpus <- Corpus(VectorSource(tweet_df$text))
sentiment_corpus <- score(tweet_corpus)

# To store back the sentiment scores into our data.frame we use the function meta(), 
# which extracts the metadata of each object (tweet), in this case the sentiment scores.
tweet_df <- cbind(tweet_df, meta(sentiment_corpus))

# The sentiment analysis returns different scores (see http://statmath.wu.ac.at/courses/SNLP/Presentations/DA-Sentiment.pdf)
## The function order() orders the a numeric or alphabetic vector. 
## We want to highest values first, so we set `decreasing = TRUE` 
# and then we take only the first ten [1:10]
tweet_df$text[order(tweet_df$pos_refs_per_ref, decreasing = TRUE)[1:10]]
tweet_df$text[order(tweet_df$neg_refs_per_ref, decreasing = TRUE)[1:10]]

# Now let's get tweets from a specific user
timeline_results <- userTimeline('realDonaldTrump', n=1000)

# We use the same loop as before
tweet_df <- data.frame()
for (tweet in timeline_results) {
  tweet_df <- rbind(tweet_df, 
                    data.frame(text = iconv(tweet$text, "latin1", "ASCII", sub=""),
                               user = tweet$screenName,
                               created_at = tweet$created,
                               tweet_id  = tweet$id,
                               source = tweet$statusSource,
                               url_to_tweet = paste0('https://twitter.com/statuses/', tweet$id),
                               stringsAsFactors = FALSE)
  )
}

# There is a lot of discussion about how Trump uses Twitter. Let's replicate some analysis on the source
# of Trump's tweets (which application was used to publish them)
# If you are interested in a very detailed analysis on Trump and Twitter check out this:
# http://varianceexplained.org/r/trump-tweets/
# This is how the source is described in  the field `source`
# <a href="http://twitter.com/download/android" rel="nofollow">Twitter for Android</a>
# or
# <a href="http://twitter.com/download/iphone" rel="nofollow">Twitter for iPhone</a>

# So let's contruct a variable called `utility`, and assign a value `iphone` if `statusSource` contains
# the pattern 'iphone', `android` if contains the pattern 'android'

tweet_df$utility <- NA # Let's create an empty column, to which we assign the value NA

# Some details on [] ...
## [] allows to select from a vector based on another vector containing information on the element to return.
## The indexing vector can be expressed as numeric vector or with a logical vector.
## Example
sample_vector <- c('dog', 'cat', 'mouse')
sample_vector[1:2]
# [1] "dog" "cat"
sample_vector[c(1,3)]
# [1] "dog"   "mouse"
sample_vector[c(FALSE,TRUE,FALSE)]
# [1] "cat"
## The fact that we can use a logical vector to select specific element of a vector is usefull because
## many functions return a logical, e.g. grepl(pattern, x), 
## which checks if the `pattern` is  in a text `x`.
grepl(pattern = "dog", x = "I had rather be a dog, and bay the moon, Than such a Roman.")
# [1] TRUE
# Let's go back to our stuff...

# This will assign the value `iphone` in the column `utility` based on the grepl test 
# conducted on the column `source`
# The attribute `ignore.case = TRUE` is self-explanatory.
tweet_df$utility[grepl('iphone', tweet_df$source, ignore.case = TRUE)] <- 'iphone'
tweet_df$utility[grepl('android', tweet_df$source, ignore.case = TRUE)] <- 'android'
# There is actually a third important source...
tweet_df$utility[grepl('twitter web client', tweet_df$source, ignore.case = TRUE)] <- 'web'

View(table(tweet_df$utility, useNA = 'always'))
View(prop.table(table(tweet_df$utility, useNA = 'always')))

# Time analysis
# Let's first create a date and datetime object. 
# (we actually use the same functions and format used in the first workshop)
tweet_df$date <- as.Date(tweet_df$created_at, format = "%a %b %d %H:%M:%S +0000 %Y")
min(tweet_df$date)
max(tweet_df$date)

tweet_df$datetime <- as.POSIXct(tweet_df$created_at, format = "%a %b %d %H:%M:%S +0000 %Y", tz = 'UTC')
min(tweet_df$datetime)
max(tweet_df$datetime)

# Now, we want to plot the frequency of `utility` in time, 
# one over the entire period and one over the 24-hour cycle.

# To do this we introduce two packages which are among the most popular in R, 
# one is for data manipulation (dplyr) and the other for data visualisation (ggplot2)

install.packages(c('dplyr', 'ggplot2'))
library(dplyr)
library(ggplot2)

# Let's count the number of tweets per day but also by `utility`
# We also introduce a new R concepts: the pipe `%>%``: it simplify a lot writing code 
# when we have a pipeline, in which data is processed by a series of functions...
# result <- original_data %>% function() %>% function() %>% function()

utility_freq_by_day <- #this is the new variable
  tweet_df %>% # in the first list we pipe the data.frame with tweets into our pipeline,
  group_by(utility, date) %>% # then we group our data by `utility` and by `date`,
  summarise(daily_freq = n()) # finally we count the occurrences with the function n()

# Now let's plot it with ggplot()
ggplot(utility_freq_by_day, aes(x=date, y=daily_freq, colour=utility)) +
  # the function aes() construct the aesthetic mapping 
  # that is, it maps variables to visual properties
  geom_line() # This will add the layer `lines`

# ...messy...
# let's try to simplify the plot by removing all NAs
# is.na() tests whether the value is `NA`, the operator `!` indicates logical negation
# read !is.na() as "is not NA"
utility_freq_by_day <- subset(utility_freq_by_day, !is.na(utility))
  
# Then instead of a line, we can group the daily frequencies into columns
ggplot(utility_freq_by_day, aes(x=date, y=daily_freq, fill=utility)) +
  geom_bar(stat='identity') + 
  geom_vline(xintercept = as.numeric(as.Date("2016-11-08"))) # this add a vertical line on election day

ggplot(utility_freq_by_day, aes(x=date, y=daily_freq, fill=utility)) +
  geom_bar(stat='identity', position = "fill") +  # by adding positition = 'fill' we plot proportions
  geom_vline(xintercept = as.numeric(as.Date("2016-11-08"))) 

# Let's now plot frequency distributed across the the 24-hour cycle
# First lets create a variable hour (set on the Trump Tower timezone)
tweet_df$hour <- format(tweet_df$datetime, "%H", tz="EST")
utility_freq_by_hour <- 
  tweet_df %>% 
  group_by(utility, hour) %>%
  summarise(hourly_freq = n()) 

ggplot(utility_freq_by_hour, aes(x=as.numeric(hour), y=hourly_freq, colour=utility)) +
  geom_line() 

# Sentiment analysis on Trump's tweets
tweet_corpus <- Corpus(VectorSource(tweet_df$text))
sentiment_corpus <- score(tweet_corpus)
tweet_df <- cbind(tweet_df, meta(sentiment_corpus))

# And let's plot a box plot with sentiment against `utility`
ggplot(tweet_df, aes(x=utility, y=senti_diffs_per_ref)) +
  geom_boxplot()
ggplot(tweet_df, aes(x=utility, y=neg_refs_per_ref)) +
  geom_boxplot()
ggplot(tweet_df, aes(x=utility, y=pos_refs_per_ref)) +
  geom_boxplot()

