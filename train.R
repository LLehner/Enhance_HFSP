library(naturalsort)
library(data.table)

load_data <- function(input_path) {
  train.paths <- naturalsort(list.files(input_path, pattern = "train_*"))
  test.paths <- naturalsort(list.files(input_path, pattern = "test_*"))
  
  train <- vector("list", length(train.paths))
  test <- vector("list", length(test.paths))
  
  for (i in 1:length(train.paths)) {
    train[[i]] <- fread(file.path(input_path, train.paths[i]))
    test[[i]] <- fread(file.path(input_path, test.paths[i]))
  }
  return(list(train = train, test = test))
}


hfsp <- function(params, alnlen, pident) {
  factor <- params[1]
  exponent <- params[2]
  
  if (alnlen <= 11) {
    hfsp_val <- 100
  } else if (11 < alnlen & alnlen <= 450) {
    hfsp_val <- factor * alnlen ^ (exponent * (1 + exp(1) ^ (-alnlen / 1000)))
  } else {
    hfsp_val <- 28.4
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


objective_function <- function(params, train_data) {
  train_data$hfsp <- mapply(hfsp, MoreArgs = list(params = params), train_data$ug_alnlen, train_data$pident)
  y_true <- train_data$y_true
  y_pred <- ifelse(train_data$hfsp > 0, 1, 0)
  return(-f1_score(y_true, y_pred))
}


data <- load_data("/nfs/home/students/l.hafner/pp1/Enhance_HFSP/testing/4_after_cv_split/with_undersampling")

train <- data$train
test <- data$test

results <- data.table(fold = integer(), factor = numeric(), exponent = numeric(), f1_score = numeric())

factors <- seq(200, 600, by = 50)
exponents <- seq(-0.1, -0.4, by = -0.05)

for (factor in factors) {
  for (exponent in exponents) {
    print(paste("Testing factor", factor, "and exponent", exponent))
    initial_params <- c(factor, exponent)
    
    for (i in 1:length(train)) {
      if (T) {
        print(paste("Fold", i))
        train_data <- train[[i]]
        test_data <- test[[i]]
        
        optim_result <- optim(initial_params, objective_function, train_data = train_data, method = "Nelder-Mead")
        best_params <- optim_result$par
        
        test_data$hfsp <- mapply(hfsp, MoreArgs = list(params = best_params), test_data$ug_alnlen, test_data$pident)
        y_true <- test_data$y_true
        y_pred <- ifelse(test_data$hfsp > 0, 1, 0)
        
        f1 <- f1_score(y_true, y_pred)
        results <- rbind(results, data.table(fold = i, factor = best_params[1], exponent= best_params[2], f1_score = f1))
      }
    }
  }
}

fwrite(results, "/nfs/home/students/l.hafner/pp1/Enhance_HFSP/results_run2.tsv", sep ="\t")
results_per_fold <- results[, .SD[which.max(f1_score)], by = fold]
fwrite(results_per_fold, "/nfs/home/students/l.hafner/pp1/Enhance_HFSP/results_per_fold_run2.tsv", sep = "\t")
