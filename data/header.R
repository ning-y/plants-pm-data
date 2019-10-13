suppressPackageStartupMessages(library(docstring))
suppressPackageStartupMessages(library(tidyverse))

SYSTIME <- Sys.time()
DIFFTIME_ZERO <- difftime(SYSTIME, SYSTIME)

get_session <- function(filename) {
    #' Get session from CSV file.
    #'
    #' Returns a two-member list representation of the recording session
    #' represented by `filename`. session$readings represent PM2.5 and PM10
    #' readings; session$comments represent comments made by experimenters.
    #'
    #' session$readings is a 3-column tibble with names 'time', 'type', and
    #' 'value'. 'time' values are `timediff`, 'type' values are `character`s,
    #' 'value' values are `numeric`s. session$comments is a 2-column tibble with
    #' names 'time', 'value' (classes are similar to session$readings).

    data <- suppressMessages(read_csv(filename, col_names=F))
    names(data) <- c('time', 'type', 'value')

    ### Trim values before PM2.5 is in range.###
    data$time <- as.numeric(as.POSIXct(data$time, origin='1970-01-01'))
    # Find the row index with the last PM2.5===999.9 reading. Some data starts
    # with PM2.5 in range, some do not. Account for this using the bool var
    # saturated.
    saturated <- !max(as.numeric(subset(data, type=='pm2.5')$value)) == 999.9
    remove_up_to <- 0
    for (i in seq(1, nrow(data))) {
        row <- data[i,]
        if (row$type != 'pm2.5') next

        pm25_reading <- as.numeric(row$value)
        if (pm25_reading == 999.9) saturated <- T
        if (pm25_reading != 999.9 & saturated) {
            remove_up_to <- i
            break
        }
    }
    # Let time at first non-max reading be 0.
    time_offset <- data[remove_up_to,]$time
    data$time <- data$time - time_offset
    # Trim off rows before PM2.5 is in range.
    data <- subset(data, time >= DIFFTIME_ZERO)

    readings <- subset(data, type != 'comment')
    readings$value <- as.numeric(readings$value)
    comments <- subset(data, type == 'comment')
    select(comments, -type)

    return(list(readings=readings, comments=comments))
}
