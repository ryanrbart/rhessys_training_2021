# RHESSys Vegetation Change Experiment

# Today, we will be setting up an vegetation-change experiment in RHESSys. We
# will learn some tools for spinning up the watershed and manipulating the
# vegetation. You, however, will be in charge of the details of your experiment.
# You will be running a control scenario and at least one treatment scenario.
# The goal is to compare total carbon (plantc), streamflow, and any other
# variables of your choice, between the scenarios.


# ------------------------------------------------------------------------------
# Libraries

library(RHESSysIOinR)



# ------------------------------------------------------------------------------
# Create a dated sequence : Changing the worldfile

# The first technique we will learn for manipulating vegetation is how to do a
# dated sequence in RHESSys. Dated sequences allow you to make patch-level
# changes within the model at specific time periods. Dated sequences have been
# developed for numerous applications in RHESSys, but today we will use the
# biomass_removal_percent function. This is a relatively quick and simple
# approach for removing a certain percent of carbon from all vegetation biomass
# stores across all patches of the watershed.

# To implement a dated sequence, we need to add a line to description of each
# patch in the worldfile. This is a patch_baseline_ID, which tells the worldfile
# to look for a dated sequence in the clim file. Since the Watershed 8 (W8) has
# 245 patches, makes it so we don't have to add the line manually. The new world
# file will be named w8TC_dated.world.


add_patch_base_station_id <- function(world_name_in, world_name_out){
  newrow <- data.frame(a=101, b="patch_basestation_ID", stringsAsFactors = FALSE)
  # Read in worldfile
  worldfile <- read.table(world_name_in, header = FALSE, stringsAsFactors = FALSE)
  for (aa in seq(2,nrow(worldfile))){         # Note that this should be a while loop since worldfile is extended. (see other examples)
    if (aa%%1000 == 0 ){print(paste(aa,"out of", nrow(worldfile)))} # Counter
    if ((worldfile[aa,2] == "num_canopy_strata" | worldfile[aa,2] == "num_stratum") && worldfile[aa-1,2] == "patch_n_basestations"){
      # Change previous n_basestations to 1
      worldfile[aa-1,1] = 1
      # Add new line containing p_base_station_ID
      worldfile[seq(aa+1,nrow(worldfile)+1),] <- worldfile[seq(aa,nrow(worldfile)),]
      worldfile[aa,] <- newrow[1,]
    }
  }
  # Write new file
  worldfile$V1 <- format(worldfile$V1, scientific = FALSE)
  write.table(worldfile, file = world_name_out, row.names = FALSE, col.names = FALSE, quote=FALSE, sep="  ")
}

world_name_in <- "worldfiles/w8TC.world"
world_name_out <- "worldfiles/w8TC_dated.world"

add_patch_base_station_id(world_name_in = world_name_in, world_name_out = world_name_out)


# Check that new worlfile has a new 'patch_basestation_ID' line


# ------------------------------------------------------------------------------
# Create a dated sequence : Changing the clim files

# ******** Note, this section is to be done in linux, not R *************

# Starting in the Testing directory

# Navigate to climate folder, modify the base station file, and rename
cd clim
vim w8_base
# Press i.
# Move cursor to very end of document and press return.
# Add following three lines of code
clim/w8_spinup
1
biomass_removal_percent
# Press esc key
:w w8_base_spinup
:q!

# Now create a new file that contains the date when the dated sequence will occur.
vim w8_spinup.biomass_removal_percent
# Press i
# Add two lines
1
1980 1 2 1 .999
# Press esc
:wq


# What we have done is made a new base station file that refers to the dated
# sequence we will be using and a dated sequence file. Now it is time to return
# to R and do a spinup.


# ------------------------------------------------------------------------------
# Spinup

# Before we run our scenarios, we will spinup the watershed. We will replicate
# conditions of a clearcut or stand-replacing fire by removing all vegetation at
# the beginning of the spinup run. The vegetation will then die and initiate the
# regrowth. We will export a worldfile at the end of spinup. This new worldfile
# will be the initial conditions for the scenarios we run.


# The w8 time series is 70 years, starting in 1978. Within RHESSys, there is a
# flag to repeat timeseries called -climrepeat, that can be used to extend
# simulations beyond the meteorological record. The simulation still needs to be
# started during the meteorological record. I picked a 100 year spinup. You can
# spinup however long you wish (while noting that it yesterdays runs took ~35
# second per decade for CARB server)


