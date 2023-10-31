# Enter the variables to be used in the analysis

# Experiment Number, used to keep track of results in different folders
ExperimentNumber <- 1

# the data used to build the SOM
MovementData <- "DogMoveData.csv"

# how many inviduals to include in the test
test_individuals <- 20

# columns to use in the analysis
# select and rename the relevant columns (match the Quoll data)
columnSubset <- c("DogID" = "ID", "t_sec" = "time", 
                  "ANeck_x" = "X_accel", "ANeck_y" = "Y_accel", "ANeck_z" = "Z_accel",
                  "Behavior_1" = "activity")

# select the chosen behaviours # don't mess with this because it's matched to the Quolls
selectedBehaviours <- c("Drinking", "Eating", "Lying chest", "Panting", "Playing", 
                        "Sitting", "Sniffing", "Standing", "Trotting", "Walking")

# features list
featuresList <- c("mean", "max", "min", "sd", "cor", "SMA", "minODBA", "maxODBA", "minVDBA", "maxVDBA")

# window and overlap # leave these as they are unless you want to go change the code
window_length <- 1
overlap_percent <- 0

# split # preferably LOIO but can be random or chronological
split <- "LOIO"

# training percentage, decimal percent
trainingPercentage <- 0.6

# threshold # change this number when you get to and can visualise that stage
threshold <- 5000
