#!/usr/bin/env python3

import sys
from collections import defaultdict

cluster_file = sys.argv[1]
output_file = sys.argv[2]
target_cluster_count = int(sys.argv[3])
verbose = bool(sys.argv[4])

clusters = defaultdict(list)
current_cluster = None

# Read cluster file into dictionary {cluster_id: [protein1, protein2, ...]}
with open(cluster_file, "r") as file:
    for line in file:
        line = line.strip()
        if line.startswith('>Cluster'):
            current_cluster = int(line.split()[1])
        else:
            parts = line.split()
            # Remove aa and convert to int
            length = int(parts[1][:-3])
            # Remove '>' at start and '...' at end
            identifier = parts[2][1:-3]
            clusters[current_cluster].append(identifier)



# Distribute proteins among clusters equally, they are added to the currently smallest cluster
merged_clusters = [[] for i in range(target_cluster_count)]
for cluster_id, proteins in clusters.items():
    # Get index of cluster with the least elements
    smallest_cluster_index = min(range(len(merged_clusters)), key=lambda i: len(merged_clusters[i]))

    merged_clusters[smallest_cluster_index].extend(proteins)
    
    if verbose:
        print(f'Adding {len(proteins)} proteins to merged cluster {smallest_cluster_index}')

print(f'Final cluster sizes: {list(map(len, merged_clusters))}')

# Write clusters to file
with open(output_file, 'w') as f:
    f.write('protein_id\tcluster_id\n')
    for cluster_id, cluster in enumerate(merged_clusters):
        lines = [f'{protein}\t{cluster_id}\n' for protein in cluster]
        f.writelines(lines)