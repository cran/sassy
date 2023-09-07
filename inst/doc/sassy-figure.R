## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----eval=FALSE, echo=TRUE----------------------------------------------------
#  library(ggplot2)
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
#  lgpth <- log_open(file.path(tmp, "example3.log"))
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
#  
#  put("Prepare format")
#  agefmt <- value(condition(x >= 18 & x <= 24, "18 to 24"),
#                  condition(x >= 25 & x <= 44, "25 to 44"),
#                  condition(x >= 45 & x <= 64, "45 to 64"),
#                  condition(x >= 65, ">= 65"))
#  
#  
#  put("Prepare data")
#  datastep(sdtm.DM, keep = v(USUBJID, SEX, AGE, ARM, AGECAT),
#      where = expression(ARM != "SCREEN FAILURE"),
#      {
#          AGECAT <- fapply(AGE, agefmt)
#  
#      }) -> dm_mod
#  
#  put("Get population counts")
#  proc_freq(dm_mod, tables = ARM,
#            options = v(nonobs, nopercent)) -> arm_pop
#  
#  proc_freq(dm_mod, tables = SEX,
#            options = v(nonobs, nopercent)) -> sex_pop
#  
#  proc_freq(dm_mod, tables = AGECAT,
#            options = v(nonobs, nopercent)) -> agecat_pop
#  
#  
#  put("Convert agecat to factor so rows will sort correctly")
#  agecat_pop$CAT <- factor(agecat_pop$CAT, levels = levels(agefmt))
#  
#  put("Sort agecat")
#  agecat_pop <-  proc_sort(agecat_pop, by = CAT)
#  
#  
#  # Create Plots ------------------------------------------------------------
#  
#  
#  plt1 <- ggplot(data = arm_pop, aes(x = CAT, y = CNT)) +
#    geom_col(fill = "#0000A0") +
#    geom_text(aes(label = CNT), vjust = 1.5, colour = "white") +
#    labs(x = "Treatment Group", y = "Number of Subjects (n)")
#  
#  plt2 <- ggplot(data = sex_pop, aes(x = CAT, y = CNT)) +
#    geom_col(fill = "#00A000") +
#    geom_text(aes(label = CNT), vjust = 1.5, colour = "white") +
#    labs(x = "Biological Sex", y = "Number of Subjects (n)")
#  
#  plt3 <- ggplot(data = agecat_pop, aes(x = CAT, y = CNT)) +
#    geom_col(fill = "#A00000") +
#    geom_text(aes(label = CNT), vjust = 1.5, colour = "white") +
#    labs(x = "Age Categories", y = "Number of Subjects (n)")
#  
#  
#  # Report ------------------------------------------------------------------
#  
#  
#  sep("Create and print report")
#  
#  
#  pth <- file.path(tmp, "output/example3.rtf")
#  
#  
#  page1 <- create_plot(plt1, 4.5, 7) |>
#    titles("Figure 1.1", "Distribution of Subjects by Treatment Group",
#           bold = TRUE, font_size = 11)
#  
#  page2 <- create_plot(plt2, 4.5, 7) |>
#    titles("Figure 1.2", "Distribution of Subjects by Biological Sex",
#           bold = TRUE, font_size = 11)
#  
#  page3 <- create_plot(plt3, 4.5, 7) |>
#    titles("Figure 1.2", "Distribution of Subjects by Age Category",
#           bold = TRUE, font_size = 11)
#  
#  rpt <- create_report(pth, output_type = "RTF", font = "Arial") |>
#    set_margins(top = 1, bottom = 1) |>
#    page_header("Sponsor: Company", "Study: ABC") |>
#    add_content(page1) |>
#    add_content(page2) |>
#    add_content(page3) |>
#    footnotes("Program: DM_Figure.R") |>
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

