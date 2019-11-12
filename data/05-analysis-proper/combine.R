#! /usr/bin/env Rscript

# load_data: reads the CSV and filters out only readings of interest.
# calibrate: used in load_data, calibrates s1 or s2 against s3.
# get_row:   used on data returned by load_data. generates row of Y, X, B
#               Y is the PM decrease after SET_TIME, X is the treatment/control
#               group, B is the box.

suppressPackageStartupMessages(library(tidyverse))
load('../03-sensor-calibration/calibrations_easy.RData')

SET_TIME <- 2 * 60 * 60
GRACE_TIME <- 0.5 * 60 * 60

load_data <- function(filename, group, box, sensor) {
    data <- suppressMessages(read_csv(filename, col_names=F))
    # Name the columns, set time as since epoch, only use PM2.5, and cast value to numeric
    names(data) <- c('time', 'type', 'value')
    data$time <- as.numeric(as.POSIXct(data$time, origin='1970-01-01'))
    data <- subset(data, type=='pm2.5')
    data$value <- as.numeric(data$value)


    # Set t=0 as first PM2.5 >= 900.
    last_saturated_reading_i <- last(which(data$value == 999.9)[-1])
    data$value <- calibrate(data$value, sensor)  # calibrate after 999.9 filter, because
                                                 # after calibration 999.9 is
                                                 # not 999.9
    data <- subset(data, time >= data[last_saturated_reading_i,]$time)
    first_good_reading_i <- which(data$value <= 900.0)[1]
    data$time <- data$time - data[first_good_reading_i,]$time

    # Visual confirmation that trimming for first_good_reading_i is OK.
    ggplot(data) +
        geom_line(mapping=aes(x=time, y=value)) +
        geom_vline(xintercept=c(0, SET_TIME), linetype='dotted') +
        geom_hline(yintercept=900, linetype='dotted') +
        xlim(NA, SET_TIME + GRACE_TIME) +  # only considering 3 hours
        labs(title=filename)
    ggsave(
        paste(tools::file_path_sans_ext(filename), '.png', sep=''),
        width=16, height=9)

    # Once confirmation is done, we don't need the stuff before
    # first_good_reading_i
    data <- subset(data, time >= 0)
    data$group <- group
    data$box <- box
    return(data)
}

calibrate <- function(values, sensor) {
    if (sensor == 's3') {
        return(values)
    }

    return(unlist(Map(
        function(x) to_s3_easy(sensor, x), values)))
}

get_row <- function(data) {
    start_reading <- data[1,]$value
    end_reading_i <- which(abs(data$time - SET_TIME) <= 5)
    end_reading <- data[end_reading_i,]$value
    group <- data$group[1]
    box <- data$box[1]
    return(data.frame(decrease=start_reading-end_reading, group=group, box=box))
}

