## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----eval=FALSE, echo=TRUE----------------------------------------------------
#  library(ggplot2)
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
#  lgpth <- log_open(file.path(tmp, "example6.log"))
#  
#  
#  # Prepare Data ------------------------------------------------------------
#  
#  
#  
#  sep("Prepare Data")
#  
#  put("Create libname for csv data")
#  libname(sdtm, pkg, "csv")
#  
#  put("Perform joins and basic filters")
#  datastep(sdtm$DM, merge = sdtm$VS, merge_by = c("USUBJID" = "USUBJID"),
#           keep = v(USUBJID, ARMCD, ARM, VSTESTCD, VSTEST, VSORRES, VISITNUM, VISIT),
#           where = expression(VSTESTCD %in% c("SYSBP", "DIABP", "PULSE", "TEMP", "RESP") &
#                                        ARMCD != "SCRNFAIL"), {}) -> prep
#  
#  put("Change VISIT to factor so it sorts properly")
#  prep$VISIT <- factor(prep$VISIT, levels = c("DAY 1", "WEEK 2", "WEEK 4",
#                                         "WEEK 6","WEEK 8", "WEEK 12",
#                                         "WEEK 16"))
#  put("Group and summarize")
#  proc_means(prep,
#             var = VSORRES,
#             class = v(ARM, VSTEST, VISITNUM, VISIT),
#             options = v(nway, nofreq, notype),
#             stats = mean) |>
#    datastep(where = expression(VISITNUM > 0 & VISITNUM < 20),{}) -> final
#  
#  put("Rename variables for clarity")
#  names(final) <- toupper(labels(final))
#  
#  
#  # Create Plots ------------------------------------------------------------
#  
#  
#  
#  sep("Create plots and print report")
#  
#  put("Create plot")
#  p <- final |>
#    ggplot(mapping = aes(y = MEAN, x = VISIT , group = ARM)) +
#    geom_point(aes(shape = ARM, color = ARM)) +
#    geom_line(aes(linetype = ARM, color = ARM)) +
#    scale_x_discrete(name = "Visit") +
#    scale_y_continuous(name = "Value")
#  
#  
#  # Create Report -----------------------------------------------------------
#  
#  put("Construct output path")
#  pth <- file.path(tmp, "output/example6.rtf")
#  
#  put("Define report object")
#  rpt <- create_report(pth, output_type = "RTF", font = "Arial") |>
#    set_margins(top = 1, bottom = 1) |>
#    page_header("Sponsor: Company", "Study: ABC") |>
#    page_by(VSTEST, "Vital Sign: ", blank_row = "none") |>
#    titles("Figure 1.0", "Vital Signs Change from Baseline",
#           "Safety Population", bold = TRUE) |>
#    add_content(create_plot(p, 4.5, 9)) |>
#    footnotes("R Program: VS_Figure.R") |>
#    page_footer(paste0("Date Produced: ", fapply(Sys.time(), "%d%b%y %H:%M")),
#                right = "Page [pg] of [tpg]")
#  
#  put("Write report to file system")
#  write_report(rpt)
#  
#  put("Close log")
#  log_close()
#  
#  # View report
#  # file.show(pth)
#  
#  # View log
#  # file.show(lgpth)

