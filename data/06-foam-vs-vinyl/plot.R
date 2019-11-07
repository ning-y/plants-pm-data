#! /usr/bin/env Rscript

suppressMessages(library(tidyverse))

SYSTIME <- Sys.time()
DIFFTIME_ZERO <- difftime(SYSTIME, SYSTIME)

foam <- read_csv('15octa-nothing-4bigbox.csv', col_names=F)
names(foam) <- c('time', 'type', 'value')
foam <- subset(foam, type != 'comment')
foam$value <- as.numeric(foam$value)
foam$time <- as.numeric(as.POSIXct(foam$time, origin='1970-01-01'))
foam$seal <- 'Polyurethane Foam'

vinyl <- read_csv('16octc-nothing-4bigbox.csv', col_names=F)
names(vinyl) <- c('time', 'type', 'value')
vinyl <- subset(vinyl, type != 'comment')
vinyl$value <- as.numeric(vinyl$value)
vinyl$time <- as.numeric(as.POSIXct(vinyl$time, origin='1970-01-01'))
vinyl$seal <- 'Vinyl Tape'

foam.pm25 <- subset(foam, type == 'pm2.5')
foam.pm10 <- subset(foam, type == 'pm10')
vinyl.pm25 <- subset(vinyl, type == 'pm2.5')
vinyl.pm10 <- subset(vinyl, type == 'pm10')

trim_saturated <- function(data, sat_point) {
    last_saturated_reading_i <- last(which(data$value >= sat_point)[-1])
    data <- subset(data, time >= data[last_saturated_reading_i,]$time)
    data$time <- data$time - data[1,]$time
    return(data)
}

foam.pm25 <- trim_saturated(foam.pm25, 999.9)
vinyl.pm25 <- trim_saturated(vinyl.pm25, 999.9)
pm25.data <- rbind(foam.pm25, vinyl.pm25)
pm25.data <- subset(pm25.data, time <= 15000)

ggplot(pm25.data) +
    geom_line(mapping=aes(x=time, y=value, colour=seal)) +
    xlab("Time (s)") +
    ylab(expression("PM"[2.5]*" ("*mu*"g m"^-3*")"))
ggsave('airtight-seal-method-comparison-pm25.png', width=4, height=7)

foam.pm10 <- trim_saturated(foam.pm10, 999.9)
vinyl.pm10 <- trim_saturated(vinyl.pm10, 999.9)
pm10.data <- rbind(foam.pm10, vinyl.pm10)
pm10.data <- subset(pm10.data, time <= 15000)

ggplot(pm10.data) +
    geom_line(mapping=aes(x=time, y=value, colour=seal)) +
    xlab("Time (s)") +
    ylab(expression("PM"[10]*" ("*mu*"g m"^-3*")"))
ggsave('airtight-seal-method-comparison-pm10.png', width=4, height=7)

labeller <- c('pm2.5' = expression("PM"[2.5]), 'pm10' = expression("PM"[10]))
ggplot(rbind(pm25.data, pm10.data)) +
    geom_line(mapping=aes(x=time, y=value, colour=seal)) +
    xlab("Time (s)") +
    ylab(expression("PM Reading ("*mu*"g m"^-3*")")) +
    guides(colour=guide_legend(title='Box-Sheet Sealant')) +
    facet_grid(cols=vars(type), labeller=labeller(type=c(
        'pm2.5' = "PM2.5", 'pm10' = "PM10")))
ggsave('airtight-seal-method-comparison.png', width=16, height=9)
