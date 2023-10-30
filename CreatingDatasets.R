#### CREATING THE QUOLL DATA ####
# Modify Josh's data to conform to our format

# Load the Data
load("RdaObjects/QuollTrainingData.rda")

# Filter and Subset Data
desired_activities <- c("Sitting", "Lying.Resting", "Scurry", "Vigilance", "Standing Vig", 
                        "Walking", "Vig Walking", "Turning", "Jumping", "Gallop")
ind <- which(trDat$activity %in% desired_activities)
meas2 <- trDat$measurements[ind,]
activ2 <- trDat$activity[ind]

# Rename Activities
activity_renaming <- c(
  "Sitting" = "Sitting",
  "Lying.Resting" = "Lying Chest",
  "Scurry" = "Playing",
  "Vigilance" = "Drinking",
  "Standing Vig" = "Standing",
  "Walking" = "Walking",
  "Vig Walking" = "Sniffing",
  "Turning" = "Panting",
  "Jumping" = "Eating",
  "Gallop" = "Trotting"
)
activ2 <- factor(activity_renaming[activ2], levels = unique(activity_renaming))

# Subset and Rename Columns
col_mapping <- c(
  "meanX" = "mean_X_accel", "maxx" = "max_X_accel", "minx" = "min_X_accel", "sdx" = "sd_X_accel",
  "meanY" = "mean_Y_accel", "maxy" = "max_Y_accel", "miny" = "min_Y_accel", "sdy" = "sd_Y_accel",
  "meanZ" = "mean_Z_accel", "maxz" = "max_Z_accel", "minz" = "min_Z_accel", "sdz" = "sd_Z_accel",
  "SMA" = "SMA", "minODBA" = "minODBA", "maxODBA" = "maxODBA", "minVDBA" = "minVDBA", 
  "maxVDBA" = "maxVDBA", "corXY" = "cor_X_accel_Y_accel", "corXZ" = "cor_X_accel_Z_accel", 
  "corYZ" = "cor_Y_accel_Z_accel"
)
meas2 <- meas2[, names(col_mapping)]
colnames(meas2) <- col_mapping

# Create New List and Save
tstDat <- list(measurements = meas2, activity = activ2)
save(tstDat, file = "RdaObjects/Quoll_TestingData.rda")
