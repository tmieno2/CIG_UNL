# /*=================================================*/
#' # Non experimental data processing and reporting
# /*=================================================*/

get_ne_data <- function(ffy, rerun = FALSE, locally_run = FALSE) {
  library(knitr)
  options(knitr.duplicate.label = "allow")

  print(paste0("Obtaining non-experiment data for ", ffy))

  #--- define field parameters ---#
  trial_parameters <- get_trial_parameter(ffy)
  ex_data <- trial_parameters$ex_data
  tr_file <-
    get_trial_parameter(ffy) %>%
    .$tr_design_data

  td_file <-
    here(
      "Data", "Growers", ffy, "TrialDesign",
      paste0(tr_file, ".shp")
    )

  if (!file.exists(td_file)) {
    return(print("No trial design file exists. Please upload one."))
  }

  if (rerun) {
    #--- remove cached files ---#
    list.files(
      file.path(here(), "Data", "Growers", ffy, "DataProcessingReport"),
      full.names = TRUE
    ) %>%
      .[str_detect(., "report_non_exp")] %>%
      .[str_detect(., c("cache|files"))] %>%
      unlink(recursive = TRUE)
  }

  nep_rmd <-
    read_rmd("DataProcessing/get_ne_data.rmd") %>%
    gsub("field-year-here", ffy, .) %>%
    gsub("title-here", "Non-experiment Data Processing Report", .)

  # /*----------------------------------*/
  #' ## Write out the rmd and render
  # /*----------------------------------*/
  nep_report_rmd_file_name <- here("Data/Growers", ffy, "DataProcessingReport/dp_report_non_exp.Rmd")

  writeLines(nep_rmd, con = nep_report_rmd_file_name)

  purl(
    nep_report_rmd_file_name,
    output =
      here(
        "Data/Growers",
        ffy,
        "DataProcessingReport/obtaining_ne_data_debug.R"
      )
  )

  #--- render ---#
  render(nep_report_rmd_file_name)
}


# /*===========================================================
#' # Process Yield Data
# /*===========================================================
process_yield <- function(ffy, ol_yield_sd_factor = 4, num_paths = NA) {
  library(knitr)
  options(knitr.duplicate.label = "allow")

  cat(paste0(
    "=============================================\n= Processing experiment data for ", ffy,
    "\n============================================="
  ))

  #--- define field parameters ---#
  trial_pars <- get_trial_parameter(ffy)
  yield_file <- trial_pars$yield_data

  exp_temp_rmd <- read_rmd("DataProcessing/data_processing_template.Rmd")

  e_yield <-
    read_rmd("DataProcessing/e01_gen_yield_polygons.Rmd") %>%
    gsub("yield-file-name-here", yield_file, .)

  yield_rmd <-
    c(exp_temp_rmd, e_yield) %>%
    gsub("field-year-here", ffy, .) %>%
    gsub("title-here", "Yield Data Processing", .) %>%
    gsub("ol_yield_sd_factor_here", ol_yield_sd_factor, .) %>%
    gsub("num_paths_here", num_paths, .)

  # /*=================================================*/
  #' # Write out the rmd and render
  # /*=================================================*/
  rmd_file_name <-
    here(
      "Data/Growers",
      ffy,
      "DataProcessingReport/yield_data_report.Rmd"
    )

  debug_file_name <-
    here(
      "Data/Growers",
      ffy,
      "DataProcessingReport/yield_for_debug.R"
    )

  writeLines(yield_rmd, con = rmd_file_name)

  purl(rmd_file_name, output = debug_file_name)

  render(rmd_file_name)
}

# /*===========================================================
#' # Process Input Data
# /*===========================================================
process_input <- function(ffy, ol_sd_factor = 4, num_paths = NA) {
  library(knitr)
  options(knitr.duplicate.label = "allow")

  cat(paste0(
    "============================================\n= Processing experiment data for ", ffy,
    "\n============================================"
  ))
  #--- define field parameters ---#
  trial_pars <- get_trial_parameter(ffy)
  trial_info <- trial_pars$input_data_trial

  template_rmd <- read_rmd("DataProcessing/data_processing_template.Rmd")

  # /*----------------------------------*/
  #' ## Rmd(s) for input processing
  # k*----------------------------------*/
  input_rmd <-
    trial_info %>%
    rowwise() %>%
    mutate(
      e02_rmd = list(
        prepare_e02_rmd(
          input_type = input_type,
          data_file = file_name,
          input_form = form,
          input_id = input_id,
          reporting_unit = reporting_unit,
          input_unit = unit,
          machine_width = machine_width
        )
      )
    ) %>%
    data.table() %>%
    .[, e02_rmd] %>%
    reduce(c)

  input_rmd_full <-
    c(template_rmd, input_rmd) %>%
    gsub("field-year-here", ffy, .) %>%
    gsub("title-here", "Input Data Processing Report", .) %>%
    gsub("ol_sd_factor_here", ol_sd_factor, .) %>%
    gsub("num_paths_here", num_paths, .)

  # /*=================================================*/
  #' # Write out the rmd and render
  # /*=================================================*/
  rmd_file_name <-
    here(
      "Data/Growers",
      ffy,
      "DataProcessingReport/input_data_report.Rmd"
    )

  debug_file_name <-
    here(
      "Data/Growers",
      ffy,
      "DataProcessingReport/input_for_debug.R"
    )

  writeLines(input_rmd_full, con = rmd_file_name)

  purl(rmd_file_name, output = debug_file_name)

  render(rmd_file_name)
}


