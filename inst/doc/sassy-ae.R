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
#  lf <- log_open(file.path(tmp, "example4.log"))
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
#  # Load data into workspace
#  lib_load(sdtm)
#  
#  put("Filter DM data")
#  datastep(sdtm.DM,
#           keep = v(USUBJID, ARM, ARMCD),
#           where = expression(ARM != "SCREEN FAILURE"), {}) -> dm
#  
#  put("Get population counts")
#  proc_freq(dm, tables = ARM,
#            output = long,
#            options = v(nopercent, nonobs)) -> arm_pop
#  
#  put ("Create lookup for AE severity")
#  sevn <- c(MILD = 1, MODERATE = 2, SEVERE = 3) |> put()
#  
#  put("Prepare table data")
#  datastep(sdtm.AE, merge = dm,
#           merge_by = "USUBJID",
#           merge_in = v(inA, inB),
#           keep = v(USUBJID, ARM, AESEV, AESEVN, AESOC, AEDECOD),
#           where = expression(inB == 1 & inA != 0),
#           {
#             AESEVN <- fapply(AESEV, sevn)
#           }) -> ae_sub
#  
#  
#  # Prepare Formats ---------------------------------------------------------
#  
#  sep("Prepare Formats")
#  fc <- fcat(CNT = "%3d",
#             PCT = "(%5.1f)",
#             CAT2 = c(MILD = "Mild",
#                      MODERATE = "Moderate",
#                      SEVERE = "Severe"))
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
#  proc_transpose(ae_soc_c, id = v(BY, CAT2),
#                 var = CNTPCT,
#                 copy = v(VAR, VARORD),
#                 by = CAT) -> ae_soc_t
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
#  proc_transpose(ae_pt_c, id = v(BY, CAT2),
#                 var = CNTPCT,
#                 copy = v(VAR, VARORD),
#                 by = CAT) -> ae_pt_t
#  
#  nms <- names(ae_soc_t)
#  
#  put("Join in SOC")
#  datastep(ae_pt_t, merge = evnts, rename = c(CAT = "CAT2", AESOC = "CAT"),
#           merge_by = c(CAT = "AEDECOD"), {
#             CAT <- toTitleCase(tolower(CAT))
#           }) -> ae_pt_tj
#  
#  put("Stack SOC and PT counts")
#  datastep(ae_soc_t, set = ae_pt_tj,
#           keep = c("VAR", "CAT", "CAT2", "VARORD",
#                    find.names(ae_pt_tj, "ARM*")), {}) -> ae_soc_pt
#  
#  
#  aefinal <- proc_sort(ae_soc_pt, by = v( CAT, VARORD, CAT2))
#  
#  
#  
#  # All Adverse Events ------------------------------------------------------
#  
#  put("Get frequencies for all events")
#  proc_freq(ae_sub, tables = "AESEV", by = v(ARM)) -> allfreq
#  
#  put("Combine all events.")
#  datastep(allfreq, format = fc,
#           drop = v(N, CNT, PCT),
#           {
#  
#             CNTPCT <- fapply2(CNT, PCT)
#             CAT <- fapply(CAT, fc$CAT2)
#  
#  
#           }) -> allfreqm
#  
#  put("Prepare data for reporting")
#  proc_transpose(allfreqm, id = v(BY, CAT),
#                 var = CNTPCT, copy = VAR, name = CAT) -> allfreqt
#  
#  
#  # Final Data --------------------------------------------------------------
#  
#  
#  sep("Create final data frame")
#  datastep(allfreqt, set = aefinal,
#           keep = names(aefinal),
#           {
#             if (VAR == "AESEV")
#               CAT <- "All Adverse Events"
#  
#           }) -> allfinal
#  
#  # Print Report ----------------------------------------------------------
#  
#  sep("Create and print report")
#  
#  put("Create table object")
#  tbl <- create_table(allfinal, first_row_blank = TRUE, width = 9) |>
#    column_defaults(from = `ARM A.Mild`, to = `ARM D.Severe`, width = 1, align = "center") |>
#    spanning_header("ARM A.Mild", "ARM A.Severe", label = "ARM A", n = arm_pop["ARM A"]) |>
#    spanning_header("ARM B.Mild", "ARM B.Severe", label = "ARM B", n = arm_pop["ARM B"]) |>
#    spanning_header("ARM C.Mild", "ARM C.Severe", label = "ARM C", n = arm_pop["ARM C"]) |>
#    spanning_header("ARM D.Mild", "ARM D.Severe", label = "ARM D", n = arm_pop["ARM D"]) |>
#    stub(vars = c("CAT", "CAT2"), label = "System Organ Class\n   Preferred Term", width = 5) |>
#    define(CAT, blank_after = TRUE) |>
#    define(CAT2, indent = .25) |>
#    define(`ARM A.Mild`, label = "Mild") |>
#    define(`ARM A.Moderate`, label = "Moderate") |>
#    define(`ARM A.Severe`, label = "Severe") |>
#    define(`ARM B.Mild`,  label = "Mild", page_wrap = TRUE) |>
#    define(`ARM B.Moderate`, label = "Moderate") |>
#    define(`ARM B.Severe`, label = "Severe") |>
#    define(`ARM C.Mild`, label = "Mild", page_wrap = TRUE) |>
#    define(`ARM C.Moderate`, label = "Moderate") |>
#    define(`ARM C.Severe`, label = "Severe") |>
#    define(`ARM D.Mild`, label = "Mild", page_wrap = TRUE) |>
#    define(`ARM D.Moderate`,label = "Moderate") |>
#    define(`ARM D.Severe`, label = "Severe") |>
#    define(VAR, visible = FALSE) |>
#    define(VARORD, visible = FALSE)
#  
#  
#  put("Create report object")
#  rpt <- create_report(file.path(tmp, "example4.rtf"), output_type = "RTF", font = "Arial") |>
#    options_fixed(font_size = 10) |>
#    page_header("Sponsor: Company", "Study: ABC") |>
#    titles("Table 5.0", "Adverse Events by Maximum Severity", bold = TRUE) |>
#    add_content(tbl) |>
#    footnotes("Program: AE_Table.R",
#              "Note: Adverse events were coded using MedDRA Version 9.1") |>
#    page_footer(Sys.time(), "Confidential", "Page [pg] of [tpg]")
#  
#  put("Print report")
#  res <- write_report(rpt)
#  
#  
#  # Clean Up ----------------------------------------------------------------
#  sep("Clean Up")
#  
#  put("Remove library from workspace")
#  lib_unload(sdtm)
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

