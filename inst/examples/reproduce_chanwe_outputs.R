# Reproduce ChanWe-branded outputs

# library(chanwer)
library(ggplot2)

devtools::load_all()

# # 1) ggplot2
# p <- ggplot(mtcars, aes(wt, mpg, color = factor(cyl))) +
#   geom_point(size = 3) +
#   scale_color_chanwe_d() +
#   labs(
#     title = chanwe_title(
#       text = "Fuel efficiency by weight",
#       eyebrow = "TLDR;"
#     ),
#     subtitle = "Chanwe branded ggplot",
#     caption = chanwe_caption("Data: mtcars")
#   ) +
#   theme_chanwe(bg_color = "#fff")

# print(p)

mt <- tibble::as_tibble(mtcars, rownames = "model")
mt <- mt |>
  dplyr::mutate(
    cyl = factor(cyl),
    gear = factor(gear),
    am = factor(am, labels = c("Automatic", "Manual"))
  )

# 2) gt
if (requireNamespace("gt", quietly = TRUE)) {
  gt_tbl <- gt::gt(head(mt, 10)) |>
    gt::tab_header(title = "Operational Snapshot") |>
    gt_theme_chanwe()

  print(gt_tbl)
}

# # 3) reactable
# if (requireNamespace("reactable", quietly = TRUE)) {
#   react_tbl <- reactable::reactable(
#     head(mt),
#     theme = reactable_theme_chanwe(),
#     defaultPageSize = 6
#   )

#   print(react_tbl)
# }

# # 4) highcharter
# if (requireNamespace("highcharter", quietly = TRUE)) {
#   hc <- highcharter::hchart(
#     mtcars,
#     "scatter",
#     highcharter::hcaes(wt, mpg, group = cyl)
#   ) |>
#     highcharter::hc_title(text = "ChanWe highcharter") |>
#     highcharter::hc_add_theme(hc_theme_chanwe())

#   print(hc)
# }

# # 5) Quarto CSS path
# cat("Use this stylesheet in Quarto:\n")
# cat(chanwe_reporting_css(), "\n")
