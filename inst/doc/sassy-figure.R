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
#  lgpth <- log_open(file.path(tmp, "example3.log"))
#  
#  sep("Prepare Data")
#  
#  # Create libname for csv data
#  libname(sdtm, pkg, "csv")
#  
#  # Load data into workspace
#  lib_load(sdtm)
#  
#  put("Perform joins and basic filters")
#  prep <- sdtm.DM %>%
#    left_join(sdtm.VS, by = c("USUBJID" = "USUBJID")) %>%
#    select(USUBJID, ARMCD, ARM, VSTESTCD, VSTEST, VSORRES, VISITNUM, VISIT) %>%
#    filter(VSTESTCD %in% c("SYSBP", "DIABP", "PULSE", "TEMP", "RESP"),
#           ARMCD != "SCRNFAIL") %>% put()
#  
#  put("Group and summarize")
#  final <- prep %>%
#    group_by(ARMCD, ARM, VSTESTCD, VSTEST, VISITNUM, VISIT) %>%
#    summarize(MEAN = mean(VSORRES, na.rm = TRUE)) %>%
#    filter(VISITNUM > 0 & VISITNUM < 20) %>%
#    mutate(VISIT = factor(VISIT, levels = c("DAY 1", "WEEK 2", "WEEK 4",
#                                            "WEEK 6","WEEK 8", "WEEK 12",
#                                            "WEEK 16"))) %>%
#    ungroup() %>% put()
#  
#  
#  sep("Create plots and print report")
#  
#  # Create plot
#  p <- final %>%
#    ggplot(mapping = aes(y = MEAN, x = VISIT , group = ARM)) +
#    geom_point(aes(shape = ARM, color = ARM)) +
#    geom_line(aes(linetype = ARM, color = ARM)) +
#    scale_x_discrete(name = "Visit") +
#    scale_y_continuous(name = "Value")
#  
#  # Construct output path
#  pth <- file.path(tmp, "output/f_vs.rtf")
#  
#  # Define report object
#  rpt <- create_report(pth, output_type = "RTF") %>%
#    set_margins(top = 1, bottom = 1) %>%
#    page_header("Sponsor: Company", "Study: ABC") %>%
#    page_by(VSTEST, "Vital Sign: ", blank_row = "none") %>%
#    titles("Figure 1.0", "Vital Signs Change from Baseline",
#           "Safety Population") %>%
#    add_content(create_plot(p, 4.5, 9)) %>%
#    footnotes("R Program: VS_Figure.R") %>%
#    page_footer(paste0("Date Produced: ", fapply(Sys.time(), "%d%b%y %H:%M")),
#                right = "Page [pg] of [tpg]")
#  
#  # Write report to file system
#  write_report(rpt)
#  
#  # Close log
#  log_close()
#  
#  # View report
#  # file.show(pth)

