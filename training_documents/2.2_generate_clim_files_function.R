# Function for generating clim files from Cal-Adapt
# Ryan Bart - May 2021


install.packages(tidyr)
install.packages(dplyr)
install.packages(purrr)
install.packages(lubridate)
install.packages(raster)
library(devtools)
install_github("ucanr-igis/caladaptr")
library(tidyr)
library(dplyr)
library(purrr)
library(lubridate)
library(raster)
library(caladaptr)


# --------------------------------------------------------------------------
# --------------------------------------------------------------------------
# --------------------------------------------------------------------------
# Function for generating clim file from Cal-Adapt

# Arguments
# slug: 
# clim_grid:
# clim_grid_dem:
# watershed_shapefile:
# output_folder:
# watershed_name: 

generate_clim_file_from_cal_adapt <- function(slug, clim_grid, clim_grid_dem, watershed_shapefile, output_folder, watershed_name){

  print(paste("Generating clim file for slug:", slug))
  
  # --------------------------------------------------------------------------
  # Subset clim grid to watershed
  
  # If clim_grid is null, generate a clim_grid from the clim_grid_dem
  # Not yet implemented
  
  # Crop clim_grid to watershed shapefile and then identify cell values.
  clim_grid_selected <- clim_grid %>% 
    raster::crop(watershed_shapefile, snap="out") 
  cells_selected <- clim_grid_selected %>% 
    values()
  clim_num <- length(cells_selected)
  
  # Generate a list of the center coordinate for each selected clim cell. This
  # will be used to query caladapt data.
  coord_selected <- map(cells_selected, function(x) as_tibble(xyFromCell(clim_grid, cell=x)))
  
  
  # --------------------------------------------------------------------------
  # Download climate data from Caladapt
  # See https://github.com/ucanr-igis/caladaptr for more on R API
  
  # Slug options
  # View(ca_catalog_rs())
  
  # Parse slug into components
  # The first component of the slug designates data type (e.g. pr, tasmax, tasmin)
  clim_type <- str_split(slug, "_")[[1]][1]
  # The second component of the slug designates time step
  clim_timestep <- str_split(slug, "_")[[1]][2]
  # The last component of the slug designates scenario
  clim_scenario <- str_split(slug, "_")[[1]][length(str_split(slug, "_")[[1]])]
  if(clim_scenario == "livneh"){ystart <- 1950; yend <- 2013}
  if(clim_scenario == "historical"){ystart <- 1950; yend <- 2005}
  if(clim_scenario %in% c("rcp45", "rcp85")){ystart <- 2006; yend <- 2099}
  # On non-observed datasets, the third component of the slug designates GCM
  clim_gcm <- if(clim_scenario != "livneh") {str_split(slug, "_")[[1]][3]} else {NULL}
  
  
  # ---- 
  # This function queries a single clim cell and returns data
  get_data <- function(coordinate, cell_id, slug, ystart, yend){
    request <- ca_loc_pt(coords = coordinate, id=cell_id) %>%
      ca_slug(slug) %>%
      ca_years(start = ystart, end = yend)
    out <- request %>% 
      ca_getvals_tbl() %>% 
      dplyr::select(-spag) %>% 
      mutate(val = as.double(val),
             dt = ymd(dt),
             year = year(dt))
    return(out)
  }
  
  
  # ----
  # Download caladapt data (Returns a list of containing data for each clim cell)
  data_cal_adapt_list <- purrr::map2(.x=coord_selected,.y=cells_selected, function(.x,.y){
    get_data(coordinate = .x, cell_id = .y,  
             slug = slug, ystart = ystart, yend =  yend)
  })
  
  
  # --------------------------------------------------------------------------
  # Make adjustment to downloaded data depending on file type
  
  # Note: Observed precip is in mm. Projected precip is Kg/m2/s.
  # Note: Observed temperature are in C. Projected temperatures are in K.
  
  # Change observed precipitation from mm to m.
  if (clim_type == "pr" & clim_scenario == "livneh"){
    data_cal_adapt_list <- purrr::map(data_cal_adapt_list, function(x) dplyr::mutate(x, val = val/1000))
  }
  
  # Change projected precipitation from  Kg/m2/s to m.
  # Conversion 1 kg/m2/s = 1 mm/s = 86400 mm/day
  if (clim_type == "pr" & clim_scenario %in% c("historical","rcp45", "rcp85")){
    data_cal_adapt_list <- purrr::map(data_cal_adapt_list, function(x) dplyr::mutate(x, val = val*86400))
  }
    
  # Change projected temperatures from K to C.
  if (clim_type %in% c("tasmax", "tasmin") & clim_scenario %in% c("historical","rcp45", "rcp85")){
    data_cal_adapt_list <- purrr::map(data_cal_adapt_list, function(x) dplyr::mutate(x, val = val - 273.15))
  }
  
  
  # --------------------------------------------------------------------------
  # Create a clim file for RHESSys
  
  # Following function prevents scientific notation in clim file
  options(scipen=999)
  
  # ----
  # First, compute zonal elevation stats for clim zones
  clim_grid_p <- clim_grid %>% 
    stack(., clim_grid_dem) %>% 
    rasterToPoints() %>% 
    as_tibble() %>% 
    rename(grid_cells = livneh_grid,
           mean_elev = clim_grid_dem) %>% 
    dplyr::filter(grid_cells %in% cells_selected)
  
  
  # ----
  # Second, generate the header component of the file
  
  clim_header_function <- function(input_list, clim_num){
    # 1st row
    clim_header <- as.data.frame(matrix(nrow=1,ncol=clim_num))
    clim_header[1,1] <- clim_num
    # 2nd row
    tmp <- as.data.frame(matrix(c(lubridate::year(input_list[[1]]$dt[1]),
                                  lubridate::month(input_list[[1]]$dt[1]),
                                  lubridate::day(input_list[[1]]$dt[1]),
                                  1, if(clim_num>4){rep_len(NA, clim_num-4)}),
                                nrow=1))
    clim_header <- bind_rows(clim_header, tmp)
    # 3rd row
    clim_header <- bind_rows(clim_header, as.data.frame(matrix(clim_grid_p$grid_cells, nrow=1)))
    # 4th row
    clim_header <- bind_rows(clim_header, as.data.frame(matrix(round(clim_grid_p$mean_elev), nrow=1)))
  }
  
  clim_header <- clim_header_function(input_list = data_cal_adapt_list, clim_num = clim_num)

  
  # ----
  # Third, assemble the data itself
  data_cal_adapt_df <- data_cal_adapt_list %>% 
    purrr::map(function(x) dplyr::select(x, val)) %>% 
    bind_cols(.name_repair = "minimal") %>% 
    setNames(colnames(clim_header))

  # ----
  # Fourth, combine header with data
  clim_file <- bind_rows(clim_header, data_cal_adapt_df)
  

  # --------------------------------------------------------------------------
  # Export clim file
  
  # Export clim file depending with correct file extension
  if (clim_type == "pr"){
    if (clim_scenario == "livneh"){
      write_delim(x = clim_file,
                  file = file.path(output_folder, paste0(paste(watershed_name, clim_scenario, ystart, yend, sep = "_"), ".rain")),
                  na="", col_names=FALSE)}
    if (clim_scenario != "livneh"){
      write_delim(x = clim_file,
                  file = file.path(output_folder, paste0(paste(watershed_name, clim_gcm, clim_scenario, ystart, yend, sep = "_"), ".rain")),
                  na="", col_names=FALSE)}
  }
  if (clim_type == "tasmax"){
    if (clim_scenario == "livneh"){
      write_delim(x = clim_file,
                  file = file.path(output_folder, paste0(paste(watershed_name, clim_scenario, ystart, yend, sep = "_"), ".tmax")),
                  na="", col_names=FALSE)}
    if (clim_scenario != "livneh"){
      write_delim(x = clim_file,
                  file = file.path(output_folder, paste0(paste(watershed_name, clim_gcm, clim_scenario, ystart, yend, sep = "_"), ".tmax")),
                  na="", col_names=FALSE)}
  }
  if (clim_type == "tasmin"){
    if (clim_scenario == "livneh"){
      write_delim(x = clim_file,
                  file = file.path(output_folder, paste0(paste(watershed_name, clim_scenario, ystart, yend, sep = "_"), ".tmin")),
                  na="", col_names=FALSE)}
    if (clim_scenario != "livneh"){
      write_delim(x = clim_file,
                  file = file.path(output_folder, paste0(paste(watershed_name, clim_gcm, clim_scenario, ystart, yend, sep = "_"), ".tmin")),
                  na="", col_names=FALSE)}
  }

}





