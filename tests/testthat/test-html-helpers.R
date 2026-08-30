fleet <- data.frame(
  model = c("A", "B", "C"),
  mpg = c(21, 22.8, 18.7),
  delta = c(6, -6.6, 0)
)

test_that("chanwe_signed_color maps valence, not raw sign", {
  tk <- chanwe_html_tokens()
  expect_identical(
    chanwe_signed_color(c(1, -1, 0, NA), tk),
    c(tk$positive, tk$negative, tk$neutral, tk$neutral)
  )
  expect_identical(
    chanwe_signed_color(c(1, -1), tk, smaller_is_better = TRUE),
    c(tk$negative, tk$positive)
  )
})

test_that("chanwe_gt builds a gt table with the chanwe heading", {
  skip_if_not_installed("gt")

  g <- chanwe_gt(
    fleet,
    title = "Fleet",
    eyebrow = "TABLE",
    subtitle = "Sub",
    caption = "Source",
    stub = "model",
    signed = "delta",
    id = "cwtest"
  )
  expect_s3_class(g, "gt_tbl")

  html <- as.character(gt::as_raw_html(g, inline_css = FALSE))
  expect_match(html, "chanwe-eyebrow")
  expect_match(html, "TABLE")
  expect_match(html, "chanwe-title")
  expect_match(html, "Source")
  # thin stub and header rules replace gt's 2px defaults
  expect_match(html, "#cwtest .gt_stub")
  opts <- g[["_options"]]
  expect_identical(opts$value[[which(opts$parameter == "stub_border_width")]], "1px")
  expect_identical(opts$value[[which(opts$parameter == "table_body_border_top_style")]], "none")

  expect_error(chanwe_gt(fleet, signed = "nope"), "not found")
})

test_that("chanwe_reactable returns a widget with header and caption", {
  skip_if_not_installed("reactable")
  skip_if_not_installed("htmlwidgets")
  skip_if_not_installed("htmltools")

  x <- chanwe_reactable(
    fleet,
    title = "Fleet",
    eyebrow = "TABLE",
    caption = "Source",
    signed = "delta",
    defaultPageSize = 5
  )
  expect_s3_class(x, "reactable")
  expect_s3_class(x, "htmlwidget")

  pre <- paste(vapply(x$prepend, function(t) as.character(t), character(1)), collapse = "")
  expect_match(pre, "chanwe-eyebrow")
  expect_match(pre, "TABLE")
  post <- paste(vapply(x$append, function(t) as.character(t), character(1)), collapse = "")
  expect_match(post, "Source")
  expect_true(any(vapply(x$dependencies, function(d) d$name == "chanwe-fonts", logical(1))))

  expect_error(chanwe_reactable(fleet, signed = "nope"), "not found")
})

test_that("chanwe_plotly applies the chanwe layout and config", {
  skip_if_not_installed("plotly")

  p <- plotly::plot_ly(fleet, x = ~model, y = ~mpg, type = "bar")
  p <- chanwe_plotly(p, title = "Fleet", eyebrow = "SECTION", caption = "Source")
  expect_s3_class(p, "plotly")

  b <- plotly::plotly_build(p)
  expect_match(b$x$layout$title$text, "SECTION")
  expect_match(b$x$layout$title$text, "#E94B2B")
  expect_identical(b$x$layout$hovermode, "x unified")
  expect_false(b$x$config$displayModeBar)
  expect_true(any(vapply(p$dependencies, function(d) d$name == "chanwe-fonts", logical(1))))
})
