#!/usr/bin/env python3

import numpy as np
import pandas as pd
from sklearn.metrics import f1_score
from itertools import product
from tqdm import tqdm

def hfsp(factor, exponent, alnlen, pident):
    if alnlen < 11:
        hfsp_val = 100
    elif 11 <= alnlen <= 450:
        hfsp_val = factor * alnlen ** (exponent * (1 + np.exp(1) ** (-alnlen / 1000)))
    else:
        hfsp_val = hfsp(factor, exponent, 450, pident)
    return pident - hfsp_val


data_train = pd.read_csv("/nfs/proj/sc-guidelines/pp1/Enhance_HFSP/testing/4_after_cv_split/whole_dataset/train.tsv", sep = "\t")
data_test = pd.read_csv("/nfs/proj/sc-guidelines/pp1/Enhance_HFSP/testing/4_after_cv_split/whole_dataset/test.tsv", sep = "\t")
data = data_train

results = []

factors = np.arange(50, 601, 2)
exponents = np.arange(-0.1, -0.5001, -0.005)

print(f"Testing {len(factors) * len(exponents)} different combinations")

for factor, exponent in tqdm(product(factors, exponents), total=len(factors) * len(exponents)):
    data['hfsp'] = data.apply(lambda row: hfsp(factor, exponent, row['ug_alnlen'], row['pident']), axis=1)
    data['y_pred'] = (data['hfsp'] > 0).astype(int)
    f1 = f1_score(data['y_true'], data['y_pred'])

    results.append({'factor': factor, 'exponent': exponent, 'f1_score': f1})

results_df = pd.DataFrame(results)
results_df.to_csv('gridsearch_python_train_2.tsv', index=False, sep = '\t')

best_result = results_df.loc[results_df['f1_score'].idxmax()]
print(best_result)