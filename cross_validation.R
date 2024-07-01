# Install necessary packages
install.packages("data.table")
install.packages("Metrics")

# Load necessary libraries
library(data.table)
library(Metrics)

# Define the HFSP function
hfsp <- function(params, ungapped_alnlen, pident) {
  factor <- params[1]
  exponent <- params[2]

  hfsp <- ifelse(ungapped_alnlen <= 11,
                 pident - 101,
                 ifelse(ungapped_alnlen > 450,
                        pident - 28.4,
                        pident - (factor * (ungapped_alnlen ^ (exponent * (1 + exp(- ungapped_alnlen / 1000)))))))

  return(hfsp)
}

# Define the objective function to minimize (negative F1 score) (not used)
objective_function <- function(params, data) {
  ungapped_alnlen <- data$ungapped_alnlen
  pident <- data$pident
  true_labels <- as.integer(data$ec_match)

  predictions <- hfsp(params, ungapped_alnlen, pident) >= 0
  f1 <- f1_score(true_labels, predictions)
  return(-f1)
}

# Load all training and testing datasets
root_path_train <- "Train_files_alignment_between_all_but_test_set/"

train_files <- list(
  paste0(root_path_train, "leave_out_0_results_processed.tsv"),
  paste0(root_path_train, "leave_out_1_results_processed.tsv"),
  paste0(root_path_train, "leave_out_2_results_processed.tsv"),
  paste0(root_path_train, "leave_out_3_results_processed.tsv"),
  paste0(root_path_train, "leave_out_4_results_processed.tsv"),
  paste0(root_path_train, "leave_out_5_results_processed.tsv"),
  paste0(root_path_train, "leave_out_6_results_processed.tsv"),
  paste0(root_path_train, "leave_out_7_results_processed.tsv"),
  paste0(root_path_train, "leave_out_8_results_processed.tsv"),
  paste0(root_path_train, "leave_out_9_results_processed.tsv")
)

root_path <- "train_files/"

test_files <- list(
  paste0(root_path, "processed_result_test_0.tsv"),
  paste0(root_path, "processed_result_test_1.tsv"),
  paste0(root_path, "processed_result_test_2.tsv"),
  paste0(root_path, "processed_result_test_3.tsv"),
  paste0(root_path, "processed_result_test_4.tsv"),
  paste0(root_path, "processed_result_test_5.tsv"),
  paste0(root_path, "processed_result_test_6.tsv"),
  paste0(root_path, "processed_result_test_7.tsv"),
  paste0(root_path, "processed_result_test_8.tsv"),
  paste0(root_path, "processed_result_test_9.tsv")
)

# Define a function to calculate F1 score, precision, and recall for a given dataset using the optimized parameters
calculate_metrics <- function(data, params) {
  ungapped_alnlen <- data$ungapped_alnlen
  pident <- data$fident * 100
  true_labels <- as.integer(data$ec_match)

  # Calculate HFSP and make predictions
  hfsp_values <- hfsp(params, ungapped_alnlen, pident)
  predictions <- hfsp_values >= 0

  # Calculate precision, recall, and F1 score
  precision <- precision_score(true_labels, predictions)
  recall <- recall_score(true_labels, predictions)
  f1 <- f1_score(true_labels, predictions)

  return(list(precision = precision, recall = recall, f1 = f1))
}

# Function to read data files
read_data <- function(file) {
  return(fread(file, sep = "\t"))
}

# Grid search for best parameters
grid_search <- function(data) {
  factors <- seq(300, 1500, by = 50)
  exponents <- seq(-0.3, -0.9, by = -0.05)
  best_f1 <- -Inf
  best_params <- c(NA, NA)

  for (factor in factors) {
    for (exponent in exponents) {
      params <- c(factor, exponent)
      metrics <- calculate_metrics(data, params)
      if (metrics$f1 > best_f1) {
        best_f1 <- metrics$f1
        best_params <- params
      }
    }
  }

  return(best_params)
}

# Custom precision, recall, and F1 score functions
precision_score <- function(true_labels, predictions) {
  tp <- sum(true_labels == 1 & predictions == 1)
  fp <- sum(true_labels == 0 & predictions == 1)
  return(ifelse((tp + fp) > 0, tp / (tp + fp), 0))
}

recall_score <- function(true_labels, predictions) {
  tp <- sum(true_labels == 1 & predictions == 1)
  fn <- sum(true_labels == 1 & predictions == 0)
  return(ifelse((tp + fn) > 0, tp / (tp + fn), 0))
}

f1_score <- function(true_labels, predictions) {
  precision <- precision_score(true_labels, predictions)
  recall <- recall_score(true_labels, predictions)
  if (precision + recall == 0) {
    return(0)
  }
  return(2 * precision * recall / (precision + recall))
}

# Perform cross-validation
cross_validation_results <- lapply(1:length(train_files), function(i) {
  # Use cluster i as the test set
  test_data <- read_data(test_files[[i]])

  # Use all other clusters as the training set
  train_data <- rbindlist(lapply(train_files[i], read_data))

  # Perform grid search to find best parameters
  best_params <- grid_search(train_data)
  cat("Best parameters found for fold", i, ":", best_params, "\n")

  # Calculate metrics for the test set
  test_metrics <- calculate_metrics(test_data, best_params)

  # Calculate metrics for the training set
  train_metrics <- calculate_metrics(train_data, best_params)

  return(list(train_metrics = train_metrics, test_metrics = test_metrics, params = best_params))
})

# Extract and display the F1, precision, and recall scores for each run
train_f1_scores <- sapply(cross_validation_results, function(res) res$train_metrics$f1)
test_f1_scores <- sapply(cross_validation_results, function(res) res$test_metrics$f1)
train_precision_scores <- sapply(cross_validation_results, function(res) res$train_metrics$precision)
test_precision_scores <- sapply(cross_validation_results, function(res) res$test_metrics$precision)
train_recall_scores <- sapply(cross_validation_results, function(res) res$train_metrics$recall)
test_recall_scores <- sapply(cross_validation_results, function(res) res$test_metrics$recall)

print("Training F1 Scores:")
print(train_f1_scores)
print("Test F1 Scores:")
print(test_f1_scores)

print("Training Precision Scores:")
print(train_precision_scores)
print("Test Precision Scores:")
print(test_precision_scores)

print("Training Recall Scores:")
print(train_recall_scores)
print("Test Recall Scores:")
print(test_recall_scores)
