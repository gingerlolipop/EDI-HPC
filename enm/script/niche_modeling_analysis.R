# niche_modeling_analysis.R
# TUTORIAL SCRIPT: Species Distribution Modeling with Random Forest
# This script demonstrates how to build, evaluate, and project species distribution models
# for Masson Pine using historical climate data (1961-1990) and projecting to newer
# climate conditions (2011-2020)

#===============================================================================
# Load required packages ------------------------------------------------------
#===============================================================================
# Each package serves a specific purpose in our workflow:
library(terra)         # Modern package for spatial data handling and raster operations
library(randomForest)  # Implementation of the Random Forest algorithm
library(caret)         # Comprehensive framework for model training and evaluation
library(ggplot2)       # Advanced visualization capabilities
library(dplyr)         # Data manipulation and transformation
library(pROC)          # Tools for ROC curve analysis and AUC calculation
library(here)          # Path management that works across different computers

# TIP: If you encounter package installation issues, use: 
# install.packages(c("terra", "randomForest", "caret", "ggplot2", "dplyr", "pROC", "here"))

#===============================================================================
# Set paths using relative references -----------------------------------------
#===============================================================================
# Define paths using here() to ensure compatibility across different computers
data_dir <- here("data processed")
model_dir <- here("models")
# Update output directory to the requested location
output_dir <- "C:/Users/jillb/Documents/women workshop/model_outputs"

# Input paths
occur_climate_path <- here("data processed", "processed_occurrences_Normal_1961_1990SY.csv")
current_clim_dir <- here("data processed", "climate_rasters", "Normal_1961_1990SY")
future_near_clim_dir <- here("data processed", "climate_rasters", "8GCMs_ensemble_ssp245_2011SY")
future_far_clim_dir <- here("data processed", "climate_rasters", "8GCMs_ensemble_ssp245_2071SY")

# Define the climate scenarios for better labeling
climate_scenarios <- list(
  historical = list(name = "Historical", period = "1961-1990"),
  near_future = list(name = "SSP245", period = "2011-2020"),
  far_future = list(name = "SSP245", period = "2071-2100")
)

# Create output directories if they don't exist
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(output_dir, "maps"), showWarnings = FALSE)
dir.create(file.path(output_dir, "plots"), showWarnings = FALSE)
dir.create(model_dir, showWarnings = FALSE, recursive = TRUE)

# Print paths for verification
cat("Working directory:", getwd(), "\n")
cat("Project root:", here(), "\n")
cat("Using occurrence data:", occur_climate_path, "\n")
cat("Output will be saved to:", output_dir, "\n")

#===============================================================================
# 1. Import Occurrence + Climate Data -----------------------------------------
#===============================================================================
# TUTORIAL NOTE: Species distribution models require two basic inputs:
# 1. Species occurrence data (presence/absence or presence-only)
# 2. Environmental variables (typically climate data)
#
# Here we're using a pre-processed dataset that already combines both

# Check if the occurrence data file exists
if(!file.exists(occur_climate_path)) {
  stop("Occurrence data not found! Please make sure to run the data preparation script first.")
}

# Import occurrence data with climate variables
df <- read.csv(occur_climate_path)

# Print original data structure to verify format
cat("Original species coding:\n")
print(table(df$species))

# Convert species column ensuring consistent numeric coding: 1=presence, 0=absence
# TUTORIAL NOTE: It's critical that presence/absence data is properly coded.
# Random Forest expects numeric or factor data for the response variable.
if(is.character(df$species)) {
  # Handle text-based species coding
  if(any(df$species %in% c("presence", "absence"))) {
    df$species <- ifelse(df$species == "presence", 1, 
                        ifelse(df$species == "absence", 0, NA))
  } else if(any(df$species %in% c("y", "n"))) {
    df$species <- ifelse(df$species == "y", 1, 
                        ifelse(df$species == "n", 0, NA))
  }
} 

# Ensure species is numeric and properly coded
df$species <- as.numeric(as.character(df$species))

# Double-check for 0/1 coding and verify after conversion
cat("\nConverted species coding (should be 0/1):\n")
print(table(df$species))
cat("Confirmed: 1 = presence, 0 = absence\n\n")

