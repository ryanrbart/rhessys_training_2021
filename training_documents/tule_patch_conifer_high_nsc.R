# Simulationfor SF Tule River
# Patch: Conifer high


# remotes::install_github(repo = "RHESSys/RHESSysIOinR")
library(RHESSysIOinR)


# ---------------------------------------------------------------------
# Model inputs


input_rhessys = IOin_rhessys_input(
  version = "ws_tule/bin/rhessys7.2",
  tec_file = "ws_tule/tecfiles/patch_conifer_high.tec",
  world_file = "ws_tule/worldfiles/patch_conifer_high.world",
  world_hdr_prefix = "patch_conifer_high",
  flowtable = "ws_tule/flowtables/patch_conifer_high.flow",
  start = "1980 10 1 1",
  end = "2060 09 30 1",
  output_folder = "ws_tule/out",
  output_prefix = "patch_conifer_high_nsc",
  commandline_options = c("-b -p -c -g -climrepeat")
)


input_tec_data = IOin_tec_std(start = "1980 10 1 1",
                              end = "2050 9 30 1",
                              output_state = TRUE)


input_hdr = IOin_hdr(
  basin = "ws_tule/defs/basin_tule.def",
  hillslope = "ws_tule/defs/hill_tule.def",
  zone = "ws_tule/defs/zone_tule.def",
  soil = "ws_tule/defs/patch_tule.def",
  landuse = "ws_tule/defs/lu_tule.def",
  stratum =  c("ws_tule/defs/veg_pine_2853.def", "ws_tule/defs/veg_pine_2853_understory.def",
               "ws_tule/defs/veg_shrub_tule.def", "ws_tule/defs/veg_nonveg_tule.def"),
  basestations = "ws_tule/clim/tule_pixel_8_1980_2016_drought.base"
)


input_def_pars = IOin_def_pars_simple(
  # Hill level parameters
  list("ws_tule/defs/hill_tule.def", "gw_loss_coeff", 0.140574399),
  # -----
  # Patch level parameters
  list("ws_tule/defs/patch_tule.def", "m", 4.580245),
  list("ws_tule/defs/patch_tule.def", "Ksat_0", 33.93113),
  list("ws_tule/defs/patch_tule.def", "m_z", 15.88254),
  list("ws_tule/defs/patch_tule.def", "pore_size_index", 0.3395034),
  list("ws_tule/defs/patch_tule.def", "psi_air_entry", 1.992954),
  list("ws_tule/defs/patch_tule.def", "sat_to_gw_coeff",0.367078691),
  list("ws_tule/defs/patch_tule.def", "soil_depth", 2.0188023)

)


run_rhessys_single(
  input_rhessys = input_rhessys,
  hdr_files = input_hdr,
  tec_data = input_tec_data
  #def_pars = input_def_pars
)







