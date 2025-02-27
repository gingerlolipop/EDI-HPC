# niche_modeling_data_prep.R
# Data preparation script for Masson Pine niche modeling
# Updated with modern practices, improved documentation, and relative paths

# Load required packages ------------------------------------------------------
library(terra)    # Spatial data handling
library(dplyr)    # Data manipulation
library(sf)       # Spatial operations
library(ggplot2)  # Visualization
library(here)     # Path management - crucial for relative paths

# Set paths using relative references -----------------------------------------
# Define directory structure
raw_data_dir <- here("data raw")
processed_data_dir <- here("data processed")

# Create base output directory
dir.create(processed_data_dir, showWarnings = FALSE, recursive = TRUE)

# Define paths to key files
dem_path <- here("data raw", "areaDEM.tif") 
area_coords_path <- here("data processed", "area_coordinates.csv")
occur_csv_path <- here("data processed", "pr_ab2.csv")
processed_occur_path <- here("data processed", "processed_occurrences.csv")
occurrence_map_path <- here("data processed", "occurrence_map.png")

# Define climate data paths and directories
climate_scenarios <- list(
  historical = list(
    name = "Normal_1961_1990SY",
    csv = here("data processed", "area_coordinates_Normal_1961_1990SY.csv"),
    dir = here("data processed", "climate_rasters", "Normal_1961_1990SY")
  ),
  future_near = list(
    name = "8GCMs_ensemble_ssp245_2011SY",
    csv = here("data processed", "area_coordinates_8GCMs_ensemble_ssp245_2011SY.csv"),
    dir = here("data processed", "climate_rasters", "8GCMs_ensemble_ssp245_2011SY")
  ),
  future_far = list(
    name = "8GCMs_ensemble_ssp245_2071SY",
    csv = "C:/Users/jillb/Documents/women workshop/data processed/area_coordinates_8GCMs_ensemble_ssp245_2071SY.csv",
    dir = here("data processed", "climate_rasters", "8GCMs_ensemble_ssp245_2071SY")
  )
)

# Create climate raster directories
sapply(climate_scenarios, function(scenario) {
  dir.create(scenario$dir, showWarnings = FALSE, recursive = TRUE)
})

# Print working directory and key paths for the workshop participants
cat("Working directory:", getwd(), "\n")
cat("Project root:", here(), "\n")
cat("Using DEM file:", dem_path, "\n")
cat("Output will be saved to:", processed_data_dir, "\n")

# 1. Extract coordinates from pixels of the DEM file and save to CSV -----------------------------------------------------
# Load the DEM raster
dem <- terra::rast(dem_path)

# Extract coordinates from the raster
coords <- terra::crds(dem)
coords_df <- as.data.frame(coords)
names(coords_df) <- c("lon", "lat")

# Don't extract elevation values from DEM as it might not be a real DEM
# Instead leave elevation empty/NA
coords_df$elev <- NA  # Set elevation to NA instead of extracting from DEM

# Add empty ID columns
coords_df$id1 <- NA
coords_df$id2 <- NA

# Rearrange columns to match required format: id1, id2, lat, lon, elev
coords_df <- coords_df[, c("id1", "id2", "lat", "lon", "elev")]

# Save to CSV
write.csv(coords_df, area_coords_path, row.names = FALSE)
message(paste("Coordinates saved to:", area_coords_path))
message("NOTE: Elevation values are set to NA - ClimateAP will estimate them automatically")

# 2. Occurrence Data Processing --------------------------------------------------
occur <- read.csv(occur_csv_path) # In this tutorial, I provide a sample CSV file with presence and pseudo-absence

# Show original coding for verification
cat("Original occurrence coding:\n")
print(table(occur$species))

# Make sure coordinates are named correctly
if("x" %in% colnames(occur) && "y" %in% colnames(occur) && 
   !("lon" %in% colnames(occur)) && !("lat" %in% colnames(occur))) {
  occur <- occur %>% rename(lon = x, lat = y)
}

