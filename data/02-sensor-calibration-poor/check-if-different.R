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
trials <- rbind(trial1, trial2, trial3, trial4)
