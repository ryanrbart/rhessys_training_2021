# Simulation for W8


# remotes::install_github(repo = "RHESSys/RHESSysIOinR")
library(RHESSysIOinR)


#setwd("C:/Users/rbart3/work_dir/rhessys_training/rhessys/Testing")


# ---------------------------------------------------------------------
# Model inputs


# Generate rhessys inputs
input_rhessys = IOin_rhessys_input(
  version = "../rhessys/rhessys7.3",
  tec_file = "tecfiles/w8TC.tec",
  world_file = "worldfiles/w8TC.world",
  world_hdr_prefix = "w8TC",
  flowtable = "flowtables/w8TC.flow",
  start = "1980 10 1 1",
  end = "1990 10 1 1",
  output_folder = "out_training",
  output_prefix = "calibration_test",
  commandline_options = c("-b -climrepeat")
)


# Generate tec file
input_tec_data = IOin_tec_std(start = "1980 10 1 1",
                              end = "1990 10 1 1",
                              output_state = FALSE)



# Generate header file
input_hdr = IOin_hdr(
  basin = "defs/basin.def",
  hillslope = "defs/hill.def",
  zone = "defs/zone.def",
  soil = "defs/soil_sandyloam.def",
  landuse = "defs/lu_undev.def",
  stratum = "defs/veg_douglasfir.def",
  basestations = "clim/w8_base"
)


# input_def_pars = IOin_def_pars_simple(
#   # Hill level parameters
#   list("ws_tule/defs/hill_tule.def", "gw_loss_coeff", 0.140574399),
#   # -----
#   # Patch level parameters
#   list("ws_tule/defs/patch_tule.def", "m", 4.580245),
#   list("ws_tule/defs/patch_tule.def", "Ksat_0", 33.93113),
#   list("ws_tule/defs/patch_tule.def", "pore_size_index", 0.3395034),
#   list("ws_tule/defs/patch_tule.def", "psi_air_entry", 1.992954),
#   list("ws_tule/defs/patch_tule.def", "sat_to_gw_coeff",0.367078691),
#   list("ws_tule/defs/patch_tule.def", "soil_depth", 2.0188023)
# )




run_rhessys_single(
  input_rhessys = input_rhessys,
  hdr_files = input_hdr,
  tec_data = input_tec_data,
  #def_pars = input_def_pars,
  output_filter = NULL
)