# /*=================================================*/
#' # Merge yield and input data
# /*=================================================*/

merge_yield_input <- function(ffy, overlap_acceptance_pct = 0.1, max_dev_ls = NA, ignore_overlap_threshold = 0.05) {
  library(knitr)
  options(knitr.duplicate.label = "allow")

  cat(paste0(
    "============================================\n= Processing experiment data for ", ffy,
    "\n============================================"
  ))
  #--- define field parameters ---#
  trial_pars <- get_trial_parameter(ffy)
  trial_info <- trial_pars$input_data_trial

  merge_rmd <-
    read_rmd("DataProcessing/data_processing_template.Rmd") %>%
    c(., read_rmd("DataProcessing/e03_yield_input_integration.Rmd")) %>%
    gsub("field-year-here", ffy, .) %>%
    gsub("title-here", "Merge Yield and Input Data", .) %>%
    gsub("max_dev_here", max_dev_ls, .) %>%
    gsub("ignore_overlap_threshold_here", ignore_overlap_threshold, .) %>%
    gsub("overlap_acceptance_pct_here", overlap_acceptance_pct, .)

  # /*=================================================*/
  #' # Write out the rmd and render
  # /*=================================================*/
  data_merge_rmd_file_name <-
    here(
      "Data/Growers",
      ffy,
      "DataProcessingReport/merge_data_report.Rmd"
    )

  debug_file_name <-
    here(
      "Data/Growers",
      ffy,
      "DataProcessingReport/merge_for_debug.R"
    )

  writeLines(merge_rmd, con = data_merge_rmd_file_name)

  purl(data_merge_rmd_file_name, output = debug_file_name)

  render(data_merge_rmd_file_name)
}


# /*=================================================*/
#' # Experiment data processing and reporting
# /*=================================================*/

exp_process_make_report <- function(ffy, ol_yield_sd_factor = 4, overlap_acceptance_pct = 0.1, max_dev = NA, rerun = FALSE, locally_run = FALSE) {
  library(knitr)
  options(knitr.duplicate.label = "allow")

  cat(paste0(
    "============================================\n= Processing experiment data for ", ffy,
    "\n============================================"
  ))
  #--- define field parameters ---#
  trial_pars <- get_trial_parameter(ffy)
  yield_file <- trial_pars$yield_data
  trial_info <- trial_pars$input_data_trial

  exp_temp_rmd <-
    read_rmd(
      "DataProcessing/data_processing_template.Rmd",
      locally_run = locally_run
    )

  e01 <-
    read_rmd(
      "DataProcessing/e01_gen_yield_polygons.Rmd",
      locally_run = locally_run
    ) %>%
    gsub("yield-file-name-here", yield_file, .)

  exp_rmd_y <- c(exp_temp_rmd, e01)

  # /*----------------------------------*/
  #' ## Rmd(s) for input processing
  # /*----------------------------------*/
  e02 <-
    trial_info %>%
    rowwise() %>%
    mutate(
      e02_rmd = list(
        prepare_e02_rmd(
          input_type = input_type,
          data_file = file_name,
          input_form = form,
          input_id = input_id,
          reporting_unit = reporting_unit,
          input_unit = unit,
          machine_width = machine_width,
          locally_run = TRUE
        )
      )
    ) %>%
    data.table() %>%
    .[, e02_rmd] %>%
    reduce(c)

  exp_rmd_yi <- c(exp_rmd_y, e02)

  # /*----------------------------------*/
  #' ## Merge yield and input data
  # /*----------------------------------*/
  e03 <- read_rmd(
    "DataProcessing/e03_yield_input_integration.Rmd",
    locally_run = locally_run
  )

  # /*----------------------------------*/
  #' ## Personalize the report
  # /*----------------------------------*/
  exp_rmd_yiy <-
    c(exp_rmd_yi, e03) %>%
    gsub("field-year-here", ffy, .) %>%
    gsub("title-here", "Experiment Data Processing Report", .) %>%
    gsub("ol_yield_sd_factor_here", ol_yield_sd_factor, .) %>%
    gsub("max_dev_here", max_dev, .) %>%
    gsub("overlap_acceptance_pct_here", overlap_acceptance_pct, .) %>%
    gsub("num_paths_here", num_paths, .)

  # /*=================================================*/
  #' # Remove cached files if rerun == TRUE
  # /*=================================================*/
  if (rerun) {
    #--- remove cached files ---#
    list.files(
      file.path(here(), "Data", "Growers", ffy, "DataProcessingReport"),
      full.names = TRUE
    ) %>%
      .[str_detect(., "report_exp")] %>%
      .[str_detect(., c("cache|files"))] %>%
      unlink(recursive = TRUE)
  }

  # /*=================================================*/
  #' # Write out the rmd and render
  # /*=================================================*/
  exp_report_rmd_file_name <-
    here(
      "Data/Growers",
      ffy,
      "DataProcessingReport/dp_report_exp.Rmd"
    )

  exp_report_r_file_name <-
    here(
      "Data/Growers",
      ffy,
      "DataProcessingReport/for_debug.R"
    )

  writeLines(exp_rmd_yiy, con = exp_report_rmd_file_name)

  purl(exp_report_rmd_file_name, output = exp_report_r_file_name)

  render(exp_report_rmd_file_name)
}

