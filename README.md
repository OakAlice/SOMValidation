This code trains a SOM on a number of dogs and then predicts the outcome on on (1) a dog from that training dataset, (2) the LOIO data, (3) a complete hold-out unseen dog, and (4) quoll data. I wrote this code to demonstrate that the original code (written many years ago by other people) was dysfunctional and that my change made it functional.

The quoll data I have access to is already in a processed format, meaning I had to modify my dog data to fit it.

Much of this code is a reduced version of my [other experimental code](https://github.com/OakAlice/DataLeakage). Dog data from [Vehkoaja et al., 2020](https://www.sciencedirect.com/science/article/pii/S2352340922000348). Quoll data from [Gaschk et al., 2023](https://royalsocietypublishing.org/doi/full/10.1098/rsos.221180).