# Check for any NAs that may have been introduced
if(any(is.na(df$species))) {
  warning(paste("Found", sum(is.na(df$species)), "NA values in species column. Check your data."))
  # Remove rows with NA species values
  df <- df[!is.na(df$species), ]
  cat("Rows with NA species values have been removed.\n")
}

# Look at the data structure for verification
cat("Data dimensions:", nrow(df), "rows,", ncol(df), "columns\n")
cat("Species distribution:", table(df$species), "\n")

#===============================================================================
# 2. Pre-training: feature selection and preprocessing ------------------------
#===============================================================================
# Select predictors and remove irrelevant columns
predictors <- df %>% select(-X, -species, -Longitude, -Latitude, -Elevation)

# Run preliminary model for variable selection
set.seed(42)
pre_model <- randomForest(
  x = predictors,
  y = factor(df$species, levels = c(0, 1), labels = c("absent", "present")),
  ntree = 100,
  importance = TRUE
)

# Select top 30 variables by importance
top_vars <- names(sort(importance(pre_model, type = 1)[,1], decreasing = TRUE)[1:30])
model_data <- df %>% select(species, Longitude, Latitude, Elevation, all_of(top_vars))
cat("Selected top 30 variables for modeling\n")

#===============================================================================
# 3. Model training with cross-validation -------------------------------------
#===============================================================================
train_model <- function(data) {
  # Split data 80/20
  set.seed(49)
  train_idx <- createDataPartition(factor(data$species, levels = c(0, 1)), p = 0.8, list = FALSE)
  train <- data[train_idx, ]
  test <- data[-train_idx, ]
  
  # Define cross-validation settings
  ctrl <- trainControl(
    method = "cv", 
    number = 5,
    classProbs = TRUE,
    summaryFunction = twoClassSummary,
    verboseIter = TRUE
  )
  
  # Define tuning grid
  rfGrid <- expand.grid(
    mtry = c(floor(sqrt(length(top_vars))), floor(length(top_vars)/3)),
    splitrule = "gini",
    min.node.size = c(1, 5)
  )
  
  # Train model
  rf_model <- train(
    x = train %>% select(all_of(top_vars)),
    y = factor(train$species, levels = c(0, 1), labels = c("absent", "present")),
    method = "ranger",
    importance = "impurity",
    tuneGrid = rfGrid,
    trControl = ctrl,
    metric = "ROC"
  )
  
  # Plot variable importance
  var_imp <- varImp(rf_model)
  png(file.path(output_dir, "variable_importance.png"), width = 800, height = 600)
  plot(var_imp, top = 10, main = "Top Variable Importance")
  dev.off()
  
  return(list(rf = rf_model, test_data = test))
}

# Train the model
models <- train_model(model_data)
saveRDS(models$rf, file.path(model_dir, "rf_masson_pine_model.rds"))

#===============================================================================
# 4. Model evaluation --------------------------------------------------------
#===============================================================================
evaluate_model <- function(model, test_data) {
  # Prepare test data
  test_data$species <- factor(test_data$species, levels = c(0, 1), labels = c("absent", "present"))
  
  # Make predictions
  pred_probs <- predict(model, newdata = test_data, type = "prob")
  pred <- pred_probs[, "present"]
  
  # Calculate metrics
  confMatrix <- confusionMatrix(
    factor(ifelse(pred > 0.5, "present", "absent"), levels = c("absent", "present")),
    test_data$species
  )
  roc_obj <- roc(as.numeric(test_data$species == "present"), pred)
  auc_value <- auc(roc_obj)
  
  # Print metrics
  cat("\nModel Performance: AUC =", round(auc_value, 3), 
      ", Accuracy =", round(confMatrix$overall["Accuracy"], 3), "\n")
  
  # Plot ROC curve
  png(file.path(output_dir, "roc_curve.png"), width = 800, height = 600)
  plot(roc_obj, main = paste("ROC Curve (AUC =", round(auc_value, 3), ")"),
       col = "blue", lwd = 2)
  abline(a = 0, b = 1, lty = 2, col = "gray")
  dev.off()
  
  return(list(auc = auc_value, confusion_matrix = confMatrix))
}

