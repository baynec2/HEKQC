library(readr)
library(rawrr)

setwd("/home/nanopore-catalyst/HDD/HEK_testing/")
# Getting command line options
args <- commandArgs()
# setting i to 7th element, this should be $i variable.
i = args[length(args)-1]
#creating filepath of file
filepath = paste0("input_raw_files/",i)
# getting the date
date = file.mtime(filepath)
# Getting the filesize in Mb
filesize = file.size(filepath) / 10^6
# protein
protein = read_tsv("results/protein.tsv")
protein = cbind(Filename = i,Date = date,protein)
write_tsv(protein,"results/protein.tsv",col_names = FALSE)
# peptide
peptide = read_tsv("results/peptide.tsv")
peptide = cbind(Filename = i,Date = date,peptide)
write_tsv(peptide,"results/peptide.tsv",col_names = FALSE)

# preparing chromatograms results
chromatogram = rawrr::readChromatogram(paste0("input_raw_files/",i),type = "tic")
retention_time = data.frame(Filename = i,
                            Date = date,
                            RT = chromatogram$times,
                            tic = chromatogram$intensities
                            )
write_tsv(retention_time,"results/chromatogram.tsv",col_names = FALSE)

# preparing filesize results
filesize = data.frame(Filename = i,
                      Date = date,
                      Filesize_mb = filesize)

write_tsv(filesize, "results/filesize.tsv",col_names = FALSE)