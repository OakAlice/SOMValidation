

# when you have determined which shape is the best, run the full version and get all the outputs
evaluateSOM <- function(ssom, type, tstDat) {
  
  ssom.pred <- predict(ssom, newdata = tstDat, whatmap = "measurements")
  ptab <- table(predictions = ssom.pred$predictions$act, act = tstDat$act)
  
  true_positives <- diag(ptab)
  false_positives <- rowSums(ptab) - true_positives
  false_negatives <- colSums(ptab) - true_positives
  
  # Calculate true negatives for each class
  true_negatives <- rep(sum(ptab), length(true_positives)) - rowSums(ptab) - colSums(ptab) + true_positives
  
  # if there were any nas, this should handle it
  true_positives <- na.omit(true_positives)
  false_negatives <- na.omit(false_negatives)
  
  # Sensitivity, Recall, and Specificity are calculated per class and then averaged
  SENS <- true_positives / (true_positives + false_negatives)
  PREC <- true_positives / (true_positives + false_positives)
  SPEC <- true_negatives / (true_negatives + false_positives)
  ACCU <- sum(true_positives) / sum(ptab)
  
  # Calculate the averages for multi-class precision and sensitivity (recall)
  AVG_SENS <- mean(SENS)
  AVG_PREC <- mean(PREC)
  AVG_SPEC <- mean(SPEC)
  
  # Compile the results into a data frame
  statistical_results <- data.frame(
    ValidationType = type,
    Accuracy = ACCU,
    Specificity = AVG_SPEC,
    Sensitivity = AVG_SENS,
    Recall = AVG_SENS, # Recall is the same as Sensitivity
    Precision = AVG_PREC
  )
  
  # Write the results to a CSV file
  write.csv(statistical_results, file.path(Experiment_path, paste0("Results/", type, "_Statistical_results.csv")), row.names = FALSE)
  
  SOMoutput <- list(SOM = ssom, SOM_performance = statistical_results)
  
  return(SOMoutput)
}


# Comparing outcomes of the various SOM conditions
# pull each of the results and combine them into a central csv and set of graphs

Summarise_results <- function(Results_tables) {
  Summary_results <- data.frame()
  
  for (results in Results_tables) {
    
    table1 <- read.csv(results)
    
    # Extract condition from the filename
    condition <- sub(".*\\/(.*)\\_Statistical_results\\.csv$", "\\1", results)
    
    # Select only the metrics and add the condition
    metrics_table <- table1[, c('ValidationType', 'Accuracy', 'Specificity', 'Sensitivity', 'Recall', 'Precision')]
    metrics_table$Condition <- condition
    
    # Combine with the summary results
    Summary_results <- rbind(Summary_results, metrics_table)
  }
  
  # Write the combined summary to a CSV file
  write.csv(Summary_results, file.path(Experiment_path, "Results/Summary_results.csv"), row.names = FALSE)
  return(Summary_results)
}


# Functions to test multiple shapes to find the optimal shape for SOM
# run the actual SOM tests combining many of the functions above
run_som_tests <- function(trDat, tstDat, file_path) {
  
  results <- list()
  shape_accuracy_score <- list() # to store accuracy scores for each iteration
  somsize3 = generate_shapes() # shapes to test
  
  AllIterationsResults <- data.frame() # initialize an empty dataframe outside the loop
  
  for (bb in 1:nrow(somsize3)) { # loop through the different shapes
    
    print(bb)
    
    for (iter in 1:1) { # Go through the 3 iterations for each shape
      iteration_results <- testing_the_SOM(trDat, tstDat, somsize3[bb,1], somsize3[bb,2])
      AllIterationsResults <- rbind(AllIterationsResults, iteration_results)
    }
    
    shape_accuracy_score[[bb]] <- generate_accuracy_score(AllIterationsResults)
    results[[bb]] <- list("acc3list" = AllIterationsResults)
  }
  
  # Combine all accuracy scores
  all_shape_averages <- do.call(rbind, shape_accuracy_score)
  
  # Calculate mean accuracy for each width-height combination 
  average_accuracies <- all_shape_averages %>%
    group_by(width, height) %>%
    summarize(mean_acc = mean(acc), .groups = "drop")
  
  # make the heatmap using the average_accuracies
  #heatmap <- create_heatmap(average_accuracies, file_path)
  
  best_shape <- determine_best_shape(average_accuracies)
  best_width <- best_shape$width
  best_height <- best_shape$height
  
  # Return the results, including the best shapes 
  return(list("best_width" = best_width, "best_height" = best_height))
}

