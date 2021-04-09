# Calibration of W8


# remotes::install_github(repo = "RHESSys/RHESSysIOinR")
library(RHESSysIOinR)


setwd("C:/Users/rbart3/work_dir/rhessys_training/rhessys/Testing")

# ---------------------------------------------------------------------
# Model inputs


# Generate rhessys inputs
input_rhessys = IOin_rhessys_input(
  version = "../rhessys/rhessys7.2",
  tec_file = "tecfiles/w8TC.tec",
  world_file = "worldfiles/w8TC.world",
  world_hdr_prefix = "w8TC",
  flowtable = "flowtables/w8TC.flow",
  start = "1980 10 1 1",
  end = "1990 10 1 1",
  output_folder = "out_training",
  output_prefix = "calibration_test",
  commandline_options = c("-b -g -p 1 74 2438 2438 -c 1 74 2438 2438 24381 -climrepeat")
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


# run_rhessys_single(
#   input_rhessys = input_rhessys,
#   hdr_files = input_hdr,
#   tec_data = input_tec_data,
#   #def_pars = input_def_pars,
#   output_method = "r",
#   output_variables = output_variables,
#   output_filter = NULL
# )



# --------------------------


# Generate parameter sets
n = 20
pars = list(
  list("defs/hill.def", "gw_loss_coeff", runif(n, 0.01, 0.7)),
  list("defs/soil_sandyloam.def", "Ksat_0", runif(n, 1, 100)),
  list("defs/soil_sandyloam.def", "m", runif(n, 0.1, 150)),
  list("defs/soil_sandyloam.def", "pore_size_index", runif(n, 0.05, 10)),
  list("defs/soil_sandyloam.def", "psi_air_entry", runif(n, 0.05, 10)),
  list("defs/soil_sandyloam.def", "sat_to_gw_coeff", runif(n, 0.001, 0.5)),
  list("defs/soil_sandyloam.def", "soil_depth", runif(n, 0.2, 5))
)



run_rhessys_multi(
  input_rhessys = input_rhessys,
  hdr_files = input_hdr,
  tec_data = input_tec_data,
  def_pars = pars,
  parallel = FALSE,
  output_filter = NULL
)







