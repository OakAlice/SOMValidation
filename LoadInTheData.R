# This is the script where Josh and I are attempting to produce low accuracy in the SOM
# Stage One. Create a SOM on dog data.
# Begin by calculating the same features that can be found in the Quoll data

load("QuollTrainingData.rda") # comes in as trDat
Quoll_features <- colnames(trDat$measurements)

library("pacman")
p_load(here, e1071, data.table, dplyr)

## FUNCTIONS ##
# Function to compute features for a given chunk of data
compute_features <- function(dat) {
  
  # Calculate all the features
  meanX <- mean(dat$ANeck_x)
  meanY <- mean(dat$ANeck_y)
  meanZ <- mean(dat$ANeck_z)
  
  meangX <- mean(dat$GNeck_x)
  meangY <- mean(dat$GNeck_y)
  meangZ <- mean(dat$GNeck_z)
  
  maxx <- max(dat$ANeck_x)
  maxy <- max(dat$ANeck_y)
  maxz <- max(dat$ANeck_z)
  
  minx <- min(dat$ANeck_x)
  miny <- min(dat$ANeck_y)
  minz <- min(dat$ANeck_z)
  
  sdx <- sd(dat$ANeck_x)
  sdy <- sd(dat$ANeck_y)
  sdz <- sd(dat$ANeck_z)
  
  SMA <- (sum(abs(dat$ANeck_x)) + sum(abs(dat$ANeck_y)) + sum(abs(dat$ANeck_z)))/nrow(dat)
  
  ODBA <- abs(dat$ANeck_x) + abs(dat$ANeck_y) + abs(dat$ANeck_z)
  VDBA <- sqrt(dat$ANeck_x^2 + dat$ANeck_y^2 + dat$ANeck_z^2) 
  
  minODBA <- min(ODBA)
  maxODBA <- max(ODBA)
  
  minVDBA <- min(VDBA)
  maxVDBA <- max(VDBA)
  
  sumODBA <- sum(ODBA)
  sumVDBA <- sum(VDBA)
  
  skx<-skewness(ANeck_x)
  sky<-skewness(ANeck_y)
  skz<-skewness(ANeck_z)
  
  corXY <- cor(dat$ANeck_x, dat$ANeck_y, use="complete.obs")
  corXZ <- cor(dat$ANeck_x, dat$ANeck_z, use="complete.obs")
  corYZ <- cor(dat$ANeck_y, dat$ANeck_z, use="complete.obs")
  
  time <- as.POSIXct((dat$t_sec[1] - 719529) * 86400, origin = "1970-01-01", tz = "UTC")
  
  activity = names(which.max(table(dat$Behavior_1)))
  
  # Here you can add other features and calculations as needed
  
  # Return a dataframe with all the features
  return(data.frame(time, meanX, meanY, meanZ,
                    maxx, maxy, maxz,
                    minx, miny, minz,
                    sdx, sdy, sdz, skx, sky, skz,
                    SMA, minODBA, maxODBA, minVDBA, maxVDBA, sumODBA, sumVDBA,
                    corXY, corXZ, corYZ, activity))
}

process_dog_data <- function(dog_id, DogMoveData) {
  
  # Subset and select desired columns
  dog_data <- DogMoveData[DogMoveData$DogID == dog_id, c("DogID", "t_sec", "ANeck_x", "ANeck_y", "ANeck_z", 
                                                         "GNeck_x", "GNeck_y", "GNeck_z", "Task", "Behavior_1")]
  
  # Initialize an empty list to store the processed data chunks
  processed_chunks <- list()
  
  # Define the starting and ending points for the chunks
  st <- 1
  fn <- 100
  
  # Iterate over the chunks of data
  while (fn <= nrow(dog_data)) {
    
    # Extract the current chunk
    dat_chunk <- dog_data[st:fn, ]
    
    # Compute features for the chunk
    features_data <- compute_features(dat_chunk)
    
    # Add the processed chunk to the list
    processed_chunks <- c(processed_chunks, list(features_data))
    
    # Update starting and ending points for the next chunk
      st <- st + 100
      fn <- fn + 100
    
  }
  
  # Combine all the processed chunks into a single data frame
  processed_data <- do.call(rbind, processed_chunks)
  # the reason why I chunk-process-recombine (seemingly pointless) is that I thought it would be faster 
  # my laptop was struggling as it was lol
  
  return(processed_data)
}

# Create with non-overlapping windows, random assignment
setwd(here())
DogMoveData <- read.csv("DogMoveData_edited.csv")


# remove the behaviours I dont want and reasign them to match the Quoll ones
original_behaviours <- unique(DogMoveData$Behavior_1)

# Define a named vector with the replacements
replacement_labels <- c(
  "Walking" = "Walking",
  "Sitting" = "Sitting",
  "Pacing" = "Vigilant Walking",
  "Lying chest" = "Lying.Resting",
  "Standing" = "Vigilance",
  "Galloping" = "Gallop"
)

# Transform the dataset
DogMoveData <- DogMoveData %>%
  mutate(Behavior_1 = ifelse(Behavior_1 %in% names(replacement_labels), 
                             replacement_labels[Behavior_1], 
                             Behavior_1)) %>%
  filter(Behavior_1 %in% replacement_labels)

# View the transformed dataset
new_behaviours <- unique(DogMoveData$Behavior_1)

# Get unique DogIDs and process the first 4 dogs # again, only 4 dogs to spare my laptop
unique_dog_ids <- unique(DogMoveData$DogID)[1:4]

# Process data for each dog and condition
processed_data <- lapply(unique_dog_ids, function(dog_id) process_dog_data(dog_id, DogMoveData))

# Combine and save the processed data
write.csv(do.call(rbind, processed_data), 'Dogs_processed.csv')