# Convert species column using consistent coding: 1 = presence, 0 = absence
if(is.numeric(occur$species)) {
  # If already numeric, ensure it's 0/1
  cat("Species already numeric. Verifying 0/1 coding...\n")
} else {
  # Convert text values to numeric
  if(any(occur$species %in% c("presence", "absence"))) {
    occur$species <- ifelse(occur$species == "presence", 1, 
                          ifelse(occur$species == "absence", 0, NA))
  } else if(any(occur$species %in% c("y", "n"))) {
    occur$species <- ifelse(occur$species == "y", 1, 
                          ifelse(occur$species == "n", 0, NA))
  }
}

# Ensure species is numeric
occur$species <- as.numeric(as.character(occur$species))

# Show final coding for verification
cat("Final occurrence coding (1=presence, 0=absence):\n")
print(table(occur$species))

# Create a factor version for visualization
occur$species_factor <- factor(occur$species, 
                              levels = c(0, 1), 
                              labels = c("absence", "presence"))

# Data Visualization ----------------------------------------------------------
map <- ggplot(occur, aes(lon, lat, color = species_factor)) +
  geom_point(size = 1.5, alpha = 0.7) +
  borders("world", colour = "gray40") +
  scale_color_manual(
    values = c("absence" = "#8B2BE2", "presence" = "#00A651"),  # Purple for absence, green for presence
    name = "Occurrence Type"  
  ) +
  labs(
    title = "Masson Pine Occurrence Records",
    subtitle = "Presence (1) and pseudo-absence (0) points",
    x = "Longitude", y = "Latitude"
  ) +
  coord_sf(xlim = range(occur$lon), ylim = range(occur$lat)) +
  theme_minimal() +
  theme(
    legend.position = "right",
    legend.title = element_text(face = "bold"),
    legend.background = element_rect(fill = "white", color = "gray80")
  )

# Display the plot (important for interactive sessions)
print(map)

# Save the map
ggsave(occurrence_map_path, map, width = 8, height = 6, dpi = 300)
message(paste("Map saved to:", occurrence_map_path))

# Save the processed occurrence data - keeping consistent 0/1 coding
write.csv(occur, processed_occur_path, row.names = FALSE)
message(paste("Processed occurrences saved to:", processed_occur_path))

# 3. Get Climate Data -----------

# In this part, we will use ClimateAP software to get climate data based on coordinates
# We use three datasets: 
# (1) a 30-year average (1961-1990) set for model building, 
# (2) a 30-year average (1961-1990) for the whole research area to predict suitability
# and (3) a recent period (2011-2020) for projection.

# Steps are below:
# 1. Download, install and open ClimateAP software, then choose "Normal 1961-1990" under the multi-location section
# 2. Select "Annual or seasonal variables (69)" - we need both annual and seasonal climate from the normal period
# 3. Select "Input File", and choose the "processed_occurrences.csv" from the processed data folder:
#    - File path: processed_occur_path (shown in console)
# 4. Select "Output File" and save it in the "data processed" folder:
#    - Suggested path: here("data processed", "occurrence_climate_Normal_1961_1990SY.csv")
# 5. Click "Start"
# Then, repeat for the coordinate CSV we generated from the DEM:
# - Input file: area_coords_path (shown in console)
# - Output file: climate_output_path (shown in console)
# Then, for the future period data:
# 6. Select "Future Normal Period" and select a 30-year average data of your interest.
#    In this tutorial, select "8GCMs_ensemble_ssp245_2011SY"
# 7. For "Input File", choose the coordinate CSV from the DEM (area_coords_path)
# 8. For "Output File", save to here("data processed", "area_coordinates_Future_2011SY.csv")
message("\n===== CLIMATE DATA PROCESSING INSTRUCTIONS =====")
message("For historical climate data (1961-1990):")
message("1. Open ClimateAP software, choose 'Normal 1961-1990' under multi-location")
message("2. Select 'Annual or seasonal variables (69)'")
message("3. Input file: ", processed_occur_path)
message("4. Output file: ", here("data processed", "occurrence_climate_Normal_1961_1990SY.csv"))
message("5. Repeat with input: ", area_coords_path)
message("6. Output file: ", climate_scenarios$historical$csv)

