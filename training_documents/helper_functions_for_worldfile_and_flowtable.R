# Some functions that may be helpful


# Function for generating a data frame from all the raster outputs
# Functions for generating a hillslope-level or patch-level worldfile and flowtable
# Functions for determining which patch or hillslope to choose



library(RHESSysPreprocessing)
library(tidyr)
library(dplyr)
library(purrr)
library(raster)


# --------------------------------------------------------------------------
# --------------------------------------------------------------------------
# --------------------------------------------------------------------------
# Function for pulling together the various rasters that are used by
# RHESSysPreprocessing and generates a data frame (table) for easier querying and data
# analysis.

# Arguments
# input_path: Path to folder containing rasters
# raster_names: A vector of the rasters to be included
# input_file_ext: File extension of the rasters
# output_file: Path and file name of generated table

rasters_as_df <- function(input_path, raster_names, input_file_ext=NULL, output_file){
  
  # Import rasters into list
  raster_list <- purrr::map(raster_names, function(x) raster::raster(file.path(input_path, paste0(x, input_file_ext))))
  
  # Generate raster with unique cell IDs
  if(!is.null(raster_list)){
    cells_raster <- raster::rasterFromCells(raster_list[[1]], cells = seq(1,ncell(raster_list[[1]])))
    raster_list <- append(cells_raster, raster_list)
  }
  
  # Stack all rasters
  raster_stack <- raster::stack(raster_list)
  
  # Convert rasters to data frame. The longitude and latitude coordinate is
  # generated from rasterToPoints for the center of each raster (Or, at least, I think it is the center).
  raster_df <- tibble::as_tibble(rasterToPoints(raster_stack))
  # Rename layer to cell_id
  raster_df <- rename(raster_df, cell_id = layer)
  
  # Generate col and row numbers
  raster_df <- bind_cols(raster_df, col_num = purrr::map_dbl(raster_df$cell_id, function(x) colFromCell(cells_raster, x)))
  raster_df <- bind_cols(raster_df, row_num = purrr::map_dbl(raster_df$cell_id, function(x) rowFromCell(cells_raster, x)))
  
  # Change order of columns
  raster_df <- relocate(raster_df, c(cell_id), .before = "x")
  raster_df <- relocate(raster_df, c(col_num, row_num), .after = "y")
  raster_df <- relocate(raster_df, c(basin, subbasin, hill, patch), .after = "row_num")
  
  # Write output
  write_csv(raster_df, output_file)
  
  return(raster_df)
}




# --------------------------------------------------------------------------
# --------------------------------------------------------------------------
# --------------------------------------------------------------------------
# Functions for making patch and hillslope-level worldfile and flowtable

# Arguments
# worldfile: Path and filename of original worldfile
# flowtable: Path and filename of original flowtable
# out: Path and filename for new worldfile or flowtable. Should include ext (.world or .flow)
# basin: Basin number to be selected
# hill: Hill number to be selected
# zone: Zone number to be selected
# patch: Patch number to be selected


select_worldfile_patch <- function(worldfile, out, basin, hill, zone, patch){
  
  world <- read_world(worldfile)
  
  # Remove last digit of canopy strata ID to make it the same as patch ID. Then filter for selected IDs.
  world <- world %>% 
    dplyr::mutate(ID = if_else(level == "canopy_strata", str_sub(ID, 1, nchar(ID)-1), ID)) %>% 
    dplyr::filter(level == "world" | 
                    level == "basin" & ID == basin | 
                    level == "hillslope" & ID == hill |
                    level == "zone" & ID == zone |
                    level == "patch" & ID == patch |
                    level == "canopy_strata" & ID == patch)
  
  # Change the number of basins, hillslopes, zones and patches to 1.
  world <- mutate(world, values = if_else(vars %in% c("num_basins", "num_hillslopes", "num_zones", "num_patches"), "1", values))
  
  # Export worldfile
  write.table(dplyr::select(world, values, vars), file = out, row.names = FALSE, col.names = FALSE, quote=FALSE, sep="  ")
}


# --------------------------------------------------------------------------

