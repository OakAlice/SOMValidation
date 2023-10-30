When experimenting with the SOM in traditional ways, I have been struggling to produce anything but perfect outcomes, even when logically this cannot be the case in every scenario. I am thinking that the SOM is likely overfit. To test, we trained a SOM on a bunch of dogs and then predicted it on (1) a dog from that dataset, (2) the LOIO dog data it had been evaluated on, (3) a total hold-out unseen dog, and (4) quoll data.

Much of this code is a reduced version of my [other experimental code](https://github.com/OakAlice/DataLeakage). Dog data from [Vehkoaja et al., 2020](https://www.sciencedirect.com/science/article/pii/S2352340922000348). Quoll data from [Gaschk et al., 2023](https://royalsocietypublishing.org/doi/full/10.1098/rsos.221180).

## Workflow
1. CreatingDatasets.R -> Altering the Quoll data so it'll match into the dog SOM.
2. Functions.R and SOMFunctions.R -> All the important functions from this analysis.
3. ExecuteScript.R -> Create the testing datasets, run the analysis.
