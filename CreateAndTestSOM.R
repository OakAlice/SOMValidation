# Create SOM and test on first the right, and then the wrong data

library(pacman)
p_load(parallel, here, dplyr, tidyverse, kohonen, RColorBrewer, data.table, sentimentr, lattice, glue, parallel, foreach, doParallel, moments)

# reset the wd
setwd(here())

## Create the SOM from the dog data
# take the width and height from the previous script
Dogssom <- supersom(DogtrDat, grid = somgrid(7, 5, "hexagonal"))
# save the SOM
save(Dogssom, file ="Dog_SOM.rda")

# Create some plots of the SOM
colours <- c("#A6CEE3", "#1F78B4", "#4363d8", "#CAB2D6", "#fabebe")
par(mfrow=c(2,2))
plot(Dogssom, type="mapping", pchs=20, col=colours, main="Mapping of behaviors on SOM")
plot(Dogssom, heatkey = TRUE, col = colours, type = "codes", shape = "straight", ncolors = 5)
plot(Dogssom, type = "counts")
plot(Dogssom, type = "codes")

## NOW TEST IT
  # Predict the Dog SOM on the Dog testing data
  ssom.pred <- predict(Dogssom, newdata = DogtstDat)
  ptab <- table(predictions = ssom.pred$predictions$act, act = DogtstDat$act)
  # as always, this is literally nearly 100% perfect... suspicious
  
  
  # Predict the Dog SOM on the Quoll Labelled Data
  ssom.pred <- predict(Dogssom, newdata = QuollLabelledData)
  ptab <- table(predictions = ssom.pred$predictions$act, act = QuollLabelledData$act)
  # this is terrible... suspiciously terrible
