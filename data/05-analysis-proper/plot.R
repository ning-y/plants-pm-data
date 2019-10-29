#! /usr/bin/env Rscript

load('combined.RData')
library('ggpubr')

groups <- factor(data$group, levels=c('nothing', 'soil', 'deadplant', 'plant'))
data$group <- groups

ggboxplot(data, x='group', y='decrease', color='box')
ggsave('boxplot.png', width=16, height=9)
