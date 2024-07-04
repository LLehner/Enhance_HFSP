#!/usr/bin/env bash

# assuming '-c' is the sequence similarity from the HFSP paper, but parameter is called sequence identity
# assuming '-aS' is the target sequence coverage from the HFSP paper

cd-hit \
   -i testing/1_after_downloading/Swiss-Prot_2017.fasta \
   -o testing/2_after_redundancy_reduction/Swiss-Prot_2017_redundancy-reduced.fasta \
   -c 0.98 \
   -aS 0.98 \
   -M 0 \
   -T 150