message("\nFor near future climate data (2011-2020):")
message("1. Select 'Future Normal Period' and '8GCMs_ensemble_ssp245_2011SY'")
message("2. Input file: ", area_coords_path)
message("3. Output file: ", climate_scenarios$future_near$csv)

message("\nFor far future climate data (2071-2100):")
message("1. Select 'Future Normal Period' and '8GCMs_ensemble_ssp245_2071SY'")
message("2. Input file: ", area_coords_path)
message("3. Output file: ", climate_scenarios$future_far$csv)
message("===== END INSTRUCTIONS =====\n")

# 4. Convert climate data from CSV to raster files --------------------------
# Create a function to process climate data for any scenario using direct rasterization
process_climate_data <- function(scenario, dem_template) {
  csv_path <- scenario$csv
  output_dir <- scenario$dir
  scenario_name <- scenario$name

  message("\nProcessing climate data for scenario: ", scenario_name)

  # Check if file exists
  if (!file.exists(csv_path)) {
    message("Climate data CSV not found: ", csv_path)
    message("Please run the ClimateAP software first to generate this file.")
    return(FALSE)
  }

  # Read the climate data
  clim_data <- read.csv(csv_path)
  message("Successfully read climate data: ", nrow(clim_data), " rows, ", ncol(clim_data), " columns")
  
  # Check for required columns
  if (!all(c("Longitude", "Latitude") %in% colnames(clim_data))) {
    message("Error: Required columns Longitude and/or Latitude not found in data")
    return(FALSE)
  }
  
  # Determine which columns are climate variables (non-coordinate columns)
  # Typically climate variables start after ID, lat/lon, elevation columns
  # Find the climate variable columns - assume they start after position 5
  if (ncol(clim_data) <= 5) {
    message("Error: Not enough columns in data. Expected climate variables after position 5")
    return(FALSE)
  }
  
  # Use columns from position 6 onwards as climate variables
  clim_var_cols <- 6:ncol(clim_data)
  
  # Create directory if it doesn't exist
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }
  
  # Get exact extent from DEM for consistent rasters
  dem_extent <- ext(dem_template)
  dem_crs <- crs(dem_template)
  dem_res <- res(dem_template)
  
  # Process each climate variable
  message("Converting ", length(clim_var_cols), " climate variables to rasters...")
  
  for (j in clim_var_cols) {
    var_name <- colnames(clim_data)[j]
    message(" - Processing: ", var_name)
    
    # Create empty raster with DEM properties
    ras_j <- rast(
      xmin = dem_extent[1], 
      xmax = dem_extent[2],
      ymin = dem_extent[3], 
      ymax = dem_extent[4],
      resolution = dem_res,
      crs = dem_crs
    )
    
    # Extract coordinates and values, removing any NA values
    valid_idx <- !is.na(clim_data[, j])
    if (sum(valid_idx) < 10) {
      message("   Warning: Too few valid points for ", var_name, ". Skipping.")
      next
    }
    
    xy_data <- clim_data[valid_idx, c("Longitude", "Latitude")]
    values_data <- clim_data[valid_idx, j]
    
    # Convert to spatial vector
    pts <- vect(cbind(xy_data, values=values_data), 
                geom=c("Longitude", "Latitude"), 
                crs=dem_crs)
    
    # Rasterize points directly (faster and simpler than interpolation)
    # Using terra's rasterize with options similar to your previous code
    # For each cell, if multiple points fall in it, take their mean
    message("   Rasterizing points...")
    asc_j <- rasterize(
      pts, 
      ras_j, 
      field="values", 
      fun=mean, 
      na.rm=TRUE
    )
    
    # Check if rasterization produced a valid raster
    if (all(is.na(values(asc_j)))) {
      message("   Warning: Rasterization produced all NA values. Check your data.")
      # Try again with nearest neighbor method as fallback
      message("   Trying nearest neighbor interpolation instead...")
      
      # Simple nearest neighbor approach
      asc_j <- rast(ras_j)  # Create empty raster
      nearest_interp <- interpolate(asc_j, pts, method="nearest")
      
      # If this also fails, skip this variable
      if (all(is.na(values(nearest_interp)))) {
        message("   Error: Could not create valid raster for ", var_name, ". Skipping.")
        next
      } else {
        asc_j <- nearest_interp
      }
    }
    
    # Apply light smoothing to reduce artifacts (optional)
    asc_j <- focal(asc_j, w=matrix(1,3,3), fun="mean", na.rm=TRUE)
    
    # Save the raster
    out_file <- file.path(output_dir, paste0(var_name, ".tif"))
    writeRaster(asc_j, out_file, overwrite=TRUE)
    message("   - Saved to: ", basename(out_file))
    
    # Create a quick check plot for verification
    check_plot_dir <- file.path(output_dir, "visual_checks")
    dir.create(check_plot_dir, showWarnings = FALSE, recursive = TRUE)
    
    png(file.path(check_plot_dir, paste0(var_name, "_check.png")), 
        width = 800, height = 600)
    plot(asc_j, main = paste("Climate Variable:", var_name))
    dev.off()
  }
  
  # Create a summary plot of a few variables
  example_files <- list.files(output_dir, pattern="\\.tif$", full.names=TRUE)[1:min(4, length(clim_var_cols))]
  
  if (length(example_files) > 0) {
    png(file.path(output_dir, "example_variables.png"), width=1000, height=800)
    par(mfrow=c(2, ceiling(length(example_files)/2)))
    
    for (f in example_files) {
      r <- rast(f)
      var_name <- tools::file_path_sans_ext(basename(f))
      plot(r, main=var_name)
    }
    
    dev.off()
    message("Summary plot saved to: ", file.path(output_dir, "example_variables.png"))
  }
  
  message("Successfully processed climate data for scenario: ", scenario_name)
  return(TRUE)
}

