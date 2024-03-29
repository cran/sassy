## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----eval=FALSE, echo=TRUE----------------------------------------------------
#  library(sassy)
#  library(ggplot2)
#  library(patchwork)
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
#  lgpth <- log_open(file.path(tmp, "example12.log"))
#  
#  
#  # Load and Prepare Data ---------------------------------------------------
#  
#  sep("Prepare Data")
#  
#  put("Define data library")
#  libname(sdtm, dir, "csv")
#  
#  put("Prepare format")
#  agefmt <- value(condition(x >= 18 & x <= 24, "18 to 24"),
#                  condition(x >= 25 & x <= 44, "25 to 44"),
#                  condition(x >= 45 & x <= 64, "45 to 64"),
#                  condition(x >= 65, ">= 65"))
#  
#  put("Prepare data")
#  datastep(sdtm$DM,
#           keep = v(USUBJID, SEX, AGE, ARM, AGECAT),
#           where = expression(ARM != "SCREEN FAILURE"),
#    {
#  
#        AGECAT = fapply(AGE, agefmt)
#  
#    }) -> dm_mod
#  
#  
#  put("Convert agecat to factor it will sort correctly")
#  dm_mod$AGECAT <- factor(dm_mod$AGECAT, levels = levels(agefmt))
#  
#  put("Split by ARM")
#  dm_sub <- split(dm_mod, factor(dm_mod$ARM))
#  
#  
#  # Create Plots ------------------------------------------------------------
#  
#  sep("Create Plots")
#  
#  put("Create plot for ARM A")
#  plt1 <- ggplot(dm_sub$`ARM A`, aes(x = AGECAT, fill = SEX)) +
#    geom_bar(position = "dodge") +
#    labs(x = "Age Groups", y = "Number of Subjects (n)", title = "Placebo")
#  
#  put("Create plot for ARM B")
#  plt2 <- ggplot(dm_sub$`ARM B`, aes(x = AGECAT, fill = SEX)) +
#    geom_bar(position = "dodge") +
#    labs(x = "Age Groups", y = "Number of Subjects (n)", title = "Drug 50mg")
#  
#  put("Create plot for ARM C")
#  plt3 <- ggplot(dm_sub$`ARM C`, aes(x = AGECAT, fill = SEX)) +
#    geom_bar(position = "dodge") +
#    labs(x = "Age Groups", y = "Number of Subjects (n)", title = "Drug 100mg")
#  
#  put("Create plot for ARM D")
#  plt4 <- ggplot(dm_sub$`ARM D`, aes(x = AGECAT, fill = SEX)) +
#    geom_bar(position = "dodge") +
#    labs(x = "Age Groups", y = "Number of Subjects (n)", title = "Competitor")
#  
#  
#  put("Combine 4 plots into 1 using patchwork")
#  plts <- (plt1 | plt2) / (plt3 | plt4)
#  
#  
#  # Report ------------------------------------------------------------------
#  
#  
#  sep("Create and print report")
#  
#  
#  pth <- file.path(tmp, "output/example12.rtf")
#  
#  
#  plt <- create_plot(plts, 4.5, 7) |>
#    titles("Figure 3.2", "Distribution of Subjects by Treatment Group",
#           font_size = 11, bold = TRUE)
#  
#  
#  rpt <- create_report(pth, output_type = "RTF", font = "Arial") |>
#    set_margins(top = 1, bottom = 1) |>
#    page_header("Sponsor: Company", "Study: ABC") |>
#    add_content(plt) |>
#    footnotes("Program: DM_Figure.R") |>
#    page_footer(paste0("Date Produced: ", fapply(Sys.time(), "%d%b%y %H:%M")),
#                right = "Page [pg] of [tpg]")
#  
#  # Write report to file
#  res <- write_report(rpt)
#  
#  
#  # Clean Up ----------------------------------------------------------------
#  
#  # Close log
#  log_close()
#  
#  # Uncomment to view files
#  # file.show(pth)
#  # file.show(lgpth)

