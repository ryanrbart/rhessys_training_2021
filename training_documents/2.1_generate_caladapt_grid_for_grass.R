# Generating Livneh grid for CARB project
# Ryan Bart - April 2021

# This script generates the grid that will be used for generating the climate
# zone map that gets input into RHESSys.


install.packages(raster)
install.packages(ncdf4)
install.packages(rgdal)
library(raster)
library(ncdf4)
library(rdgal)

# --------------------------------------------------------------------------
# --------------------------------------------------------------------------
# --------------------------------------------------------------------------
# Create grid for GRASS

# Create a grid for the 3.75 minute (1/16 degree, ~6 km) Livneh tiles
clim_grid <- raster("/Users/ryanbart/work_dir/projects/carb_project/data/clim/livneh/livneh_CA_NV_15Oct2014.195001.nc",
                    varname="Prec") # Product options: Prec, Tmax, Tmin, wind
# Create a new raster based on cell number
# This will be the unique id for clim stations
# Cell numbers start at 1 in the upper left corner, and increase from left to right, and then from top to bottom. 
clim_grid <- raster::rasterFromCells(clim_grid, cells = seq(1,ncell(clim_grid)))


# Export Raster for uploading to GRASS
raster::writeRaster(clim_grid, "data/clim/livneh_grid", format = "GTiff", overwrite=TRUE)




# --------------------------------------------------------------------------
# --------------------------------------------------------------------------
# --------------------------------------------------------------------------


