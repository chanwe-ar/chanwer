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

test_that("HTML helpers load the brand fonts from local files, not a CDN", {
  skip_if_not_installed("htmltools")

  dep <- chanwe_html_fonts_dependency()[[1]]
  expect_identical(dep$name, "chanwe-fonts")
  expect_null(dep$head)
  expect_identical(dep$stylesheet, "chanwe-fonts.css")

  css_path <- file.path(dep$src$file, dep$stylesheet)
  css <- paste(readLines(css_path), collapse = "\n")
  expect_false(grepl("googleapis|gstatic|fontshare|https?://", css))
  expect_false(grepl("\"Inter\"", css, fixed = TRUE))
  for (fam in c("Satoshi", "Schibsted Grotesk", "JetBrains Mono")) {
    expect_match(css, sprintf("font-family: \"%s\"", fam), fixed = TRUE)
  }
  urls <- regmatches(css, gregexpr('url\\("[^"]+"\\)', css))[[1]]
  files <- gsub('^url\\("|"\\)$', "", urls)
  expect_true(length(files) >= 10)
  expect_true(all(file.exists(file.path(dep$src$file, files))))

  # the stacks lead with the brand trio and never name Inter
  expect_match(.cw_font_sans, "^Satoshi,")
  expect_match(.cw_font_display, "^Schibsted Grotesk,")
  expect_false(any(grepl("Inter", c(.cw_font_sans, .cw_font_display, .cw_font_mono))))
})

test_that("the reporting stylesheet uses the bundled fonts", {
  scss_path <- chanwe_reporting_css()
  scss <- paste(readLines(scss_path), collapse = "\n")

  expect_false(grepl("googleapis|gstatic|fontshare", scss))
  expect_false(grepl("Inter", scss))
  urls <- regmatches(scss, gregexpr('url\\("\\.\\./fonts/[^"]+"\\)', scss))[[1]]
  files <- gsub('^url\\("|"\\)$', "", urls)
  expect_true(length(files) >= 10)
  expect_true(all(file.exists(file.path(dirname(scss_path), files))))
})

test_that("chanwe_gt sets the table in Satoshi", {
  skip_if_not_installed("gt")
  g <- chanwe_gt(fleet, title = "Fleet", id = "cwfont")
  opts <- g[["_options"]]
  fonts <- opts$value[[which(opts$parameter == "table_font_names")]]
  expect_identical(fonts[[1]], "Satoshi")
  expect_false("Inter" %in% fonts)
})

test_that("chanwe_highchart attaches local fonts and no Google Fonts loader", {
  skip_if_not_installed("highcharter")
  skip_if_not_installed("htmlwidgets")

  hc <- highcharter::highchart() |>
    highcharter::hc_add_series(data = c(1, 3, 2), type = "line", name = "A")
  hc <- chanwe_highchart(hc, title = "T", eyebrow = "SECTION", caption = "Source")

  expect_null(hc$x$fonts)
  expect_true(any(vapply(hc$dependencies, function(d) d$name == "chanwe-fonts", logical(1))))
  title <- hc$x$hc_opts$title$text
  expect_match(title, "text-transform:uppercase", fixed = TRUE)
  expect_false(grepl("Inter", title, fixed = TRUE))
})
