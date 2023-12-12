library(reticulate)
source_python(here("Codes/DataProcessing/get_elev_py.py"))

field_bbox <-
  here(
    "Data", "Growers", ffy, "TrialDesign",
    paste0(get_trial_parameter(ffy)$tr_design_data, ".shp")
  ) %>%
  st_read() %>%
  st_transform(4326) %>%
  st_bbox() %>%
  as.list() %>%
  tuple()

file_path <- here("Data", "Growers", ffy, "Intermediate/dem.tif")

get_dem <- function(bbox, file_path) {
  get_elev_py(bbox, file_path)
  dem <- raster(file_path)
  return(dem)
}

dem <- get_dem(field_bbox, file_path)

plot(dem)