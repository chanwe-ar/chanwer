# Reproduce ChanWe-branded outputs

# library(chanwer)
library(ggplot2)
library(kableExtra)
library(gt)
library(magrittr)

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
# ggplot(mt, aes(wt, mpg, color = hp_band)) +
#   geom_point(size = 2.2, alpha = 0.88) +
#   geom_smooth(method = "lm", se = FALSE, linewidth = 0.7) +
#   facet_wrap(~am) +
#   scale_color_chanwe_d() +
#   theme_chanwe(bg_color = "#F5F5F5") +
#   labs(
#     title = chanwe_title(
#       "Performance profile by transmission",
#       eyebrow = "TLDR;"
#     ),
#     subtitle = chanwe_subtitle("Faceted by transmission type"),
#     x = "Weight (1000 lbs)",
#     y = "Miles per gallon",
#     color = "HP band",
#     caption = chanwe_caption("Source: Motor Trend, 1974")
#   )

# 2) gt
mt <- tibble::as_tibble(mtcars, rownames = "model")

# mt |>
#   dplyr::select(model, mpg, cyl, hp, wt) |>
#   dplyr::slice_head(n = 8) |>
#   gt(rowname_col = "model") |>
#   gt::fmt_number(columns = c(mpg, hp, wt), decimals = 2) |>
#   chanwe_gt_header(
#     title = "Simple fleet view",
#     subtitle = "Top 8 vehicles · mtcars · white background",
#     eyebrow = "TABLE · SPACIOUS",
#     caption = "Source · Motor Trend, 1974 · mtcars dataset."
#   ) |>
#   gt_theme_chanwe(bg_color = "#FFFFFF")

mtcars |>
  tibble::rownames_to_column("model") |>
  dplyr::slice_head(n = 8) |>
  chanwe_kbl(
    title = "Simple fleet view",
    subtitle = "Top 8 vehicles · mtcars",
    eyebrow = "TABLE · SPACIOUS",
    caption = "Source · Motor Trend, 1974.",
    stub = "model"
  ) %>%
  print()
