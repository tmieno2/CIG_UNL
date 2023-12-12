---
title: User Manual
---

# Workflow

1. Go to the **Users** folder and run **01_initiate.rmd** with appropriate information.

2. Go to the **DataProcessingReport** folder and find **add_info_to_json.rmd** to add input, Rx, and extra information to the **metadata.json** file for this experiment 

3. (Once all the datasets are available) Go to the **DataProcessingReport** folder and find **process_data.rmd** to process and combine datasets 

# How to add information using **add_information.rmd**

Once you initiated a project folder for an experiment, you now need to populate information about the experiment to its corresponding entry in the **metadata.json** file. 

## Must

### Basic information

+ `yield_file`: name of the yield data file
+ `trial_design_file`: name of trial design shape file (outliers detected by treatment block indicated by `trd_PlotNum`)
+ `harvester_width`: harvester width in feet


```{r, eval = FALSE}
basic_data <-
  data.table(
    yield_file = "23_GSPA_C_VR_HV",
    trial_design_file = "23_GSPA_C_VR_TR",
    harvester_width = 30
  )
```


**add_basic_info()**

### Input information for trial:

+ `form` (or type): UAN32, UREA, etc
+ `product` (or type): UAN32, UREA, etc
+ `strategy`: this must be "trial"
+ `file_name`: name of the as-applied data file 
+ `machine_with`: machine width in feet (necessary for creating polygons around points)
+ `Rx_data`: Rx shape file. (This is used to check if the target input rate for any of the treatment blocks are 0 or not. If there is any, there will be no data points for those blocks. The code will "populate" the blocks with input points with 0 rate.) 

### Input information for base:

+ `form`: this must be "N_equiv"
+ `strategy`: this must be "base"
+ `rate`: nitrogen-equivalent rate in lb

```{r, eval = FALSE}
input_data <-
  data.table(
    form = c("NH3", "N_equiv"),
    product = c("NH3", "ATS"),
    strategy = c("trial", "base"),
    file_name = c("23_GSPA_C_VR_FA1", NA),
    unit = c("lbs", "lbs"),
    date = c("11/23/2022", "05/07/2023"),
    Rx_data = c("23_GSPA_C_VR_RX1", "none"),
    machine_width = c(35, NA),
    rate = c(NA, 7),
    var_name_prefix = c("FA1", "none")
  )
```

**add_inputs()**

## Optional

### Rx_data: commercial Rx data to compare against

+ `form` (or type): UAN32, UREA, etc
+ `model`: model used to generate the Rx
+ `file``: name of the Rx file
+ `date`: date of application

```{r, eval = FALSE}
Rx_data <-
  data.table(
    form = c("MAP", "UREA32"),
    model = c("granular", "AdaptN"),
    file = c("Rx_granular.shp", "Rx_AdaptN.shp"),
    date = c("04/01/2021", "04/02/2021")
  )
```


### Ex_data: Extra external dataset (NDVI, etc)

+ data_type: type of data,
+ file: name of the file,
+ date: date,
+ vars: list of variable names from the data file you want to have in the final dataset

```{r, eval = FALSE}
Ex_data <-
  data.table(
    data_type = c("NDRE"),
    file = c("21_BROB_W_SN_SRO.shp"),
    date = c("04/02/2021"),
    vars = list(c("NDVI", "Tgt_Rate_N"))
  )
```

# How to process datasets in **process_data.rmd**

## Get non-experimental data 

`get_ne_data()`

+ extract trial parameters with `get_trial_parameter()`
+ check whether trial design shape file has been uploaded
+ define field boundary using the trial design data
+ download elevation data using the `elvatr` package
+ download SSURGO data using the `soilDB` package
+ download weather (Daymet) data using the `daymetr` package

## Process yield data

`process_yield()`

+ necessary information from the JSON entry
  + yield shape file name under "yield_data"
  + trial design shape file name under "tr_data" 

+ check outliers (yield and speed)
+ check duplicate path
+ create polygons around points

## Process input data

`process_input()`

Virtually does the same thing as done to the input data.

## Merge yield and input data

`merge_yield_input()`

+ Link yield and nitrogen rate based on location
+ Link commercial Rx (if any) with yield 
