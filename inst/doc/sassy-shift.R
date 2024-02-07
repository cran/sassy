## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----eval=FALSE, echo=TRUE----------------------------------------------------
#  library(sassy)
#  
#  options("logr.notes" = FALSE,
#          "logr.autolog" = TRUE,
#          "procs.print" = FALSE)
#  
#  # Get temp location for log and report output
#  tmp <- tempdir()
#  
#  lf <- log_open(file.path(tmp, "example16.log"))
#  
#  
#  # Get data ----------------------------------------------------------------
#  
#  sep("Get data")
#  
#  # Get sample data path
#  pth <- system.file("extdata", package = "sassy")
#  
#  put("Open data library")
#  #libname(sdtm, pth, "csv")
#  libname(sdtm, "./data/abc/SDTM", "csv")
#  
#  
#  # Create Formats ----------------------------------------------------------
#  
#  sep("Create Formats")
#  
#  put("Format for visits")
#  vfmt <- value(condition(x == "DAY 1", "Day 1"),
#                condition(x == "WEEK 2", "Week 2"),
#                condition(x == "WEEK 6", "Week 6"),
#                condition(x == "WEEK 12", "Week 12"),
#                as.factor = TRUE)
#  
#  put("Format for ARMs")
#  afmt <- value(condition(x == "ARM A", "Placebo"),
#                condition(x == "ARM B", "Drug (10mg)"),
#                condition(x == "ARM C", "Drug (20mg)"),
#                condition(x == "ARM D", "Competitor"),
#                as.factor = TRUE)
#  
#  put("Format for Lab Result Indicator")
#  rfmt <- value(condition(x == "LOW", "Low"),
#                condition(x == "NORMAL", "Normal"),
#                condition(x == "HIGH", "High"),
#                condition(x == "UNKNOWN", "Unknown"),
#                as.factor = TRUE)
#  
#  
#  # Prepare data ------------------------------------------------------------
#  
#  sep("Prepare data")
#  
#  put("Pull out needed visits and columns")
#  lbsub1 <- subset(sdtm$LB, VISIT %in% toupper(levels(vfmt)),
#                   v(USUBJID, VISIT, VISITNUM, LBCAT, LBORRESU, LBTEST,
#                     LBTESTCD, LBBLFL, LBNRIND)) |> put()
#  
#  put("Pull out baseline subset")
#  lbsub2 <- subset(lbsub1, LBBLFL == 'Y',
#                   v(USUBJID, VISIT, LBCAT, LBTESTCD, LBNRIND)) |> put()
#  
#  put("Merge and append change from baseline")
#  datastep(lbsub1, merge = lbsub2, merge_by = v(USUBJID, LBCAT, LBTESTCD),
#           rename = v(LBNRIND.1 = LBNRIND, LBNRIND.2 = BLBNRIND, VISIT.1 = VISIT),
#           drop = VISIT.2, {
#  
#             if (is.na(LBNRIND.1)) {
#  
#               LBNRIND.1 <- "UNKNOWN"
#             }
#  
#             if (is.na(LBNRIND.2)) {
#  
#               LBNRIND.2 <- "UNKNOWN"
#             }
#  
#           }) -> lbsub
#  
#  put("Pull needed ARMs and columns for DM")
#  dmsub <- subset(sdtm$DM, ARM != "SCREEN FAILURE" & is.na(ARM) == FALSE,
#                  v(USUBJID, ARMCD, ARM)) |> put()
#  
#  put("Merge DM with LB to get subject treatments")
#  datastep(lbsub, merge = dmsub, merge_by = USUBJID,
#           where = expression(toupper(VISIT) != 'SCREENING'),
#           {
#             VISIT <- fapply(VISIT, vfmt)
#           }) -> lbdat
#  
#  
#  # Get population counts ---------------------------------------------------
#  
#  sep("Get population counts")
#  
#  proc_sort(lbdat, by = v(ARM, USUBJID),
#            keep = v(ARM, USUBJID),
#            options = nodupkey) -> lb_unique
#  
#  
#  put("Get population frequencies")
#  proc_freq(lb_unique, tables = ARM,
#            output = long,
#            options = v(nopercent, nonobs)) -> lb_pop
#  
#  
#  # Prepare lab test labels -------------------------------------------------
#  
#  sep("Lab test labels")
#  
#  put("Get lookup data for lab tests")
#  proc_sort(lbdat, by = v(LBTESTCD, LBTEST, LBORRESU),
#            keep = v(LBTESTCD, LBTEST, LBORRESU),
#            options = nodupkey) -> tcodes
#  
#  put("Create test label with units")
#  datastep(tcodes, where = expression(is.na(LBORRESU) == FALSE),
#           keep = v(LBTESTCD, LABEL),
#           {
#  
#             LABEL <- paste0(LBTEST, " (", LBORRESU, ")")
#  
#           }) -> tfmtdat
#  
#  put("Create lab value lookup")
#  tfmt <- tfmtdat$LABEL
#  names(tfmt) <- tfmtdat$LBTESTCD
#  
#  
#  # Calculate frequencies ----------------------------------------------------
#  
#  sep("Calculate frequencies")
#  
#  put("Apply formats")
#  lbdat$LBNRIND <- fapply(lbdat$LBNRIND, rfmt)
#  lbdat$BLBNRIND <- fapply(lbdat$BLBNRIND, rfmt)
#  
#  put("Get freqs by ARM and visit")
#  proc_freq(lbdat, by = v(ARM, LBTESTCD, VISIT),
#            tables = LBNRIND * BLBNRIND) -> lb_freq
#  
#  put("Combine frequencies and percents")
#  datastep(lb_freq,
#           drop = v(VAR1, VAR2, CNT, PCT),
#           {
#             if (CNT == 0) {
#               CNTPCT <- fapply(CNT, "%d", width = 10, justify = "left")
#             } else {
#               CNTPCT <- fapply2(CNT, PCT, "%d", "(%5.1f%%)")
#             }
#           }) -> lb_comb
#  
#  
#  put("Transpose ARMs")
#  proc_transpose(lb_comb, id = v(BY1, CAT2), copy = N,
#                 by = v(BY2, BY3, CAT1), var = CNTPCT,
#                 options = noname) -> lb_final
#  
#  put("Apply formats")
#  lb_final$BY2 <- fapply(lb_final$BY2, tfmt)
#  
#  put("Rename variables")
#  datastep(lb_final,
#           rename = c(BY2 = "LBTEST", BY3 = "VISIT", CAT1 = "RIND"),
#           {}) -> lb_final
#  
#  put("Sort by lab test")
#  proc_sort(lb_final, by = v(LBTEST, VISIT)) -> lb_final
#  
#  
#  
#  # Create report -----------------------------------------------------------
#  
#  sep("Create report")
#  
#  put("Create output path")
#  pth <- file.path(tmp, "output/example16.pdf") |> put()
#  
#  
#  tbl <- create_table(lb_final) |>
#    spanning_header(`ARM A.Low`, `ARM A.Unknown`, "Placebo", n = lb_pop["ARM A"]) |>
#    spanning_header(`ARM B.Low`, `ARM B.Unknown`, "Drug 10mg", n = lb_pop["ARM B"]) |>
#    spanning_header(`ARM C.Low`, `ARM C.Unknown`, "Drug 20mg", n = lb_pop["ARM C"]) |>
#    spanning_header(`ARM D.Low`, `ARM D.Unknown`, "Competitor", n = lb_pop["ARM D"]) |>
#    define(LBTEST, visible = FALSE) |>
#    define(VISIT, "Visit", format = vfmt, dedupe = TRUE, align = "left",
#           id_var = TRUE, blank_after = TRUE) |>
#    define(N, "n", visible = FALSE) |>
#    define(RIND, "", align = "left", id_var = TRUE) |>
#    define(`ARM A.Low`, "Low") |>
#    define(`ARM A.Normal`, "Normal") |>
#    define(`ARM A.High`, "High") |>
#    define(`ARM A.Unknown`, "Unknown") |>
#    define(`ARM B.Low`, "Low") |>
#    define(`ARM B.Normal`, "Normal") |>
#    define(`ARM B.High`, "High") |>
#    define(`ARM B.Unknown`, "Unknown") |>
#    define(`ARM C.Low`, "Low", page_wrap = TRUE) |>
#    define(`ARM C.Normal`, "Normal") |>
#    define(`ARM C.High`, "High") |>
#    define(`ARM C.Unknown`, "Unknown") |>
#    define(`ARM D.Low`, "Low") |>
#    define(`ARM D.Normal`, "Normal") |>
#    define(`ARM D.High`, "High") |>
#    define(`ARM D.Unknown`, "Unknown") |>
#  
#  
#    put("Create report")
#  rpt <- create_report(pth, output_type = "PDF",
#                       font = "Courier", font_size = 9) |>
#    set_margins(top = 1, left = 1, right = 1, bottom = .5) |>
#    page_header(c("Protocol: ABC 12345-678", "DRUG/INDICATION: Consultopan",
#                  "TLF Version: Final Database Lock (03FEB2024)"),
#                right = c("(Page [pg] of [tpg])", "DATABASE VERSION: 01FEB2024",
#                          "TASK: CSR")) |>
#    titles("Table 4.3.1.1", "", "Shift Table of Laboratory Values - Hematology",
#           "(Safety Population)", blank_row = "below") |>
#    page_by(LBTEST, "Laboratory Value: ") |>
#    add_content(tbl) |>
#    footnotes("PROGRAM/OUTPUT: T_LABSHIFT/T_4_3_1_1_HEM",
#              "DATE (TIME): " %p% toupper(fapply(Sys.time(), "%d%b%Y (%H:%M)")),
#              columns = 2, borders = "top", blank_row = "below") |>
#    footnotes(paste("Note 1: For N(%) of participants, percentages are calculated",
#                    "as the number of participants for each ARM at each visit",
#                    "as the denominator."),
#              "Reference: Listing 2.8.1.1, 2.8.1.2", blank_row = "none")
#  
#  
#  
#  
#  
#  put("Write out report to file system")
#  res <- write_report(rpt)
#  
#  
#  # Clean Up ----------------------------------------------------------------
#  
#  sep("Clean Up")
#  
#  log_close()
#  
#  # View report
#  # file.show(res$modified_path)
#  
#  # View log
#  # file.show(lf)
#  
#  

