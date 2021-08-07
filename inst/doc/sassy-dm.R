## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----eval=FALSE, echo=TRUE----------------------------------------------------
#  library(tidyverse)
#  library(sassy)
#  
#  
#  # Prepare Log -------------------------------------------------------------
#  
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
#  lgpth <- log_open(file.path(tmp, "example2.log"))
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
#  dm_mod <- sdtm.DM %>%
#    select(USUBJID, SEX, AGE, ARM) %>%
#    filter(ARM != "SCREEN FAILURE") %>%
#    datastep({
#  
#       if (AGE >= 18 & AGE <= 24)
#         AGECAT = "18 to 24"
#       else if (AGE >= 25 & AGE <= 44)
#         AGECAT = "25 to 44"
#       else if (AGE >= 45 & AGE <= 64)
#         AGECAT <- "45 to 64"
#       else if (AGE >= 65)
#         AGECAT <- ">= 65"
#  
#     }) %>% put()
#  
#  put("Get ARM population counts")
#  arm_pop <- count(dm_mod, ARM) %>% deframe() %>% put()
#  
#  
#  # Age Summary Block -------------------------------------------------------
#  
#  sep("Create summary statistics for age")
#  
#  age_block <-
#    dm_mod %>%
#    group_by(ARM) %>%
#    summarise( N = fmt_n(AGE),
#               `Mean (SD)` = fmt_mean_sd(AGE),
#               Median = fmt_median(AGE),
#               `Q1 - Q3` = fmt_quantile_range(AGE),
#               Range  = fmt_range(AGE)) %>%
#    pivot_longer(-ARM,
#                 names_to  = "label",
#                 values_to = "value") %>%
#    pivot_wider(names_from = ARM,
#                values_from = "value") %>%
#    add_column(var = "AGE", .before = "label") %>%
#    put()
#  
#  
#  # Age Group Block ----------------------------------------------------------
#  
#  sep("Create frequency counts for Age Group")
#  
#  
#  put("Create age group frequency counts")
#  ageg_block <-
#    dm_mod %>%
#    select(ARM, AGECAT) %>%
#    group_by(ARM, AGECAT) %>%
#    summarize(n = n()) %>%
#    pivot_wider(names_from = ARM,
#                values_from = n,
#                values_fill = 0) %>%
#    transmute(var = "AGECAT",
#              label =  factor(AGECAT, levels = c("18 to 24",
#                                                 "25 to 44",
#                                                 "45 to 64",
#                                                 ">= 65")),
#              `ARM A` = fmt_cnt_pct(`ARM A`, arm_pop["ARM A"]),
#              `ARM B` = fmt_cnt_pct(`ARM B`, arm_pop["ARM B"]),
#              `ARM C` = fmt_cnt_pct(`ARM C`, arm_pop["ARM C"]),
#              `ARM D` = fmt_cnt_pct(`ARM D`, arm_pop["ARM D"])) %>%
#    arrange(label) %>%
#    put()
#  
#  
#  # Sex Block ---------------------------------------------------------------
#  
#  sep("Create frequency counts for SEX")
#  
#  # Create user-defined format
#  fmt_sex <- value(condition(is.na(x), "Missing"),
#                   condition(x == "M", "Male"),
#                   condition(x == "F", "Female"),
#                   condition(TRUE, "Other")) %>% put()
#  
#  # Create sex frequency counts
#  sex_block <-
#    dm_mod %>%
#    select(ARM, SEX) %>%
#    group_by(ARM, SEX) %>%
#    summarize(n = n()) %>%
#    pivot_wider(names_from = ARM,
#                values_from = n,
#                values_fill = 0) %>%
#    transmute(var = "SEX",
#              label =   fct_relevel(SEX, "M", "F"),
#              `ARM A` = fmt_cnt_pct(`ARM A`, arm_pop["ARM A"]),
#              `ARM B` = fmt_cnt_pct(`ARM B`, arm_pop["ARM B"]),
#              `ARM C` = fmt_cnt_pct(`ARM C`, arm_pop["ARM C"]),
#              `ARM D` = fmt_cnt_pct(`ARM D`, arm_pop["ARM D"])) %>%
#    arrange(label) %>%
#    mutate(label = fapply(label, fmt_sex)) %>%
#    put()
#  
#  put("Combine blocks into final data frame")
#  final <- bind_rows(age_block, ageg_block, sex_block) %>% put()
#  
#  # Report ------------------------------------------------------------------
#  
#  
#  sep("Create and print report")
#  
#  var_fmt <- c("AGE" = "Age", "AGECAT" = "Age Group", "SEX" = "Sex")
#  
#  # Create Table
#  tbl <- create_table(final, first_row_blank = TRUE) %>%
#    column_defaults(from = `ARM A`, to = `ARM D`, align = "center", width = 1.25) %>%
#    stub(vars = c("var", "label"), "Variable", width = 2.5) %>%
#    define(var, blank_after = TRUE, dedupe = TRUE, label = "Variable",
#           format = var_fmt,label_row = TRUE) %>%
#    define(label, indent = .25, label = "Demographic Category") %>%
#    define(`ARM A`,  n = arm_pop["ARM A"]) %>%
#    define(`ARM B`,  n = arm_pop["ARM B"]) %>%
#    define(`ARM C`,  n = arm_pop["ARM C"]) %>%
#    define(`ARM D`,  n = arm_pop["ARM D"])
#  
#  pth <- file.path(tmp, "output/example2.rtf")
#  
#  rpt <- create_report(pth, output_type = "RTF") %>%
#    set_margins(top = 1, bottom = 1) %>%
#    page_header("Sponsor: Company", "Study: ABC") %>%
#    titles("Table 1.0", "Analysis of Demographic Characteristics",
#           "Safety Population") %>%
#    add_content(tbl) %>%
#    footnotes("Program: DM_Table.R",
#              "NOTE: Denominator based on number of non-missing responses.") %>%
#    page_footer(paste0("Date Produced: ", fapply(Sys.time(), "%d%b%y %H:%M")),
#                right = "Page [pg] of [tpg]")
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
#  # View files
#  # file.show(pth)
#  # file.show(lgpth)
#  

