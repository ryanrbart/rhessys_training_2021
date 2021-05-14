# Call function for generating clim files from Cal-Adapt
# Ryan Bart - May 2021


source("R/0_utilities.R")
source("R/2.2_generate_clim_files_function.R")


# --------------------------------------------------------------------------
# --------------------------------------------------------------------------
# --------------------------------------------------------------------------
# Get California-scale data (that can be used in all calls to function)

# Import full clim grid (This was generated in R)
clim_grid <- raster::raster("data/clim/livneh_grid.tif")

# Import dem that has mean elevation for each zone (This was generated in GRASS)
clim_grid_dem <- raster::raster("data/clim/clim_grid_dem.tif")


# --------------------------------------------------------------------------
# --------------------------------------------------------------------------
# --------------------------------------------------------------------------
# Get watershed-scale data and establish watershed-scale variables
# Sagehen

# Get shapefiles for watershed (This was generated in GRASS)
watershed_shapefile <- read_sf("grass/grass_outputs/sagehen/basin.shp") %>% 
  st_transform(crs = 4326)

# Folder where clim file will be sent
output_folder <- "ws/sagehen/clim"

# Name of watershed
watershed_name <- "sagehen"


# ----
# Establish scenarios (aka slugs in cal-adapt speak)

# Slug options
# View(ca_catalog_rs())

# Vector of all slugs to be called as a batch.
slug_long <- c("pr_day_livneh",
               "tasmax_day_livneh",
               "tasmin_day_livneh",
               "pr_day_HadGEM2-ES_historical",
               "pr_day_HadGEM2-ES_rcp45",
               "pr_day_HadGEM2-ES_rcp85",
               "tasmax_day_HadGEM2-ES_historical",
               "tasmax_day_HadGEM2-ES_rcp45",
               "tasmax_day_HadGEM2-ES_rcp85",
               "tasmin_day_HadGEM2-ES_historical",
               "tasmin_day_HadGEM2-ES_rcp45",
               "tasmin_day_HadGEM2-ES_rcp85")


# Generate clim files
purrr::walk(slug_long, function(x) generate_clim_file_from_cal_adapt(slug=x,
                                                                    clim_grid=clim_grid,
                                                                    clim_grid_dem=clim_grid_dem,
                                                                    watershed_shapefile=watershed_shapefile,
                                                                    output_folder=output_folder,
                                                                    watershed_name=watershed_name)
)



# --------------------------------------------------------------------------
# --------------------------------------------------------------------------
# --------------------------------------------------------------------------
# Get California-scale data (that can be used in all calls to function)
# Next watershed...




