test_that("theme_chanwe returns a complete ggplot theme", {
  th <- theme_chanwe(add_logo = FALSE)
  th_custom <- theme_chanwe(
    base_text_size = 11,
    legend_position = "bottom",
    add_logo = FALSE
  )
  th_logo <- theme_chanwe()

  expect_s3_class(th, "theme")
  if (requireNamespace("ggtext", quietly = TRUE)) {
    expect_true(is.list(th_logo))
    expect_s3_class(th_logo[[1]], "theme")
    expect_true(is.character(th_logo[[2]]$tag))
    expect_true(grepl("img", th_logo[[2]]$tag))
  } else {
    expect_s3_class(th_logo, "theme")
  }
  expect_identical(th$plot.title$face, "bold")
  expect_identical(th$plot.title$hjust, 0)
  expect_identical(th$plot.subtitle$hjust, 0)
  expect_identical(th$plot.caption$hjust, 1)
  expect_identical(th$plot.caption$colour, "#6D6D6D")
  expect_identical(th$plot.background$fill, "#F7F7F7")
  expect_identical(th$panel.background$fill, "#F7F7F7")
  expect_identical(th$legend.background$fill, "#F7F7F7")
  expect_identical(th$legend.position, "bottom")
  expect_equal(th$legend.title$size, 9.75)
  expect_equal(th$legend.text$size, 9)
  expect_identical(th_custom$legend.position, "bottom")
  expect_equal(th_custom$axis.title$size, 8.58)
  expect_equal(th_custom$axis.text$size, 7.04)
  expect_equal(as.numeric(th$plot.margin)[1], 22)
  expect_equal(as.numeric(th$plot.margin)[2], 22)
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

test_that("gt theme function returns gt_tbl", {
  skip_if_not_installed("gt")

  tbl_default <- gt::gt(head(mtcars)) |>
    gt_theme_chanwe()
  tbl_compact <- gt::gt(head(mtcars)) |>
    gt_theme_chanwe(variant = "compact")
  tbl_spacious <- gt::gt(head(mtcars)) |>
    gt_theme_chanwe_spacious()
  tbl_compact_wrap <- gt::gt(head(mtcars)) |>
    gt_theme_chanwe_compact()

  expect_s3_class(tbl_default, "gt_tbl")
  expect_s3_class(tbl_compact, "gt_tbl")
  expect_s3_class(tbl_spacious, "gt_tbl")
  expect_s3_class(tbl_compact_wrap, "gt_tbl")
})

test_that("reactable theme function returns reactable theme object", {
  skip_if_not_installed("reactable")

  theme <- reactable_theme_chanwe()

  expect_s3_class(theme, "reactableTheme")
  expect_identical(theme$style$fontFamily, "DM Sans")
})

test_that("highcharter helper returns hc theme", {
  skip_if_not_installed("highcharter")

  theme <- hc_theme_chanwe()
  theme_no_logo <- hc_theme_chanwe(add_logo = FALSE)

  expect_s3_class(theme, "hc_theme")
  expect_identical(theme$chart$style$fontFamily, "DM Sans")
  expect_identical(theme$chart$borderRadius, 4)
  expect_identical(theme$chart$backgroundColor, "#F7F7F7")
  expect_identical(theme$chart$spacingTop, 28)
  expect_identical(theme$chart$spacingRight, 26)
  expect_false(is.null(theme$chart$events$load))
  expect_true(is.null(theme_no_logo$chart$events$load))
  expect_identical(theme$xAxis$gridLineWidth, 1)
  expect_identical(theme$xAxis$title$style$fontWeight, "700")
  expect_identical(theme$yAxis$title$style$fontWeight, "700")
  expect_identical(theme$xAxis$labels$style$color, "#6D6D6D")
  expect_identical(theme$yAxis$labels$style$color, "#6D6D6D")
  expect_identical(theme$plotOptions$series$dataLabels$style$color, "#6D6D6D")
})
