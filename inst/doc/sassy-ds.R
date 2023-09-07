## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----eval=FALSE, echo=TRUE----------------------------------------------------
#  library(sassy)
#  library(stringr)
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
#  lf <- log_open(file.path(tmp, "example10.log"))
#  
#  # Get data
#  dir <- system.file("extdata", package = "sassy")
#  
#  
#  
#  # Load and Prepare Data ---------------------------------------------------
#  
#  sep("Prepare Data")
#  
#  put("Define data library")
#  libname(sdtm, dir, "csv")
#  
#  put("Loads data into workspace")
#  lib_load(sdtm)
#  
#  put("Prepare DM data")
#  datastep(sdtm.DM, keep = v(USUBJID, ARM),
#           where = expression(ARM != "SCREEN FAILURE"), {}) -> dm_mod
#  
#  put("Prepare DS data")
#  datastep(sdtm.DS, keep = v(USUBJID, DSTERM, DSDECOD, DSCAT),
#           where = expression(DSCAT != "PROTOCOL MILESTONE"), {}) -> ds_mod
#  
#  put("Join DM with DS to get ARMs on DS")
#  datastep(dm_mod, merge = ds_mod, merge_by = USUBJID, {}) -> dmds
#  
#  put("Change ARM to factor to assist with sparse data")
#  dmds$ARM <- factor(dmds$ARM, levels = c("ARM A", "ARM B", "ARM C", "ARM D"))
#  
#  
#  put("Get ARM population counts")
#  proc_freq(dm_mod, tables = ARM, output = long,
#            options = v(nonobs, nopercent)) -> arm_pop
#  
#  # Prepare formats ---------------------------------------------------------
#  
#  # Completed Study
#  complete_fmt <- value(condition(x == "SUBJECT COMPLETED ALL VISITS AND PROTOCOL REQUIREMENTS",
#                                  str_to_title("SUBJECT COMPLETED ALL VISITS AND PROTOCOL REQUIREMENTS")),
#                        condition(x == "SUBJECT COMPLETED ALL VISITS BUT WITH MAJOR PROTOCOL VIOLATIONS",
#                                  str_to_title("SUBJECT COMPLETED ALL VISITS BUT WITH MAJOR PROTOCOL VIOLATIONS")))
#  
#  # Subject Non-compliance
#  noncomp_fmt <- value(condition(x == "NON-COMPLIANCE WITH STUDY DRUG",
#                                 str_to_title("NON-COMPLIANCE WITH STUDY DRUG")))
#  
#  # Early Termination
#  term_fmt <- value(condition(x == "LACK OF EFFICACY",
#                              str_to_title("LACK OF EFFICACY")),
#                    condition(str_detect(x, "LOST"),
#                              str_to_title("LOST TO FOLLOW UP")),
#                    condition(TRUE, str_to_title("LACK OF EFFICACY")))
#  
#  # Group labels
#  group_fmt <- value(condition(x == "COMPLETED", "Subjects who Completed Study"),
#                     condition(x == "NONCOMPLIANCE", "Subjects terminated due to non-compliance"),
#                     condition(x == "OTHER", "Subjects who terminated early"))
#  
#  
#  # Disposition Groups ------------------------------------------------------
#  
#  put("Create vector of final dataframe columns")
#  cols <- v(group, cat, catseq, `ARM A`, `ARM B`, `ARM C`, `ARM D`) |> put()
#  
#  put("Get group counts")
#  proc_freq(dmds, tables = DSDECOD, by = ARM) |>
#    datastep(keep = v(BY, CAT, CNTPCT), {
#  
#      CNTPCT <- fmt_cnt_pct(CNT, arm_pop[[BY]])
#  
#    }) |>
#    proc_transpose(var = CNTPCT, by = CAT, id = BY) |>
#    datastep(keep = cols,
#      {
#  
#      group <- ifelse(CAT == "NON-COMPLIANCE WITH STUDY DRUG", "NONCOMPLIANCE", CAT)
#      cat = NA
#      catseq = 1
#  
#    }) -> grps
#  
#  
#  # Disposition Subgroups ----------------------------------------------------
#  
#  put("Pull out subjects who completed study.")
#  datastep(dmds, where = expression(DSDECOD == "COMPLETED"),
#           {
#             TERMDECOD <- fapply(DSTERM, complete_fmt)
#  
#           }) |>
#    proc_freq(tables = v(DSDECOD * TERMDECOD), by = ARM) |>
#    datastep(keep = v(BY, CAT1, CAT2, CNTPCT),
#      {
#  
#        CNTPCT <- fmt_cnt_pct(CNT, arm_pop[[BY]])
#  
#      }) |>
#    proc_transpose(var = CNTPCT, by = v(CAT1, CAT2), id = BY) |>
#    datastep(keep = cols,
#      {
#        group = CAT1
#        cat = CAT2
#        catseq = 2
#      }) -> cmplt
#  
#  
#  put("Pull out subjects who were non-compliant")
#  datastep(dmds, where = expression(DSDECOD == "NON-COMPLIANCE WITH STUDY DRUG"),
#           {
#             TERMDECOD <- fapply(DSTERM, noncomp_fmt)
#  
#           }) |>
#    proc_freq(tables = v(DSDECOD * TERMDECOD), by = ARM) |>
#    datastep(keep = v(BY, CAT1, CAT2, CNTPCT),
#             {
#  
#               CNTPCT <- fmt_cnt_pct(CNT, arm_pop[[BY]])
#  
#             }) |>
#    proc_transpose(var = CNTPCT, by = v(CAT1, CAT2), id = BY) |>
#    datastep(keep = cols,
#             {
#               group = "NONCOMPLIANCE"
#               cat = CAT2
#               catseq = 2
#             }) -> noncompl
#  
#  
#  put("Pull out subjects who terminated early")
#  datastep(dmds, where = expression(DSDECOD == "OTHER"),
#           {
#             TERMDECOD <- fapply(DSTERM, term_fmt)
#  
#           }) |>
#    proc_freq(tables = v(DSDECOD * TERMDECOD), by = ARM) |>
#    datastep(keep = v(BY, CAT1, CAT2, CNTPCT),
#             {
#  
#               CNTPCT <- fmt_cnt_pct(CNT, arm_pop[[BY]])
#  
#             }) |>
#    proc_transpose(var = CNTPCT, by = v(CAT1, CAT2), id = BY) |>
#    datastep(keep = cols,
#             {
#               group = "OTHER"
#               cat = CAT2
#               catseq = 2
#             }) -> earlyterm
#  
#  
#  put("Combine blocks into final data frame")
#  datastep(grps, set = list(cmplt, noncompl, earlyterm),
#      {
#        lblind <- ifelse(is.na(cat), TRUE, FALSE)
#      }) |>
#    proc_sort(by = v(group, catseq, cat)) -> final
#  
#  
#  # Report ------------------------------------------------------------------
#  
#  sep("Create and print report")
#  
#  # Create Table
#  tbl <- create_table(final, first_row_blank = TRUE,
#                      borders = "all", width = 8.5, header_bold = TRUE) |>
#    column_defaults(from = `ARM A`, to = `ARM D`,
#                    align = "center", width = 1) |>
#    stub(vars = v(group, cat), "Completion Status",
#         style = cell_style(bold = TRUE, indicator = "lblind")) |>
#    define(group, blank_after = TRUE, dedupe = TRUE,
#           format = group_fmt) |>
#    define(cat, indent = .5) |>
#    define(catseq, visible = FALSE) |>
#    define(`ARM A`, label = "Placebo", n = arm_pop["ARM A"]) |>
#    define(`ARM B`, label = "Drug 50mg", n = arm_pop["ARM B"]) |>
#    define(`ARM C`, label = "Drug 100mg", n = arm_pop["ARM C"]) |>
#    define(`ARM D`, label = "Competitor", n = arm_pop["ARM D"]) |>
#    define(lblind, visible = FALSE) |>
#    titles("Table 5.2.3", "Subject Disposition by Category and Treatment Group",
#           "Safety Population", bold = TRUE, font_size = 11,
#           borders = "outside", blank_row = "none") |>
#    footnotes("Program: DS_Table.R",
#              "NOTE: Denominator based on number of non-missing responses.",
#              borders = "outside", blank_row = "none")
#  
#  pth <- file.path(tmp, "example10.pdf")
#  
#  rpt <- create_report(pth, output_type = "PDF", font = "Arial") |>
#    set_margins(top = 1, bottom = 1) |>
#    add_content(tbl)
#  
#  
#  write_report(rpt)
#  
#  
#  # Clean Up ----------------------------------------------------------------
#  
#  # Unload library from workspace
#  lib_unload(sdtm)
#  
#  # Close log
#  log_close()
#  
#  # Uncomment to view files
#  # file.show(pth)
#  # file.show(lf)
#  

