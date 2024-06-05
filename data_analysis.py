import os
import sys
import matplotlib.pyplot as plt
import pandas as pd
from Bio import PDB
from tqdm import tqdm

def load_pdb_files(data_path):
    pdb_files = []
    for file_name in os.listdir(data_path):
        if file_name.endswith('.pdb'):
            pdb_files.append(os.path.join(data_path, file_name))
    return pdb_files

def calculate_residue_counts(pdb_files):
    parser = PDB.PDBParser(QUIET=True)
    residue_counts = []

    for pdb_file in tqdm(pdb_files, desc="Processing PDB files"):
        structure_id = os.path.basename(pdb_file).split('.')[0]
        structure = parser.get_structure(structure_id, pdb_file)
        for model in structure:
            for chain in model:
                residue_count = len(chain)
                residue_counts.append(residue_count)

    return residue_counts

def plot_residue_count_histogram(residue_counts, save_path):
    plt.figure(figsize=(20, 12))
    plt.hist(residue_counts, bins=21, edgecolor='black')
    plt.title('Residue Count Histogram')
    plt.xlabel('Number of Residues')
    plt.ylabel('Frequency')
    plt.savefig(os.path.join(save_path, 'residue_count_histogram.png'))

def ec_class_sizes(df, save_path):
    for i in range(4):
        df['ec_class'] = df['ec_number'].apply(lambda x: '.'.join(x.split('.')[:i + 1]))
        ec_class_counts = df['ec_class'].value_counts()
        bar_plot_ec(ec_class_counts, i + 1, save_path)

def bar_plot_ec(data, ec_level, save_path):
    plt.figure(figsize=(20, 12))
    data.plot(kind='bar')
    plt.title(f'Size Distribution of {ec_level}. EC Categories')
    plt.xlabel('EC Categories ordered by size')
    plt.ylabel('Count')
    if len(data) < 70:
        plt.xticks(rotation=90)
    else:
        plt.xticks([])

    plt.savefig(os.path.join(save_path, f'ec_{ec_level}_class_distribution.png'))

def main(data_path, ids_path, save_path, sheet_index):
    pdb_files = load_pdb_files(data_path)
    if not pdb_files:
        print(f"No PDB files found in {data_path}. Exiting")
        return

    residue_counts = calculate_residue_counts(pdb_files)

    if sheet_index is not None:
        xls = pd.ExcelFile(ids_path)
        sheet_name = xls.sheet_names[sheet_index]
        df = pd.read_excel(xls, sheet_name=sheet_name)
    else:
        df = pd.read_excel(ids_path)

    if not os.path.exists(save_path):
        os.makedirs(save_path)

    plt.rcParams.update({'font.size': 20})

    plot_residue_count_histogram(residue_counts, save_path)
    print(f"Residue count histogram saved in {save_path}")

    ec_class_sizes(df, save_path)
    print(f"EC categories distributions saved in {save_path}")

if __name__ == "__main__":
    if len(sys.argv) < 4 or len(sys.argv) > 5:
        print("Usage: python data_analysis.py <pdb_folder_path> <ids_excel_path> <output_path> [sheet index]")
        sys.exit(1)

    pdb_path = sys.argv[1]
    ids_path = sys.argv[2]
    save_path = sys.argv[3]
    sheet_index = int(sys.argv[4]) if len(sys.argv) == 5 else None
    main(pdb_path, ids_path, save_path, sheet_index)