# /*=================================================*/
#' # Final data processing and reporting
# /*=================================================*/
f_process_make_report <- function(ffy, rerun = FALSE, locally_run = FALSE) {
  library(knitr)
  options(knitr.duplicate.label = "allow")

  print(paste0("Combining experimental and external data for ", ffy))

  #--- define field parameters ---#
  trial_parameters <- get_trial_parameter(ffy)
  ex_data <- trial_parameters$ex_data
  tr_file <-
    get_trial_parameter(ffy) %>%
    .$tr_design_data

  #* Read the template rmd file
  fp_temp_rmd <-
    read_rmd(
      "DataProcessing/data_processing_template.Rmd"
    ) %>%
    gsub("field-year-here", ffy, .)

  # f01_rmd <- readLines(file.path(here(), "Codes/DataProcessing/f01_combine_all_datasets.Rmd"))

  f01_rmd <-
    read_rmd(
      "DataProcessing/f01_combine_all_datasets.Rmd"
    )

  fp_rmd <- c(fp_temp_rmd, f01_rmd)

  if (rerun) {
    #--- remove cached files ---#
    list.files(
      file.path(here(), "Data", "Growers", ffy, "DataProcessingReport"),
      full.names = TRUE
    ) %>%
      .[str_detect(., "final")] %>%
      .[str_detect(., "cache|files")] %>%
      unlink(recursive = TRUE)
  }

  # /*----------------------------------*/
  #' ## Write out the rmd and render
  # /*----------------------------------*/
  exp_report_rmd_file_name <-
    "DataProcessingReport/final_processing_report.Rmd" %>%
    file.path(here(), "Data", "Growers", ffy, .) %>%
    paste0(.)

  writeLines(fp_rmd, con = exp_report_rmd_file_name)

  render(exp_report_rmd_file_name)
}

# /*=================================================*/
#' # Run analysis
# /*=================================================*/
run_analysis <- function(ffy, rerun = FALSE, locally_run = FALSE) {
  library(knitr)
  options(knitr.duplicate.label = "allow")

  data_for_analysis_exists <- here("Data", "Growers", ffy, "Analysis-Ready", "analysis_data.rds") %>%
    file.exists()

  if (!data_for_analysis_exists) {
    return(print("No data that is ready for analysis exist. Process the datasets first."))
  }

  if (rerun) {
    #--- remove cached files ---#
    list.files(
      file.path(here(), "Reports/Growers", ffy),
      full.names = TRUE
    ) %>%
      .[str_detect(., "analysis")] %>%
      .[str_detect(., "cache|files")] %>%
      unlink(recursive = TRUE)
  }

  analysis_rmd <- read_rmd(
    "Analysis/a01_analysis.Rmd",
    locally_run = locally_run
  ) %>%
    gsub("field-year-here", ffy, .)

  # /*----------------------------------*/
  #' ## Save and run
  # /*----------------------------------*/
  analysis_rmd_file_name <- here() %>%
    paste0(., "/Reports/Growers/", ffy, "/analysis.Rmd")

  writeLines(analysis_rmd, con = analysis_rmd_file_name)

  render(analysis_rmd_file_name)
}

# /*=================================================*/
#' # Make report (run after run_analysis)
# /*=================================================*/

