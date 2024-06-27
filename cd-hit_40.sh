#!/usr/bin/env bash

# assuming '-c' is the sequence similarity from the HFSP paper, but parameter is called sequence identity
# assuming '-aS' is the target sequence coverage from the HFSP paper

cd-hit \
   -i testing/Swiss-Prot_2002_redundancy-reduced.fasta \
   -o testing/Swiss-Prot_2002_redundancy-reduced_clusters.fasta \
   -c 0.4 \
   -n 2 \
   -d 0 \
   -M 0 \
   -T 150
