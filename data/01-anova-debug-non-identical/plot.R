#! /usr/bin/env Rscript

library(ggforce)
source('../header.R')

sesh1 <- get_session('10octc-nothing-1a.csv')
sesh2 <- get_session('oct11a-nothing-1a.csv')
sesh3 <- get_session('13octa_nothing_1a.csv')
# Look at PM2.5 readings only
sesh1$pm25only <- subset(sesh1$readings, type=='pm2.5')
sesh2$pm25only <- subset(sesh2$readings, type=='pm2.5')
sesh3$pm25only <- subset(sesh3$readings, type=='pm2.5')
sesh1$pm25only$source <- '10oct'
sesh2$pm25only$source <- '11oct'
sesh3$pm25only$source <- '13oct'
# Adjust time so that t=0 represents the closest reading to 900 (s.t. it is
# still >= 900)
sesh1$pm25only$time <- sesh1$pm25only$time - sesh1$pm25only$time[2]
sesh3$pm25only$time <- sesh3$pm25only$time - sesh3$pm25only$time[2]
a_sesh <- rbind(sesh1$pm25only, sesh2$pm25only, sesh3$pm25only)
a_sesh$box <- 'a'

ggplot(a_sesh) + geom_line(mapping=aes(x=time, y=value, colour=source))

sesh1 <- get_session('10octc-nothing-2b.csv')
sesh2 <- get_session('oct11a-nothing-2b.csv')
sesh3 <- get_session('13octa_nothing_2b.csv')
# Look at PM2.5 readings only
sesh1$pm25only <- subset(sesh1$readings, type=='pm2.5')
sesh2$pm25only <- subset(sesh2$readings, type=='pm2.5')
sesh3$pm25only <- subset(sesh3$readings, type=='pm2.5')
sesh1$pm25only$source <- '10oct'
sesh2$pm25only$source <- '11oct'
sesh3$pm25only$source <- '13oct'
sesh2$pm25only$time <- sesh2$pm25only$time - sesh2$pm25only$time[2]
b_sesh <- rbind(sesh1$pm25only, sesh2$pm25only, sesh3$pm25only)
b_sesh$box <- 'b'

sesh1 <- get_session('10octc-nothing-4d.csv')
sesh2 <- get_session('oct11a-nothing-4d.csv')
sesh3 <- get_session('13octa_nothing_4d.csv')
# Look at PM2.5 readings only
sesh1$pm25only <- subset(sesh1$readings, type=='pm2.5')
sesh2$pm25only <- subset(sesh2$readings, type=='pm2.5')
sesh3$pm25only <- subset(sesh3$readings, type=='pm2.5')
sesh1$pm25only$source <- '10oct'
sesh2$pm25only$source <- '11oct'
sesh3$pm25only$source <- '13oct'
sesh1$pm25only$time <- sesh1$pm25only$time - sesh1$pm25only$time[4]
sesh2$pm25only$time <- sesh2$pm25only$time - sesh2$pm25only$time[3]
sesh3$pm25only$time <- sesh3$pm25only$time - sesh3$pm25only$time[4]
d_sesh <- rbind(sesh1$pm25only, sesh2$pm25only, sesh3$pm25only)
d_sesh$box <- 'd'

all <- rbind(a_sesh, b_sesh, d_sesh)
# Observation: tends to zero after t = 4000s
all <- subset(all, time <= 40000)

ggplot(all) +
    geom_line(mapping=aes(x=time, y=value, colour=box, linetype=source)) +
    labs(title='PM2.5 retention for boxes a, b, d',
          subbtitle='without replacing box-rubber sheet tapes') +
    xlab('Time (s)') + ylab('PM2.5')
ggsave('plot.png', width=16, height=9)

ggplot(all) +
    geom_line(mapping=aes(x=time, y=value, colour=box, linetype=source)) +
    labs(title='PM2.5 retention for boxes a, b, d',
          subbtitle='without replacing box-rubber sheet tapes') +
    xlab('Time (s)') + ylab('PM2.5') +
    facet_zoom(x = time > -100 & time < 3600, zoom.size=3)
ggsave('plot-zoom.png', width=16, height=9)
