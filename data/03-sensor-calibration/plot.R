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

trial <- get_trial('16octc',
    '16octc-nothing-1bigbox.csv',
    '16octc-nothing-2bigbox.csv',
    '16octc-nothing-3bigbox.csv',
    '16octc-nothing-4bigbox.csv')

trial.pm25 <- subset(trial, type=='pm2.5')
trial.pm25$time <- trial.pm25$time - time_of_first_desaturation(trial.pm25, 999.9)
trial.pm25 <- subset(trial.pm25, time >= -660 & time <= 10000)
ggplot(trial.pm25) +
    geom_line(mapping=aes(x=time, y=value, colour=sensor)) +
    ylab('PM2.5') + xlab('Time (s)')
ggsave('pm25.png', width=16, height=9)

trial.pm10 <- subset(trial, type=='pm10')
trial.pm10$time <- trial.pm10$time - time_of_first_desaturation(trial.pm10, 1999.9)
trial.pm10 <- subset(trial.pm10, time >= -780 & time <= 10000)
ggplot(trial.pm10) +
    geom_line(mapping=aes(x=time, y=value, colour=sensor)) +
    ylab('PM10') + xlab('Time (s)')
ggsave('pm10.png', width=16, height=9)

### Make a pretty plot for our report: ###
get_trial <- function(trial_name, s1, s2, s3) {
    sensor1 <- read_csv(s1, col_names=F)
    sensor1$Sensor <- 'Sensor 1'
    sensor2 <- read_csv(s2, col_names=F)
    sensor2$Sensor <- 'Sensor 2'
    sensor3 <- read_csv(s3, col_names=F)
    sensor3$Sensor <- 'Sensor 3'
    trial <- rbind(sensor1, sensor2, sensor3)
    names(trial) <- c('time', 'type', 'value', 'Sensor')

    trial$trial <- trial_name
    trial$time <- as.numeric(as.POSIXct(trial$time, origin='1970-01-01'))
    trial <- subset(trial, type != 'comment')
    trial$value <- as.numeric(trial$value)

    return(trial)
}

trial <- get_trial('16octc',
    '16octc-nothing-1bigbox.csv',
    '16octc-nothing-2bigbox.csv',
    '16octc-nothing-3bigbox.csv')
trial <- subset(trial, type=='pm2.5')
trial$time <- trial$time - time_of_first_desaturation(trial, 999.9)
trial <- subset(trial, time >= -660 & time <= 10000)
ggplot(trial) +
    geom_line(mapping=aes(x=time, y=value, colour=Sensor)) +
    ylab(expression("PM"[2.5]*" ("*mu*"g/m"^-3*")")) + xlab('Time (s)')
ggsave('sensor-calibration-3.png', width=16, height=7)
