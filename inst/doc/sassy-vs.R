## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----eval=FALSE, echo=TRUE----------------------------------------------------
#  library(tidyverse)
#  library(sassy)
#  
#  options("logr.autolog" = TRUE,
#          "logr.notes" = FALSE)
#  
#  # Get path to temp directory
#  tmp <- tempdir()
#  
#  # Get path to sample data
#  pkg <- system.file("extdata", package = "sassy")
#  
#  # Open log
#  lgpth <- log_open(file.path(tmp, "example5.log"))
#  
#  sep("Prepare Data")
#  
#  # Create libname for csv data
#  libname(sdtm, pkg, "csv")
#  
#  # Load data into workspace
#  lib_load(sdtm)
#  
#  put("Join and prepare data")
#  prep <- sdtm.DM |>
#    left_join(sdtm.VS, by = c("USUBJID" = "USUBJID")) |>
#    select(USUBJID, VSTESTCD, VISIT, VISITNUM, VSSTRESN, ARM, VSBLFL) |>
#    filter(VSTESTCD %in% c("PULSE", "RESP", "TEMP", "DIABP", "SYSBP"),
#           !(VISIT == "SCREENING" & VSBLFL != "Y")) |>
#    arrange(USUBJID, VSTESTCD, VISITNUM) |>
#    group_by(USUBJID, VSTESTCD) |>
#    datastep(retain = list(BSTRESN = 0), {
#  
#      # Combine treatment groups
#      # And distingish baseline time points
#      if (ARM == "ARM A") {
#        if (VSBLFL %eq% "Y") {
#          GRP <- "A_BASE"
#        } else {
#          GRP <- "A_TRT"
#        }
#      } else {
#        if (VSBLFL %eq% "Y") {
#          GRP <- "O_BASE"
#        } else {
#          GRP <- "O_TRT"
#        }
#      }
#  
#      # Populate baseline value
#      if (first.)
#        BSTRESN = VSSTRESN
#  
#    }) |>
#    ungroup() |>
#    put()
#  
#  put("Get population counts")
#  pop_A <- prep |> select(USUBJID, GRP) |> filter(GRP == "A_BASE") |>
#    distinct() |> count() |> deframe() |> put()
#  pop_O <- prep |> select(USUBJID, GRP) |> filter(GRP == "O_BASE") |>
#    distinct() |> count() |> deframe() |> put()
#  
#  put("Prepare final data frame")
#  final <- prep |>
#    select(VSTESTCD, GRP, VSSTRESN, BSTRESN) |>
#    group_by(VSTESTCD, GRP) |>
#    summarize(Mean = fmt_mean_sd(VSSTRESN),
#              Median = fmt_median(VSSTRESN),
#              Quantiles = fmt_quantile_range(VSSTRESN),
#              Range = fmt_range(VSSTRESN)) |>
#    ungroup() |>
#    pivot_longer(cols = c(Mean, Median, Quantiles, Range),
#                 names_to = "stats",
#                 values_to = "values") |>
#    pivot_wider(names_from = GRP,
#                values_from = values) |>
#    put()
#  
#  
#  sep("Create formats")
#  
#  # Vital sign lookup format
#  vs_fmt <- c(PULSE = "Pulse",
#              TEMP = "Temperature °C",
#              RESP = "Respirations/min",
#              SYSBP = "Systolic Blood Pressure",
#              DIABP = "Diastolic Blood Pressure") |>
#    put()
#  
#  # Statistics user-defined format
#  stat_fmt <- value(condition(x == "Mean", "Mean (SD)"),
#                    condition(x == "Quantiles", "Q1 - Q3")) |>
#    put()
#  
#  sep("Create Report")
#  
#  
#  # Apply sort
#  final <- final |>
#    mutate(VSTESTCD = factor(VSTESTCD, levels = names(vs_fmt))) |>
#    arrange(VSTESTCD)
#  
#  # Define table object
#  tbl <- create_table(final, borders = "bottom") |>
#    spanning_header(A_BASE, A_TRT, "Placebo", n = pop_A) |>
#    spanning_header(O_BASE, O_TRT, "Treated", n = pop_O) |>
#    column_defaults(width = 1.25, align = "center") |>
#    stub(c(VSTESTCD, stats), width = 2.5) |>
#    define(VSTESTCD, "Vital Sign", format = vs_fmt,
#           blank_after = TRUE, dedupe = TRUE, label_row = TRUE) |>
#    define(stats, indent = .25, format = stat_fmt) |>
#    define(A_BASE, "Baseline") |>
#    define(A_TRT, "After Treatment") |>
#    define(O_BASE, "Baseline") |>
#    define(O_TRT, "After Treatment")
#  
#  # Construct output path
#  pth <- file.path(tmp, "output/t_vs.pdf")
#  
#  # Define report object
#  rpt <- create_report(pth, output_type = "PDF", font = "Times",
#                       font_size = 11) |>
#    page_header("Sponsor: Company", "Study: ABC") |>
#    titles("Table 4.0", "Selected Vital Signs", bold = TRUE, font_size = 12) |>
#    add_content(tbl, align = "center") |>
#    page_footer(Sys.time(), "CONFIDENTIAL", "Page [pg] of [tpg]")
#  
#  # Write report to file system
#  write_report(rpt)
#  
#  # Unload data from workspace
#  lib_unload(sdtm)
#  
#  # Close log
#  log_close()
#  
#  # View files
#  # file.show(pth)
#  # file.show(lgpth)
#  

