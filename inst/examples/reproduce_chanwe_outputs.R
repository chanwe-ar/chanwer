# Reproduce ChanWe-branded outputs

# library(chanwer)
library(ggplot2)
library(gt)

devtools::load_all()
mt <- tibble::as_tibble(mtcars, rownames = "model") |>
  dplyr::mutate(
    cyl = factor(cyl),
    gear = factor(gear),
    am = factor(am, labels = c("Automatic", "Manual")),
    hp_band = cut(
      hp,
      breaks = c(-Inf, 110, 180, Inf),
      labels = c("Low", "Mid", "High")
    )
  )
# chanwe_load_fonts()

# 1) ggplot2
ggplot(mt, aes(wt, mpg, color = hp_band)) +
  geom_point(size = 2.2, alpha = 0.88) +
  geom_smooth(method = "lm", se = FALSE, linewidth = 0.7) +
  facet_wrap(~am) +
  scale_color_chanwe_d() +
  theme_chanwe(bg_color = "#F5F5F5") +
  labs(
    title = chanwe_title(
      "Performance profile by transmission",
      eyebrow = "TLDR;"
    ),
    subtitle = chanwe_subtitle("Faceted by transmission type"),
    x = "Weight (1000 lbs)",
    y = "Miles per gallon",
    color = "HP band",
    caption = chanwe_caption("Source: Motor Trend, 1974")
  )


# 2) gt
mt <- tibble::as_tibble(mtcars, rownames = "model")

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
