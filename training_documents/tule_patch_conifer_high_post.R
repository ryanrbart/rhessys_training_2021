# Post processing for SF Tule River
# Patch: Conifer high


# remotes::install_github(repo = "RHESSys/RHESSysIOinR")
library(RHESSysIOinR)
library(ggplot2)


# ---------------------------------------------------------------------
# Import results to R

out <- readin_rhessys_output("ws_tule/out/patch_conifer_high")


# What variables can be plotted?

ls(out)

ls(out$bd)
ls(out$bdg)

ls(out$pd)
ls(out$pdg)

ls(out$cd)
ls(out$cdg)



# ---------------------------------------------------------------------
# Make plots

# Plot timeseries by canopy
ggplot() +
  geom_line(data = out$bd, aes(x=date, y=plantc))



# Plot timeseries by canopy
ggplot() +
  geom_line(data = out$cdg, aes(x=date, y=plantc, group = stratumID))

ggplot() +
  geom_line(data = out$cd, aes(x=date, y=height, group = stratumID))


