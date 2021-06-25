# Example script for running RHESSys


# The pathways for your files will have to be substituted below. The parameters
# designated assigned to input_def_pars should be a decent subsurface
# combination to start parameterizing vegetation

# Reminder: The below code outputs patch and canopy variables (-p & -c flags),
# which is fine for patch or hillslope scales. Remove flags for watershed-scale
# runs.


library(RHESSysIOinR)

# --------------------------------------------------------------------------
# --------------------------------------------------------------------------
# --------------------------------------------------------------------------
# Spinup


input_rhessys = IOin_rhessys_input(
  version = "ws/bin/rhessys7.2",
  tec_file = "ws/sagehen/tecfiles/sagehen_tower_patch.tec",
  world_file = "ws/sagehen/worldfiles/sagehen_tower_patch.world",
  world_hdr_prefix = "sagehen_tower_patch",
  flowtable = "ws/sagehen/flowtables/sagehen_tower_patch.flow",
  start = "1950 10 1 1",
  end = "2150 10 1 1",
  output_folder = "ws/sagehen/out",
  output_prefix = "sagehen_tower_patch_spinup",
  commandline_options = c("-g -asciigrid -b -p -c")
)


input_tec_data = IOin_tec_std(start = "1950 10 1 1",
                              end = "2050 10 1 1",
                              output_state = TRUE)


input_hdr = IOin_hdr(
  basin = "ws/sagehen/defs/basin.def",
  hillslope = "ws/sagehen/defs/hill.def",
  zone = "ws/sagehen/defs/zone.def",
  soil = "ws/sagehen/defs/patch.def",
  landuse = "ws/sagehen/defs/lu.def",
  stratum =  c("ws/sagehen/defs/veg_pine_2853.def", "ws/sagehen/defs/veg_pine_2853_understory.def",
               "ws/sagehen/defs/veg_shrub.def", "ws/sagehen/defs/veg_nonveg.def"),
  basestations = "ws/sagehen/clim/sagehen_livneh_1950_2589.base"
)


input_def_pars = IOin_def_pars_simple(
  # Hill level parameters
  list("ws/sagehen/defs/hill.def", "gw_loss_coeff", 0.140574399),
  # -----
  # Patch level parameters
  list("ws/sagehen/defs/patch.def", "m", 4.580245),
  list("ws/sagehen/defs/patch.def", "Ksat_0", 33.93113),
  list("ws/sagehen/defs/patch.def", "m_z", 15.88254),
  list("ws/sagehen/defs/patch.def", "pore_size_index", 0.3395034),
  list("ws/sagehen/defs/patch.def", "psi_air_entry", 1.992954),
  list("ws/sagehen/defs/patch.def", "sat_to_gw_coeff",0.367078691),
  list("ws/sagehen/defs/patch.def", "soil_depth", 2.0188023)
  
)


# --------------------------------------------------------------------------
# Run model

run_rhessys_single(
  input_rhessys = input_rhessys,
  hdr_files = input_hdr,
  tec_data = input_tec_data,
  def_pars = input_def_pars
)


