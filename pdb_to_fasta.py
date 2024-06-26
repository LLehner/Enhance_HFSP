import sys
import os
from tqdm import tqdm
from Bio import PDB
from Bio.SeqUtils import seq1

def extract_sequences_from_pdb(pdb_file):
    parser = PDB.PDBParser(QUIET=True)
    structure = parser.get_structure(os.path.basename(pdb_file), pdb_file)
    sequences = {}
    
    for model in structure:
        for chain in model:
            seq = ''
            for residue in chain:
                if PDB.is_aa(residue, standard=True):
                    seq += seq1(residue.get_resname())
            if seq:
                sequences[chain.id] = seq
                
    return sequences

def generate_fasta_header(pdb_file):
    file_name = os.path.splitext(os.path.basename(pdb_file))[0]
    header = f">{file_name}"
    return header

def write_fasta(sequences, output_file):
    with open(output_file, 'w') as f:
        for pdb_file, chains in sequences.items():
            for chain_id, sequence in chains.items():
                header = generate_fasta_header(pdb_file)
                f.write(f"{header}\n")
                f.write(f"{sequence}\n")

# Define input directory and output file
input_directory = sys.argv[1]
output_fasta_file = sys.argv[2]

# Extract sequences from all PDB files in the input directory
sequences = {}
for filename in tqdm(os.listdir(input_directory)):
    if filename.endswith(".pdb"):
        pdb_file = os.path.join(input_directory, filename)
        sequences[filename] = extract_sequences_from_pdb(pdb_file)

# Write the extracted sequences to the output FASTA file
write_fasta(sequences, output_fasta_file)
