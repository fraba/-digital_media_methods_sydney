# Load the data
## The following line will read the data (a comma separated values (CSV) file) with the function 
## `read.csv()` and will store it in the variable `my_data`.
my_data <- read.csv('https://raw.githubusercontent.com/fraba/digital_media_methods_sydney/master/ws01/data/twitter_data.csv')

# View the data
## If you are working in RStudio, you might check the data with the function View().
View(my_data)

# Exploring the data
## Time series analysis
### First I need to define a variable as a `date` variable. 
### To do so I need to specify the format of date, 
### which in this case is stored by Twitter as `Fri Oct 14 13:16:52 +0000 2016`
my_data$date <- as.Date(my_data$created_at, format = "%a %b %d %H:%M:%S +0000 %Y")

### `as.Date(my_data$created_at)` 
### this will throw an error because formatting is not unambiguous. 
### I can plot an histogram, with the frequency of tweets for each day in the time series with
hist(my_data$date, breaks = 'days', freq = TRUE)

### If I want more details I can create a `datetime` object 
### instead of a simple `date` object (which disregards information on hours, minutes and seconds)
my_data$datetime <- as.POSIXct(my_data$created_at, format = "%a %b %d %H:%M:%S +0000 %Y", tz = 'UTC')
hist(my_data$datetime, breaks = 'hours', freq = TRUE)

### During which hour the traffic peaked?
my_data$hour <- format(my_data$datetime, "%I%p, %a %d %b")
my_table <- table(my_data$hour) 
View(my_table)

### Weird that peak time is on 2AM... Not really if you think that times are in UTC. 
### Let's convert it in AEDT
my_data$hour <- format(my_data$datetime, "%I%p, %a %d %b", tz="Australia/Sydney")
my_table <- table(my_data$hour) 
View(my_table)

### Finally let's count the number of tweet during each hour by this time 
### disregarding the day 
my_data$hour <- format(my_data$datetime, "%H", tz="Australia/Sydney")
my_table <- table(my_data$hour)
View(my_table)
barplot(my_table, xlab = 'Hour', ylab = 'Frequency', main = 'Tweeting during the day')

## Hashtag analysis
### How to you extract an hashtag from a tweet? You can use regular expressions (AKA `regex`)
### So far we have used the basic packages contained in R. 
### But one of the best feature of R is that there is a large library of packages (9391), 
### doing all sort of things. Before you can use a package you need to install it with
install.packages('stringr')
### and then load it with
library(stringr)
### Now you can use all the functions contained in the package.

### Let's extract the hashtag with our first regular expression.
my_list_of_hashtags <- str_extract_all(my_data$text, '#[a-zA-Z0-9]+')
### The regular expression is `#[a-zA-Z0-9]+`. 
### It indicates a precise set of rules to find an hashtag:
### 1) Find the `#` sign;
### 2) Find, after the `#` lower letters `a-z`, upper letters `A-Z` and digits `0-9`;
### 3) And find as many as possible `+` sign. 

### The function str_extract_all() returns a list, 
### to count the occurrences of the hashtags we need to unpack the list with
my_hashtags <- unlist(my_list_of_hashtags)

### Also before we count them we want to disregard 
### the case of each letter (or #AUSPOL will be counted separatly from #auspol)
my_hashtags <- tolower(my_hashtags)
my_table <- table(my_hashtags)
my_prop.table <- prop.table(my_table)
View(my_prop.table)

### Remove all `#smashedavo` hastags
my_hashtags <- my_hashtags[-which(my_hashtags == '#smashedavo')]
my_hashtags <- tolower(my_hashtags)
my_table <- table(my_hashtags)
my_prop.table <- prop.table(my_table)
View(my_prop.table)

# >> MUCH HARDER STUFF BELOW << #

## Network analysis
install.packages('igraph')

my_data$retweeted_user <- str_extract(my_data$text, 'RT @[a-zA-Z0-9_]+')
my_data$retweeted_user <- gsub('RT @', '', my_data$retweeted_user)

my_data$from_user <- tolower(my_data$from_user)
my_data$retweeted_user <- tolower(my_data$retweeted_user)

my_rt_edges <- data.frame(from = my_data$from_user,
                          to = my_data$retweeted_user)
my_rt_edges <- my_rt_edges[complete.cases(my_rt_edges),]

library(igraph)
my_rt_network <- graph_from_data_frame(my_rt_edges)
V(my_rt_network)$indegree <- degree(my_rt_network, mode = 'in')
V(my_rt_network)$outdegree <- degree(my_rt_network, mode = 'out')

V(my_rt_network)$label <- NA
V(my_rt_network)$label[V(my_rt_network)$indegree > 15] <- V(my_rt_network)$name[V(my_rt_network)$indegree > 9]

plot(my_rt_network, 
     vertex.size = 0.6, vertex.label = V(my_rt_network)$label,
     edge.width = 0.05, edge.arrow.width = 0.1, edge.arrow.size = 0.05,
     main = "RT network with most retweeted users")

V(my_rt_network)$label <- NA
V(my_rt_network)$label[V(my_rt_network)$outdegree > 5] <- V(my_rt_network)$name[V(my_rt_network)$indegree > 9]

plot(my_rt_network, 
     vertex.size = 0.6, vertex.label = V(my_rt_network)$label,
     edge.width = 0.05, edge.arrow.width = 0.1, edge.arrow.size = 0.05,
     main = "RT network with most retweeting users")


