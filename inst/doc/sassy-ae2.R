## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----eval=FALSE, echo=TRUE----------------------------------------------------
#  library(sassy)
#  
#  options("logr.autolog" = TRUE,
#          "logr.notes" = FALSE,
#          "logr.on" = TRUE,
#          "procs.print" = FALSE)
#  
#  # Get temp directory
#  tmp <- tempdir()
#  
#  # Open log
#  lf <- log_open(file.path(tmp, "example14.log"))
#  
#  # Get data
#  dir <- system.file("extdata", package = "sassy")
#  
#  
#  # Get Data ----------------------------------------------------------------
#  
#  sep("Prepare Data")
#  
#  # Create libname for csv data
#  libname(sdtm, dir, "csv", quiet = TRUE)
#  
#  put("Filter DM data")
#  datastep(sdtm$DM,
#           keep = v(USUBJID, ARM, ARMCD),
#           where = expression(ARM != "SCREEN FAILURE"), {}) -> dm
#  
#  put("Get population counts")
#  proc_freq(dm, tables = ARM,
#            output = long,
#            options = v(nopercent, nonobs)) -> arm_pop
#  
#  
#  put("Prepare table data")
#  datastep(sdtm$AE, merge = dm,
#           merge_by = "USUBJID",
#           merge_in = v(inA, inB),
#           keep = v(USUBJID, ARM, AESEV, AESOC, AEDECOD),
#           where = expression(inB == 1 & inA != 0),
#           {}) -> ae_sub
#  
#  
#  # Prepare Formats ---------------------------------------------------------
#  
#  sep("Prepare Formats")
#  fc <- fcat(CNT = "%3d",
#             PCT = "(%5.1f)",
#             CAT2 = c(MILD = "Mild",
#                      MODERATE = "Moderate",
#                      SEVERE = "Severe"),
#             SEVN = c(Mild = 1, Moderate = 2, Severe = 3))
#  
#  
#  # Perform Calculations ----------------------------------------------------
#  sep("Perform Calculations")
#  
#  
#  put("Get SOC Frequencies")
#  proc_freq(ae_sub,
#            tables = v(AESOC * AESEV),
#            by = "ARM") -> ae_soc
#  
#  
#  put("Combine columns for SOC")
#  datastep(ae_soc,
#           format = fc,
#           rename = list(VAR1 = "VAR", CAT1 = "CAT"),
#           drop = v(VAR2, CNT, PCT),
#           {
#             VARORD <- 1
#             CNTPCT <- fapply2(CNT, PCT)
#             CAT2 <- fapply(CAT2)
#  
#           }) -> ae_soc_c
#  
#  
#  put("Pivot SOC frequencies")
#  proc_transpose(ae_soc_c, id = v(BY),
#                 var = CNTPCT,
#                 copy = v(VAR, VARORD),
#                 by = v(CAT, CAT2)) |>
#    datastep(rename = c(CAT = "AESOC", CAT2 = "SEVERITY"),
#             drop = "NAME", {
#  
#                 AEDECOD <- NA_character_
#               }) -> ae_soc_t
#  
#  
#  put("Get PT Frequencies")
#  proc_freq(ae_sub,
#            tables = "AEDECOD * AESEV",
#            by = "ARM",
#            options = nonobs) -> ae_pt
#  
#  put("Get unique SOC and PT combinations")
#  proc_sort(ae_sub, keep = v(AESOC, AEDECOD),
#            by = v(AESOC, AEDECOD), options = nodupkey) -> evnts
#  
#  put("Combine columns for PT")
#  datastep(ae_pt,
#           format = fc,
#           rename = list(VAR1 = "VAR", CAT1 = "CAT"),
#           drop = v(VAR2, CNT, PCT),
#           {
#             VARORD <- 2
#             CNTPCT <- fapply2(CNT, PCT)
#             CAT2 <- fapply(CAT2)
#  
#           }) -> ae_pt_c
#  
#  
#  put("Pivot PT frequencies")
#  proc_transpose(ae_pt_c, id = v(BY),
#                 var = CNTPCT,
#                 copy = v(VAR, VARORD),
#                 by = v(CAT, CAT2)) -> ae_pt_t
#  
#  nms <- names(ae_soc_t)
#  
#  
#  
#  put("Join in SOC")
#  datastep(ae_pt_t, merge = evnts, rename = c(CAT2 = "SEVERITY", CAT = "AEDECOD"),
#           merge_by = c(CAT = "AEDECOD"), {
#             CAT <- toTitleCase(tolower(CAT))
#             AESEVN <- fapply(CAT2, fc$SEVN)
#           }) -> ae_pt_tj
#  
#  
#  # All Adverse Events ------------------------------------------------------
#  
#  put("Get frequencies for all events")
#  proc_freq(ae_sub, tables = "AESEV", by = v(ARM)) -> allfreq
#  
#  put("Combine all events.")
#  datastep(allfreq, format = fc,
#           drop = v(N, CNT, PCT, CAT),
#           {
#  
#             CNTPCT <- fapply2(CNT, PCT)
#             SEVERITY <- fapply(CAT, fc$CAT2)
#             VARORD <- 0
#  
#           }) -> allfreqm
#  
#  put("Prepare data for reporting")
#  proc_transpose(allfreqm, id = v(BY),
#                 var = CNTPCT, by = v(SEVERITY),
#                 copy = v(VAR, VARORD)) -> allfreqt
#  
#  put("Clean up")
#  datastep(allfreqt, drop = NAME, {
#  
#    AESOC <- "All Adverse Events"
#    AEDECOD <- "All Preferred Terms "
#  
#  }) -> allfreqtc
#  
#  
#  
#  # Prepare Final Dataframe -------------------------------------------------
#  
#  
#  
#  put("Stack SOC and PT counts")
#  datastep(ae_soc_t, set = list(allfreqtc, ae_pt_tj),
#           keep = c("VAR", "AESOC", "AEDECOD", "SEVERITY", "AESEVN", "VARORD",
#                    find.names(ae_pt_tj, "ARM*")), {
#                      AESEVN <- fapply(SEVERITY, fc$SEVN)
#                      if (is.na(AEDECOD))
#                        AEDECOD <- "All Preferred Terms"
#                      }) -> ae_soc_pt
#  
#  put("Select desired columns")
#  datastep(ae_soc_pt, keep = c("AESOC", "AEDECOD", "AESEVN", "VARORD"),
#           where = expression(AESEVN == 1), {
#  
#  }) -> ae_prep
#  
#  put("Output extra rows")
#  datastep(ae_prep, {
#  
#    AESEVN <- 0
#    output()
#  
#    AESEVN <- -1
#    output()
#  
#  }) -> ae_soc_rows
#  
#  
#  put("Set additonal rows")
#  datastep(ae_soc_pt, set = ae_soc_rows, {}) -> ae_all
#  
#  put("Sort combined rows")
#  aecombined <- proc_sort(ae_all, by = v( AESOC, VARORD, AEDECOD, AESEVN))
#  
#  
#  put("Create stub and paging.")
#  datastep(aecombined, retain = list(PG = 1, RWNM = 0), {
#  
#    if (AESEVN == -1) {
#      VAR <- AESOC
#    } else if (AESEVN == 0) {
#      VAR <- "  " %p% AEDECOD
#    } else {
#      VAR <- "    " %p% SEVERITY
#    }
#  
#    RWNM <- RWNM + 1
#  
#    if (RWNM == 21) {
#      PG <- PG + 1
#      RWNM <- 1
#    }
#  
#  
#  }) -> aefinal
#  
#  
#  # Print Report ----------------------------------------------------------
#  
#  sep("Create and print report")
#  
#  put("Create table object")
#  tbl <- create_table(aefinal, first_row_blank = TRUE, width = 9, show_cols = "none") |>
#    column_defaults(from = `ARM A`, to = `ARM D`, width = 1, align = "center") |>
#    define(VAR, label = "System Organ Class\n  Preferred Term\n    Maximum Grade") |>
#    define(AEDECOD, visible = FALSE, blank_after = TRUE) |>
#    define(`ARM A`, label = "Placebo", n = arm_pop["ARM A"]) |>
#    define(`ARM B`,  label = "Drug A", n = arm_pop["ARM B"]) |>
#    define(`ARM C`, label = "Drug B", n = arm_pop["ARM C"]) |>
#    define(`ARM D`, label = "Drug C", n = arm_pop["ARM D"]) |>
#    define(PG, visible = FALSE, page_break = TRUE)
#  
#  
#  
#  put("Create report object")
#  rpt <- create_report(file.path(tmp, "example14.rtf"), output_type = "RTF",
#                       font_size = 10, font = "Arial") |>
#    page_header(left = c("Sponsor: Company", "Protocol: ABC-123"),
#                right = c("Page [pg] of [tpg]", "Database: 2023-10-01")) |>
#    titles("Table 5.2.4", "Summary of Treatment-Emergent Adverse Events by MedDRA System Organ Class",
#    "Preferred Term, and Maximum Severity", "(Safety Population)", font_size = 12,
#    bold = TRUE, borders = "bottom") |>
#    add_content(tbl) |>
#    footnotes("Program: AE_Table.R",
#              "Confidential", fapply(Sys.time(), "%Y-%m-%d %H:%M:%S"),
#              columns = 3,  borders = "top", blank_row = "none") |>
#    footnotes("Treatment-Emergent AEs: any AE either reported for the first time or " %p%
#                "worsening of a pre-existing event after firstdose of study drug " %p%
#                "until 31 days after the last dose of study drug",
#              "Note: Participants where counted only once under the highest grade; " %p%
#                "TEAEs with missing severity were included under 'Any Grade' only.",
#              "Severity vs CTCAE Grade: Mild = Grade 1, Moderate = Grade 2, " %p%
#                "Severe = Grade 3, Life-Threatening = Grade 4, Fatal = Grade 5.",
#              "MedDRA Version: 23.0", footer = TRUE)
#  
#  put("Print report")
#  res <- write_report(rpt)
#  
#  
#  # Clean Up ----------------------------------------------------------------
#  sep("Clean Up")
#  
#  put("Close log")
#  log_close()
#  
#  
#  # Uncomment to view report
#  # file.show(res$modified_path)
#  
#  # Uncomment to view log
#  # file.show(lf)
#  

