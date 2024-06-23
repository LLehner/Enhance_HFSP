import os
from Bio import SeqIO

def extract_uniprot_ids_from_fasta(fasta_file):
    uniprot_ids = set()
    for record in SeqIO.parse(fasta_file, "fasta"):
        uniprot_id = record.id.split('|')[1]  # Assuming UniProt ID is the second field in the FASTA header
        uniprot_ids.add(uniprot_id)
    return uniprot_ids

def extract_uniprot_ids_from_pdb_directory(pdb_directory):
    pdb_files = os.listdir(pdb_directory)
    pdb_ids = {os.path.splitext(filename)[0] for filename in pdb_files if filename.endswith('.pdb')}
    return pdb_ids

def find_missing_ids(fasta_file, pdb_directory):
    fasta_ids = extract_uniprot_ids_from_fasta(fasta_file)
    pdb_ids = extract_uniprot_ids_from_pdb_directory(pdb_directory)
    missing_ids = pdb_ids - fasta_ids
    return missing_ids

# Usage
fasta_file = 'Swiss-Prot_2002_redundancy_reduced.fasta'
pdb_directory = 'Swiss-Prot_2002'

missing_ids = find_missing_ids(fasta_file, pdb_directory)
print("Missing UniProt IDs in FASTA file:", missing_ids)