make_grower_report <- function(ffy, rerun = TRUE, locally_run = FALSE) {
  library(knitr)
  options(knitr.duplicate.label = "allow")

  source(
    get_r_file_name("Functions/unpack_field_parameters.R"),
    local = TRUE
  )

  # /*----------------------------------*/
  #' ## If rerun = TRUE
  # /*----------------------------------*/
  if (rerun) {
    #--- remove cached files ---#
    list.files(
      file.path(here(), "Reports/Growers", ffy),
      full.names = TRUE
    ) %>%
      .[str_detect(., "grower-report")] %>%
      .[str_detect(., c("cache|files"))] %>%
      unlink(recursive = TRUE)
  }

  results <- readRDS(here("Reports", "Growers", ffy, "analysis_results.rds"))

  base_rmd <- read_rmd(
    "Report/r00_report_header.Rmd",
    locally_run = locally_run
  )

  results_gen_rmd <- read_rmd(
    "Report/r01_gen_results.Rmd",
    locally_run = locally_run
  )

  report_rmd_ls <- results %>%
    mutate(
      report_rmd = list(c(base_rmd, results_gen_rmd))
    ) %>%
    rowwise() %>%
    mutate(
      unit_txt = case_when(
        input_type == "S" ~ "K seeds",
        input_type == "N" ~ "lbs",
        input_type == "K" ~ "lbs"
      )
    ) %>%
    mutate(
      input_full_name = case_when(
        input_type == "S" ~ "Seed",
        input_type == "N" ~ "Nitrogen",
        input_type == "K" ~ "Potassium"
      )
    ) %>%
    mutate(
      report_body = list(
        read_rmd(
          "Report/r01_make_report.Rmd",
          locally_run = locally_run
        )
      )
    ) %>%
    mutate(
      res_disc_rmd = list(
        get_ERI_texts(
          input_type = input_type,
          gc_rate = gc_rate,
          whole_profits_test = whole_profits_test,
          pi_dif_test_zone = pi_dif_test_zone,
          opt_gc_data = opt_gc_data,
          gc_type = gc_type,
          locally_run = locally_run
        )
      ),
      td_txt = list(
        get_td_text(
          input_type = input_type,
          gc_type = gc_type,
          locally_run = locally_run
        )
      )
    ) %>%
    mutate(
      report_body = list(
        insert_rmd(
          target_rmd = report_body,
          inserting_rmd = res_disc_rmd,
          target_text = "_results-and-discussions-here_"
        ) %>%
          insert_rmd(
            target_rmd = .,
            inserting_rmd = td_txt,
            target_text = "_trial_design_information_here_"
          )
      )
    ) %>%
    mutate(
      report_rmd = list(
        c(report_rmd, report_body)
      )
    ) %>%
    mutate(field_plots_rmd = list(
      if (!is.null(field_plots)) {
        field_plots %>%
          ungroup() %>%
          mutate(index = as.character(seq_len(nrow(.)))) %>%
          rowwise() %>%
          mutate(rmd = list(
            read_rmd(
              "Report/ri04_interaction_figures.Rmd",
              locally_run = locally_run
            ) %>%
              str_replace_all("_i-here_", index) %>%
              str_replace_all(
                "_ch_var_here_no_underbar_",
                gsub("_", "-", ch_var)
              ) %>%
              str_replace_all("_ch_var_here_", ch_var)
          )) %>%
          pluck("rmd") %>%
          reduce(c)
      } else {
        NULL
      }
    )) %>%
    mutate(report_rmd = list(
      insert_rmd(
        target_rmd = report_rmd,
        inserting_rmd = field_plots_rmd,
        target_text = "_field-interactions-here_"
      )
    )) %>%
    mutate(
      write_file_name = list(
        here(
          "Reports/Growers", ffy,
          paste0("grower-report-", tolower(input_type), ".Rmd")
        )
      )
    ) %>%
    mutate(
      report_rmd = list(
        report_rmd %>%
          gsub(
            "_base_rate_statement_here_",
            case_when(
              gc_type == "uniform" ~ "`r round(_gc_rate_here_, digits = 0)` _unit_here_",
              gc_type == "Rx" ~ "Rx (see the map below)"
            ),
            .
          ) %>%
          str_replace_all("_unit_here_", unit_txt) %>%
          str_replace_all("_input_full_name_here_c_", input_full_name) %>%
          str_replace_all("_input_type_here_", input_type) %>%
          str_replace_all("_field-year-here_", ffy) %>%
          str_replace_all("_gc_rate_here_", as.character(gc_rate)) %>%
          str_replace_all(
            "_planter-applicator-here_",
            case_when(
              input_type == "S" ~ "planter",
              input_type != "S" ~ "applicator"
            )
          ) %>%
          str_replace_all(
            "_asa-or-asp_",
            case_when(
              input_type == "S" ~ "as-planted",
              input_type != "S" ~ "as-applied"
            )
          ) %>%
          str_replace_all(
            "_seeding-or-application_",
            case_when(
              input_type == "S" ~ "seeding",
              input_type != "S" ~ "_input_full_name_l_ application"
            )
          ) %>%
          str_replace_all(
            "_input_full_name_l_",
            tolower(input_full_name)
          ) %>%
          str_replace_all(
            "_crop_type_here_",
            case_when(
              crop == "soy" ~ "soybean",
              crop != "soy" ~ crop
            )
          ) %>%
          str_replace_all(
            "_uniform_Rx_1_",
            case_when(
              gc_type == "Rx" ~ "the commercial variable-rate prescription",
              gc_type != "Rx" ~ "the uniform rate"
            )
          ) %>%
          str_replace_all(
            "_uniform_Rx_2_",
            case_when(
              gc_type == "Rx" ~ "commercial Rx",
              gc_type != "Rx" ~ "uniform rate"
            )
          ) %>%
          str_replace_all(
            "_RX_notes_here_",
            case_when(
              gc_type == "Rx" ~ "(the average of the Rx rates within the zone)",
              gc_type != "Rx" ~ ""
            )
          )
      )
    )

  # /*----------------------------------*/
  #' ## Write to Rmd file(s)
  # /*----------------------------------*/
  report_rmd_ls %>%
    summarise(
      list(
        writeLines(report_rmd, write_file_name)
      )
    )

  # /*----------------------------------*/
  #' ## Knit
  # /*----------------------------------*/
  report_rmd_ls %>%
    pluck("write_file_name") %>%
    lapply(., render)
}