# Load the DEM as template for consistent raster properties
dem <- rast(dem_path)

# Process climate data for both historical and future scenarios
message("\nProcessing climate data for multiple scenarios...")

for (scenario_name in names(climate_scenarios)) {
  scenario <- climate_scenarios[[scenario_name]]
  message("\n==== Processing ", scenario$name, " ====")
  success <- process_climate_data(scenario, dem)
  
  if (success) {
    message("Successfully processed climate data for ", scenario$name)
  } else {
    message("Failed to process climate data for ", scenario$name)
  }
}

# Plot one raster for verification
if (length(list.files(climate_scenarios$historical$dir, pattern="\\.tif$")) > 0) {
  example_file <- list.files(climate_scenarios$historical$dir, pattern="\\.tif$", full.names=TRUE)[1]
  r <- rast(example_file)
  
  png(file.path(processed_data_dir, "example_climate_raster.png"), width=800, height=600)
  plot(r, main=paste("Example Climate Raster:", basename(example_file)))
  dev.off()
  
  message("\nVerification: Example climate raster properties:")
  message("  Resolution: ", paste(res(r), collapse=" x "))
  message("  Extent: ", paste(round(as.vector(ext(r)), 4), collapse=", "))
  message("  CRS: ", crs(r, describe=TRUE)$name)
  message("\nExample raster saved to: ", file.path(processed_data_dir, "example_climate_raster.png"))
}

# Tutorial completion message
message("\n===== Tutorial Data Preparation Complete =====")
message("All outputs saved using relative paths under: ", processed_data_dir)
message("Output directory structure:")
message(" - ", climate_scenarios$historical$dir, " (Historical climate)")
message(" - ", climate_scenarios$future_near$dir, " (Near future climate, 2011-2020)")
message(" - ", climate_scenarios$future_far$dir, " (Far future climate, 2071-2100)")
message("You can now proceed to the niche modeling steps.")

# plot one raster for visualization
r <- rast(here("data processed", "climate_rasters", "Normal_1961_1990SY", "Tmax_MAM.tif"))
plot(r)