# --------------------------------------------------------------------------
# --------------------------------------------------------------------------
# --------------------------------------------------------------------------
# Batch function for calling function generate_clim_file_from_cal_adapt

generate_clim_file_via_batch <- function(clim_grid_path,
                                         clim_grid_dem_path,
                                         watershed_shapefile_path,
                                         output_folder,
                                         watershed_name){
  
  # --------------------------------------------------------------------------
  # Get California-scale data (that can be used in all calls to function)
  
  # Establish scenarios (aka slugs in cal-adapt speak)
  # Slug options
  # View(ca_catalog_rs())
  
  # Vector of all slugs to be called as a batch.
  slug_long <- c("pr_day_livneh",
                 "tasmax_day_livneh",
                 "tasmin_day_livneh",
                 
                 "pr_day_HadGEM2-ES_historical",
                 "tasmax_day_HadGEM2-ES_historical",
                 "tasmin_day_HadGEM2-ES_historical",
                 
                 "pr_day_HadGEM2-ES_rcp45",
                 "tasmax_day_HadGEM2-ES_rcp45",
                 "tasmin_day_HadGEM2-ES_rcp45",
                 
                 "pr_day_HadGEM2-ES_rcp85",
                 "tasmax_day_HadGEM2-ES_rcp85",
                 "tasmin_day_HadGEM2-ES_rcp85"
  )
  
  
  # Import full clim grid (This was generated in R)
  clim_grid <- raster::raster(clim_grid_path)
  
  # Import dem that has mean elevation for each zone (This was generated in GRASS)
  clim_grid_dem <- raster::raster(clim_grid_dem_path)
  
  # --------------------------------------------------------------------------
  # Get watershed-scale data and establish watershed-scale variables
  # Sagehen
  
  # Get shapefiles for watershed (This was generated in GRASS)
  watershed_shapefile <- read_sf(watershed_shapefile_path) %>% 
    st_transform(crs = 4326)
  
  # --------------------------------------------------------------------------
  
  # Generate clim files
  purrr::walk(slug_long, function(x) generate_clim_file_from_cal_adapt(slug=x,
                                                                       clim_grid=clim_grid,
                                                                       clim_grid_dem=clim_grid_dem,
                                                                       watershed_shapefile=watershed_shapefile,
                                                                       output_folder=output_folder,
                                                                       watershed_name=watershed_name))
}





