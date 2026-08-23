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
  expect_equal(th$plot.title$size, 10 * 1.50)
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
