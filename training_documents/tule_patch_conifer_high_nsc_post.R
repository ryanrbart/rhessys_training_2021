# Post processing for SF Tule River
# Patch: Conifer high


# remotes::install_github(repo = "RHESSys/RHESSysIOinR")
library(RHESSysIOinR)
library(ggplot2)
library(dplyr)
library(lubridate)


# ---------------------------------------------------------------------
# Import results to R

out <- readin_rhessys_output("ws_tule/out/patch_conifer_high_nsc")


# Plot height by canopy
out$cd %>% 
  mutate(stratumID = as.factor(stratumID)) %>% 
  ggplot(data = .) +
  geom_line(aes(x=date, y=height, group = stratumID, color = stratumID))


# Plot lai by canopy
out$cd %>% 
  mutate(stratumID = as.factor(stratumID)) %>% 
  ggplot(data = .) +
  geom_line(aes(x=date, y=lai, group = stratumID, color = stratumID))


# Plot leafc by canopy
out$cdg %>% 
  mutate(stratumID = as.factor(stratumID)) %>% 
  ggplot(data = .) +
  geom_line(aes(x=date, y=leafc, group = stratumID, color = stratumID))


# Plot plantc by canopy
out$cdg %>% 
  mutate(stratumID = as.factor(stratumID)) %>% 
  ggplot(data = .) +
  geom_line(aes(x=date, y=plantc, group = stratumID, color = stratumID))


# Plot cpool by canopy
out$cdg %>% 
  mutate(stratumID = as.factor(stratumID)) %>% 
  ggplot(data = .) +
  geom_line(aes(x=date, y=cpool, group = stratumID, color = stratumID))


# Plot psn_to_cpool by canopy
out$cdg %>% 
  mutate(stratumID = as.factor(stratumID)) %>% 
  ggplot(data = .) +
  geom_line(aes(x=date, y=psn_to_cpool, group = stratumID, color = stratumID))



