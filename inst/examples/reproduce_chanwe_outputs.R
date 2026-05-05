# Reproduce ChanWe-branded outputs

# library(chanwer)
library(ggplot2)
library(gt)

devtools::load_all()
chanwe_load_fonts()

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
#   theme_chanwe(bg_color = "white")

# print(p)

mt <- tibble::as_tibble(mtcars, rownames = "model")
mt <- mt |>
  dplyr::mutate(
    cyl = factor(cyl),
    gear = factor(gear),
    am = factor(am, labels = c("Automatic", "Manual"))
  )

# 2) gt
gt_tbl <- gt::gt(head(mt, 10), rowname_col = "model") |>
  chanwe_gt_header(
    title = "Operational Snapshot",
    subtitle = "Fleet overview · mtcars sample · Q1 2026.",
    eyebrow = "SECTION · OPERATIONAL",
    caption = "Source · Motor Trend, 1974 · mtcars dataset."
  ) |>
  gt_theme_chanwe(bg_color = "#fff")

print(gt_tbl)

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
