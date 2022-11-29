## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----eval=FALSE, echo=TRUE----------------------------------------------------
#  library(grid)
#  library(forestploter)
#  library(magrittr)
#  library(sassy)
#  
#  options("logr.notes" = FALSE,
#          "logr.autolog" = TRUE)
#  
#  
#  # Get temp directory
#  tmp <- tempdir()
#  
#  # Open log
#  lf <- log_open(file.path(tmp, "example9.log"))
#  
#  
#  # Prepare Data ------------------------------------------------------------
#  
#  sep("Prepare Data")
#  
#  put("Read example data from forestploter package")
#  dt <- read.csv(system.file("extdata", "example_data.csv", package = "forestploter"))
#  
#  put("Keep needed columns")
#  dt <- dt[,1:6] %>% put()
#  
#  put("Indent the subgroup if there is a number in the placebo column")
#  dt$Subgroup <- ifelse(is.na(dt$Placebo),
#                        dt$Subgroup,
#                        paste0("   ", dt$Subgroup)) %>% put()
#  
#  put("NA to blank or NA will be transformed to character.")
#  dt$Treatment <- ifelse(is.na(dt$Treatment), "", dt$Treatment)
#  dt$Placebo <- ifelse(is.na(dt$Placebo), "", dt$Placebo)
#  dt$se <- (log(dt$hi) - log(dt$est))/1.96
#  
#  put("Add blank column for the forest plot to display CI.")
#  dt$` ` <- paste(rep(" ", 20), collapse = " ")
#  
#  put("Create confidence interval column to display")
#  dt$`HR (95% CI)` <- ifelse(is.na(dt$se), "",
#                             sprintf("%.2f (%.2f to %.2f)",
#                                     dt$est, dt$low, dt$hi))
#  put("Final data frame")
#  put(dt)
#  
#  
#  # Create Plot -------------------------------------------------------------
#  
#  sep("Create Plot")
#  
#  put("Assign Forest Properties")
#  p <- forest(dt[,c(1:3, 8:9)],
#    est = dt$est,
#    lower = dt$low,
#    upper = dt$hi,
#    sizes = dt$se,
#    ci_column = 4,
#    ref_line = 1,
#    arrow_lab = c("Placebo Better", "Treatment Better"),
#    xlim = c(0, 4),
#    ticks_at = c(0.5, 1, 2, 3))
#  
#  put("Create temp file name")
#  tmppth <- tempfile(fileext = ".jpg") %>% put()
#  
#  put("Turn on jpeg device context")
#  jpeg(tmppth, width = 600, height = 500)
#  
#  put("Print plot")
#  plot(p)
#  
#  put("Turn off device context")
#  dev.off()
#  
#  
#  # Create Report -----------------------------------------------------------
#  
#  sep("Create Report")
#  
#  put("Create plot object from jpeg file")
#  plt <- create_plot(tmppth, 5.5, 7.5)
#  
#  put("Construct report file path")
#  pth <- file.path(tmp, "example9.rtf")
#  
#  put("Create report")
#  rpt <- create_report(pth, output_type = "RTF", font = "Arial") %>%
#    titles("Figure 3.1.4", "Forest Plot Comparison of Treated vs. Placebo",
#           "Safety Population", bold = TRUE, blank_row = "none") %>%
#    add_content(plt) %>%
#    footnotes("Program: {Sys.path()}",
#             "Output: {basename(pth)}", blank_row = "none") %>%
#    page_header("Sponsor: Sassy", "Study: ABC") %>%
#    page_footer("Date: {Sys.time()}", right = "Page [pg] of [tpg]")
#  
#  put("Write report")
#  res <- write_report(rpt)
#  
#  # Uncomment to Show report
#  # file.show(res$modified_path)
#  
#  # Uncomment to View Log
#  # file.show(lf)
#  
#  
#  # Clean Up ----------------------------------------------------------------
#  
#  # Kill image file
#  file.remove(tmppth)
#  
#  log_close()
#  

