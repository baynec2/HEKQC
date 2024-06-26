#!/bin/bash
# Fusion computer mounted via samba to ../Fusion_computer directory
#mv ../Fusion_computer/*.raw input_raw_files/

### Create manifest file for new samples ###
# finding new files
files=$(ls input_raw_files/*.raw)

### Looping through each new file
for i in $files;
do
# Generating manifest
touch manifest

echo "/home/nanopore-catalyst/HDD/HEK_testing/input_raw_files/$i\t\t\t\tDDA" > manifest

### Running Fragpipe in headless mode ###
fragpipe --headless --workflow HEK.workflow --manifest manifest --workdir results/

### Adding filename and date to each the files ###
Rscript file_convert.R $i --save

### Adding relevant results to sql database ###
sqlite3 hek.db <<EOF
.mode tabs
.import results/protein.tsv protein
.import results/peptide.tsv peptide
.import results/chromatogram.tsv chromatogram
.import results/filesize.tsv filesize
EOF

### Removing old files ###
mv input_raw_files/$i old_raw_files/
rm input_raw_files/*.mzML 
rm manifest
rm results/*
done


