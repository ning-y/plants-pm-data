#! /usr/bin/env Rscript

load('combined.RData')

data$has_soil <- ifelse(data$group %in% c('soil', 'deadplant', 'plant'), 1, 0)
data$has_sa <- ifelse(data$group %in% c('deadplant', 'plant'), 1, 0)
data$has_life <- ifelse(data$group == 'plant', 1, 0)
data

data.lm <- lm(decrease ~ has_soil + has_sa + has_life + box, data=data)
summary(data.lm)

sink('test.txt')
summary(data.lm)
sink(NULL)
