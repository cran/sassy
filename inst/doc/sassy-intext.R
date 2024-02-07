## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----eval=FALSE, echo=TRUE----------------------------------------------------
#  library(sassy)
#  
#  # Prepare Log -------------------------------------------------------------
#  
#  
#  options("logr.autolog" = TRUE,
#          "logr.on" = TRUE,
#          "logr.notes" = FALSE,
#          "procs.print" = FALSE)
#  
#  # Get temp directory
#  tmp <- tempdir()
#  
#  # Open log
#  lf <- log_open(file.path(tmp, "example15.log"))
#  
#  
#  # Prepare formats ---------------------------------------------------------
#  
#  sep("Prepare formats")
#  
#  put("Age categories")
#  agecat <- value(condition(is.na(x), "Missing", 5),
#                  condition(x >= 18 & x <= 29, "18 to 29", 1),
#                  condition(x >=30 & x <= 39, "30 to 39", 2),
#                  condition(x >=40 & x <=49, "40 to 49", 3),
#                  condition(x >= 50, ">= 50", 4),
#                  as.factor = TRUE)
#  
#  put("Sex decodes")
#  fmt_sex <- value(condition(is.na(x), "Missing", 4),
#                   condition(x == "M", "Male", 1),
#                   condition(x == "F", "Female", 2),
#                   condition(TRUE, "Other", 3),
#                   as.factor = TRUE)
#  
#  put("Race decodes")
#  fmt_race <- value(condition(is.na(x), "Missing", 5),
#                    condition(x == "WHITE", "White", 1),
#                    condition(x == "BLACK OR AFRICAN AMERICAN", "Black or African American", 2),
#                    condition(x == "ASIAN", "Asian or Pacific Islander", 3),
#                    condition(TRUE, "Unkown", 4),
#                    as.factor = TRUE)
#  
#  put("Ethnic decodes")
#  fmt_ethnic <- value(condition(is.na(x), "Missing", 4),
#                      condition(x == "HISPANIC OR LATINO", "Hispanic or Latino", 1),
#                      condition(x == "NOT HISPANIC OR LATINO", "Not Hispanic or Latino", 2),
#                      condition(x == "UNKNOWN", "Unknown", 3),
#                      as.factor = TRUE)
#  
#  put("ARM decodes")
#  fmt_arm <- value(condition(x == "ARM A", "Placebo"),
#                   condition(x == "ARM B", "Drug 10mg"),
#                   condition(x == "ARM C", "Drug 20mg"),
#                   condition(x == "ARM D", "Competitor"))
#  
#  put("Compile format catalog")
#  fc <- fcat(MEAN = "%.1f", STD = "(%.2f)",
#             Q1 = "%.1f", Q3 = "%.1f",
#             MIN = "%d", MAX = "%d",
#             CNT = "%2d", PCT = "(%5.1f%%)")
#  
#  
#  # Load and Prepare Data ---------------------------------------------------
#  
#  sep("Prepare Data")
#  
#  # Get sample data path
#  pth <- system.file("extdata", package = "sassy")
#  
#  put("Open data library")
#  libname(sdtm, pth, "csv")
#  
#  put("Extract DM dataset")
#  datdm <- subset(sdtm$DM, ARM != 'SCREEN FAILURE')
#  
#  put("Apply formats")
#  datdm$AGECAT <- fapply(datdm$AGE, agecat)
#  datdm$SEXF <- fapply(datdm$SEX, fmt_sex)
#  datdm$RACEF <- fapply(datdm$RACE, fmt_race)
#  datdm$ARMF <- fapply(datdm$ARM, fmt_arm)
#  datdm$ETHNICF <- fapply(datdm$ETHNIC, fmt_ethnic)
#  
#  put("Get ARM population counts")
#  proc_freq(datdm, tables = ARM,
#            output = long,
#            options = v(nopercent, nonobs)) -> arm_pop
#  
#  # Age Summary Block -------------------------------------------------------
#  
#  sep("Create summary statistics for age")
#  
#  put("Call means procedure to get summary statistics for age")
#  proc_means(datdm, var = AGE,
#             stats = v(n, mean, std, median, q1, q3, min, max),
#             by = ARM,
#             options = v(notype, nofreq)) -> age_stats
#  
#  put("Combine stats")
#  datastep(age_stats,
#           format = fc,
#           drop = find.names(age_stats, start = 4),
#           {
#             `Mean (SD)` <- fapply2(MEAN, STD)
#             Median <- MEDIAN
#             `Q1 - Q3` <- fapply2(Q1, Q3, sep = " - ")
#             `Min - Max` <- fapply2(MIN, MAX, sep = " - ")
#  
#  
#           }) -> age_comb
#  
#  put("Transpose ARMs into columns")
#  proc_transpose(age_comb,
#                 var = names(age_comb),
#                 copy = VAR, id = BY,
#                 name = LABEL) -> age_block
#  
#  
#  # Age Group Block ----------------------------------------------------------
#  
#  sep("Create frequency counts for Age Group")
#  
#  
#  put("Get age group frequency counts")
#  proc_freq(datdm,
#            table = AGECAT,
#            by = ARM,
#            options = nonobs) -> ageg_freq
#  
#  put("Combine counts and percents and assign age group factor for sorting")
#  datastep(ageg_freq,
#           format = fc,
#           keep = v(VAR, LABEL, BY, CNTPCT),
#           {
#             CNTPCT <- fapply2(CNT, PCT)
#             LABEL <- CAT
#           }) -> ageg_comb
#  
#  put("Tranpose age group block")
#  proc_transpose(ageg_comb,
#                 var = CNTPCT,
#                 copy = VAR,
#                 id = BY,
#                 by = LABEL,
#                 options = noname) -> ageg_block
#  
#  # Sex Block ---------------------------------------------------------------
#  
#  sep("Create frequency counts for SEX")
#  
#  put("Get sex frequency counts")
#  proc_freq(datdm, tables = SEXF,
#            by = ARM,
#            options = nonobs) -> sex_freq
#  
#  
#  put("Combine counts and percents.")
#  datastep(sex_freq,
#           format = fc,
#           rename = list(CAT = "LABEL"),
#           drop = v(CNT, PCT),
#           {
#  
#             CNTPCT <- fapply2(CNT, PCT)
#  
#           }) -> sex_comb
#  
#  put("Transpose ARMs into columns")
#  proc_transpose(sex_comb, id = BY,
#                 var = CNTPCT,
#                 copy = VAR, by = LABEL,
#                 options = noname) -> sex_block
#  
#  
#  # Race block --------------------------------------------------------------
#  
#  
#  sep("Create frequency counts for RACE")
#  
#  put("Get race frequency counts")
#  proc_freq(datdm, tables = RACEF,
#            by = ARM,
#            options = nonobs) -> race_freq
#  
#  
#  put("Combine counts and percents.")
#  datastep(race_freq,
#           format = fc,
#           rename = list(CAT = "LABEL"),
#           drop = v(CNT, PCT),
#           {
#  
#             CNTPCT <- fapply2(CNT, PCT)
#  
#           }) -> race_comb
#  
#  put("Transpose ARMs into columns")
#  proc_transpose(race_comb, id = BY, var = CNTPCT,
#                 copy = VAR, by = LABEL,
#                 options = noname) -> race_block
#  
#  
#  
#  
#  
#  # Ethnic Block ---------------------------------------------------------------
#  
#  sep("Create frequency counts for ETHNIC")
#  
#  put("Get ethnic frequency counts")
#  proc_freq(datdm, tables = ETHNICF,
#            by = ARM,
#            options = nonobs) -> ethnic_freq
#  
#  put("Combine counts and percents.")
#  datastep(ethnic_freq, format = fc,
#           rename = list(CAT = "LABEL"),
#           drop = v(CNT, PCT),
#           {
#             CNTPCT <- fapply2(CNT, PCT)
#           }) -> ethnic_comb
#  
#  put("Transpose ARMs into columns")
#  proc_transpose(ethnic_comb, id = BY,
#                 var = CNTPCT,
#                 copy = VAR, by = LABEL,
#                 options = noname) -> ethnic_block
#  
#  
#  # Prepare final dataset ---------------------------------------------------
#  
#  put("Combine blocks into final data frame")
#  datastep(age_block,
#           set = list(ageg_block, sex_block, race_block, ethnic_block),
#           {}) -> final
#  
#  # Report ------------------------------------------------------------------
#  
#  
#  var_fmt <- c("AGE" = "Age", "AGECAT" = "Age Group", "SEXF" = "Sex",
#               "RACEF" = "Race", "ETHNICF" = "Ethnicity")
#  
#  sep("Create and print stand-alone report")
#  
#  # Create Table
#  tbl1 <- create_table(final, first_row_blank = TRUE) |>
#    column_defaults(from = `ARM A`, to = `ARM D`, align = "center", width = 1.1) |>
#    stub(vars = c("VAR", "LABEL"), "Variable", width = 2.5) |>
#    define(VAR, blank_after = TRUE, dedupe = TRUE, label = "Variable",
#           format = var_fmt,label_row = TRUE) |>
#    define(LABEL, indent = .25, label = "Demographic Category") |>
#    define(`ARM A`,  label = "Placebo", n = arm_pop["ARM A"]) |>
#    define(`ARM B`,  label = "Drug 50mg", n = arm_pop["ARM B"]) |>
#    define(`ARM C`,  label = "Drug 100mg", n = arm_pop["ARM C"]) |>
#    define(`ARM D`,  label = "Competitor", n = arm_pop["ARM D"]) |>
#    titles("Table 1.0", "Analysis of Demographic Characteristics",
#           "Safety Population", bold = TRUE) |>
#    footnotes("Program: DM_Table.R",
#              "NOTE: Denominator based on number of non-missing responses.",
#              valign = "bottom", align = "left")
#  
#  rpt1 <- create_report(file.path(tmp, "example15s"),
#                       output_type = "PDF",
#                       font = "Courier") |>
#    page_header(c("Sponsor: Company", "Study: ABC"),
#                right = c("DRUG: XYZ", "LOCK DATE: 02FEB2024")) |>
#    set_margins(top = 1, bottom = 1) |>
#    add_content(tbl1) |>
#    page_footer("Date Produced: {Sys.Date()}", right = "Page [pg] of [tpg]")
#  
#  put("Write out the report")
#  res1 <- write_report(rpt1)
#  
#  
#  sep("Create and print intext report")
#  
#  # Create Table
#  tbl2 <- create_table(final, first_row_blank = TRUE, continuous = TRUE,
#                       borders = c("top"), width = 6.5) |>
#    column_defaults(from = `ARM A`, to = `ARM D`, align = "center", width = 1.1) |>
#    stub(vars = c("VAR", "LABEL"), "Variable") |>
#    define(VAR, blank_after = TRUE, dedupe = TRUE, label = "Variable",
#           format = var_fmt,label_row = TRUE) |>
#    define(LABEL, indent = .25, label = "Demographic Category") |>
#    define(`ARM A`,  label = "Placebo", n = arm_pop["ARM A"]) |>
#    define(`ARM B`,  label = "Drug 50mg", n = arm_pop["ARM B"]) |>
#    define(`ARM C`,  label = "Drug 100mg", n = arm_pop["ARM C"]) |>
#    define(`ARM D`,  label = "Competitor", n = arm_pop["ARM D"]) |>
#  
#    footnotes("Program: DM_Table.R",
#              "NOTE: Denominator based on number of non-missing responses.",
#              borders = c("top", "bottom"), blank_row = "none")
#  
#  rpt2 <- create_report(file.path(tmp, "example15i"),
#                       output_type = "RTF",
#                       font = "Arial", orientation = "landscape") |>
#    set_margins(top = 1, bottom = 1) |>
#    add_content(tbl2) |>
#    titles("Table 1.0", "Analysis of Demographic Characteristics",
#           "Safety Population", bold = TRUE, header = TRUE)
#  
#  
#  put("Write out the report")
#  res2 <- write_report(rpt2)
#  
#  # Clean Up ----------------------------------------------------------------
#  sep("Clean Up")
#  
#  put("Close log")
#  log_close()
#  
#  
#  # Uncomment to view report
#  # file.show(res1$modified_path)
#  
#  # Uncomment to view report
#  # file.show(res2$modified_path)
#  
#  # Uncomment to view log
#  # file.show(lf)
#  

