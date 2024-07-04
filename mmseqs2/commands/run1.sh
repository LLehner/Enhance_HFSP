#!/usr/bin/env bash

MMSEQS2_DIR="/nfs/home/students/l.hafner/pp1/Enhance_HFSP/testing/mmseqs2"

mmseqs easy-search \
    ${MMSEQS2_DIR}/Swiss-Prot_2002_redundancy_reduced_50.fasta \
    ${MMSEQS2_DIR}/Swiss-Prot_2002_redundancy_reduced_50.fasta \
    ${MMSEQS2_DIR}/outputs/run1.tsv \
    ${MMSEQS2_DIR}/tmp \
    --alignment-mode 3 \
    --num-iterations 3 \
    --e-profile 1e-10 \
    -e 1e-3 \
    -s 5.6 \
    --format-mode 4 \
    --format-output query,target,evalue,bits,pident,fident,nident,alnlen,mismatch,gapopen,qstart,qend,qlen,tstart,tend,tlen,qcov,tcov,cigar \
    --compressed 1 \
    --threads 120