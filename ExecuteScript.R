# Execution script
#### SET UP ####
  library(pacman)
  p_load(here, kohonen, dplyr, tidyr, png, fs)
  
  setwd(here())
  
  source("VariableEntry.R")
  source("ProcessToDatFormat.R")
  source("GeneralFunctions.R")
  source("SOMFunctions.R")

# build directories for sorting the data etc.
  Experiment_path <- paste0("Experiment_", ExperimentNumber)
  ensure_dir(Experiment_path) # experiment directory
  ensure_dir(file.path(Experiment_path, "ValidationSets"))
  ensure_dir(file.path(Experiment_path, "BuildingSOM"))
  ensure_dir(file.path(Experiment_path, "Results"))
  
#### PART ONE: Format the Dataset ####
  # load in the data
  MoveData0 <- read.csv(MovementData)
  MoveData <- subset_and_rename(MoveData0, columnSubset)
  
  # downsample the data (for the sake of processing time)
  skip <- 100 / 20
  MoveData <- MoveData[seq(1, nrow(MoveData), by = skip), ]
  # select the key behaviours
  MoveData <- MoveData[MoveData$activity %in% selectedBehaviours, ]
  # select indivuduals
  individuals <- unique(MoveData$ID)[1:test_individuals]
  MoveData <- MoveData[MoveData$ID %in% individuals, ]
  
  # write to csv
  write.csv(MoveData, file.path(Experiment_path, "Formatted_MoveData.csv"))

#### PART TWO: CREATE THE DOG SOM ####
  # Feature Creation #
  file_path <- file.path(Experiment_path, "Formatted_MoveData.csv")
  processed_data <- process_data(file_path, featuresList, window_length, overlap_percent)
  write.csv(processed_data, file.path(Experiment_path, "Processed_Data.csv"))
  
  # Create Training and Testing Data #
  file_path <- file.path(Experiment_path, 'Processed_Data.csv')
  split_condition(file_path, threshold, split) # remove trainingPercentage
  
  # Trial SOM shapes and produce final map #
  load(file = paste0(Experiment_path, "/BuildingSOM/TrainingData.rda"))
  load(file = paste0(Experiment_path, "/BuildingSOM/TestingData.rda"))
  file_path <- file.path(Experiment_path, "BuildingSOM")
  optimal_dimensions <- run_som_tests(trDat, tstDat, file_path)
  width <- optimal_dimensions$best_width
  height <- optimal_dimensions$best_height
  som_results <- performOptimalSOM(trDat, tstDat, width, height, file_path)
  save_and_plot_optimal_SOM(trDat, tstDat, width, height, file_path)


#### PART THREE: CREATE VALIDATION SETS ####
  #Quoll one dealt with seperately in CreatingQuollDataset.R
  
  # save a copy of the testing data from the SOM creation into the new folder
  save(tstDat, file = file.path(Experiment_path, "ValidationSets", "LOIO_TestingData.rda"))

  # create indiviual dataframes for each of the individuals
  # load in the data and format it again
  MoveData <- subset_and_rename(MoveData0, columnSubset)
  MoveData <- MoveData[seq(1, nrow(MoveData), by = skip), ]
  MoveData <- MoveData[MoveData$activity %in% selectedBehaviours, ]
  
  # make the other ones
  ValidationTypes <- c("Included", "HoldOut")
  length(unique(MoveData$ID))
  # complete examples to use as the testing set
  Specific_IDs <- c("Included" = 20, "HoldOut" = 47) # determined from manual data inspection
  
  for (type in ValidationTypes) {
    # type <- ValidationTypes[1]
    selected_id <- Specific_IDs[[type]]
    specificMoveData <- subset(MoveData, ID %in% selected_id)
    write.csv(specificMoveData, file = paste0(Experiment_path, "/ValidationSets/", paste0(type, "_raw.csv")))
  }

## Process validation sets into tstDat ##
# Quoll one dealt with seperately at the bottom
featuresList <- c("mean", "max", "min", "sd", "cor", "SMA", "minODBA", "maxODBA", "minVDBA", "maxVDBA")

datasets <- list.files(paste0(Experiment_path, "/ValidationSets"), "*_raw.csv")
for (set in datasets) { # for each of the dataset conditions
    
    # set <- datasets[2]
  
    print(set) # progress check
  
    processed_data <- process_data(file.path(Experiment_path, "ValidationSets", set), featuresList, window_length, overlap_percent) # preset these
    
    # write as a CSV
    filename <- sub("_raw.csv", "", set)
    file_path <- paste0(Experiment_path, '/ValidationSets/', filename, '_Processed_Data.csv')
    write.csv(processed_data, file_path)
    
    make_dat_format(file_path)
}


#### PART THREE: EVALUATION ####
ValidationTypes <- c("Included", "LOIO", "HoldOut", "Quoll")

# load the ssom
load(file.path(Experiment_path, "BuildingSOM/Dog_SOM.rda"))
ValidationTypes <- c("Included", "LOIO", "HoldOut", "Quoll")

for (type in ValidationTypes) { # for each of the testing datasets
  
  # type <- ValidationTypes[1]
  
  # progress tracking
  print(type)
  
  # load the files
  load(paste0(Experiment_path, "/ValidationSets/", type, "_TestingData.rda"))
  
  # produce the results
  som_results <- evaluateSOM(ssom, type, tstDat)
}

#### SOM Results ####
Results_tables <- find_all_instances(file.path(Experiment_path, "Results"), "*_Statistical_results.csv")
Summarise_results(Results_tables)


