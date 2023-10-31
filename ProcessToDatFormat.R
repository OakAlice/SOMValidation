# Functions for creating the validation datasets and SOM
# Given the window sizes, overlaps, and list of features specified on the main page
# process the data by that specification

# compute features based on the features list provided
compute_features <- function(window_chunk, featuresList) {
  
  # Determine the available axes from the dataset
  all_axes <- c("X_accel", "Y_accel", "Z_accel", "X_gyro", "Y_gyro", "Z_gyro")
  available_axes <- intersect(colnames(window_chunk), all_axes) # the ones we actually have
  
  result <- data.frame(row.names = 1)
  
  for (axis in available_axes) {
    
    # axis = "X_accel"
    
    if ("mean" %in% featuresList) {
      result[paste0("mean_", axis)] <- mean(window_chunk[[axis]])
    }
    
    if ("max" %in% featuresList) {
      result[paste0("max_", axis)] <- max(window_chunk[[axis]])
    }
    
    if ("min" %in% featuresList) {
      result[paste0("min_", axis)] <- min(window_chunk[[axis]])
    }
    
    if ("sd" %in% featuresList) {
      result[paste0("sd_", axis)] <- sd(window_chunk[[axis]])
    }
  }
  
  accel_axes <- intersect(available_axes, c("X_accel", "Y_accel", "Z_accel"))
  
  if (length(accel_axes) > 0 && ("SMA" %in% featuresList)) {
    result$SMA <- sum(rowSums(abs(window_chunk[, accel_axes]))) / nrow(window_chunk)
  }
  
  if (length(accel_axes) > 0 && ("minODBA" %in% featuresList || "maxODBA" %in% featuresList)) {
    ODBA <- rowSums(abs(window_chunk[, accel_axes]))
    result$minODBA <- min(ODBA)
    result$maxODBA <- max(ODBA)
  }
  
  if (length(accel_axes) > 0 && ("minVDBA" %in% featuresList || "maxVDBA" %in% featuresList)) {
    VDBA <- sqrt(rowSums(window_chunk[, accel_axes]^2))
    result$minVDBA <- min(VDBA)
    result$maxVDBA <- max(VDBA)
  }
  
  if ("cor" %in% featuresList) {
    for (i in 1:(length(accel_axes) - 1)) {
      for (j in (i+1):length(accel_axes)) {
        axis1 <- accel_axes[i]
        axis2 <- accel_axes[j]
        result[paste0("cor_", axis1, "_", axis2)] <- cor(window_chunk[[axis1]], window_chunk[[axis2]], use="complete.obs")
      }
    }
  }
  
  result$activity <- names(which.max(table(window_chunk$activity)))
  result$ID <- window_chunk$ID[1]
  
  return(result)
}

process_data <- function(file_path, featuresList, window, overlap) {
  # data <- MoveData
  
  # Initialize an empty list to store the processed data chunks
  processed_windows <- list()
  
  # Update starting and ending points for the next chunk
  window_samples = 1 * 20 # based on our data Hz # change if neccesary
  
  # Define the starting and ending points for the chunks
  st <- 1
  fn <- window_samples
  
  dat <- read.csv(file_path)
  
  # Iterate over the chunks of data
  while (fn <= nrow(dat)) {
    
    # Extract the current chunk
    window_chunk <- dat[st:fn, ]
    
    # Compute features for the chunk
    features_data <- compute_features(window_chunk, featuresList)
    
    # Add the processed chunk to the list
    processed_windows <- c(processed_windows, list(features_data))
    
    st <- st + window_samples
    fn <- fn + window_samples
    
  }
  
  # Combine all the processed chunks into a single data frame
  processed_data <- do.call(rbind, processed_windows)
  
  return(processed_data)
}


