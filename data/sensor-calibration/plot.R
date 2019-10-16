#! /usr/bin/env Rscript

library(tidyverse)

get_trial <- function(trial_name, s1, s2, s3, s4) {
    sensor1 <- read_csv(s1, col_names=F)
    sensor1$sensor <- 's1'
    sensor2 <- read_csv(s2, col_names=F)
    sensor2$sensor <- 's2'
    sensor3 <- read_csv(s3, col_names=F)
    sensor3$sensor <- 's3'
    sensor4 <- read_csv(s4, col_names=F)
    sensor4$sensor <- 's4'
    trial <- rbind(sensor1, sensor2, sensor3, sensor4)
    names(trial) <- c('time', 'type', 'value', 'sensor')

    trial$trial <- trial_name
    trial$time <- as.numeric(as.POSIXct(trial$time, origin='1970-01-01'))
    trial <- subset(trial, type != 'comment')
    trial$value <- as.numeric(trial$value)

    return(trial)
}

time_of_first_desaturation <- function(trial, sat_value) {
    has_saturated <- F
    for (i in seq(1, nrow(trial))) {
        row <- trial[i,]
        val <- row$value

        if (has_saturated & val < sat_value) return(row$time)
        if (val >= sat_value) has_saturated <- T
    }
}

trial1 <- get_trial('13octb',
    '13octb_nothing_1bigbox.csv',
    '13octb_nothing_2bigbox.csv',
    '13octb_nothing_3bigbox.csv',
    '13octb_nothing_4bigbox.csv')
trial2 <- get_trial('14octa',
    '14octa-nothing-1bigbox.csv',
    '14octa-nothing-2bigbox.csv',
    '14octa-nothing-3bigbox.csv',
    '14octa-nothing-4bigbox.csv')
trial3 <- get_trial('14octb',
    '14octb_nothing_1bigbox.csv',
    '14octb_nothing_2bigbox.csv',
    '14octb_nothing_3bigbox.csv',
    '14octb_nothing_4bigbox.csv')
trial4 <- get_trial('15octa',
    '15octa-nothing-1bigbox.csv',
    '15octa-nothing-2bigbox.csv',
    '15octa-nothing-3bigbox.csv',
    '15octa-nothing-4bigbox.csv')

trial1.pm25 <- subset(trial1, type=='pm2.5')
trial2.pm25 <- subset(trial2, type=='pm2.5')
trial3.pm25 <- subset(trial3, type=='pm2.5')
trial4.pm25 <- subset(trial4, type=='pm2.5')
trial1.pm25$time <- trial1.pm25$time - time_of_first_desaturation(trial1.pm25, 999.9)
trial2.pm25$time <- trial2.pm25$time - time_of_first_desaturation(trial2.pm25, 999.9)
trial3.pm25$time <- trial3.pm25$time - time_of_first_desaturation(trial3.pm25, 999.9)
trial4.pm25$time <- trial4.pm25$time - time_of_first_desaturation(trial4.pm25, 999.9)
trials.pm25 <- rbind(trial1.pm25, trial2.pm25, trial3.pm25, trial4.pm25)
trials.pm25 <- subset(trials.pm25, time >= 0 & time <= 20000)

ggplot(trials.pm25) +
    geom_line(mapping=aes(x=time, y=value, colour=sensor, linetype=trial)) +
    scale_linetype_manual(values=c('dashed', 'dotdash', 'solid', 'dotted')) +
    labs('PM2.5 for sensors in the same box') +
    xlab('Time since first report of valid reading per trial (s)')

ggsave('pm25.png', width=16, height=9)

trial1.pm10 <- subset(trial1, type=='pm10')
trial2.pm10 <- subset(trial2, type=='pm10')
trial3.pm10 <- subset(trial3, type=='pm10')
trial4.pm10 <- subset(trial4, type=='pm10')
trial1.pm10$time <- trial1.pm10$time - time_of_first_desaturation(trial1.pm10, 1986.7)
trial2.pm10$time <- trial2.pm10$time - time_of_first_desaturation(trial2.pm10, 1986.7)
trial3.pm10$time <- trial3.pm10$time - time_of_first_desaturation(trial3.pm10, 1986.7)
trial4.pm10$time <- trial4.pm10$time - time_of_first_desaturation(trial4.pm10, 1986.7)
trials.pm10 <- rbind(trial1.pm10, trial2.pm10, trial3.pm10, trial4.pm10)
trials.pm10 <- subset(trials.pm10, time >= 0 & time <= 30000)

ggplot(trials.pm10) +
    geom_line(mapping=aes(x=time, y=value, colour=sensor, linetype=trial)) +
    scale_linetype_manual(values=c('dashed', 'dotdash', 'solid', 'dotted')) +
    labs('PM10 for sensors in the same box') +
    xlab('Time since first report of approx valid reading (1986.7) per trial (s)')

ggsave('pm10.png', width=16, height=9)
