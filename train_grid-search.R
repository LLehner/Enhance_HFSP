library(data.table)


hfsp <- function(params, alnlen, pident) {
  factor <- params[1]
  exponent <- params[2]
  
  if (alnlen <= 11) {
    hfsp_val <- 100
  } else if (11 < alnlen & alnlen <= 450) {
    hfsp_val <- factor * alnlen ^ (exponent * (1 + exp(1) ^ (-alnlen / 1000)))
  } else {
    hfsp_val <- hfsp(params, 450, pident)
  }
  return(pident - hfsp_val)
}


f1_score <- function(y_true, y_pred) {
  confusion_matrix <- table(factor(y_true, levels = c(0, 1)), factor(y_pred, levels = c(0, 1)))
  TP <- confusion_matrix[2, 2]
  FP <- confusion_matrix[1, 2]
  FN <- confusion_matrix[2, 1]
  precision <- TP / (TP + FP)
  recall <- TP / (TP + FN)
  f1 <- 2 * (precision * recall) / (precision + recall)
  return(f1)
}


data.train <- fread("/nfs/proj/sc-guidelines/pp1/Enhance_HFSP/testing/4_after_cv_split/whole_dataset/train.tsv")
data.test <- fread("/nfs/proj/sc-guidelines/pp1/Enhance_HFSP/testing/4_after_cv_split/whole_dataset/test.tsv")


results <- data.table(factor = numeric(), exponent = numeric(), f1_score = numeric())

factors <- seq(50, 600, by = 2)
exponents <- seq(-0.1, -0.5, by = -0.005)

print(paste("Testing", length(factors) * length(exponents), "possible combinations..."))

for (factor in factors) {
  for (exponent in exponents) {
    print(paste("Testing factor", factor, "and exponent", exponent))
    params <- c(factor, exponent)
  
    data.train$hfsp <- mapply(hfsp, MoreArgs = list(params = params), data.train$ug_alnlen, data.train$pident)
    y_true <- data.train$y_true
    y_pred <- ifelse(data.train$hfsp > 0, 1, 0)
    
    f1 <- f1_score(y_true, y_pred)
    results <- rbind(results, data.table(factor = params[1], exponent= params[2], f1_score = f1))
  }
}

fwrite(results, "/nfs/home/students/l.hafner/pp1/Enhance_HFSP/gridsearch_r_train_2.tsv", sep ="\t")
#results_per_fold <- results[, .SD[which.max(f1_score)], by = fold]
#fwrite(results_per_fold, "/nfs/home/students/l.hafner/pp1/Enhance_HFSP/results_per_fold_run2.tsv", sep = "\t")
