## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----eval=FALSE, echo=TRUE----------------------------------------------------
#  library(tidyverse)
#  library(sassy)
#  
#  # Prepare Log -------------------------------------------------------------
#  
#  options("logr.autolog" = TRUE,
#          "logr.on" = TRUE,
#          "logr.notes" = FALSE)
#  
#  # Get path to temp directory
#  tmp <- tempdir()
#  
#  # Get sample data directory
#  dir <- system.file("extdata", package = "sassy")
#  
#  # Open log
#  lf <- log_open(file.path(tmp, "example11.log"))
#  
#  
#  # Prepare formats ---------------------------------------------------------
#  
#  sep("Prepare formats")
#  
#  fc <- fcat(SEX = c("M" = "Male", "F" = "Female"),
#             AGE = "%d Years",
#             RACE = value(condition(x == "WHITE", "White"),
#                          condition(x == "BLACK OR AFRICAN AMERICAN", "Black or African American"),
#                          condition(x == "ASIAN OR PACIFIC ISLANDER", "Asian or Pacific Islander"),
#                          condition(TRUE, "Other")),
#             WEIGHT = "%6.2f kg",
#             EAR = c("L" = "Left", "R" = "Right"),
#             DOSE = "%4.2fug",
#             ETHNIC = value(condition(x == "NOT HISPANIC OR LATINO", "Not Hispanic or Latino"),
#                            condition(x == "HISPANIC OR LATINO", "Hispanic or Latino"),
#                            condition(TRUE, "Unknown")),
#             ARMT = value(condition(x == "ARM A", "Placebo"),
#                          condition(x == "ARM B", "Drug 50mg"),
#                          condition(x == "ARM C", "Drug 100mg"),
#                          condition(x == "ARM D", "Competitor"),
#                          condition(TRUE, "Not Treated/Screen Failure")),
#             UNITS = value(condition(x ==  "BEATS/MIN", "bpm"),
#                           condition(x == "BREATHS/MIN", "brths/min"),
#                           condition(x == "C", symbol("degC")),
#                           condition(x == "mmHg", "")),
#             VISIT = value(condition(x == "DAY 1", "Day 1"),
#                           condition(x == "WEEK 2", "Week 2"),
#                           condition(x == "WEEK 4", "Week 4"),
#                           condition(x == "WEEK 6", "Week 6"),
#                           condition(x == "WEEK 8", "Week 8"),
#                           condition(x == "WEEK 12", "Week 12"),
#                           condition(x == "WEEK 16", "Week 16"),
#                           condition(TRUE, "Early Termination"))
#  )
#  
#  # Prepare Data ------------------------------------------------------------
#  
#  sep("Prepare Data")
#  
#  libname(sdtm, dir, "csv")
#  
#  lib_load(sdtm)
#  
#  put("Format desired vital signs")
#  datastep(sdtm.VS,
#           keep = v(USUBJID, VSTESTCD, VSCOMB, VISITNUM, VISIT),
#           where = expression(VSTESTCD != 'HEIGHT' & VISITNUM > 0),
#           {
#  
#             if (VSORRESU == "C")
#               VSCOMB <- paste0(VSORRES, fapply(VSORRESU, fc$UNITS))
#             else
#               VSCOMB <- paste(VSORRES, fapply(VSORRESU, fc$UNITS))
#           }) -> vso
#  
#  put("Pivot vitals signs")
#  vsot <- vso |>
#    group_by(USUBJID, VISITNUM, VISIT) |>
#    pivot_wider(names_from = VSTESTCD,
#                values_from = VSCOMB) |>
#    ungroup() |>
#    arrange(USUBJID, VISITNUM) |> put()
#  
#  
#  put("Assign and apply formats")
#  formats(sdtm.DM) <- fc
#  dmf <- fdata(sdtm.DM) |> put()
#  
#  put("Prepare final data for reporting")
#  datastep(dmf, format = fc,
#           by = USUBJID,
#           retain = list(PTCNT = 0, PG = 1),
#           merge = vsot, merge_by = USUBJID,
#           {
#  
#             # Combine subject info into label row
#             BASELINE <- paste0(USUBJID, ", Site=", SITEID,
#                                ", Age=", AGE, ", Sex=", SEX, ", Race=", RACE,
#                                ", Ethnic=", ETHNIC)
#  
#             # Deal with non-recorded blood pressure
#             if (is.na(DIABP))
#               DIABP <- "-"
#  
#             if (is.na(SYSBP))
#               SYSBP <- "-"
#  
#             # Combine distolic and systolic in one column
#             BP <- paste0(trimws(DIABP), "/", trimws(SYSBP), " mmHg")
#  
#             # Format treatment group
#             if (first.)
#               TREATMENT <- fapply(ARM, fc$ARMT)
#             else
#               TREATMENT <- ""
#  
#             # Count up patients
#             if (first.) {
#               PTCNT <- PTCNT + 1
#             }
#  
#             # Create paging variable with 3 patients per page
#             if (PTCNT == 4) {
#  
#               PTCNT <- 1
#               PG <- PG + 1
#             }
#  
#           }) -> final
#  
#  
#  # Create report -----------------------------------------------------------
#  
#  sep("Create and Print Report")
#  
#  tbl <- create_table(final, show_cols = "none",
#                      width = 9, first_row_blank = FALSE,
#                      header_bold = TRUE) |>
#    column_defaults(from = "VISIT", to = "BP", width = 1.25) |>
#    stub(v(BASELINE, TREATMENT), label = "Subject/Treatment") |>
#    define(BASELINE, label_row = TRUE) |>
#    define(TREATMENT) |>
#    define(VISIT, label = "Visit") |>
#    define(TEMP, label = "Temperature") |>
#    define(PULSE, label = "Pulse") |>
#    define(RESP, label = "Respirations") |>
#    define(BP, label = "Blood Pressure") |>
#    define(USUBJID, blank_after = TRUE, visible = FALSE) |>
#    define(PG, page_break = TRUE, visible = FALSE)
#  
#  rpt <- create_report(file.path(tmp, "example11"), font = "Courier", font_size = 9) |>
#    add_content(tbl) |>
#    set_margins(top = 1, bottom = 1) |>
#    page_header("Program:" %p% Sys.path(), right = "Draft", width = 7) |>
#    titles( "Study: ABC", "Appendix 10.2.6.1.2.1", "Source: DM, VS",
#            columns = 3, header = TRUE, blank_row = "none") |>
#    titles("Subject Listing with Vital Signs by Visit{supsc('1')}",
#           "All Randomized Patients", align = "center", header = TRUE, blank_row = "below") |>
#    footnotes("{supsc('1')} Baseline through completion of study or early termination.",
#              "Values flagged with {symbol('dagger')} were excluded from the by-visit " %p%
#                "analysis in tables showing the qualitative test results.",
#              blank_row = "none", footer = TRUE) |>
#    page_footer("Date: " %p% toupper(fapply(Sys.time(), "%d%b%Y %H:%M:%S")),
#                "Archytas", "Page [pg] of [tpg]")
#  
#  # Generate both RTF and PDF with same report object
#  res1 <- write_report(rpt, output_type = "RTF")
#  res2 <- write_report(rpt, output_type = "PDF")
#  
#  
#  # Uncomment to show reports
#  # file.show(res1$modified_path)
#  # file.show(res2$modified_path)
#  
#  # Uncomment to show log
#  # file.show(lf)
#  
#  
#  # Clean Up ----------------------------------------------------------------
#  
#  lib_unload(sdtm)
#  
#  log_close()
#  

