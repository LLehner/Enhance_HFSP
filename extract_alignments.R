library(data.table)
library(dplyr)

calculate_ungapped_length <- function(cigar_string) {
  lengths <- as.numeric(unlist(strsplit(gsub("[A-Z]", " ", cigar_string), " ")))
  operations <- unlist(strsplit(gsub("[0-9]", "", cigar_string), ""))
  
  ungapped_length <- sum(lengths[operations == "M"])
  
  return(ungapped_length)
}

base.output <- "/nfs/proj/sc-guidelines/pp1/Enhance_HFSP/testing/4_after_cv_split/with_undersampling"

cv.splits <- fread("/nfs/proj/sc-guidelines/pp1/Enhance_HFSP/testing/4_after_cv_split/cv_clusters.tsv")
cv.splits$fold <- cv.splits$cluster_id + 1

alignments <- fread("/nfs/proj/sc-guidelines/pp1/Enhance_HFSP/testing/foldseek/outputs/run1.tsv")
proteins <- fread("/nfs/proj/sc-guidelines/pp1/Enhance_HFSP/testing/3_after_ec_filtering/Swiss-Prot_2002_redundancy_reduced_50.tsv") %>%
  dplyr::select(id, ec3)

for (i in 1:10) {
  print(paste("Prepare iteration", i))
    proteins.train <- cv.splits[fold != i]$protein_id
    proteins.test <- cv.splits[fold == i]$protein_id
    
    aln.train <- alignments %>%
      filter(query %in% proteins.train & target %in% proteins.train) %>%
      filter(query != target) %>%
      group_by(query) %>%
      filter(bits == max(bits)) %>%
      ungroup() %>%
      mutate(ug_alnlen = sapply(cigar, calculate_ungapped_length)) %>%
      dplyr::select(query, target, pident, ug_alnlen)
    
    aln.test <- alignments %>%
      filter(query%in% proteins.test & target %in% proteins.test) %>%
      filter(query != target) %>%
      group_by(query) %>%
      filter(bits == max(bits)) %>%
      ungroup() %>%
      mutate(ug_alnlen = sapply(cigar, calculate_ungapped_length)) %>%
      dplyr::select(query, target, pident, ug_alnlen)
    
    train <- inner_join(
      inner_join(aln.train, proteins, by = c("query" = "id")) %>%
        dplyr::rename(ec3_query = ec3),
      proteins,
      by = c("target" = "id")
    ) %>%
      dplyr::rename(ec3_target = ec3) %>%
      mutate(y_true = ifelse(ec3_query == ec3_target, 1, 0)) %>%
      dplyr::select(-ec3_query, -ec3_target)
    
    test <- inner_join(
      inner_join(aln.test, proteins, by = c("query" = "id")) %>%
        dplyr::rename(ec3_query = ec3),
      proteins,
      by = c("target" = "id")
    ) %>%
      dplyr::rename(ec3_target = ec3) %>%
      mutate(y_true = ifelse(ec3_query == ec3_target, 1, 0)) %>%
      dplyr::select(-ec3_query, -ec3_target)
    
    train_pos <- train %>% filter(y_true == 1)
    train_neg <- train %>% filter(y_true == 0)
    
    if (nrow(train_pos) < nrow(train_neg)) {
      train_neg <- train_neg %>% sample_n(nrow(train_pos))
    } else {
      train_pos <- train_pos %>% sample_n(nrow(train_neg))
    }
    
    train_balanced <- bind_rows(train_pos, train_neg)
    
    fwrite(train_balanced, file = paste0(base.output, "/train_", i, ".tsv"), sep = "\t")
    fwrite(test, file = paste0(base.output, "/test_", i, ".tsv"), sep = "\t")
}


