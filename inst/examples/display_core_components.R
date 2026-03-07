# Display one example each for ggplot2, highcharter, gt, and reactable

devtools::load_all()
# Shared data
cars_tbl <- tibble::as_tibble(mtcars, rownames = "model")

# # 1) ggplot2
# plot_gg <- ggplot(cars_tbl, aes(wt, mpg, color = factor(cyl))) +
#   geom_point(size = 3, alpha = 0.9) +
#   scale_color_chanwe_d() +
#   labs(
#     title = "GGPlot Example",
#     subtitle = chanwe_subtitle("ChanWe style"),
#     caption = "Source: mtcars"
#   ) +
#   theme_chanwe(base_family = "sans")

# print(plot_gg)

# # 2) highcharter
# plot_hc <- highcharter::hchart(
#   cars_tbl,
#   "scatter",
#   highcharter::hcaes(wt, mpg, group = cyl)
# ) |>
#   highcharter::hc_title(text = "Highcharter Example") |>
#   highcharter::hc_add_theme(hc_theme_chanwe())

# print(plot_hc)

# 3) gt (spacious + compact rich examples)
# cars_gt <- cars_tbl |>
#   dplyr::mutate(
#     cyl = factor(cyl),
#     transmission = ifelse(am == 1, "Manual", "Automatic")
#   ) |>
#   dplyr::arrange(cyl, dplyr::desc(mpg)) |>
#   dplyr::select(
#     model,
#     cyl,
#     mpg,
#     hp,
#     qsec,
#     wt,
#     disp,
#     transmission,
#     gear,
#     carb
#   )

# gt_base <- gt::gt(
#   cars_gt,
#   rowname_col = "model",
#   groupname_col = "cyl"
# ) |>
#   gt::tab_header(
#     title = gt::md("Powertrain Comparison"),
#     subtitle = "Grouped by cylinder count with ChanWe styling"
#   ) |>
#   gt::tab_caption(
#     "Table 1. Core GT showcase with grouped rows and summaries."
#   ) |>
#   gt::cols_label(
#     mpg = "MPG",
#     hp = "HP",
#     qsec = "QSec",
#     wt = "Weight",
#     disp = "Displacement",
#     transmission = "Transmission",
#     gear = "Gears",
#     carb = "Carb"
#   ) |>
#   gt::tab_spanner(label = "Performance", columns = c(mpg, hp, qsec)) |>
#   gt::tab_spanner(label = "Engine & Mass", columns = c(wt, disp)) |>
#   gt::tab_spanner(
#     label = "Drivetrain",
#     columns = c(transmission, gear, carb)
#   ) |>
#   gt::fmt_number(columns = c(mpg, wt, disp, qsec), decimals = 1) |>
#   gt::fmt_number(columns = c(hp), decimals = 0) |>
#   gt::summary_rows(
#     groups = TRUE,
#     columns = c(mpg, hp, wt),
#     fns = list(
#       Avg = ~ mean(.x, na.rm = TRUE),
#       Max = ~ max(.x, na.rm = TRUE)
#     )
#   ) |>
#   gt::grand_summary_rows(
#     columns = c(mpg, hp, wt),
#     fns = list(Overall = ~ mean(.x, na.rm = TRUE))
#   ) |>
#   gt::tab_source_note("Source: mtcars dataset") |>
#   gt::tab_source_note("Notes: grouped by `cyl`; values rounded for display") |>
#   gt::tab_footnote(
#     footnote = "Miles per gallon",
#     locations = gt::cells_column_labels(columns = mpg)
#   ) |>
#   gt::tab_footnote(
#     footnote = "Quarter-mile time in seconds",
#     locations = gt::cells_column_labels(columns = qsec)
#   )

# gt_base |>
#   gt_theme_chanwe_spacious()

# gt_base |>
#   gt_theme_chanwe_compact()

cars_tbl |>
  dplyr::select(model, mpg, cyl, hp, wt) |>
  head(8) |>
  gt::gt() |>
  gt::tab_header(
    title = "Simple GT Example",
    subtitle = "Minimal ChanWe table"
  ) |>
  gt::tab_caption("Table 2. Simple table.") |>
  gt_theme_chanwe_compact() |>
  gt::tab_style(
    style = gt::cell_text(color = "black", align = "center"),
    locations = gt::cells_title(groups = "title")
  )

# 4) reactable
reactable::reactable(
  head(cars_tbl, 10),
  theme = reactable_theme_chanwe(),
  defaultPageSize = 5
)
