#!/usr/bin/env bash

# assuming '-c' is the sequence similarity from the HFSP paper, but parameter is called sequence identity
# assuming '-aS' is the target sequence coverage from the HFSP paper

cd-hit \
   -i testing/3_after_ec_filtering/Swiss-Prot_2002_redundancy_reduced_50.fasta \
   -o testing/4_after_cv_split/Swiss-Prot_2002_clustering.fasta \
   -c 0.4 \
   -n 2 \
   -d 0 \
   -M 0 \
   -T 150