# choose the best shape
determine_best_shape <- function(average_accuracies) {
  best_shape <- average_accuracies[which.max(average_accuracies$mean_acc), ]
  return(list("width" = best_shape$width, "height" = best_shape$height))
}

# the actual test that's performed on the training/testing data, returns overallResultsTable
testing_the_SOM <- function(trDat, tstDat, width, height) {  # originally doSOMperf
  
  # build the som using the training data
  ssom <- supersom(trDat, grid = somgrid(width, height, "hexagonal"), whatmap = c("measurements", "activity"))
  # predict on the testing data # skip if it doesn't work
  tryCatch({
    ssom.pred <- predict(ssom, newdata = tstDat,  whatmap = "measurements")
  }, 
  error = function(e) {
    if (grepl("Number of columns of newdata do not match codebook vectors", e$message)) {
      print("Error encountered with mismatched columns. Skipping this iteration.")
      next()
    } else {
      stop(e)  # If it's a different error, continue with the error propagation
    }
  })
  # save the results as a table
  resultsTable <- table(predictions = ssom.pred$predictions$act, act = tstDat$act)
  
  # use table to make statistics for understanding the model performance
  true_positives  <- diag(resultsTable)
  false_positives <- rowSums(resultsTable) - true_positives
  false_negatives <- colSums(resultsTable) - true_positives
  true_negatives  <- sum(resultsTable) - true_positives - false_positives - false_negatives
  SENS<-c(true_positives/(true_positives+false_negatives), shape=width)
  PREC<-c(true_positives/(true_positives+false_positives), shape=width)
  SPEC<-c(true_negatives/(true_negatives+false_positives), shape=width)
  ACCU<-c(sum(diag(resultsTable))/sum(resultsTable), shape=width)
  
  # save the statistics 
  statisticsTable <- as.data.frame(rbind(SENS,PREC,SPEC,ACCU))
  # save as a table that gives the results, size, and time it took to compute
  overallResultsTable <- cbind(test = rownames(statisticsTable), statisticsTable, width=width, height=height)
  # return that dataframe
  return(overallResultsTable)
}

# generate shapes to test
generate_shapes <- function() {
  somsize <- rep(seq(4,9,1),6) # Create some widths
  somsize2 <- rep(4:9, times=1, each=6) # Create some lengths
  somsize3 <- cbind(somsize, somsize2) # Combine the sizes
  return(somsize3)
}

# generate an accuracy heatmap matrix
generate_accuracy_score <- function(AllIterationsResults) {
  accuracy_scores <- subset(AllIterationsResults, test=='ACCU') # extract the accuracy scores for each
  # rearrange to be a long dataframe
  long_accuracy_scores <- accuracy_scores %>%
    gather(key = "behavior", value = "accuracy", 
           2:length(selectedBehaviours)) %>%
    select(behavior, accuracy, width, height)
  mean_accuracy_scores <- long_accuracy_scores %>%
    group_by(width, height) %>%
    summarise(mean_accuracy = mean(accuracy), .groups = "drop")
  
  shape_accuracy_score <- data.frame(acc=mean_accuracy_scores$mean_accuracy, width=mean_accuracy_scores$width, height=mean_accuracy_scores$height)
  
  return(shape_accuracy_score)
}

