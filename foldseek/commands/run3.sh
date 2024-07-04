#!/usr/bin/env bash

FOLDSEEK_DIR="/nfs/home/students/l.hafner/pp1/Enhance_HFSP/testing/foldseek"

foldseek easy-search \
    /nfs/proj/sc-guidelines/pp1/Enhance_HFSP/testing/1_after_downloading/Swiss-Prot_2002 \
    /nfs/proj/sc-guidelines/pp1/Enhance_HFSP/testing/1_after_downloading/Swiss-Prot_2002 \
    ${FOLDSEEK_DIR}/outputs/run3.tsv \
    ${FOLDSEEK_DIR}/tmp \
    --alignment-mode 3 \
    --num-iterations 3 \
    -e 1e-3 \
    -s 9.6 \
    -k 0 \
    --gap-open aa:11,nucl:5 \
    --gap-extend aa:1,nucl:2 \
    --format-mode 4 \
    --format-output query,target,evalue,bits,pident,fident,nident,alnlen,mismatch,gapopen,qstart,qend,qlen,tstart,tend,tlen,lddt,rmsd,prob,qtmscore,ttmscore,alntmscore,qcov,tcov,cigar \
    --compressed 1 \
    --threads 120
