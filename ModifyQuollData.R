# Modify Josh's data to confirm to our format

load("QuollTrainingData.rda") # comes in as trDat

# find the indices with the behaviours I want
ind <- which(trDat$activity == "Walking" | trDat$activity == "Sitting" | trDat$activity == "Lying.Resting" |
               trDat$activity == "Vigilance" | trDat$activity == "Vig Walking" | trDat$activity == "Gallop")

# drop the ones we dont want
meas2 <- trDat$measurements[ind,]
activ2 <- trDat$activity[ind]
activ2 <- droplevels(activ2)

QuollLabelledData <- list(measurements = meas2, activity = activ2)

save(QuollLabelledData, file = "QuollLabelledData.rda")
# saved to the working directory