select_worldfile_hillslope <- function(worldfile, out, basin, hill){
  
  world <- read_world(worldfile)
  
  world <- world %>% 
    dplyr::mutate(hill_ID = case_when(level == "world" ~ "0",
                                      level == "basin" ~ "0",
                                      level == "hillslope" ~ ID,
                                      level == "zone" ~ NA_character_,
                                      level == "patch" ~ NA_character_,
                                      level == "canopy_strata" ~ NA_character_)
    ) %>% 
    tidyr::fill(hill_ID, .direction = "down") %>% 
    dplyr::filter(level == "world" | 
                    level == "basin" & ID == basin | 
                    hill_ID == hill)
  
  # Change the number of basins and hillslopes to 1.
  world <- mutate(world, values = if_else(vars %in% c("num_basins", "num_hillslopes"), "1", values))
  
  # Export worldfile
  write.table(dplyr::select(world, values, vars), file = out, row.names = FALSE, col.names = FALSE, quote=FALSE, sep="  ")
}


# --------------------------------------------------------------------------

select_flowtable_patch <- function(flowtable, out, patch){
  
  # Flow table is read in as a list
  flow <- read_in_flow(flowtable)
  
  # Keep the component of the list associated with the patch ID.
  flow <- purrr::keep(flow, function(x) x$PatchID == patch)
  # Change the number of neighbors to NULL.
  flow[[1]]$Neighbors <- NULL
  
  # Export flowtable
  RHESSysPreprocessing:::make_flow_table(flw = flow, output_file = out, parallel = TRUE)
}


# --------------------------------------------------------------------------

select_flowtable_hillslope <- function(flowtable, out, hill){
  
  # Flow table is read in as a list
  flow <- read_in_flow(flowtable)
  
  # Keep the component of the list associated with the patch ID.
  flow <- purrr::keep(flow, function(x) x$HillID == hill)
  
  # Export flowtable
  RHESSysPreprocessing:::make_flow_table(flw = flow, output_file = out, parallel = TRUE)
}





# --------------------------------------------------------------------------
# --------------------------------------------------------------------------
# --------------------------------------------------------------------------
# Functions for guiding which patch or hillslope to choose

# This function selects a raster cell based on median elevation of land cover type.
select_cell_based_on_median_elevation <- function(raster_df, land_cover_number){
  cell <- raster_df %>% 
    dplyr::filter(., lc_overstory == land_cover_number) %>% 
    dplyr::arrange(dem) %>% 
    dplyr::mutate(dem_rank = rank(dem)) %>% 
    dplyr::mutate(dem_med = floor(median(dem_rank))) %>% 
    dplyr::filter(dem_med == dem_rank)
  return(cell)
}


# This function identifies the raster cell that is closest to an inputted long/lat.
select_cell_from_longlat <- function(raster_df, long, lat){
  cell <- raster_df %>% 
    dplyr::filter(abs(x-long) == min(abs(x-long))) %>% 
    dplyr::filter(abs(y-lat) == min(abs(y-lat))) 
  return(cell)
}






# --------------------------------------------------------------------------
# --------------------------------------------------------------------------
# --------------------------------------------------------------------------
# Examples of how to run all the above functions
# Should work if you substitute your watershed for sagehen


# --------------------------------------------------------------------------
# Create a table from rasters

raster_names=c("aspect", "basin", "cf_overstory", "cf_understory",
               "clim_grid", "dem", "ehr", "hill", "lc_overstory",
               "lc_understory", "patch", "slope", "streams",
               "subbasin", "whr")

# Sagehen
sagehen_df <- rasters_as_df(input_path="grass/grass_outputs/sagehen", 
                            raster_names=raster_names,
                            input_file_ext = ".tif",
                            output_file = "out_r/sagehen/sagehen_df.csv")



# --------------------------------------------------------------------------
# This example finds the cell that has the median elevation of all conifer cells


cell_selected <- select_cell_based_on_median_elevation(raster_df=sagehen_df, 42)
  
select_worldfile_patch(worldfile = "ws/sagehen/worldfiles/sagehen_gridded.world",
                       out ="ws/sagehen/worldfiles/sagehen_tower_patch.world",
                       basin = cell_selected$basin, hill = cell_selected$hill,
                       zone = cell_selected$patch, patch = cell_selected$patch)

select_flowtable_patch(flowtable = "ws/sagehen/flowtables/sagehen_gridded.flow",
                       out = "ws/sagehen/flowtables/sagehen_tower_patch.flow",
                       patch = cell_selected$patch)


select_worldfile_hillslope(worldfile = "ws/sagehen/worldfiles/sagehen_gridded.world",
                           out ="ws/sagehen/worldfiles/sagehen_tower_hillslope.world",
                           basin = cell_selected$basin, hill = cell_selected$hill)

select_flowtable_hillslope(flowtable = "ws/sagehen/flowtables/sagehen_gridded.flow",
                           out = "ws/sagehen/flowtables/sagehen_tower_hillslope.flow",
                           hill = cell_selected$hill)