# Generate rhessys inputs
input_rhessys = IOin_rhessys_input(
  version = "../RHESSys/rhessys7.3",               # CARB folks need to change this to "../rhessys/rhessys7.2"
  tec_file = "tecfiles/w8TC.tec",
  world_file = "worldfiles/w8TC_dated.world",      # New worldfile
  world_hdr_prefix = "w8TC",
  flowtable = "flowtables/w8TC.flow",
  start = "1980 1 1 1",
  end = "2080 1 1 1",
  output_folder = "out_training",
  output_prefix = "spinup",                        # New output name
  commandline_options = c("-g -b -p 1 74 2438 2438 -c 1 74 2438 2438 24381 -climrepeat")     # New flags
)


# Generate tec file: For non-CARB users
input_tec_data = IOin_tec_std(start = "1980 1 1 1",
                              end = "2080 1 1 1",
                              output_state = TRUE)


# Generate tec file: For CARB users
IOin_tec_std2 <- function (start, end, output_state = TRUE){
  start_split = unlist(strsplit(as.character(start), split = " "))
  end_split = unlist(strsplit(as.character(end), split = " "))
  input_tec_data <- data.frame(year = integer(), month = integer(),
                               day = integer(), hour = integer(), name = character(), stringsAsFactors=FALSE)
  input_tec_data[1, ] <- data.frame(as.numeric(start_split[1]), as.numeric(start_split[2]),
                                    as.numeric(start_split[3]), as.numeric(start_split[4]),
                                    "print_daily_on", stringsAsFactors=FALSE)
  input_tec_data[2, ] <- data.frame(as.numeric(start_split[1]), as.numeric(start_split[2]),
                                    as.numeric(start_split[3]), (as.numeric(start_split[4]) + 1),
                                    "print_daily_growth_on", stringsAsFactors=FALSE)
  if (output_state) {
    input_tec_data[3, ] <- data.frame(as.numeric(end_split[1]), as.numeric(end_split[2]),
                                      (as.numeric(end_split[3]) - 1), 1,
                                      "output_current_state", stringsAsFactors=FALSE)}
  return(input_tec_data)
}
input_tec_data = IOin_tec_std2(start = "1980 1 1 1", end = "2080 1 1 1", output_state = TRUE)



# Generate header file
input_hdr = IOin_hdr(
  basin = "defs/basin.def",
  hillslope = "defs/hill.def",
  zone = "defs/zone.def",
  soil = "defs/soil_sandyloam.def",
  landuse = "defs/lu_undev.def",
  stratum = "defs/veg_douglasfir.def",
  basestations = "clim/w8_base_spinup"              # New basestation file
)

# Run the model
run_rhessys_single(
  input_rhessys = input_rhessys,
  hdr_files = input_hdr,
  tec_data = input_tec_data
)


# Make sure that a new worldfile was generated in the worldfiles folder. It
# should be named w8TC_dated.world.Y2080M1D1H1 (or a similar if you used a
# different end date)

# ------------------------------------------------------------------------------
# Plot spinup output

# Import results to R
spinup_results <- readin_rhessys_output("out_training/spinup")

# What variables can we look at?
ls(spinup_results$bd)
ls(spinup_results$bdg)

ls(spinup_results$pd)
ls(spinup_results$pdg)

ls(spinup_results$cd)
ls(spinup_results$cdg)



# Lets plot a couple of figures
plot(spinup_results$bdg$plantc)
plot(spinup_results$bdg$lai)
plot(spinup_results$bdg$litrc)
plot(spinup_results$bd$trans)
plot(spinup_results$bd$streamflow)



# ------------------------------------------------------------------------------
# Time for scenarios #1: baseline

# In linux, create a new basestation with a fake dated sequence
vim w8_base_spinup
# Change third to last line to "clim/w8_baseline"
# Press esc
:w w8_base_baseline
:q!

# In Linux, create new dated sequence file
vim w8_spinup.biomass_removal_percent
# Set biomass removal percent at 0.0001
# Press esc
:w w8_baseline.biomass_removal_percent
:q!


# ---------
# Back to R

# Generate rhessys inputs
input_rhessys = IOin_rhessys_input(
  version = "../RHESSys/rhessys7.3",                           # CARB folks need to change this to "../rhessys/rhessys7.2"
  tec_file = "tecfiles/w8TC.tec",
  world_file = "worldfiles/w8TC_dated.world.Y2079M12D31H1.state",      # Change to appropriate date
  world_hdr_prefix = "w8TC",
  flowtable = "flowtables/w8TC.flow",
  start = "1980 1 1 1",
  end = "2030 1 1 1",                                          # You can decide on length of run
  output_folder = "out_training",
  output_prefix = "baseline",                                  # New output name
  commandline_options = c("-g -b -p 1 74 2438 2438 -c 1 74 2438 2438 24381 -climrepeat")     # New flags
)