# Evaluate model
model_eval <- evaluate_model(models$rf, models$test_data)

#===============================================================================
# 5. Spatial prediction and Projection ---------------------------------------
#===============================================================================
# Load mapping libraries
library(maps)
library(mapdata)
library(GISTools)

# Get top 10 important variables
var_imp <- varImp(models$rf)
top10_vars <- rownames(var_imp$importance)[order(var_imp$importance$Overall, decreasing=TRUE)][1:10]
cat("Top 10 variables:", paste(top10_vars, collapse=", "), "\n")

# Function to load climate rasters and predict
predict_distribution <- function(clim_dir, model, period_name) {
  # List all raster files in directory
  all_files <- list.files(clim_dir, pattern="\\.tif$", full.names=TRUE)
  cat("Loading rasters from:", clim_dir, "\n")
  cat("Found", length(all_files), "raster files\n")
  
  # Load all rasters to ensure we have all variables the model needs
  rasters <- list()
  for(file in all_files) {
    # Extract variable name from filename
    var_name <- tools::file_path_sans_ext(basename(file))
    rasters[[var_name]] <- rast(file)
  }
  
  # Stack all rasters
  if(length(rasters) > 0) {
    climate_stack <- rast(rasters)
    cat("Created raster stack with", names(climate_stack), "\n")
    
    # Make prediction
    cat("Predicting for", period_name, "...\n")
    tryCatch({
      prediction <- terra::predict(climate_stack, model, na.rm=TRUE, type="prob")
      
      # If prediction returns multiple layers, select the second one (probability of presence)
      if(nlyr(prediction) > 1) {
        prediction <- prediction[[2]]
      }
      
      # Save prediction
      output_file <- file.path(output_dir, "maps", paste0("masson_pine_", period_name, ".tif"))
      writeRaster(prediction, output_file, overwrite=TRUE)
      cat("Saved prediction to:", output_file, "\n")
      
      # Plot basic map
      png(file.path(output_dir, "maps", paste0("masson_pine_", period_name, ".png")), 
          width=800, height=600)
      plot(prediction, main=paste("Masson Pine -", period_name))
      map('world', add=TRUE)
      dev.off()
      
      return(prediction)
    }, error = function(e) {
      cat("Error in prediction:", e$message, "\n")
      return(NULL)
    })
  } else {
    cat("No raster files found in directory\n")
    return(NULL)
  }
}

# Simple approach: Make predictions one by one
cat("\nMaking predictions for historical period...\n")
hist_pred <- predict_distribution(current_clim_dir, models$rf, "1961_1990")

cat("\nMaking predictions for near future period...\n")  
near_pred <- predict_distribution(future_near_clim_dir, models$rf, "2011_2020")

cat("\nMaking predictions for far future period...\n")
far_pred <- predict_distribution(future_far_clim_dir, models$rf, "2071_2100")

# Calculate and plot changes if predictions were successful
if(!is.null(hist_pred) && !is.null(near_pred)) {
  change_near <- near_pred - hist_pred
  writeRaster(change_near, file.path(output_dir, "maps", "change_to_2011_2020.tif"), overwrite=TRUE)
  
  # Plot change map
  png(file.path(output_dir, "maps", "change_near_future.png"), width=800, height=600)
  plot(change_near, main="Change by 2011-2020",
       col=colorRampPalette(c("red", "white", "blue"))(100))
  map('world', add=TRUE)
  dev.off()
}

if(!is.null(hist_pred) && !is.null(far_pred)) {
  change_far <- far_pred - hist_pred
  writeRaster(change_far, file.path(output_dir, "maps", "change_to_2071_2100.tif"), overwrite=TRUE)
  
  # Plot change map
  png(file.path(output_dir, "maps", "change_far_future.png"), width=800, height=600)
  plot(change_far, main="Change by 2071-2100",
       col=colorRampPalette(c("red", "white", "blue"))(100))
  map('world', add=TRUE)
  dev.off()
}