## Creating the Training and Testing data

library(pacman)
p_load(here, dplyr)

setwd(here())

## MANUAL SELECTION OF OVERREPRESENTATION VALUE
# before processing the data, choose how many rows to remove
dat0 <- read.csv("Dogs_processed.csv") # Example filename for visualization
table_activity <- table(dat0$activity)
barplot(table_activity, las = 2)
# put the thresholds you choose into the command at the very bottom

# Functions

# downsample the data according to the above determined value
downsample_data <- function(data, threshold) {
  
  # Determine counts of each 'activity' and identify over-represented behaviors
  activity_counts <- data %>% 
    group_by(activity) %>%
    tally() %>%
    mutate(over_threshold = ifelse(n > threshold, threshold, n)) # Use the min of n and threshold
  
  # For over-represented behaviors, sample the desired threshold number of rows
  oversampled_data <- data %>% 
    inner_join(filter(activity_counts, n > threshold), by = "activity") %>%
    group_by(activity) %>%
    sample_n(size = first(over_threshold), replace = FALSE) # Use the calculated threshold
  
  # For other behaviors, take all rows
  undersampled_data <- data %>% 
    anti_join(filter(activity_counts, n > threshold), by = "activity")
  
  # Combine and return
  return(bind_rows(oversampled_data, undersampled_data))
}

# Formatting the data
trSamp2 <- function(x) { 
  d <- x[,3:27] ## INPUT ## Match these to the actual columns
  activity <- as.factor(x$activity) # Corresponding activities
  out <- list(measurements = as.matrix(d), activity = activity)
  return(out)
}

# process the data
split_condition <- function(filename, threshold) {
  
  dat <- read.csv(filename)
  dat <- na.omit(dat)
  
  # Balance the data
  dat <- downsample_data(dat, threshold)
  
  # Version One: Random 70:30 split
  ind <- dat %>% group_by(dat$activity) %>% sample_frac(.7)
  DogtrDat<-trSamp2(ind)
  tstind<-subset(dat, !(dat$X %in% ind$X))
  DogtstDat<-trSamp2(tstind)
  
  # save the random training and testing data
  save(DogtrDat, file = "DogTrDat.rda")
  save(DogtstDat, file = "DogTstDat.rda")
  
}

#### INPUT names of the files and thresholds ####
# Process both conditions

processed_data <- "Dogs_processed.csv"

# filename then theshold
split_condition(processed_data, 200)

