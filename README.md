# README

This is the HEK QC Pipeline used in the Gonzalez lab

A big batch of HEK proteins were isolated and prepared for label free
proteomics by someone? in the lab a some time? ago. We use these as a known
standard to evaluate how well the MS is performing. 

Briefly, this pipeline transfers .raw files from the mass spec computer via a
samba mount. Runs Fragpipe in headless mode to determine protein and peptides.
A R script is used to extract the chromatograms and other data from files. 
Relevant results are imported into a SQLite database. Then a Rshiny app is used
to visualize results over time. 