data <- rbind(
    # First set of parallel trials.
    get_row(load_data("19-octa-nothing-1a.csv", 'nothing', 'a', 's1')),
    get_row(load_data("19-octa-nothing-2b.csv", 'nothing', 'b', 's2')),
    get_row(load_data("19-octa-nothing-3d.csv", 'nothing', 'd', 's3')),
    get_row(load_data("20octa-nothing1a.csv", 'nothing', 'a', 's1')),
    get_row(load_data("20octa-nothing2b.csv", 'nothing', 'b', 's2')),
    get_row(load_data("20octa-nothing3d.csv", 'nothing', 'd', 's3')),
    get_row(load_data("21octa-nothing-1a.csv", 'nothing', 'a', 's1')),
    get_row(load_data("21octa-nothing-2b.csv", 'nothing', 'b', 's2')),
    get_row(load_data("21octa-nothing-3d.csv", 'nothing', 'd', 's3')),
    get_row(load_data("21octb-nothing-1a.csv", 'nothing', 'a', 's1')),
    get_row(load_data("21octb-nothing-2b.csv", 'nothing', 'b', 's2')),
    get_row(load_data("21octb-nothing-3d.csv", 'nothing', 'd', 's3')),
    get_row(load_data("22octa-nothing-1a.csv", 'nothing', 'a', 's1')),
    get_row(load_data("22octa-nothing-2b.csv", 'nothing', 'b', 's2')),
    get_row(load_data("22octa-nothing-3d.csv", 'nothing', 'd', 's3')),
    # Second set of parallel trials.
    get_row(load_data("25octa-deadplant-1a.csv", 'deadplant', 'a', 's1')),
    get_row(load_data("25octa-plant-3D.csv", 'plant', 'd', 's3')),
    get_row(load_data("25octa-soil-2b.csv", 'soil', 'b', 's2')),
    get_row(load_data("25octb-deadplant-1a.csv", 'deadplant', 'a', 's1')),
    get_row(load_data("25octb-plant-3D.csv", 'plant', 'd', 's3')),
    get_row(load_data("25octb-soil-2b.csv", 'soil', 'b', 's2')),
    get_row(load_data("26octa-deadplant-1a.csv", 'deadplant', 'a', 's1')),
    get_row(load_data("26octa-plant-3d.csv", 'plant', 'd', 's3')),
    get_row(load_data("26octa-soil-2b.csv", 'soil', 'b', 's2')),
    get_row(load_data("27octa-deadplant-1a.csv", 'deadplant', 'a', 's1')),
    get_row(load_data("27octa-plant-3d.csv", 'plant', 'd', 's3')),
    get_row(load_data("27octa-soil-2b.csv", 'soil', 'b', 's2')),
    get_row(load_data("28octa-deadplant-1a.csv", 'deadplant', 'a', 's1')),
    get_row(load_data("28octa-plant-3d.csv", 'plant', 'd', 's3')),
    get_row(load_data("28octa-soil-2b.csv", 'soil', 'b', 's2')),
    # Third set of parallel trials.
    get_row(load_data("2nova-plant-1a.csv", 'plant', 'a', 's1')),
    get_row(load_data("2nova-deadplant-2b.csv", 'deadplant', 'b', 's2')),
    get_row(load_data("2nova-soil-3d.csv", 'soil', 'd', 's3')),
    get_row(load_data("2novb-plant-1a.csv", 'plant', 'a', 's1')),
    get_row(load_data("2novb-deadplant-2b.csv", 'deadplant', 'b', 's2')),
    get_row(load_data("2novb-soil-3d.csv", 'soil', 'd', 's3')),
    get_row(load_data("30octa-plant-1a.csv", 'plant', 'a', 's1')),
    get_row(load_data("30octa-deadplant-2b.csv", 'deadplant', 'b', 's2')),
    get_row(load_data("30octa-soil-3d.csv", 'soil', 'd', 's3')),
    get_row(load_data("30octb-plant-1a.csv", 'plant', 'a', 's1')),
    get_row(load_data("30octb-deadplant-2b.csv", 'deadplant', 'b', 's2')),
    get_row(load_data("30octb-soil-3d.csv", 'soil', 'd', 's3')),
    get_row(load_data("31octb-plant-1a.csv", 'plant', 'a', 's1')),
    get_row(load_data("31octb-deadplant-2b.csv", 'deadplant', 'b', 's2')),
    get_row(load_data("31octb-soil-3d.csv", 'soil', 'd', 's3')),
    # Fourth set of parallel trials, minus last three. TODO:
    get_row(load_data("3nova-soil-1a.csv", 'soil', 'a', 's1')),
    get_row(load_data("3nova-plant-2b.csv", 'plant', 'b', 's2')),
    get_row(load_data("3nova-deadplant-3d.csv", 'deadplant', 'd', 's3')),
    get_row(load_data("4nova-soil-1a.csv", 'soil', 'a', 's1')),
    get_row(load_data("4nova-plant-2b.csv", 'plant', 'b', 's2')),
    get_row(load_data("4nova-deadplant-3d.csv", 'deadplant', 'd', 's3')),
    get_row(load_data("5nova-soil-1a.csv", 'soil', 'a', 's1')),
    get_row(load_data("5nova-plant-2b.csv", 'plant', 'b', 's2')),
    get_row(load_data("5nova-deadplant-3d.csv", 'deadplant', 'd', 's3')),
    get_row(load_data("6nova-soil-1a.csv", 'soil', 'a', 's1')),
    get_row(load_data("6nova-plant-2b.csv", 'plant', 'b', 's2')),
    get_row(load_data("6nova-deadplant-3d.csv", 'deadplant', 'd', 's3')),
    get_row(load_data("7nova-soil-1a.csv", 'soil', 'a', 's1')),
    get_row(load_data("7nova-deadplant-2b.csv", 'plant', 'b', 's2')), # typo in filename
    get_row(load_data("7nova-deadplant-3d.csv", 'deadplant', 'd', 's3'))
)

save(data, file='combined.RData')
