import py3dep
import rioxarray

def get_elev_py (geom, file_path): 

  # return type(geom)
  # download the dem data
  dem = py3dep.get_map(
    "DEM", 
    geom, 
    resolution=1, 
    geo_crs="epsg:4326", 
    crs="epsg:3857"
  ) 

  # save the elevation data as a tif file
  dem.rio.to_raster(file_path)
