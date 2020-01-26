library(tidyverse)
x <- read.csv('Documents/Uni/Semester 2/Stochastic modelling/different miners bitcoin network miner centralisation Centralisation over time and optimal miner strategy-table.csv', skip = 6)
colnames(x) <- c("run", "min_price_prediction", "initial_BTC_price", "num_risk_averse_miners", "max_price_prediction", "initial_cost_to_mine", "BTC_reward_per_block", "num_risk_taking_miners", "months", "count_risk_averse", "count_risk_taking", "current_era_reward")
clean <- x[,c(1,2,3,4,5,6,8,9,10,11,12)]
