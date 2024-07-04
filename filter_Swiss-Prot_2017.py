#!/usr/bin/env python3

import os
import shutil
from tqdm import tqdm

path_filtered_ids = "testing/2_after_redundancy_reduction/Swiss-Prot_2017_redundancy_reduced.txt"
path_input_directory = "testing/1_after_downloading/Swiss-Prot_2017"
path_output_directory = "testing/2_after_redundancy_reduction/Swiss-Prot_2017_redundancy_reduced"

if not os.path.exists(path_output_directory):
    os.makedirs(path_output_directory)

with open(path_filtered_ids) as f:
    ids = f.read().strip().split('\n')

for pdb_id in tqdm(ids):
    file_name = pdb_id + '.pdb'
    if os.path.isfile(os.path.join(path_input_directory, file_name)):
        shutil.copyfile(os.path.join(path_input_directory, file_name), os.path.join(path_output_directory, file_name))
    else:
        print(f"File not found: {pdb_id}.pdb")