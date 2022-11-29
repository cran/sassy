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
#          "logr.notes" = FALSE)
#  
#  # Get path to temp directory
#  tmp <- tempdir()
#  
#  # Get sample data directory
#  dir <- system.file("extdata", package = "sassy")
#  
#  # Open log
#  lgpth <- log_open(file.path(tmp, "example10.log"))
#  
#  
#  # Load and Prepare Data ---------------------------------------------------
#  
#  sep("Prepare Data")
#  
#  # Define data library
#  libname(sdtm, dir, "csv")
#  
#  # Loads data into workspace
#  lib_load(sdtm)
#  
#  # Prepare data
#  dm_mod <- sdtm.DM |>
#    select(USUBJID, ARM) |>
#    filter(ARM != "SCREEN FAILURE") |> put()
#  
#  
#  ds_mod <- sdtm.DS |>
#    select(USUBJID, DSTERM, DSDECOD, DSCAT) |>
#    filter(DSCAT != "PROTOCOL MILESTONE")
#  
#  put("Join DS to DM")
#  dmds <- inner_join(dm_mod, ds_mod)
#  
#  
#  put("Get ARM population counts")
#  arm_pop <- count(dm_mod, ARM) |> deframe() |> put()
#  
#  
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
#  put("Get group counts")
#  grps <- dmds |> select(ARM, DSDECOD) |>
#    group_by(ARM, DSDECOD) |>
#    summarize(n = n()) |>
#    ungroup() |>
#    pivot_wider(names_from = ARM,
#                values_from = n,
#                values_fill = 0) |>
#    transmute(group = ifelse(DSDECOD == "NON-COMPLIANCE WITH STUDY DRUG", "NONCOMPLIANCE", DSDECOD),
#              cat = NA,
#              catseq = 1,
#              `ARM A` = fmt_cnt_pct(`ARM A`, arm_pop["ARM A"]),
#              `ARM B` = fmt_cnt_pct(`ARM B`, arm_pop["ARM B"]),
#              `ARM C` = fmt_cnt_pct(`ARM C`, arm_pop["ARM C"]),
#              `ARM D` = fmt_cnt_pct(`ARM D`, arm_pop["ARM D"])) |> put()
#  
#  
#  
#  # Disposition Subgroups ----------------------------------------------------
#  
#  put("Pull out subjects who completed study.")
#  cmplt <- dmds |> filter(DSDECOD == "COMPLETED") |>
#    mutate(TERMDECOD = fapply(DSTERM, complete_fmt)) |>
#    group_by(ARM, DSDECOD, TERMDECOD) |>
#    summarize(n = n()) |>
#    ungroup() |>
#    pivot_wider(names_from = ARM,
#                values_from = n,
#                values_fill = 0) |>
#    transmute(group = "COMPLETED",
#              cat = TERMDECOD,
#              catseq = 2,
#              `ARM A` = fmt_cnt_pct(`ARM A`, arm_pop["ARM A"]),
#              `ARM B` = fmt_cnt_pct(`ARM B`, arm_pop["ARM B"]),
#              `ARM C` = fmt_cnt_pct(`ARM C`, arm_pop["ARM C"]),
#              `ARM D` = fmt_cnt_pct(`ARM D`, arm_pop["ARM D"])) |> put()
#  
#  
#  put("Pull out subjects who were non-compliant")
#  noncompl1 <- dmds |> filter(DSDECOD == "NON-COMPLIANCE WITH STUDY DRUG") |>
#    mutate(TERMDECOD = fapply(DSTERM, noncomp_fmt)) |>
#    group_by(ARM, DSDECOD, TERMDECOD) |>
#    summarize(n = n()) |>
#    ungroup() |>
#    pivot_wider(names_from = ARM,
#                values_from = n,
#                values_fill = 0)
#  
#  nms <- names(noncompl1)
#  
#  noncompl2 <- noncompl1 |>
#    transmute(group = "NONCOMPLIANCE",
#              cat = TERMDECOD,
#              catseq = 2,
#              `ARM A` = ifelse("ARM A" %in% nms, fmt_cnt_pct(`ARM A`, arm_pop["ARM A"]), "0 (  0.0%)"),
#              `ARM B` = ifelse("ARM B" %in% nms, fmt_cnt_pct(`ARM B`, arm_pop["ARM B"]), "0 (  0.0%)"),
#              `ARM C` = ifelse("ARM C" %in% nms, fmt_cnt_pct(`ARM C`, arm_pop["ARM C"]), "0 (  0.0%)"),
#              `ARM D` = ifelse("ARM D" %in% nms, fmt_cnt_pct(`ARM D`, arm_pop["ARM D"]), "0 (  0.0%)")) |> put()
#  
#  put("Pull out subjects who terminated early")
#  earlyterm <- dmds |> filter(DSDECOD == "OTHER") |>
#    mutate(TERMDECOD = fapply(DSTERM, term_fmt)) |>
#    group_by(ARM, DSDECOD, TERMDECOD) |>
#    summarize(n = n()) |>
#    ungroup() |>
#    pivot_wider(names_from = ARM,
#                values_from = n,
#                values_fill = 0) |>
#    transmute(group = "OTHER",
#              cat = TERMDECOD,
#              catseq = 2,
#              `ARM A` = fmt_cnt_pct(`ARM A`, arm_pop["ARM A"]),
#              `ARM B` = fmt_cnt_pct(`ARM B`, arm_pop["ARM B"]),
#              `ARM C` = fmt_cnt_pct(`ARM C`, arm_pop["ARM C"]),
#              `ARM D` = fmt_cnt_pct(`ARM D`, arm_pop["ARM D"])) |> put()
#  
#  put("Combine blocks into final data frame")
#  final <- bind_rows(grps, cmplt, noncompl2, earlyterm) |>
#    arrange(group, catseq, cat) |>
#    mutate(lblind = ifelse(is.na(cat), TRUE, FALSE)) |> put()
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
#            "NOTE: Denominator based on number of non-missing responses.",
#            borders = "outside", blank_row = "none")
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
#  # file.show(lgpth)

