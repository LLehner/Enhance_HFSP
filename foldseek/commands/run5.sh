#!/usr/bin/env bash

FOLDSEEK_DIR="/nfs/home/students/l.hafner/pp1/Enhance_HFSP/testing/foldseek"

foldseek easy-search \
    /nfs/home/students/l.hafner/pp1/Enhance_HFSP/testing/3_after_ec_filtering/Swiss-Prot_2017_redundancy_reduced_50 \
    /nfs/home/students/l.hafner/pp1/Enhance_HFSP/testing/3_after_ec_filtering/Swiss-Prot_2017_redundancy_reduced_50 \
    ${FOLDSEEK_DIR}/outputs/run5.tsv \
    ${FOLDSEEK_DIR}/tmp \
    --alignment-mode 3 \
    --num-iterations 3 \
    -e 1e-3 \
    -s 5.6 \
    -k 0 \
    --gap-open aa:11,nucl:5 \
    --gap-extend aa:1,nucl:2 \
    --format-mode 4 \
    --format-output query,target,pident,alnlen,mismatch,lddt,cigar \
    --compressed 1 \
    --threads 120