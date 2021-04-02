# Post processing for W8 simulations
#


# remotes::install_github(repo = "RHESSys/RHESSysIOinR")
library(RHESSysIOinR)
library(ggplot2)
library(dplyr)
library(lubridate)
library(tidyr)
library(hydroGOF)


# ---------------------------------------------------------------------
# Import files

# Simulated results
out <- readin_rhessys_output("out_training/calibration_test")

# Observed streamflow for W8
obs_q <- read.csv("../../rhessys_training_2021/data/streamflow/q_hja_w8.csv")


# ---------------------------------------------------------------------
# Process data

# Combine modeled and observed data into a single dataframe

q_out <- out$bd %>% 
  dplyr::select(year, month, day, streamflow) %>% 
  right_join(., 
             dplyr::select(obs_q, year, month, day, DATE, wy, mm), by = c("year", "month", "day")) %>% 
  relocate(streamflow, .before = "mm") %>% 
  rename(q_model = streamflow, q_obs = mm) %>% 
  dplyr::filter(wy>1980, wy<1991)

q_out_long <- q_out %>% 
  pivot_longer(cols = c(q_model, q_obs), names_to = "q_type", values_to = "q")



# ---------------------------------------------------------------------
# Compare streamflow

q_out_long %>% 
  ggplot(data = .) +
  geom_line(aes(x=DATE, y=q, color=q_type, group=q_type))


#Zoom in
q_out_long %>% 
  dplyr::filter(wy %in% c(1981, 1982)) %>% 
  ggplot(data = .) +
  geom_line(aes(x=DATE, y=q, color=q_type, group=q_type))


#Zoom in
q_out_long %>% 
  dplyr::filter(wy %in% c(1983, 1984)) %>% 
  ggplot(data = .) +
  geom_line(aes(x=DATE, y=q, color=q_type, group=q_type))




# ---------------------------------------------------------------------
# Compute objective function
# Kling-Gupta Efficiency


KGE(sim=q_out$q_model, obs=q_out$q_obs, out.type="full")

KGE(sim=q_out$q_model, obs=q_out$q_obs, out.type="single")









