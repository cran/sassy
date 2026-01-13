## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----eval=FALSE, echo=TRUE----------------------------------------------------
#  library(sassy)
#  library(ggplot2)
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
#  # Prepare Data ------------------------------------------------------------
#  
#  sep("Prepare Data")
#  
#  put("Load data files")
#  libname(dat, pkg, "csv", filter = c("DM", "VS"))
#  
#  
#  put("Prepare factor levels")
#  visit_levels <- c("SCREENING", "DAY 1",   "WEEK 2",  "WEEK 4",  "WEEK 6",
#                    "WEEK 8",  "WEEK 12", "WEEK 16") |> put()
#  
#  arm_levels <- c("ARM A", "ARM B") |> put()
#  
#  test_codes <- c("SYSBP", "DIABP", "PULSE", "RESP") |> put()
#  
#  put("Prepare data for analysis")
#  datastep(dat$DM, merge = dat$VS, merge_by = v(STUDYID, USUBJID),
#           keep = v(STUDYID, USUBJID, ARM, VISIT, VSTESTCD, VSORRES),
#           merge_in = v(inDM, inVS),
#           where = expression(VISIT != "END OF STUDY EARLY TERMINATION" &
#                              ARM %in% c("ARM A", "ARM B") &
#                              VSTESTCD %in% test_codes
#                              ),
#           {
#  
#             # Assign factors to VISIT and ARM
#             VISIT <- factor(VISIT, levels = visit_levels)
#             ARM <- factor(ARM, levels = arm_levels)
#             VSTESTCD <- factor(VSTESTCD, levels = test_codes)
#  
#             if (!inDM & inVS) {
#               delete()
#             }
#  
#           }) -> vitals
#  
#  
#  # Create Plot -------------------------------------------------------------
#  
#  sep("Create Plot")
#  
#  put("Assign Colors")
#  arm_cols <- c("ARM B" = "#1f77b4", "ARM A" = "#2f2f2f")
#  
#  put("Define Boxplot")
#  p_box <- ggplot2::ggplot(
#    vitals,
#    ggplot2::aes(x = VISIT, y = VSORRES, fill = ARM, colour = ARM)
#  ) +
#    ggplot2::geom_boxplot(
#      position = ggplot2::position_dodge(width = 0.75),
#      width = 0.6,
#      outlier.size = 0.7,
#      alpha = 0.9
#    ) +
#    ggplot2::scale_fill_manual(values = arm_cols) +
#    ggplot2::scale_colour_manual(values = arm_cols) +
#    ggplot2::labs(
#      x = NULL,
#      y = "Lab Value",
#      fill = NULL,
#      colour = NULL
#    ) +
#    ggplot2::theme_bw(base_size = 10) +
#    ggplot2::theme(
#      legend.position = "bottom",
#      panel.grid.major.x = ggplot2::element_blank(),
#      plot.title = ggplot2::element_text(face = "bold", hjust = 0),
#      plot.caption = ggplot2::element_text(hjust = 0)
#    )
#  
#  put("Create format for lab codes")
#  lbfmt <- value(condition(x == "SYSBP", "Systolic Blood Pressure (mmHg)"),
#                 condition(x == "DIABP", "Diastolic Blood Pressure (mmHg)"),
#                 condition(x == "PULSE", "Pulse (bpm)"),
#                 condition(x == "RESP", "Respirations (bpm)"))
#  
#  
#  # Report ------------------------------------------------------------------
#  
#  sep("Report")
#  
#  put("Create plot object definition")
#  plt <- create_plot(p_box, height = 4, width = 7, borders = "outside") |>
#    titles("Figure 10. Box Plot: Median and Interquartile Range of Vital Signs by Treatment Arm",
#           bold = TRUE, font_size = 12, align = "left") |>
#    page_by(VSTESTCD, label = "Lab Test: ", format = lbfmt, blank_row = "none") |>
#    footnotes(
#      "Source: example6.rtf. {version$version.string}",
#      "Note: Boxes span the interquartile range (25th to 75th percentile); horizontal line = median;",
#      "whiskers = 1.5×IQR; individual outliers are those beyond this range.",
#      font_size = 9, italics = TRUE, blank_row = "none"
#    )
#  
#  put("Create report output path")
#  pth <- file.path(tempdir(), "example6.rtf")
#  
#  put("Create report")
#  rpt <- create_report(pth, font = "Arial", font_size = 10, output_type = "RTF") |>
#    page_header("Sponsor: Company", right = "Study: ABC", blank_row = "below") |>
#    add_content(plt) |>
#    page_footer("Date Produced: {fapply(Sys.Date(), 'date7')}", right = "Page [pg] of [tpg]")
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
#  

