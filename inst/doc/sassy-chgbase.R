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
#  options("logr.notes" = FALSE,
#          "logr.autolog" = TRUE,
#          "procs.print" = FALSE)
#  
#  # Get temp location for log and report output
#  tmp <- tempdir()
#  
#  lf <- log_open(file.path(tmp, "example13.log"))
#  
#  # Get data ----------------------------------------------------------------
#  
#  sep("Get data")
#  
#  # Get sample data path
#  pth <- system.file("extdata", package = "sassy")
#  
#  put("Open data library")
#  libname(sdtm, pth, "csv")
#  
#  # Create Formats ----------------------------------------------------------
#  
#  sep("Create Formats")
#  
#  put("Format for visits")
#  vfmt <- value(condition(x == "DAY 1", "Day 1"),
#                condition(x == "WEEK 2", "Week 2"),
#                condition(x == "WEEK 4", "Week 4"),
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
#  
#  # Prepare data ------------------------------------------------------------
#  
#  sep("Prepare data")
#  
#  put("Pull out needed visits and columns")
#  lbsub1 <- subset(sdtm$LB, VISIT %in% toupper(levels(vfmt)),
#                  v(USUBJID, VISIT, VISITNUM, LBORRES, LBCAT, LBORRESU, LBTEST,
#                    LBTESTCD, LBBLFL)) |> put()
#  
#  put("Pull out baseline subset")
#  lbsub2 <- subset(lbsub1, LBBLFL == 'Y',
#                  v(USUBJID, VISIT, LBORRES, LBCAT, LBTESTCD)) |> put()
#  
#  put("Merge and calculate change from baseline")
#  datastep(lbsub1, merge = lbsub2, merge_by = v(USUBJID, LBCAT, LBTESTCD),
#           rename = v(LBORRES.1 = LBORRES, LBORRES.2 = BLBORES, VISIT.1 = VISIT),
#           drop = VISIT.2, {
#  
#             # Convert to double
#             LBORRES.1 <- suppressWarnings(as.double(LBORRES.1))
#  
#             # Convert to double
#             LBORRES.2 <- suppressWarnings(as.double(LBORRES.2))
#  
#             # Calculate Change from baseline
#             if (!(is.na(LBORRES.1) | is.na(LBORRES.2))) {
#               LBCHG <- LBORRES.1 - LBORRES.2
#             } else {
#               LBCHG <- NA
#             }
#  
#           }) -> lbsub
#  
#  put("Pull needed ARMs and columns for DM")
#  dmsub <- subset(sdtm$DM, ARM != "SCREEN FAILURE", v(USUBJID, ARMCD, ARM)) |> put()
#  
#  put("Merge DM with LB to get subject treatments")
#  datastep(lbsub, merge = dmsub, merge_by = USUBJID,
#           where = expression(toupper(VISIT) != 'SCREENING'),
#           {
#             VISIT <- fapply(VISIT, vfmt)
#           }) -> lbdat
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
#  put("Apply superscripts as needed")
#  tfmt <- sub("(9)", supsc('9'), tfmt, fixed = TRUE)
#  tfmt <- sub("(12)", supsc('12'), tfmt, fixed = TRUE)
#  
#  
#  # Calculate statistics ----------------------------------------------------
#  
#  sep("Calculate statistics")
#  
#  put("Get statistics for change from baseline")
#  proc_means(lbdat, by = LBTESTCD,
#             class = v(ARM, VISIT),
#             var = LBCHG,
#             stats = v(n, mean, std, clm),
#             options = nway) -> datcl
#  
#  put("Get statistics for mean lab value")
#  proc_means(lbdat, by = LBTESTCD,
#             class = v(ARM, VISIT),
#             var = LBORRES,
#             stats = v(n, mean),
#             options = nway) -> datmn
#  
#  put("Add mean lab values to change from baseline")
#  datcl$MEANV <- datmn$MEAN
#  
#  put("Apply formats")
#  datcl$BY <- fapply(datcl$BY, tfmt)
#  datcl$CLASS1 <- fapply(datcl$CLASS1, afmt)
#  
#  
#  # Create report -----------------------------------------------------------
#  
#  sep("Create report")
#  
#  put("Create output path")
#  pth <- file.path(tmp, "output/example13.rtf") |> put()
#  
#  put("Create report first so content can be added dynamically")
#  rpt <- create_report(pth, output_type = "RTF",
#                       font = "Arial", font_size = 10) |>
#    page_header("Sponsor: Archytas", right = "Study: ABC") |>
#    titles("Figure 1.0", "Mean Change From Baseline (HEMATOLOGY)", "Safety Population",
#           bold = TRUE, blank_row = "none") |>
#    page_footer("Date: " %p% fapply(Sys.time(), "%d%b%Y %H:%M:%S"),
#                "Confidential", "Page [pg] of [tpg]")
#  
#  put("Loop through lab tests")
#  for (tst in unique(datcl$BY)) {
#  
#    put("**** Lab Test: " %p% tst %p% " ****")
#  
#    put("Apply subset")
#    dat <- subset(datcl, BY == tst)
#  
#    put("Create plot")
#    p <- ggplot(data = dat, aes(x = CLASS2, y = MEAN, group = CLASS1)) +
#      geom_point(aes(color = CLASS1), size = 1.5, position = position_dodge(width = 0.5)) +
#      geom_line(aes(color = CLASS1, linetype = CLASS1), position = position_dodge(width = 0.5)) +
#      geom_errorbar(aes(x = CLASS2, ymin = LCLM, ymax = UCLM, color = CLASS1),
#                    position = position_dodge(width = 0.5)) +
#      theme_light() +
#      scale_linetype(guide = "none") +
#      scale_color_manual(values = c("blue", "red", "green", "purple")) +
#      theme(legend.position = "bottom", plot.title = element_text(size = 11, hjust = 0)) +
#      guides(color = guide_legend(title = "Treatment")) +
#      labs(x = 'Visit', y = '\n\nMean Change from Baseline (95% CI)') +
#      geom_hline(yintercept = 0, linetype = 'dashed')
#  
#    put("Create table for mean change/mean value")
#    t1 <- ggplot(data = dat) +
#      geom_text(aes(CLASS1, x = CLASS2, label = fapply2(MEAN, MEANV, "%4.2f", "%.2f", sep = "/"),
#                    hjust = 0.5, vjust = 0.5), size = 8 / .pt) +
#      ggtitle("Mean Change from Baseline/Mean Value") +
#      scale_y_discrete(limits = rev) +
#      theme_bw() +
#      theme(
#        axis.line = element_blank(),
#        panel.grid = element_blank(),
#        axis.ticks = element_blank(),
#        axis.title.y = element_blank(),
#        axis.title.x = element_blank(),
#        axis.text.x = element_text(color = "white"),
#        plot.title = element_text(size =10, hjust = 0, face = "bold")
#      )
#  
#    put("Create table for patient counts")
#    t2 <- ggplot(data = dat) +
#      geom_text(aes(CLASS1, x = CLASS2, label = as.character(N),
#                    hjust = 0.5, vjust = 0.5), size = 8 / .pt) +
#      ggtitle("Number of Patients") +
#      scale_y_discrete(limits = rev) +
#      theme_bw() +
#      theme(
#        axis.line = element_blank(),
#        panel.grid = element_blank(),
#        axis.ticks = element_blank(),
#        axis.title.y = element_blank(),
#        axis.title.x = element_blank(),
#        axis.text.x = element_text(color = "white"),
#        plot.title = element_text(size = 10, hjust = 0, face = "bold")
#      )
#  
#    put("Patch together plot and tables")
#    plts <- p + t1 + t2 + plot_layout(ncol = 1, nrow = 3,
#                                      widths = c(1, 2, 2), heights = c(8, 2, 2))
#  
#    put("Create plot content")
#    plt1 <- create_plot(plts, height = 6, width = 9) |>
#      titles("Laboratory Test: " %p% tst, align = "left", blank_row = "below")
#  
#    put("Add content to report")
#    rpt <- rpt |>
#      add_content(plt1, page_break = TRUE, blank_row = "none")
#  
#  }
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

