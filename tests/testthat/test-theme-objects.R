test_that("theme_chanwe returns a theme with the ChanWe custom elements", {
  th <- theme_chanwe()

  expect_s3_class(th, "theme")
  expect_s3_class(th$plot.title, "element_chanwe_title")
  expect_s3_class(th$plot.subtitle, "element_chanwe_subtitle")
  expect_s3_class(th$plot.caption, "element_chanwe_caption")
  expect_identical(th$plot.title.position, "plot")
  expect_identical(th$plot.caption.position, "plot")
  expect_identical(th$legend.position, "bottom")
})

test_that("theme_chanwe background variants resolve to brand surfaces", {
  th_default <- theme_chanwe()
  th_white <- theme_chanwe(bg_color = "white")
  th_beige <- theme_chanwe(bg_color = "beige")
  th_hex <- theme_chanwe(bg_color = "#123456")

  expect_identical(th_default$plot.background$fill, "#F7F7F7")
  expect_identical(th_white$plot.background$fill, "#FFFFFF")
  expect_identical(th_beige$plot.background$fill, "#F5F1EB")
  expect_identical(th_hex$plot.background$fill, "#123456")
  expect_identical(th_white$panel.background$fill, "#FFFFFF")
  expect_identical(th_white$legend.background$fill, "#FFFFFF")
})

test_that("theme_chanwe honors layout parameters", {
  th <- theme_chanwe(
    base_text_size = 10,
    legend_position = "none",
    plot_padding = 18
  )

  expect_identical(th$legend.position, "none")
  expect_equal(as.numeric(th$plot.margin), rep(18, 4))
  expect_equal(th$plot.title$size, 10 * 1.85)
  expect_equal(th$plot.title$lineheight, 1.0)
  expect_identical(th$plot.title$eyebrow_colour, "#FD3810")
  expect_identical(th$plot.caption$primary_colour, "#FD3810")
  expect_equal(th$plot.subtitle$size, 10 * 0.9)
})

test_that("chanwe ggplot scales are constructed", {
  sc_d <- scale_color_chanwe_d()
  sf_d <- scale_fill_chanwe_d()
  sc_c <- scale_color_chanwe_c()
  sf_c <- scale_fill_chanwe_c()

  expect_s3_class(sc_d, "ScaleDiscrete")
  expect_s3_class(sf_d, "ScaleDiscrete")
  expect_s3_class(sc_c, "ScaleContinuous")
  expect_s3_class(sf_c, "ScaleContinuous")
})

test_that("discrete palette recycles beyond the 8 chart colors", {
  pal_fn <- chanwe_discrete_pal()
  chart <- unname(chanwe_palette("chart"))

  expect_identical(pal_fn(3), chart[1:3])
  expect_identical(pal_fn(8), chart)
  expect_identical(pal_fn(10), c(chart, chart[1:2]))
})

test_that("discrete palette accepts group names, raw vectors, and reverse", {
  blue_ramp <- unname(chanwe_palette("p15_blue"))

  expect_identical(chanwe_discrete_pal("p15_blue")(5), blue_ramp)
  expect_identical(chanwe_discrete_pal("p15_blue", reverse = TRUE)(5), rev(blue_ramp))
  expect_identical(chanwe_discrete_pal(c("#111111", "#222222"))(2), c("#111111", "#222222"))

  sc <- scale_fill_chanwe_d(palette = "p15_blue", reverse = TRUE)
  expect_s3_class(sc, "ScaleDiscrete")
})

test_that("sequential palettes are named, light-to-dark, and gated", {
  ramps <- c(
    "orange", "coral", "blue", "teal", "green",
    "vermillion", "magenta", "violet", "mustard", "ink"
  )
  for (r in ramps) {
    values <- chanwe_seq_pal(r)
    expect_true(length(values) >= 3, info = r)
  }

  # green and vermillion end in the signed poles for a readable dark end
  expect_identical(rev(chanwe_seq_pal("green"))[[1]], "#147705")
  expect_identical(rev(chanwe_seq_pal("vermillion"))[[1]], "#CC1914")

  # reverse flips, raw vectors pass through
  expect_identical(chanwe_seq_pal("blue", reverse = TRUE), rev(chanwe_seq_pal("blue")))
  expect_identical(chanwe_seq_pal(c("#111111", "#999999")), c("#111111", "#999999"))

  # yellow and cyan are deliberately not sequential ramps
  expect_error(chanwe_seq_pal("yellow"), "must be one of")
  expect_error(chanwe_seq_pal("cyan"), "must be one of")

  expect_s3_class(scale_color_chanwe_c(palette = "teal"), "ScaleContinuous")
  expect_s3_class(scale_fill_chanwe_c(palette = "green"), "ScaleContinuous")
})

