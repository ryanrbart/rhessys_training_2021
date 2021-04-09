# Post processing for W8 simulations
#


# remotes::install_github(repo = "RHESSys/RHESSysIOinR")
library(RHESSysIOinR)
library(ggplot2)
library(dplyr)
library(lubridate)
library(tidyr)
library(hydroGOF)
library(hydroTSM)


# ---------------------------------------------------------------------
# Import files

# Simulated results
out1 <- readin_rhessys_output("out_training/calibration_test_run1")
out2 <- readin_rhessys_output("out_training/calibration_test_run2")
out3 <- readin_rhessys_output("out_training/calibration_test_run3")
out4 <- readin_rhessys_output("out_training/calibration_test_run4")
out5 <- readin_rhessys_output("out_training/calibration_test_run5")
out6 <- readin_rhessys_output("out_training/calibration_test_run6")
out7 <- readin_rhessys_output("out_training/calibration_test_run7")
out8 <- readin_rhessys_output("out_training/calibration_test_run8")
out9 <- readin_rhessys_output("out_training/calibration_test_run9")
out10 <- readin_rhessys_output("out_training/calibration_test_run10")

# Observed streamflow for W8
obs_q <- read.csv("../../rhessys_training_2021/data/streamflow/q_hja_w8.csv")

# Get parameter file
parameters <- bind_cols(tibble(pars[[1]][[3]]),
                        tibble(pars[[2]][[3]]),
                        tibble(pars[[3]][[3]]),
                        tibble(pars[[4]][[3]]),
                        tibble(pars[[5]][[3]]),
                        tibble(pars[[6]][[3]]),
                        tibble(pars[[7]][[3]])
)
colnames(parameters) <-  c(pars[[1]][[2]],pars[[2]][[2]],pars[[3]][[2]],pars[[4]][[2]],
                           pars[[5]][[2]],pars[[6]][[2]],pars[[7]][[2]])


# ---------------------------------------------------------------------
# Process data

out <- bind_cols(
  dplyr::select(out1$bd, year, month, day, streamflow1 = streamflow),
  dplyr::select(out2$bd, streamflow2 = streamflow),
  dplyr::select(out3$bd, streamflow3 = streamflow),
  dplyr::select(out4$bd, streamflow4 = streamflow),
  dplyr::select(out5$bd, streamflow5 = streamflow),
  dplyr::select(out6$bd, streamflow6 = streamflow),
  dplyr::select(out7$bd, streamflow7 = streamflow),
  dplyr::select(out8$bd, streamflow8 = streamflow),
  dplyr::select(out9$bd, streamflow9 = streamflow),
  dplyr::select(out10$bd, streamflow10 = streamflow))


# Combine modeled and observed data into a single dataframe
q_out <- out %>% 
  #dplyr::select(year, month, day, streamflow) %>% 
  right_join(., 
             dplyr::select(obs_q, year, month, day, DATE, wy, mm), by = c("year", "month", "day")) %>% 
  relocate(DATE, wy, .after = "day") %>% 
  rename(q_obs = mm) %>% 
  dplyr::filter(wy>1980, wy<1991)

q_out_long <- q_out %>% 
  pivot_longer(cols = -c(year, month, day, DATE, wy, q_obs), names_to = "q_type", values_to = "q") %>% 
  group_by(q_type) %>% 
  mutate(fdc_model = fdc(q, plot=FALSE),
         fdc_obs = fdc(q_obs, plot=FALSE)) %>% 
  ungroup()


# ---
out <- bind_cols(
  dplyr::select(out1$bd, year, month, day, nppcum1 = nppcum),
  dplyr::select(out2$bd, nppcum2 = nppcum),
  dplyr::select(out3$bd, nppcum3 = nppcum),
  dplyr::select(out4$bd, nppcum4 = nppcum),
  dplyr::select(out5$bd, nppcum5 = nppcum),
  dplyr::select(out6$bd, nppcum6 = nppcum),
  dplyr::select(out7$bd, nppcum7 = nppcum),
  dplyr::select(out8$bd, nppcum8 = nppcum),
  dplyr::select(out9$bd, nppcum9 = nppcum),
  dplyr::select(out10$bd, nppcum10 = nppcum))


# Combine modeled and observed data into a single dataframe
nppcum_out <- out %>% 
  #dplyr::select(year, month, day, streamflow) %>% 
  right_join(., 
             dplyr::select(obs_q, year, month, day, DATE, wy), by = c("year", "month", "day")) %>% 
  relocate(DATE, wy, .after = "day") %>% 
  dplyr::filter(wy>1980, wy<1991)

nppcum_out_long <- nppcum_out %>% 
  pivot_longer(cols = -c(year, month, day, DATE, wy), names_to = "nppcum_type", values_to = "nppcum")


# ---------------------------------------------------------------------
# Plot streamflow

#Zoom in
q_out_long %>% 
  ggplot(data = .) +
  geom_line(aes(x=DATE, y=q, group=q_type), color="blue") +
  geom_line(aes(x=DATE, y=q_obs, group=q_type), color="black")


#Zoom in
q_out_long %>% 
  dplyr::filter(wy %in% c(1983)) %>% 
  ggplot(data = .) +
  geom_line(aes(x=DATE, y=q, group=q_type), color="blue") +
  geom_line(aes(x=DATE, y=q_obs, group=q_type), color="black")


#Zoom in
q_out_long %>% 
  dplyr::filter(wy %in% c(1984)) %>% 
  ggplot(data = .) +
  geom_line(aes(x=DATE, y=q, group=q_type), color="blue") +
  geom_line(aes(x=DATE, y=q_obs, group=q_type), color="black")


# ----
# Plot flow duration curve (fdc)
q_out_long %>% 
  dplyr::filter(q_type %in% c("streamflow1")) %>% 
  ggplot(data=.) +
  geom_point(aes(x=fdc_model, y=q),color="red") +
  geom_point(aes(x=fdc_obs, y=q_obs),color="black") +
  scale_y_log10()




# ---------------------------------------------------------------------
# Compute objective function
# Kling-Gupta Efficiency


parameters$KGE <- c(KGE(sim=q_out$streamflow1, obs=q_out$q_obs, out.type="single"),
                    KGE(sim=q_out$streamflow2, obs=q_out$q_obs, out.type="single"),
                    KGE(sim=q_out$streamflow3, obs=q_out$q_obs, out.type="single"),
                    KGE(sim=q_out$streamflow4, obs=q_out$q_obs, out.type="single"),
                    KGE(sim=q_out$streamflow5, obs=q_out$q_obs, out.type="single"),
                    KGE(sim=q_out$streamflow6, obs=q_out$q_obs, out.type="single"),
                    KGE(sim=q_out$streamflow7, obs=q_out$q_obs, out.type="single"),
                    KGE(sim=q_out$streamflow8, obs=q_out$q_obs, out.type="single"),
                    KGE(sim=q_out$streamflow9, obs=q_out$q_obs, out.type="single"),
                    KGE(sim=q_out$streamflow10, obs=q_out$q_obs, out.type="single"))


# Dotty plots!!!!
parameters %>% 
  pivot_longer(cols = -c("KGE"), names_to="parm", values_to="parm_value") %>% 
  ggplot(data = .) +
  geom_point(aes(x=parm_value, y=KGE)) +
  facet_wrap(.~parm, scales = "free")  



# ---------------------------------------------------------------------
# Plot nppcum

#Zoom in
nppcum_out_long %>% 
  ggplot(data = .) +
  geom_line(aes(x=DATE, y=nppcum, group=nppcum_type))









