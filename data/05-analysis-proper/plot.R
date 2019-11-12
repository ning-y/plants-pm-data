#! /usr/bin/env Rscript

load('combined.RData')
library('ggpubr')

groups <- factor(data$group, levels=c('nothing', 'soil', 'deadplant', 'plant'))
data$group <- groups

ggboxplot(data, x='group', y='decrease', color='box') +
    ylab(expression(atop("PM"[2.5]*" decrease ("*mu*"g m"^-3*")", ""))) +
    xlab("\nControl/Treatment Group") +
    guides(color=guide_legend(title='Box')) +
    scale_x_discrete(labels=c(
        'nothing'='Control',
        'soil'='Potting Mix Only',
        'deadplant'=expression('Pressed '*italic('S. trifasciata')),
        'plant'=expression('Live '*italic('S. trifasciata')))) +
    theme_grey()
ggsave('boxplot.png', width=12, height=7)
