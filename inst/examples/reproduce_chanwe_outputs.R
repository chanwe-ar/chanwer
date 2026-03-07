# Reproduce ChanWe-branded outputs

library(chanweThemes)
library(ggplot2)

# 1) ggplot2
p <- ggplot(mtcars, aes(wt, mpg, color = factor(cyl))) +
  geom_point(size = 3) +
  scale_color_chanwe_d() +
  labs(
    title = "Fuel efficiency by weight",
    subtitle = "ChanWe branded ggplot",
    caption = "Data: mtcars"
  ) +
  theme_chanwe()

print(p)

# 2) gt
if (requireNamespace("gt", quietly = TRUE)) {
  gt_tbl <- gt::gt(head(mtcars)) |>
    gt::tab_header(title = "Vehicle table") |>
    gt_theme_chanwe()

  print(gt_tbl)
}

# 3) reactable
if (requireNamespace("reactable", quietly = TRUE)) {
  react_tbl <- reactable::reactable(
    head(mtcars),
    theme = reactable_theme_chanwe(),
    defaultPageSize = 6
  )

  print(react_tbl)
}

# 4) highcharter
if (requireNamespace("highcharter", quietly = TRUE)) {
  hc <- highcharter::hchart(
    mtcars,
    "scatter",
    highcharter::hcaes(wt, mpg, group = cyl)
  ) |>
    highcharter::hc_title(text = "ChanWe highcharter") |>
    highcharter::hc_add_theme(hc_theme_chanwe())

  print(hc)
}

# 5) Quarto CSS path
cat("Use this stylesheet in Quarto:\n")
cat(chanwe_reporting_css(), "\n")