# /*=================================================*/
#' # Make trial design and create a report
# /*=================================================*/
# Create plots and ab-lines

make_trial_design <- function(ffy,
                              json_file,
                              head_dist = NA,
                              side_dist = NA,
                              boundary = NA,
                              plot_heading = NA, # the name of the ab-line file
                              perpendicular = FALSE,
                              min_plot_length = 200,
                              max_plot_length = 300,
                              ab_line_type = "free", # one of "free", "lock", "non"
                              design_type = NA,
                              rates = NA,
                              num_levels = 6,
                              max_jumps = NA,
                              file_name_append = NA,
                              locally_run = FALSE) {
  print(paste0("Generating a trial-design for ", ffy))

  # plot_heading = "ab-line"

  # /*----------------------------------*/
  #' ## Create trial data
  # /*----------------------------------*/
  trial_data <-
    get_td_parameters(ffy, json_file) %>%
    mutate(
      input_plot_width = conv_unit(input_plot_width, "ft", "m"),
      machine_width = conv_unit(machine_width, "ft", "m"),
      section_width = machine_width / section_num,
      harvester_width = conv_unit(harvester_width, "ft", "m"),
      plot_heading = plot_heading,
      perpendicular = perpendicular,
      min_plot_length = min_plot_length,
      max_plot_length = max_plot_length,
      ab_line_type = ab_line_type,
      rates = rates,
      num_levels = num_levels,
      max_jump = max_jumps,
      file_name_append = file_name_append
    )

  # === trial design type ===#
  if (nrow(trial_data) == 1) {
    if (is.na(design_type)) {
      trial_data$design_type <- "ejca"
    } else {
      trial_data$design_type <- design_type[1]
    }
  } else if (is.na(design_type)) {
    # === if two inputs and no design_type is specified ===#
    trial_data <- trial_data %>%
      mutate(design_type = ifelse(form == "seed", "jcl", "ejca"))
  } else if (length(design_type) == 1) {
    return(print(
      "Error: you did not provide two design type values even though this is a two
      input-case."
    ))
  } else {
    trial_data <- trial_data %>%
      mutate(design_type = design_type)
  }

  if (nrow(trial_data) > 1 & all(trial_data$design_type == "ejca")) {
    return(print(
      "Error: you cannot use ejca for both inputs as it will create
      significant positive or negative correlations between the two inputs"
    ))
  }

  # === head distance ===#
  if (is.na(head_dist)) {
    # === machine width converted above ===#
    head_dist <- 2 * max(trial_data$machine_width)
  } else {
    # === conversion necessary ===#
    head_dist <- conv_unit(head_dist, "ft", "m")
  }

  # === side distance ===#
  if (is.na(side_dist)) {
    # === section width converted above ===#
    side_dist <- max(max(trial_data$section_width), 30)
  } else {
    # === conversion necessary ===#
    side_dist <- conv_unit(side_dist, "ft", "m")
  }

  trial_data$headland_length <- head_dist
  trial_data$side_length <- side_dist

  saveRDS(
    trial_data,
    here("Data", "Growers", ffy, "TrialDesign/trial_data.rds")
  )

  # /*=================================================*/
  #' # Rmd
  # /*=================================================*/
  td_rmd <-
    read_rmd(
      "TrialDesignGeneration/make-trial-design-template.Rmd",
      locally_run = locally_run
    ) %>%
    gsub("_field-year-here_", ffy, .) %>%
    gsub("_json-file-here_", json_file, .) %>%
    gsub(
      "_boundary-file-here_",
      ifelse(is.na(boundary), "boundary", boundary),
      .
    )


  # /*=================================================*/
  #' # Wrapping up
  # /*=================================================*/
  td_file_name <- file.path(
    here(), "Data/Growers", ffy,
    paste0(
      "TrialDesign/make_trial_design",
      ifelse(is.na(file_name_append) | file_name_append == "", "", paste0("_", file_name_append)),
      ".Rmd"
    )
  )

  writeLines(td_rmd, con = td_file_name)

  td_r_file_name <- here(
    "Data/Growers",
    ffy,
    "TrialDesign/for_debug.R"
  )

  purl(td_file_name, output = td_r_file_name)

  #--- render ---#
  render(td_file_name)
}

