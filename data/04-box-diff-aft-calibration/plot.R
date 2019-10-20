#! /usr/bin/env Rscript

source('../header.R')
load('../03-sensor-calibration/calibrations.RData')

session_for_1a <- get_session('19-octa-nothing-1a.csv')$readings
session_for_2b <- get_session('19-octa-nothing-2b.csv')$readings
session_for_3d <- get_session('19-octa-nothing-3d.csv')$readings
session_for_1a <- subset(session_for_1a, type=='pm2.5')
session_for_2b <- subset(session_for_2b, type=='pm2.5')
session_for_3d <- subset(session_for_3d, type=='pm2.5')

original_1a <- subset(session_for_1a, T)
original_2b <- subset(session_for_2b, T)
original_1a$value_type <- 'original'
original_2b$value_type <- 'original'
original_1a$box <- 'a'
original_2b$box <- 'b'
session_for_1a$value_type <- 'adjusted'
session_for_2b$value_type <- 'adjusted'
session_for_3d$value_type <- 'adjusted'

print('Mapping s1 to s3')
session_for_1a$value <- unlist(Map(
    function(x) to_s3(s1vs3.lm, x),
    session_for_1a$value))
print('Mapping s2 to s3')
session_for_2b$value <- unlist(Map(
    function(x) to_s3(s2vs3.lm, x),
    session_for_2b$value))

# header.R truncates data s.t. the first reading is the first 'non-saturated'
# reading. At that point, all three sessions are 'synced' with t=0.
# However, after the s1_to_s3 and s2_to_s3 mappings, the first readings would
# all deviate from each other. So, resync them (for the plot).
max_consensus <- min(
    max(session_for_1a$value, na.rm=T),
    max(session_for_2b$value, na.rm=T),
    max(session_for_3d$value, na.rm=T))
session_for_1a <- subset(session_for_1a, value <= max_consensus)
session_for_2b <- subset(session_for_2b, value <= max_consensus)
session_for_3d <- subset(session_for_3d, value <= max_consensus)
original_1a$time <- original_1a$time - session_for_1a$time[1]  # also adjust original in parallel
session_for_1a$time <- session_for_1a$time - session_for_1a$time[1]
original_2b$time <- original_2b$time - session_for_2b$time[1]
session_for_2b$time <- session_for_2b$time - session_for_2b$time[1]
session_for_3d$time <- session_for_3d$time - session_for_3d$time[1]

session_for_1a$box <- 'a'
session_for_2b$box <- 'b'
session_for_3d$box <- 'd'
sessions <- rbind(
    session_for_1a, session_for_2b, session_for_3d, original_1a, original_2b)
sessions <- subset(sessions, time <= 30000)

ggplot(sessions) +
    geom_line(mapping=aes(x=time, y=value, colour=box, linetype=value_type)) +
    labs(title='19octa-nothing trials (PM2.5, post calibration-adjustment, set t=0 for first consensus in adjusted readings)')
ggsave('plot.png', width=16, height=9)
