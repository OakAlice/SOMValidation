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

process_data <- function(set, featuresList, window, overlap) {
  
  # Initialize an empty list to store the processed data chunks
  processed_windows <- list()
  
  # Update starting and ending points for the next chunk
  window_samples = 1 * 20 # based on our data Hz
  
  # Define the starting and ending points for the chunks
  st <- 1
  fn <- window_samples
  
  dat <- read.csv(paste0("Data/", set))
  
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



# functions to create the various testing data, saving them both as .rda files
# Formatting the data #### MAY HAVE TO CHANGE THIS
trSamp2 <- function(x) { 
  d <- x[,2:21]
  activity <- as.factor(x$activity) # Corresponding activities
  out <- list(measurements = as.matrix(d), activity = activity)
  return(out)
}

# process the data into lists
make_testing_data <- function(filename, file_path) {
  # filename <- "HoldOut"
  # file_path <- "Data/HoldOut_Processed_Data.csv"
  
  dat <- read.csv(file_path)
  dat <- na.omit(dat)
  
  tstDat <- trSamp2(dat)
  testing_file_path <- paste0("RdaObjects/", filename, "_TestingData.rda")
  save(tstDat, file = testing_file_path)
}

# when you have determined which shape is the best, run the full version and get all the outputs
evaluateSOM <- function(ssom, type, tstDat) {
  
  file_path <- here()
  ssom.pred <- predict(ssom, newdata = tstDat)
  ptab <- table(predictions = ssom.pred$predictions$act, act = tstDat$act)
  
  true_positives  <- diag(ptab)
  false_positives <- rowSums(ptab) - true_positives
  false_negatives <- colSums(ptab) - true_positives
  true_negatives  <- sum(ptab) - true_positives - false_positives - false_negatives
  
  SENS<-c(true_positives/(true_positives+false_negatives))
  PREC<-c(true_positives/(true_positives+false_positives))
  SPEC<-c(true_negatives/(true_negatives+false_positives))
  ACCU<-c((true_positives+true_negatives)/(true_positives+true_negatives+false_positives+false_negatives))
  
  dat_out<-as.data.frame(rbind(SENS,PREC,SPEC,ACCU))
  statistical_results <- cbind(test = rownames(dat_out), dat_out)
  write.csv(statistical_results, file.path(file_path, paste0("Results/", type, "_Statistical_results.csv")))
  
  SOMoutput <- list(SOM = ssom, SOM_performance = statistical_results)
  
  return(SOMoutput)
  
}

# Comparing outcomes of the various SOM conditions
# pull each of the results and combine them into a central csv and set of graphs

Summarise_results <- function(Results_tables) {
  Summary_results <- data.frame()
  
  for (results in Results_tables) {
    
    # results <- Results_tables[4]
    table1 <- read.csv(results)
    
    # Compute the average for each metric (ignoring the first two columns and the last 'shape' column)
    table1$average <- rowMeans(table1[, 3:12], na.rm = TRUE)
    
    # Extract condition
    condition <- sub(".*\\/(.*)\\_Statistical_results\\.csv$", "\\1", results)
    
    # Add subdirectory information to the results
    table1 <- cbind(table1, as.data.frame(condition))
    
    # Only keep the metrics and the subdirectory information
    average_table1 <- table1[, c("X", "average", "condition")]
    average_table1 <- average_table1 %>% spread(X, average)
    
    Summary_results <- rbind(Summary_results, average_table1)
  }
  
  write.csv(Summary_results, paste0("Results/Summary_results.csv"))
  return(Summary_results)
}
