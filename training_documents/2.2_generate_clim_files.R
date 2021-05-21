# Call function for generating clim files from Cal-Adapt
# Ryan Bart - May 2021


source("R/0_utilities.R")
source("R/2.2_generate_clim_files_function.R")


# --------------------------------------------------------------------------
# --------------------------------------------------------------------------
# --------------------------------------------------------------------------
# Generate climate files (calls function in 2.2_generate_clim_files_function.R)


# Bull
generate_clim_file_via_batch(clim_grid_path="data/clim/livneh_grid.tif",
                             clim_grid_dem_path="data/clim/clim_grid_dem.tif",
                             watershed_shapefile_path="grass/grass_outputs/bull/basin.shp",
                             output_folder="ws/bull/clim",
                             watershed_name="bull")

# Indian
generate_clim_file_via_batch(clim_grid_path="data/clim/livneh_grid.tif",
                             clim_grid_dem_path="data/clim/clim_grid_dem.tif",
                             watershed_shapefile_path="grass/grass_outputs/indian/basin.shp",
                             output_folder="ws/indian/clim",
                             watershed_name="indian")

# Sagehen
generate_clim_file_via_batch(clim_grid_path="data/clim/livneh_grid.tif",
                             clim_grid_dem_path="data/clim/clim_grid_dem.tif",
                             watershed_shapefile_path="grass/grass_outputs/sagehen/basin.shp",
                             output_folder="ws/sagehen/clim",
                             watershed_name="sagehen")












