## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----eval=FALSE, echo=TRUE----------------------------------------------------
#  library(sassy)
#  
#  options("logr.autolog" = TRUE,
#          "logr.notes" = FALSE)
#  
#  # Get path to temp directory
#  tmp <- tempdir()
#  
#  # Get path to sample data
#  pkg <- system.file("extdata", package = "sassy")
#  
#  # Open log
#  lgpth <- log_open(file.path(tmp, "example1.log"))
#  
#  sep("Get Data")
#  
#  # Define data library
#  libname(sdtm, pkg, "csv")
#  
#  sep("Write Report")
#  
#  # Define table object
#  tbl <- create_table(sdtm$DM) |>
#    define(USUBJID, id_var = TRUE)
#  
#  # Construct report path
#  pth <- file.path(tmp, "output/l_dm.rtf")
#  
#  # Define report object
#  rpt <- create_report(pth, output_type = "RTF", font = "Courier") |>
#    page_header("Sponsor: Company", "Study: ABC") |>
#    titles("Listing 1.0", "SDTM Demographics") |>
#    add_content(tbl, align = "left") |>
#    page_footer(Sys.time(), "CONFIDENTIAL", "Page [pg] of [tpg]")
#  
#  # Write report to file system
#  write_report(rpt)
#  
#  # Close log
#  log_close()
#  
#  # View report
#  # file.show(pth)
#  
#  # View log
#  # file.show(lgpth)

