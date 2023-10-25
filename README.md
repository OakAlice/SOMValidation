When experimenting with the SOM in traditional ways, I have been struggling to produce anything but perfect outcomes, even when logically this cannot be the case in every scenario. I am thinking that the SOM is likely overfit. To test, we trained a SOM on a dog and then predicted it on the correct dog data but also then quoll data to see what would happen.

We found that it has a 99.9% accuracy, precision, and sensitivity when trained and tested on dogs (suspiciously high but okay). When we used the model trained on a dog to predict on a quoll (different, but not THAT different animals) however, we found that it was completely non-functional, and failed to predict any behaviour other than sitting - any correctness was just by accident.

Much of this code is a reduced version of my [other experimental code](https://github.com/OakAlice/DataLeakage). Dog data from [Vehkoaja et al., 2020](https://www.sciencedirect.com/science/article/pii/S2352340922000348). Quoll data from [Gaschk et al., 2023](https://royalsocietypublishing.org/doi/full/10.1098/rsos.221180).

## Workflow
1. ModifyQuollData.R -> Adjust the training data provided by Josh Gaschk (Gaschk et al., 2023) to a limited subset of behaviours (that we preselected to match a subset of behaviours from the dog data).
2. ProcessDogData.R -> Calculate the same features for the dog as exist in the quoll dataset.
3. CreatingTrainingTestingData.R -> Split the dataset randomly
4. TrialSOMShapes.R -> Test the different som shapes to get the optimal dimensions
5. CreateAndTestSOM.R -> Create the dog trained SOM and then test it on dog data and quoll data.