test_that("diverging scale runs vermillion -> neutral -> green with signed poles", {
  ramp <- .chanwe_div_ramp()

  expect_identical(ramp[[1]], "#CC1914")
  expect_identical(ramp[[length(ramp)]], "#147705")
  expect_true("#E8E8E8" %in% ramp)

  expect_s3_class(scale_color_chanwe_div(), "ScaleContinuous")
  expect_s3_class(scale_fill_chanwe_div(), "ScaleContinuous")
  expect_s3_class(scale_fill_chanwe_div(reverse = TRUE), "ScaleContinuous")
})

test_that("chanwe_col_signed maps sign to the canonical tokens", {
  fn <- chanwe_col_signed()
  out <- fn(c(2.5, -1.25, 0, NA))

  expect_identical(out, c(
    'rgb("#147705")', 'rgb("#CC1914")', 'rgb("#666666")', 'rgb("#666666")'
  ))

  # flip = TRUE for smaller-is-better metrics
  expect_identical(
    chanwe_col_signed(flip = TRUE)(c(-3, 4)),
    c('rgb("#147705")', 'rgb("#CC1914")')
  )

  # custom threshold
  expect_identical(
    chanwe_col_signed(threshold = 10)(c(15, 5)),
    c('rgb("#147705")', 'rgb("#CC1914")')
  )

  # plugs into chanwe_kbl and colors by raw sign while fmt renders text
  skip_if_not_installed("knitr")
  df <- data.frame(m = c("a", "b"), delta = c(1.5, -2))
  txt <- as.character(chanwe_kbl(
    df,
    fmt = list(delta = function(x) sprintf("%+.1f%%", x)),
    col_colors = list(delta = chanwe_col_signed())
  ))
  expect_match(txt, 'rgb("#147705")', fixed = TRUE)
  expect_match(txt, 'rgb("#CC1914")', fixed = TRUE)
})

test_that("title/subtitle/kpi encoders produce parseable strings", {
  sep <- .CW_SEP

  expect_identical(chanwe_title("Plain"), "Plain")
  expect_identical(
    chanwe_title("Title", eyebrow = "SECTION"),
    paste("SECTION", "Title", sep = sep)
  )

  expect_identical(chanwe_subtitle("Sub"), "Sub")
  expect_identical(
    chanwe_subtitle("Sub", note = "Note"),
    paste("Sub", "Note", sep = sep)
  )

  kpi <- chanwe_kpi(
    num = "45,91", label = "USD MM", period = "05-MAY-2026",
    mtc1_num = "0,19%", mtc1_label = "WoW", mtc1_direction = "+",
    mtc2_num = "3,29%", mtc2_label = "MoM", mtc2_direction = "-"
  )
  parsed <- .cw_parse_kpi(kpi)

  expect_identical(parsed$value, "45,91")
  expect_identical(parsed$unit, "USD MM")
  expect_identical(parsed$date, "05-MAY-2026")
  expect_length(parsed$metrics, 2L)
  expect_identical(parsed$metrics[[1]]$label, "WoW")
  expect_identical(parsed$metrics[[1]]$dir, 1L)
  expect_identical(parsed$metrics[[2]]$dir, -1L)

  # note is dropped when a KPI panel is present
  with_kpi <- chanwe_subtitle("Sub", note = "ignored", kpi = kpi)
  parts <- strsplit(with_kpi, sep, fixed = TRUE)[[1]]
  expect_identical(parts[1], "Sub")
  expect_identical(parts[2], "")
  expect_identical(parts[3], kpi)

  expect_identical(chanwe_caption("Source: x"), "Source: x")
})

test_that("a full chanwe plot builds without errors", {
  df <- data.frame(x = 1:6, y = c(2, 4, 3, 6, 5, 7), g = rep(c("a", "b"), 3))

  p <- ggplot2::ggplot(df, ggplot2::aes(x, y, color = g)) +
    ggplot2::geom_line() +
    scale_color_chanwe_d() +
    ggplot2::labs(
      title = chanwe_title("Test title", eyebrow = "SECTION"),
      subtitle = chanwe_subtitle(
        "Test subtitle",
        kpi = chanwe_kpi(num = "1,0", label = "X", period = "2026")
      ),
      caption = chanwe_caption("Source: test")
    ) +
    theme_chanwe()

  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  # suppressWarnings: the pdf device lacks the brand fonts; only errors matter here
  expect_no_error(suppressWarnings(ggplot2::ggplotGrob(p)))
})
