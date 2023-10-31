When experimenting with the SOM in traditional ways, I have been struggling to produce anything but perfect outcomes, even when logically this cannot be the case. I am thinking that rather than the SOM being overfit, there may be some issue with the validation method. Therefore, I have broken that down here. This code trains a SOM on a number of dogs and then predicts the outcome on on (1) a dog from that training dataset, (2) the LOIO dog data the training model had been evaluated on, (3) a complete hold-out unseen dog, and (4) quoll data.

I hypothesise that there should be a decline in accuracy for each of these validation types, with the included training dog achieving close to perfect accuracy while the quoll could reasonably be expected 30-50% accuracy. I assessed accuracy both using my previous method (from Clemente code), as well as designing a new evaluation.

Much of this code is a reduced version of my [other experimental code](https://github.com/OakAlice/DataLeakage). Dog data from [Vehkoaja et al., 2020](https://www.sciencedirect.com/science/article/pii/S2352340922000348). Quoll data from [Gaschk et al., 2023](https://royalsocietypublishing.org/doi/full/10.1098/rsos.221180).

## Workflow
1. Create a SOM from the dog data, LOIO method.
2. Create 3 additional validation sets (Included, HoldOut, Quoll)
3. Evaluate the SOM on each of the 4 sets.
4. Compare outcomes.

## Scripts
- ExecuteScript.R -> Create the testing datasets, run the analysis.
- Functions.R and SOMFunctions.R -> All the important functions from this analysis.
- CreatingQuollDataset.R -> Altering the Quoll data so it'll match into the dog SOM.
