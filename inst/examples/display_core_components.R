# Display core ChanWe components: ggplot2 chart, KPI scoreboard, Typst table
#
# Run interactively from the package root. Charts print to the active device;
# the chanwe_kbl() output is a raw {=typst} block for Quarto PDF reports, so
# here we just cat() it to inspect the generated Typst code.

devtools::load_all(".")

library(ggplot2)

mt <- tibble::as_tibble(mtcars, rownames = "model") |>
  dplyr::mutate(
    cyl = factor(cyl),
    am = factor(am, labels = c("Automatic", "Manual"))
  )

# 1) ggplot2 — categorical scale, full header treatment
plot_gg <- ggplot(mt, aes(wt, mpg, color = cyl)) +
  geom_point(size = 3, alpha = 0.9) +
  scale_color_chanwe_d() +
  labs(
    title = chanwe_title("Fuel economy by weight", eyebrow = "SECTION - FLEET"),
    subtitle = chanwe_subtitle("MPG versus weight by cylinder count"),
    caption = chanwe_caption("Source: mtcars"),
    color = "Cylinders"
  ) +
  theme_chanwe()

print(plot_gg)

# 2) KPI scoreboard — signed arrows use the canonical tokens
plot_kpi <- ggplot(mt, aes(wt, mpg)) +
  geom_line(stat = "smooth", method = "loess", formula = y ~ x) +
  labs(
    title = chanwe_title("Fleet overview", eyebrow = "MOTOR TREND"),
    subtitle = chanwe_subtitle(
      "Highway mpg vs vehicle weight",
      kpi = chanwe_kpi(
        num = "21,0", label = "MPG", period = "1974",
        mtc1_num = "2,1%", mtc1_label = "WoW", mtc1_direction = "+",
        mtc2_num = "0,5%", mtc2_label = "MoM", mtc2_direction = "-",
        mtc3_num = "4,3%", mtc3_label = "YoY", mtc3_direction = "+"
      )
    ),
    caption = chanwe_caption("Source: mtcars")
  ) +
  theme_chanwe()

print(plot_kpi)

# 3) Typst table — signed delta coloring via chanwe_col_signed()
deltas <- data.frame(
  metric = c("Revenue", "EBITDA", "Net income", "Opex"),
  actual = c(1240.5, 310.2, 185.7, -420.3),
  delta = c(12.4, -3.1, 5.8, -1.9)
)

tbl <- chanwe_kbl(
  deltas,
  title = "Quarterly performance",
  subtitle = "Deltas vs previous quarter",
  eyebrow = "SECTION - FINANCE",
  caption = "Source: finance close, Q1",
  col_labels = c(metric = "Metric", actual = "USD K", delta = "QoQ"),
  fmt = list(
    actual = function(x) formatC(x, format = "f", digits = 1, big.mark = ","),
    delta = function(x) sprintf("%+.1f%%", x)
  ),
  col_colors = list(delta = chanwe_col_signed())
)

cat(as.character(tbl))
