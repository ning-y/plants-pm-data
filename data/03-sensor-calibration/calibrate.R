#! /usr/bin/env Rscript

suppressMessages(library(tidyverse))

SYSTIME <- Sys.time()
DIFFTIME_ZERO <- difftime(SYSTIME, SYSTIME)

get_paired_readings <- function(s1, fn1, s2, fn2, filter_by='pm2.5', tolerance=5) {
    #' s1, s2 are sensor names. fn1, fn2 are corresponding CSV filenames for
    #' those sensor readings *in the same trial*. filter_by is 'pm2.5' or 'pm10'.
    #' Tolerance is the threshold in seconds between readings of s1/s2 in which
    #' they count as measurement pairs at the same point in time.

    data1 <- suppressMessages(read_csv(fn1, col_names=F))
    data2 <- suppressMessages(read_csv(fn2, col_names=F))
    names(data1) <- c('time', 'type', 'value')
    names(data2) <- c('time', 'type', 'value')
    data1 <- subset(data1, type == filter_by)
    data2 <- subset(data2, type == filter_by)
    data1$value <- as.numeric(data1$value)
    data2$value <- as.numeric(data2$value)
    data1$time <- as.numeric(as.POSIXct(data1$time, origin='1970-01-01'))
    data2$time <- as.numeric(as.POSIXct(data2$time, origin='1970-01-01'))

    pairwise <- tibble(time=double(), s1=double(), s2=double())
    for (i in seq(1, nrow(data1))) {
        s1row <- data1[i,]
        s2row <- subset(data2, abs(time-s1row$time) <= tolerance)
        if (nrow(s2row) == 0) next
        pairwise[i,] <- c(s1row$time, s1row$value, s2row$value)
    }

    pairwise <- na.omit(pairwise)
    omitted <- i - nrow(pairwise)
    if (omitted > 0) {
        warnings(paste(c(omitted, ' rows omitted.')))
    }

    ### Trim values before PM2.5/PM10 is in range. ###
    threshold <- ifelse(filter_by=='pm2.5', 999.9, 1999.9)
    saturated <- F
    remove_up_to <- 0
    for (i in seq(1, nrow(pairwise))) {
        row <- pairwise[i,]
        if (row$s1 >= threshold & row$s2 >= threshold) saturated <- T
        if (saturated & (row$s1 < threshold | row$s2 < threshold)) break
    }
    # Let time at first non-max reading be 0.
    time_offset <- pairwise[i,]$time
    pairwise$time <- pairwise$time - time_offset
    # Trim off rows before PM2.5 is in range.
    pairwise <- subset(pairwise, time >= DIFFTIME_ZERO)

    names(pairwise) <- c('time', s1, s2)
    return(pairwise)
}

s1vs2 <- get_paired_readings(
    's1', '16octc-nothing-1bigbox.csv', 's2', '16octc-nothing-2bigbox.csv')
s1vs3 <- get_paired_readings(
    's1', '16octc-nothing-1bigbox.csv', 's3', '16octc-nothing-3bigbox.csv')
s1vs4 <- get_paired_readings(
    's1', '16octc-nothing-1bigbox.csv', 's4', '16octc-nothing-4bigbox.csv')
s2vs3 <- get_paired_readings(
    's2', '16octc-nothing-2bigbox.csv', 's3', '16octc-nothing-3bigbox.csv')
s2vs4 <- get_paired_readings(
    's2', '16octc-nothing-2bigbox.csv', 's4', '16octc-nothing-4bigbox.csv')
s3vs4 <- get_paired_readings(
    's3', '16octc-nothing-3bigbox.csv', 's4', '16octc-nothing-4bigbox.csv')

s1vs3 <- subset(s1vs3, s1 != 999.9 & s3 != 999.9)
ggplot(s1vs3, aes(x=s3, y=s1)) +
    geom_point() +
    geom_smooth(method='lm', formula=y~x+I(x^2), colour='blue') +
    geom_abline() +
    labs(title='s1 v s3 polynomial fit')
ggsave('s1vs3.png', width=16, height=9)

s1vs3.lm <- lm(s1~s3+I(s3^2), data=s1vs3)
sink('s1vs3.txt')
summary(s1vs3.lm)
sink(NULL)

s2vs3 <- subset(s2vs3, s2 != 999.9 & s3 != 999.9)
ggplot(s2vs3, aes(x=s3, y=s2)) +
    geom_point() +
    geom_smooth(method='lm', formula=y~x+I(x^2), colour='blue') +
    geom_abline() +
    labs(title='s2 v s3 polynomial fit')
ggsave('s2vs3.png', width=16, height=9)

s2vs3.lm <- lm(s2~s3+I(s3^2), data=s2vs3)
sink('s2vs3.txt')
summary(s2vs3.lm)
sink(NULL)

png('s1vs3-diag.png', width=16, height=9, units='in', res=300)
layout(matrix(1:4, ncol = 2))
plot(s1vs3.lm)
title('s1 v s3 diagnostics for polynomial fit')
layout(1)
dev.off()

png('s2vs3-diag.png', width=16, height=9, units='in', res=300)
layout(matrix(1:4, ncol = 2))
plot(s2vs3.lm)
title('s2 v s3 diagnostics for polynomial fit')
layout(1)
dev.off()

### Calibration functions ###

to_s3 <- function(lm, x) {
    coeff <- lm$coefficients - c(x, 0, 0)
    roots <- Re(polyroot(coeff))
    root <- roots[roots>=0]
    if (length(root) == 1) return(root)
    return(NA)  # would use NULL, but can't have NA in the middle of a vector
}

save(s1vs3.lm, s2vs3.lm, to_s3, file='calibrations.RData')
