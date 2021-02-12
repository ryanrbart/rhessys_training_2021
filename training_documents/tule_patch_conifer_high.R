# Simulationfor SF Tule River
# Patch: Conifer high


# remotes::install_github(repo = "RHESSys/RHESSysIOinR", ref = "develop")
library(RHESSysIOinR)


# ---------------------------------------------------------------------
# Model inputs


input_rhessys = IOin_rhessys_input(
  version = "ws_tule/bin/rhessys7.3",
  tec_file = "ws_tule/tecfiles/patch_conifer_high.tec",
  world_file = "ws_tule/worldfiles/patch_conifer_high.world",
  world_hdr_prefix = "patch_conifer_high",
  flowtable = "ws_tule/flowtables/patch_conifer_high.flow",
  start = "2000 10 1 1",
  end = "2100 09 30 1",
  output_folder = "ws_tule/out",
  output_prefix = "patch_conifer_high",
  commandline_options = c("-b -g -c -vmort_off -asciigrid -climrepeat")
)


input_tec_data = IOin_tec_std(start = "2000 10 1 1",
                              end = "2100 9 30 1",
                              output_state = TRUE)


input_hdr = IOin_hdr(
  basin = "ws_tule/defs/basin_tule.def",
  hillslope = "ws_tule/defs/hill_tule.def",
  zone = "ws_tule/defs/zone_tule.def",
  soil = "ws_tule/defs/patch_tule.def",
  landuse = "ws_tule/defs/lu_tule.def",
  stratum =  c("ws_tule/defs/veg_conifer_tule.def", "ws_tule/defs/veg_understory_tule.def",
               "ws_tule/defs/veg_shrub_tule.def", "ws_tule/defs/veg_nonveg_tule.def"),
  basestations = "ws_tule/clim/tule_maca_gridmet_1980_2016.base"
)


input_def_pars = IOin_def_pars_simple(
  # Hill level parameters
  list("ws_tule/defs/hill_tule.def.def", "gw_loss_coeff", (0.140574399)),
  # -----
  # Patch level parameters
  list("ws_tule/defs/patch_tule.def", "m", (4.580245)),
  list("ws_tule/defs/patch_tule.def", "Ksat_0", (33.93113)),
  list("ws_tule/defs/patch_tule.def", "m_z", (15.88254)),
  list("ws_tule/defs/patch_tule.def", "pore_size_index", (0.3395034)),
  list("ws_tule/defs/patch_tule.def", "psi_air_entry", (1.992954)),
  list("ws_tule/defs/patch_tule.def", "sat_to_gw_coeff",(0.367078691)),
  list("ws_tule/defs/patch_tule.def", "soil_depth", 2.0188023),
  # -----
  # Conifer parameters (ID 42)
  list("ws_tule/defs/veg_conifer_tule.def", "epc.alloc_frootc_leafc", 1.2),
  list("ws_tule/defs/veg_conifer_tule.def", "epc.alloc_crootc_stemc", 0.328037407),
  list("ws_tule/defs/veg_conifer_tule.def", "epc.alloc_stemc_leafc", 0.4),
  list("ws_tule/defs/veg_conifer_tule.def", "epc.alloc_livewoodc_woodc", 0.52048545),
  list("ws_tule/defs/veg_conifer_tule.def", "epc.leaf_turnover", 0.26129135),
  list("ws_tule/defs/veg_conifer_tule.def", "epc.livewood_turnover", 0.490868272),
  list("ws_tule/defs/veg_conifer_tule.def", "epc.branch_turnover", 0.00179873),
  list("ws_tule/defs/veg_conifer_tule.def", "epc.height_to_stem_coef", 1.2),
  list("ws_tule/defs/veg_conifer_tule.def", "epc.resprout_leaf_carbon", 0.02),
  # -----
  # Understory low parameters (ID 50)
  list("ws_tule/defs/veg_understory_tule.def", "epc.alloc_frootc_leafc", 1.2),
  list("ws_tule/defs/veg_understory_tule.def", "epc.alloc_crootc_stemc", 0.355894604),
  list("ws_tule/defs/veg_understory_tule.def", "epc.alloc_stemc_leafc", 0.15),
  list("ws_tule/defs/veg_understory_tule.def", "epc.alloc_livewoodc_woodc", 0.906725388),
  list("ws_tule/defs/veg_understory_tule.def", "epc.leaf_turnover", 0.165855171),
  list("ws_tule/defs/veg_understory_tule.def", "epc.livewood_turnover", 0.192506467),
  list("ws_tule/defs/veg_understory_tule.def", "epc.branch_turnover", 0.017954816),
  list("ws_tule/defs/veg_understory_tule.def", "epc.height_to_stem_coef", 0.25),
  list("ws_tule/defs/veg_understory_tule.def", "epc.resprout_leaf_carbon", 0.02),
)



run_rhessys_single(
  input_rhessys = input_rhessys,
  hdr_files = input_hdr,
  tec_data = input_tec_data,
  def_pars = input_def_pars
)

