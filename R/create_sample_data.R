
df <- data.frame(
  date = rep(seq(as.POSIXct('2018-01-01 12:00:00'),as.POSIXct('2018-01-05 14:00:00'),by='2 hours'),3),
  category = c('A','B','C'),
  value = rexp(n = 450,rate = 0.01)
  
)

catA <- df[df$category=='A',]
plot(catA$date,catA$value)

raw_content <- c("Error","Warn","Debug","Attach","Limit","No clue","Check with author")

rawdf <- data.frame(
  date = rep(seq(as.POSIXct('2018-01-01 12:00:00'),as.POSIXct('2018-01-05 14:00:00'),by='20 min'),3),
  category = c('A','B','C'),
  content = sample(raw_content,replace = T,size = 885)
)

write.csv(df,"data/sample-2H.csv")
write.csv(rawdf,"data/sample-raw.csv")
