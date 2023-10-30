library(pacman)
p_load(here, kohonen, dplyr, tidyr)

source("CreatingDatasets.R")
source("GeneralFunctions.R")
source("SOMFunctions.R")

ensure_dir("RdaObjects") # save all the rda testing data sets into here
ensure_dir("Results") # save all the results into here
ensure_dir("Data") # put the raw dataframes into there

#### Create the Raw Datasets #### Quoll one dealt with seperately at the bottom
ValidationTypes <- c("Included", "LOIO", "HoldOut")
# complete examples to use as the testing set
Specific_IDs <- c("Included" = 20, "LOIO" = 26, "HoldOut" = 25) # determined from manual data inspection

# load in the data
MovementData <- "DogMoveData.csv"
MoveData0 <- read.csv(MovementData)

# select and rename the relevant columns (match the Quoll data)
columnSubset <- c("DogID" = "ID", "t_sec" = "time", 
                  "ANeck_x" = "X_accel", "ANeck_y" = "Y_accel", "ANeck_z" = "Z_accel",
                  "Behavior_1" = "activity")

MoveData <- subset_and_rename(MoveData0, columnSubset)

# downsample the data (for the sake of processing time)
skip <- 100 / 20
downsampled_data <- MoveData[seq(1, nrow(MoveData), by = skip), ]
MoveData <- MoveData[seq(1, nrow(MoveData), by = skip), ]

# select only the chosen behaviours
selectedBehaviours <- c("Drinking", "Eating", "Lying chest", "Panting", "Playing", 
                        "Sitting", "Sniffing", "Standing", "Trotting", "Walking")

MoveData <- MoveData[MoveData$activity %in% selectedBehaviours, ]

# create indiviual dataframes for each of the individuals
# only select the test individuals
for (type in ValidationTypes) {
  # type <- ValidationTypes[1]
  selected_id <- Specific_IDs[[type]]
  specificMoveData <- subset(MoveData, ID %in% selected_id)
  write.csv(specificMoveData, file = paste0("Data/", paste0(type, "_raw.csv")))
}

#### Process into tstDat #### Quoll one dealt with seperately at the bottom
# do all of the features
featuresList <- c("mean", "max", "min", "sd", "cor", "SMA", "minODBA", "maxODBA", "minVDBA", "maxVDBA")

datasets <- list.files("Data", "*.csv")
for (set in datasets) { # for each of the dataset conditions
    
    # set <- datasets[1]
  
    print(set) # progress check
  
    window_length = 1
    overlap_percent = 90
    
    processed_data <- process_data(set, featuresList, window_length, overlap_percent) # preset these
    
    # write as a CSV
    filename <- sub("_raw.csv", "", set)
    file_path <- paste0('Data/', filename, '_Processed_Data.csv')
    write.csv(processed_data, file_path)
    
    make_testing_data(filename, file_path)
    
  }

#### Evaluate on each of the types ####
ValidationTypes <- c("Included", "LOIO", "HoldOut", "Quoll")

# load the ssom
load("RdaObjects/Final_SOM.rda")

for (type in ValidationTypes) { # for each of the testing datasets
  
  # type <- ValidationTypes[1]
  
  # progress tracking
  print(type)
  
  # load the files
  load(paste0("RdaObjects/", type, "_TestingData.rda"))
  
  # produce the results
  som_results <- evaluateSOM(ssom, type, tstDat)
}

#### SOM Results ####
Results_tables <- find_all_instances("Results", "*_Statistical_results.csv")
Summarise_results(Results_tables)