# Code to create the training and testing data, saving them both as .rda files
# balance the data according to the above determined value
balance_data <- function(dat, threshold) {
  
  # Determine counts of each 'activity' and identify over-represented behaviors
  activity_counts <- dat %>% 
    group_by(activity) %>%
    tally() %>%
    mutate(over_threshold = ifelse(n > threshold, threshold, n)) # Use the min of n and threshold
  
  # For over-represented behaviors, sample the desired threshold number of rows or all if less
  oversampled_data <- dat %>% 
    inner_join(activity_counts %>% filter(n > threshold), by = "activity") %>%
    group_by(activity) %>%
    sample_n(size = min(over_threshold[1], n()), replace = FALSE) 
  
  # For other behaviors, take all rows
  undersampled_data <- dat %>% 
    anti_join(filter(activity_counts, n > threshold), by = "activity")
  
  # Combine and return
  balance_data <- bind_rows(oversampled_data, undersampled_data)
  return(balance_data)
}

# Formatting the data #### MAY HAVE TO CHANGE THIS
trSamp2 <- function(x) { 
  d <- x[,2:21] ### adjust this number
  activity <- as.factor(x$activity) # Corresponding activities
  out <- list(measurements = as.matrix(d), activity = activity)
  return(out)
}

# process the data
split_condition <- function(file_path, threshold, split, trainingPercentage) {
  
  dat <- read.csv(file_path)
  dat <- na.omit(dat)
  
  # Balance the data
  # dat <- balance_data
  dat <- balance_data(dat, threshold)
  
  # Split data by different conditions
  if (split == "random") {
    
    # if split is random, select randomly based on the specified trainingPercentage
    ind <- dat %>% 
      group_by(activity) %>%
      sample_frac(trainingPercentage)
    
    trDat <- ind
    
    tstDat <- anti_join(dat, ind, by = "X")
    
  } else if (split == "chronological") { 
    
    # Group by ID and behavior, take the first % as the training 
    # and calculate the split index for each ID-behavior combination
    id_behavior_split <- dat %>%
      group_by(ID, activity) %>%
      mutate(split_index = floor(trainingPercentage * n()))
    
    # Split data into training and testing based on the calculated split index for each ID-behavior combination
    train_data_list <- id_behavior_split %>%
      group_by(ID, activity) %>%
      group_split() %>%
      lapply(function(.x) .x[1:unique(.x$split_index[1]), ])
    
    test_data_list <- id_behavior_split %>%
      group_by(ID, activity) %>%
      group_split() %>%
      lapply(function(.x) .x[(unique(.x$split_index[1]) + 1):nrow(.x), ])
    
    # Combine all the training and testing data
    trDat <- bind_rows(train_data_list)
    tstDat <- bind_rows(test_data_list)
    
  } else if (split == "LOIO") {
    
    number_leave_out <- ceiling(0.2*test_individuals)
    
    # Sample a random individual from the dataset
    unique_IDs <- unique(dat$ID)
    selected_individual <- sample(unique_IDs, number_leave_out)
    #selected_individual <- 20
    
    tstDat <- dat %>% filter(ID %in% selected_individual)
    
    trDat <- subset(dat, !(ID %in% selected_individual))
    
  }
  
  # Apply trSamp2 to the resultant datasets to format them for the SOM
  trDat <- trSamp2(trDat)
  tstDat <- trSamp2(tstDat)
  
  # Save the training data
  training_file_path <- file.path(Experiment_path, 'BuildingSOM/TrainingData.rda')
  save(trDat, file = training_file_path)
  
  # save the testing data
  testing_file_path <- file.path(Experiment_path, 'BuildingSOM/TestingData.rda')
  save(tstDat, file = testing_file_path)
}

# make dat format
make_dat_format <- function(file_path) {
  
  dat <- read.csv(file_path)
  dat <- na.omit(dat)
  
  # Apply trSamp2 to the resultant datasets to format them for the SOM
  tstDat <- trSamp2(dat)
  
  # name and save 
  filename <- sub("_Processed_Data.csv", "", file_path)
  
  # save the testing data
  testing_file_path <- paste0(filename, "_TestingData.rda")
  save(tstDat, file = testing_file_path)
}

