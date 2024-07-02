library(naturalsort)

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

objective_function <- function(params) {
  f1_scores <- c()
  
  for (i in 1:length(train)) {
    train_data <- train[[i]]
    test_data <- test[[i]]
    
    # Apply the HFSP function to the test data
    test_data$hfsp <- mapply(hfsp, MoreArgs = list(params = params), test_data$ug_alnlen, test_data$pident)
    y_true <- test_data$y_true
    y_pred <- ifelse(test_data$hfsp > 0, 1, 0)
    
    f1 <- f1_score(y_true, y_pred)
    f1_scores <- c(f1_scores, f1)
  }
  
  average_f1 <- mean(f1_scores)
  return(-average_f1)
}

input.path <- "/nfs/home/students/l.hafner/pp1/Enhance_HFSP/testing/4_after_cv_split/with_undersampling"

train.paths <- naturalsort(list.files(input.path, pattern = "train_*"))
test.paths <- naturalsort(list.files(input.path, pattern = "test_*"))

train <- vector("list", length(train.paths))
test <- vector("list", length(test.paths))

for (i in 1:length(train.paths)) {
  train[[i]] <- fread(file.path(input.path, train.paths[i]))
  test[[i]] <- fread(file.path(input.path, test.paths[i]))
}



factors <- seq(300, 1500, by = 50)
exponents <- seq(-0.3, -0.9, by = -0.05)

results <- data.table(factor = numeric(), exponent = numeric(), f1_score = numeric())

for (factor in factors) {
  for (exponent in exponents) {
    print(paste("Testing factor", factor, "and exponent", exponent))
    initial_params <- c(factor, exponent)
    result <- optim(initial_params, objective_function, method = "Nelder-Mead")
    best_factor <- result$par[1]
    best_exponent <- result$par[2]
    best_f1 <- -result$value
    results <- rbind(results, data.table(factor = best_factor, exponent = best_exponent, f1_score = best_f1))
  }
}

best_result <- results[which.max(f1_score)]
print(best_result)