# /*----------------------------------*/
#' ## Read rmd file from github repository
# /*----------------------------------*/

# file_name <- "DataProcessing/data_processing_template.Rmd"
# rmd_file[1:10]

read_rmd <- function(file_name, locally_run = TRUE) {
  if (locally_run == FALSE) {
    file_name_on_github <-
      paste0(
        "https://github.com/tmieno2/OnFarmExperiments/blob/master/", file_name,
        "?raw=TRUE"
      )
  } else {
    file_name_on_github <- here::here(file_name)
  }


  rmd_file <- suppressMessages(readLines(file_name_on_github))

  return(rmd_file)
}

get_r_file_name <- function(file_name, locally_run = FALSE) {
  if (locally_run == FALSE) {
    file_name <- paste0("https://github.com/tmieno2/OnFarmExperiments/blob/master/", file_name, "?raw=TRUE")
  } else if (here() == "/Users/tmieno2/OneDrive - University of Nebraska-Lincoln/OnFarmExperiments") {
    # === if in TM's DIFM_DevTeam folder ===#
    file_name <- here("Codes", file_name)
  } else {
    # === if in anybody's DIFM_HQ  ===#
    file_name <- here("Codes", file_name)
  }

  return(file_name)
}

insert_rmd <- function(target_rmd, inserting_rmd, target_text) {
  inserting_index <- which(str_detect(target_rmd, target_text))

  return_md <- c(
    target_rmd[1:(inserting_index - 1)],
    inserting_rmd,
    target_rmd[(inserting_index + 1):length(target_rmd)]
  )

  return(return_md)
}


get_ERI_texts <- function(input_type, gc_rate, whole_profits_test, pi_dif_test_zone, opt_gc_data, gc_type, locally_run = FALSE) {

  # === for debugging ===#
  # input_type <- report_rmd_ls$input_type[[1]]
  # gc_rate <- report_rmd_ls$gc_rate[[1]]
  # whole_profits_test <- report_rmd_ls$whole_profits_test[[1]]
  # pi_dif_test_zone <- report_rmd_ls$pi_dif_test_zone[[1]]
  # opt_gc_data <- report_rmd_ls$opt_gc_data[[1]]
  # gc_type <- report_rmd_ls$gc_type[[1]]

  res_disc_rmd <- read_rmd("Report/ri01_results_by_zone.Rmd", locally_run = locally_run)

  # /*----------------------------------*/
  #' ## Profit differential narrative
  # /*----------------------------------*/
  # Statements about the difference between
  # optimal vs grower-chosen rates

  if (nrow(pi_dif_test_zone) > 1) {
    pi_dif_zone_rmd <- tibble(
      w_zone = 2:nrow(pi_dif_test_zone)
    ) %>%
      rowwise() %>%
      mutate(t_value = list(
        pi_dif_test_zone[zone_txt == paste0("Zone ", w_zone), t]
      )) %>%
      mutate(pi_dif_rmd_indiv = list(
        read_rmd(
          "Report/ri02_profit_dif_statement.Rmd",
          locally_run = locally_run
        ) %>%
          gsub("_insert-zone-here_", w_zone, .) %>%
          gsub(
            "_t-confidence-statement_",
            get_t_confidence_statement(t_value),
            .
          )
      )) %>%
      pluck("pi_dif_rmd_indiv") %>%
      reduce(c)
  } else {
    # === if there is only one zone ===#
    pi_dif_zone_rmd <- NULL
  }

  res_disc_rmd <- insert_rmd(
    target_rmd = res_disc_rmd,
    inserting_rmd = pi_dif_zone_rmd,
    target_text = "_rest-of-the-zones-here_"
  ) %>%
    gsub("_gc_rate_here_", gc_rate, .) %>%
    # === t-test statement for zone 1 (exception) ===#
    gsub(
      "_t-confidence-statement_1_",
      get_t_confidence_statement(
        pi_dif_test_zone[zone_txt == paste0("Zone ", 1), t]
      ),
      .
    )

  # /*----------------------------------*/
  #' ## Difference between optimal vs grower-chosen rates
  # /*----------------------------------*/
  # Statements about the difference between
  # optimal vs grower-chosen rates

  gc_opt_comp_txt <- left_join(
    opt_gc_data[type == "opt_v", ],
    opt_gc_data[type == "gc", ],
    by = "zone_txt"
  ) %>%
    # === y for gc and x for opt_v ===#
    mutate(dif = input_rate.y - input_rate.x) %>%
    dplyr::select(zone_txt, dif) %>%
    arrange(zone_txt) %>%
    mutate(
      gc_opt_comp_txt =
        paste0(
          abs(dif) %>% round(digits = 0),
          " _unit_here_ per acre",
          ifelse(dif > 0, " too high", " too low"),
          " in ",
          str_to_title(zone_txt)
        )
    ) %>%
    pull(gc_opt_comp_txt) %>%
    paste(collapse = ", ")

  res_disc_rmd <- gsub(
    "_gc-opt-comp-txt-comes-here_",
    gc_opt_comp_txt,
    res_disc_rmd
  )


  return(res_disc_rmd)
}


