
library(tidyverse)
library(crossdes)
library(data.table)

mat <- MOLS(5, 1)

cor(
  mat[, , 4] %>% as.vector(),
  mat[, , 2] %>% as.vector()
)

data.table(mat[, , 4]) %>%
  .[, lapply(.SD, diff), .SDcols = names(.)] %>%
  .[, lapply(.SD, function(x) x^2), .SDcols = names(.)] %>%
  .[, lapply(.SD, sum), .SDcols = names(.)]
data.table(mat[, , 3]) %>%
  .[, lapply(.SD, diff), .SDcols = names(.)] %>%
  .[, lapply(.SD, function(x) x^2), .SDcols = names(.)] %>%
  .[, lapply(.SD, sum), .SDcols = names(.)]

dif_mat <- data.table(mat[, , 2]) %>%
  .[, lapply(.SD, diff), .SDcols = names(.)] %>%
  .[, lapply(.SD, function(x) x^2), .SDcols = names(.)]

colSums(dif_mat)

data.table(mat[, , 1]) %>%
  .[, lapply(.SD, diff), .SDcols = names(.)] %>%
  .[, lapply(.SD, function(x) x^2), .SDcols = names(.)] %>%
  .[, lapply(.SD, sum), .SDcols = names(.)]