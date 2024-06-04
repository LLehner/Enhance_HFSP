import os
import sys
import pandas as pd

def main():
    if len(sys.argv) < 3 or len(sys.argv) > 4:
        print("Usage: python check_retrieved.py directory/of/pdb_files file.xlsx [sheet index]")
        sys.exit(1)
    
    pdb_directory = sys.argv[1]
    excel_path = sys.argv[2]
    sheet_index = int(sys.argv[3]) if len(sys.argv) == 4 else None

    # Ensure pdb_directory exists
    if not os.path.isdir(pdb_directory):
        print(f"Directory {pdb_directory} does not exist.")
        sys.exit(1)

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

    uniprot_ids = set(df['id'].tolist())

    # Get list of retrieved PDB files
    retrieved_ids = {filename.split('.')[0] for filename in os.listdir(pdb_directory) if filename.endswith('.pdb')}

    # Find missing IDs
    missing_ids = uniprot_ids - retrieved_ids

    # Write missing IDs to CSV
    missing_ids_path = os.path.join(os.getcwd(), 'missing_ids.csv')
    with open(missing_ids_path, 'w') as file:
        for uniprot_id in missing_ids:
            file.write(f"{uniprot_id}\n")

    print(f"Missing IDs have been written to {missing_ids_path}")

if __name__ == "__main__":
    main()