# Function to create and save an accuracy heatmap
create_heatmap <- function(average_accuracies, file_path) {
  # Create a matrix
  df2 <- with(average_accuracies, tapply(mean_acc, list(shape = width, height), FUN= mean, na.rm=TRUE))
  
  # Define custom color map
  colours_heat3 = c('#F4E119', '#F7C93B', '#C4BB5F', '#87BE76', '#59BD87', '#2CB6A0', '#00AAC1', '#1B8DCD', '#3D56A6', '#3A449C')
  
  # Save the heatmap to a temporary location (because % wont work in the filepath here)
  png("heatmap_temp_save.png")
  
  # Create the heatmap using Lattice plot
  heatmap <- levelplot(t(df2), cex.axis=1.0, cex.lab=1.0, col.regions=colorRampPalette(rev(colours_heat3)), 
                       screen = list(z = -90, x = -60, y = 0),
                       xlab=list(label='height', cex = 1.0),
                       ylab=list(label='width', cex = 1.0),
                       main=list(label= paste0('ACCU'), cex=1.0), 
                       colorkey=list(labels=list(cex=1.0)),
                       scales = list(cex=1.0),
                       asp=1)
  print(heatmap)
  
  # Finish saving to PNG file
  dev.off()
  
  # Now, move the heatmap from the temporary location to your desired location
  # Use fs::file_move() to rename/move the file
  fs::file_move("heatmap_temp_save.png", paste0(file_path, "/heatmap.png"))
  
  return(heatmap)
}











# when you have determined which shape is the best, run the full version and get all the outputs
performOptimalSOM <- function(trDat, tstDat, width, height, file_path) {
  
  ssom <- supersom(trDat, grid = somgrid(width, height, "hexagonal"), whatmap = c("measurements", "activity"))
  
  # save this optimal SOM
  save(ssom, file = file.path(file_path, "Dog_SOM.rda"))
}

# final output, saving the trained SOM, plot it, and save the confusion matrix
save_and_plot_optimal_SOM <- function(trDat, tstDat, width, height, file_path) {
  
  # Create a confusion matrix
  load(file = file.path(file_path, "Dog_SOM.rda"))
  ssom.pred <- predict(ssom, newdata = tstDat, whatmap = "measurements")
  ptab <- table(predictions = ssom.pred$predictions$act, act = tstDat$act)
  write.csv(ptab, file.path(file_path, "Confusion_Matrix.csv"))
  
  # make plots
  # Perform SOM with the optimal width and height
  SOMoutput <- performOptimalSOM(trDat, tstDat, width, height, file_path)
  
  # Extract the prediction outputs
  pred_outputs <- SOMoutput$SOM_performance
  SOM_model <- SOMoutput$SOM
  
  ## PLOTS 
  colours <- c("#A6CEE3", "#1F78B4", "#4363d8", "#CAB2D6", "#fabebe", "#FB9A99", 
               "#FF7F00", "#FDBF6F", "goldenrod1", "#FFFF99", "#bfef45", "#B2DF8A", 
               "#33A02C", "#469990")
  
  # Use the function to save and move the plots
  # main mapping plots
  #plot_and_move("Mapping.png", { plot(SOM_model, type="mapping", pchs=20, col=colours, main="Mapping of behaviors on SOM") })
  plot_and_move("optimal_SOM_plot.png", file_path,
                { plot(ssom, heatkey = TRUE, col = colours, type = "codes", shape = "straight", ncolors = 14) })

  plot_and_move("Training_Process.png", file_path,
                { plot(ssom, type="changes", main = "Training Process") })
  plot_and_move("Codes_Weight.png", file_path,
                { plot(ssom, type="codes", main="Codes/Weights of the SOM nodes") })
  plot_and_move("Counts.png", file_path,
                { plot(ssom, type="counts", main="Counts") })
  plot_and_move("Quality.png", file_path,
                { plot(ssom, type="quality", main="Quality") })
  # Return the confusion matrix for additional use if necessary
  return(ptab)
}

