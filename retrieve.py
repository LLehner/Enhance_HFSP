import os
import sys
import requests
import pandas as pd
from tqdm import tqdm

def retrieve_pdb(uniprot_id, output_dir):
    url = f"https://alphafold.ebi.ac.uk/files/AF-{uniprot_id}-F1-model_v4.pdb"
    response = requests.get(url)
    if response.status_code == 200:
        with open(os.path.join(output_dir, f"{uniprot_id}.pdb"), 'w') as file:
            file.write(response.text)
        return True
    else:
        return False

def main():
    if len(sys.argv) < 3 or len(sys.argv) > 4:
        print("Usage: python retrieve.py /path/proteins.xlsx structure_dir [sheet_index]")
        sys.exit(1)
    
    excel_path = sys.argv[1]
    output_dir = sys.argv[2]
    sheet_index = int(sys.argv[3]) if len(sys.argv) == 4 else None

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    # Read Excel file
    if sheet_index is not None:
        xls = pd.ExcelFile(excel_path)
        sheet_name = xls.sheet_names[sheet_index]
        df = pd.read_excel(xls, sheet_name=sheet_name)
    else:
        df = pd.read_excel(excel_path)

    # Ensure 'id' column exists
    if 'id' not in df.columns:
        print("The Excel file must contain a column named 'id'.")
        sys.exit(1)

    uniprot_ids = df['id'].tolist()

    # Retrieve PDB files
    print(f"Retrieving PDB files for {len(uniprot_ids)} proteins...")

    for uniprot_id in tqdm(uniprot_ids):
        success = retrieve_pdb(uniprot_id, output_dir)
        if not success:
            print(f"Failed to retrieve PDB for {uniprot_id}")

if __name__ == "__main__":
    main()