get_t_confidence_statement <- function(t_value) {
  case_when(
    t_value < qt(0.75, df = 1000) ~ "could establish only with a negligible",
    qt(0.75, df = 1000) <= t_value & t_value < qt(0.85, df = 1000) ~ "could establish only with a limited",
    qt(0.85, df = 1000) <= t_value & t_value < qt(0.95, df = 1000) ~ "established with a moderate",
    t_value >= qt(0.95, df = 1000) ~ "established with a strong"
  )
}

get_whole_pi_txt <- function(results) {
  whole_pi_t <- results$whole_profits_test[[1]][type_short == "ovg", t]

  if (whole_pi_t > qt(0.95, df = 1000)) {
    text_summary <- "The data and model provide a high degree of statistical confidence in this result"
  } else if (whole_pi_t > qt(0.85, df = 1000)) {
    text_summary <- "The data and model provide a moderate degree of statistical confidence in this result"
  } else if (whole_pi_t > qt(0.75, df = 1000)) {
    text_summary <- "The data and model provide an only limited  degree of statistical confidence in this result"
  } else {
    text_summary <- "But, the data and model provide a low degree of statistical confidence in this result"
  }

  return(text_summary)
}


get_td_text <- function(input_type, gc_type, locally_run = FALSE) {
  td_rmd_file <- "Report/ri03_trial_design.Rmd"

  td_rmd <- read_rmd(td_rmd_file, locally_run = locally_run)

  if (gc_type == "Rx") {
    grower_plan_text <- "follow the commercial prescription depicted
      in the first panel of figure \\\\@ref(fig:mix-figures)"
  } else if (gc_type == "uniform") {
    grower_plan_text <- "apply _gc_rate_here_ _unit_here_ per acre
      uniformly across the field. `r length(unique(trial_design$tgti))`
      experimental _input_full_name_l_ rates were assigned randomly and in
      roughly equal number to plots"
  }

  td_rmd <- gsub("_grower-plan-here_", grower_plan_text, td_rmd)

  return(td_rmd)
}

prepare_e02_rmd <- function(input_type, use_td = FALSE, data_file, input_form, input_id, reporting_unit, input_unit, machine_width) {
  if (!use_td) {
    return_rmd <-
      read_rmd("DataProcessing/e02_process_as_applied_base.Rmd", locally_run = TRUE) %>%
      gsub("input_type_here", input_type, .) %>%
      gsub(
        "as-applied-file-name-here",
        paste0("as-applied-", tolower(input_type)),
        .
      ) %>%
      gsub("data_file_name_here", paste0(data_file, ".shp"), .) %>%
      gsub("input_form_here", input_form, .) %>%
      gsub("input_id_here", input_id, .) %>%
      gsub("reporting_unit_here", reporting_unit, .) %>%
      gsub("input_unit_here", input_unit, .) %>%
      gsub("machine_width_here", machine_width, .)
  } else {
    return_rmd <-
      read_rmd("DataProcessing/e02_use_td.Rmd", locally_run = TRUE) %>%
      gsub("input_type_here", input_type, .)
  }

  return(return_rmd)
}

