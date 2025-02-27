# List of required packages
required_packages <- c("terra", "dplyr", "sf", "ggplot2", "here",
                       "rnaturalearth", "rnaturalearthdata", "randomForest", 
                       "caret", "pROC", "ranger")

# Install any packages that are not already installed
installed <- rownames(installed.packages())
for(pkg in required_packages){
  if (!pkg %in% installed) {
    install.packages(pkg)
  }
}
