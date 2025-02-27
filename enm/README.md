# Ecological Niche Modeling (ENM) Tutorial

Jing Jiang (with a little touch up from Copilot)
2025-02-27

This directory contains resources, scripts, and data for the Ecological Niche Modeling tutorial. The materials are designed to guide users through the process of creating, evaluating, and interpreting ecological niche models.

## Purpose

Ecological Niche Modeling (ENM) is a technique used to project areas suitable for a tree species or a forest ecosystem under climate change, based on environmental variables. This tutorial provides a structured approach to learning ENM concepts and implementing them using R.

## Contents

This folder is organized as follows:

- **data/**: Contains input datasets
  - **climate/**: Climate variables and environmental layers
  - **occurrence/**: Species occurrence records
  - **shapefiles/**: Geographic boundary files

- **scripts/**: R scripts for the ENM workflow
  - **01_data_preparation.R**: Prepare and clean input data
  - **02_model_building.R**: Build ecological niche models
  - **03_model_evaluation.R**: Evaluate model performance
  - **04_visualization.R**: Visualize model outputs and results

- **results/**: Model outputs and visualizations
  - **models/**: Saved model objects
  - **maps/**: Generated distribution maps
  - **plots/**: Performance charts and plots
  - **tables/**: Summary statistics and evaluation metrics

## Usage

Follow these steps to work through the tutorial:

1. Ensure all dependencies are installed (see Requirements section)
2. Start with the introductory scripts in the Scripts directory
3. Follow the workflow from data preparation to model evaluation
4. Compare your results with the examples provided

## Requirements

This tutorial requires R and the following packages:

- **terra**: For handling spatial raster data
- **dplyr**: For data manipulation
- **sf**: For vector data processing
- **ggplot2**: For creating visualizations
- **randomForest**: For machine learning model implementation
- **caret**: For model training and evaluation
- **pROC**: For model performance assessment
- **ranger**: For efficient random forest implementation

You can install the required packages using the `install_dependencies.R` script in the root directory.

## Getting Help

If you encounter any issues while following this tutorial, please refer to the documentation or raise an issue in the repository.