get_input <- function(opt_gc_data, c_type, w_zone) {
  opt_gc_data[type == c_type & zone_txt == paste0("Zone ", w_zone), input_rate] %>% round(digits = 0)
}

# /*=================================================*/
#' # Extract input information from field data
# /*=================================================*/

get_trial_parameter <- function(ffy_w) {


  #--- field data ---#
  field_data <-
    jsonlite::fromJSON(
      here("Data/CommonData/metadata.json"),
      flatten = TRUE
    ) %>%
    data.table() %>%
    .[, farm_field := paste(farm, field, sep = "_")] %>%
    .[, field_year := paste(farm_field, year, sep = "_")]

  #--- get field parameters for the field-year ---#
  w_field_data <- field_data[field_year == ffy_w, ]
  
  w_farm_field <- w_field_data$farm_field
  w_year <- w_field_data$year

  # === Input data ===#
  input_data <-
    w_field_data$input_data[[1]]$data %>%
    rbindlist(fill = TRUE) %>%
    .[, input_id := 1:.N]

  # === Rx data ===#
  rx_exists <- w_field_data$Rx_data[[1]] %>% nrow()

  if (!is.null(rx_exists)) {
    rx_data <-
      w_field_data$Rx_data[[1]]$data %>%
      rbindlist(fill = TRUE)
  } else {
    rx_data <- NA
  }

  # === External data ===#
  ex_exists <- w_field_data$Ex_data[[1]] %>% nrow()

  if (!is.null(ex_exists)) {
    ex_data <-
      w_field_data$Ex_data[[1]]$data %>%
      rbindlist(fill = TRUE)
  } else {
    ex_data <- NA
  }

  # /*----------------------------------*/
  #' ## Crop information
  # /*----------------------------------*/
  crop <- w_field_data[, crop]
  crop_unit <- w_field_data[, crop_unit]
  # crop_price <- as.numeric(w_field_data[, crop_price])
  # if(is.na(crop_price) == TRUE) {
  #   print("Crop price is either missing in the metadata or the value provided is not valid. Using the default value.")
  #   crop_price <- case_when(
  #     crop == "soy" ~ 14, # $/bu
  #     crop == "corn" ~ 5.5, # $/bu
  #     crop == "cotton" ~ 0.93 * 480, # $/bales
  #   )
  # }

  land_unit <- w_field_data[, land_unit]
  reporting_unit <- w_field_data[, reporting_unit]
  harvester_width <- w_field_data[, h_width][[1]]

  # /*=================================================*/
  #' # Input information
  # /*=================================================*/
  n_var_ls <- c(
    "NH3", "UREA46", "UAN32", "UAN28", "1_2_1(36)", "LAN(26)", "MAP", "UAN32mix",
    "1_0_0", "1_0_1", "2_3_2(22)", "15_10_6", "3_0_1", "2_3_4(32)",
    "4_3_4(33)", "5_1_5", "Sp"
  )

  input_data_trial <-
    input_data[
      strategy == "trial",
      .(form, input_id, machine_width, unit, file_name, Rx_data, var_name_prefix, date)
    ] %>%
    .[, input_type := NA] %>%
    .[, input_type := ifelse(form == "seed", "S", input_type)] %>%
    .[, input_type := ifelse(form %in% n_var_ls, "N", input_type)] %>%
    .[, reporting_unit := w_field_data$reporting_unit]

  # /*~~~~~~~~~~~~~~~~~~~~~~*/
  #' ### Base nitrogen
  # /*~~~~~~~~~~~~~~~~~~~~~~*/
  is_base_N <- "base" %in% input_data[, strategy]

  if (is_base_N) {
    n_base_rate <-
      input_data[strategy == "base", ] %>%
      rowwise() %>%
      mutate(
        n_equiv_rate = convert_N_unit(
          form = form,
          unit = unit,
          rate = rate,
          reporting_unit = reporting_unit
        )
      ) %>%
      data.table()

    n_wide <-
      n_base_rate %>%
      .[, date := gsub("/", "-", date)] %>%
      .[, product_name := paste0("base_", product, "_", date)] %>%
      .[, .(product_name, n_equiv_rate)] %>%
      .[, id := 1:.N] %>%
      dcast(. ~ product_name, value.var = "n_equiv_rate") %>%
      .[, `.` := NULL]

    n_total <- n_base_rate[, sum(n_equiv_rate)]
  } else {
    n_base_rate <- 0
    n_wide <- data.table(base = 0)
    n_total <- 0
  }

  return(list(
    crop = crop,
    year = w_year,
    n_base_data = list(n_indiv = n_wide, n_total = n_total),
    yield_data = w_field_data$yield_data,
    tr_design_data = w_field_data$tr_data,
    input_data_trial = input_data_trial,
    rx_data = rx_data,
    ex_data = ex_data
  ))
}