# Generate tec file: For non-CARB users
input_tec_data = IOin_tec_std(start = "1980 1 1 1",
                              end = "2030 1 1 1",
                              output_state = TRUE)


# Generate tec file: For CARB users
input_tec_data = IOin_tec_std2(start = "1980 1 1 1", end = "2030 1 1 1", output_state = TRUE)


# Generate header file
input_hdr = IOin_hdr(
  basin = "defs/basin.def",
  hillslope = "defs/hill.def",
  zone = "defs/zone.def",
  soil = "defs/soil_sandyloam.def",
  landuse = "defs/lu_undev.def",
  stratum = "defs/veg_douglasfir.def",
  basestations = "clim/w8_base_baseline"                         # Original basestation file
)

# Run the model
run_rhessys_single(
  input_rhessys = input_rhessys,
  hdr_files = input_hdr,
  tec_data = input_tec_data
)



# ------------------------------------------------------------------------------
# Time for scenarios #2: Treatments

# You can do whatever you want here (that is within our capabilities)
# Want to change temperature? -tchange # #

# Want to change do fuel treatments? You will need to make a new base station
# file in Linux as done previously. You can change the magnitude of treatments
# (range 0 to 1 percent). Want to have repeated treatments, set multiple dates
# in the dated sequence file



# Create a new basestation with a fake dated sequence using previous linux steps
# Name new base station file: w8_base_scenario1
# Name new dated sequence file: w8_scenario1.biomass_removal_percent

# You will need to manipulate the arguments in the following function.


# Generate rhessys inputs
input_rhessys = IOin_rhessys_input(
  version = "../RHESSys/rhessys7.3",                           # CARB folks need to change this to "../rhessys/rhessys7.2"
  tec_file = "tecfiles/w8TC.tec",
  world_file = "worldfiles/w8TC_dated.world.Y2079M12D31H1.state",      # Change to appropriate date
  world_hdr_prefix = "w8TC",
  flowtable = "flowtables/w8TC.flow",
  start = "1980 1 1 1",
  end = "2030 1 1 1",                                          # Dates should be the same as baseline
  output_folder = "out_training",
  output_prefix = "scenario1",                                  # New output name
  commandline_options = c("-g -b -p 1 74 2438 2438 -c 1 74 2438 2438 24381 -climrepeat")     # New flags
)


# Generate tec file: For non-CARB users
input_tec_data = IOin_tec_std(start = "1980 1 1 1",
                              end = "2030 1 1 1",
                              output_state = TRUE)


# Generate tec file: For CARB users
input_tec_data = IOin_tec_std2(start = "1980 1 1 1", end = "2030 1 1 1", output_state = TRUE)


# Generate header file
input_hdr = IOin_hdr(
  basin = "defs/basin.def",
  hillslope = "defs/hill.def",
  zone = "defs/zone.def",
  soil = "defs/soil_sandyloam.def",
  landuse = "defs/lu_undev.def",
  stratum = "defs/veg_douglasfir.def",
  basestations = "clim/w8_base_scenario1"                         # Need to make this file in Linux using vim
)

# Run the model
run_rhessys_single(
  input_rhessys = input_rhessys,
  hdr_files = input_hdr,
  tec_data = input_tec_data
)




# ------------------------------------------------------------------------------
# Compare scenarios


# Import results to R
baseline_results <- readin_rhessys_output("out_training/baseline")
scenario1_results <- readin_rhessys_output("out_training/scenario1")


# Compare total carbon and streamflow between scenarios

mean(baseline_results$bd$streamflow)
mean(scenario1_results$bd$streamflow)

mean(baseline_results$bd$plantc)
mean(scenario1_results$bd$plantc)



# ---------------
# Make some plots

install.packages("ggplot2")
install.packages("dplyr")
library(ggplot2)
library(dplyr)


# Plot timeseries
ggplot() +
  geom_line(data = baseline_results$bd, aes(x=date, y=lai)) +
  geom_line(data = scenario1_results$bd, aes(x=date, y=lai))


# Plot streamflow
baseline_results$bd %>% 
  bind_rows(scenario1_results$bd, .id = "scenario") %>% 
  dplyr::select(-date) %>% 
  group_by(wy, scenario) %>% 
  summarise_all(sum) %>% 
  ggplot(data = .) +
  geom_col(aes(x=wy, y=streamflow)) +
  facet_wrap(.~scenario)



