test_that("reporting css is bundled", {
  css <- chanwe_reporting_css()

  expect_true(file.exists(css))
  expect_match(css, "chanwe-reporting\\.scss$")
})

test_that("palette preview returns ggplot object", {
  plt <- chanwe_preview_palette("chart")

  expect_s3_class(plt, "ggplot")
})

test_that("chanwe_resolve_bg maps named surfaces to hex", {
  expect_identical(chanwe_resolve_bg("white"), "#FFFFFF")
  expect_identical(chanwe_resolve_bg("beige"), "#F5F1EB")
  expect_identical(chanwe_resolve_bg("metallic"), "#F7F7F7")
  expect_identical(chanwe_resolve_bg("gray"), "#EDF0F1")
  expect_identical(chanwe_resolve_bg("grey"), "#EDF0F1")
  expect_identical(chanwe_resolve_bg("white-ivory"), "#FAF9F7")
  expect_identical(chanwe_resolve_bg("transparent"), "transparent")
  # hex strings pass through untouched
  expect_identical(chanwe_resolve_bg("#ABCDEF"), "#ABCDEF")
})

test_that("chanwe_base64_encode matches the base64 reference vectors", {
  expect_identical(chanwe_base64_encode(charToRaw("Man")), "TWFu")
  expect_identical(chanwe_base64_encode(charToRaw("Ma")), "TWE=")
  expect_identical(chanwe_base64_encode(charToRaw("M")), "TQ==")
  expect_identical(chanwe_base64_encode(raw(0)), "")
})

test_that("chanwe_png_dims reads dimensions from a bundled asset", {
  asset <- chanwe_logo_path("Estrategia_Color1.png")
  skip_if(!nzchar(asset), "bundled asset not found")

  dims <- chanwe_png_dims(asset)

  expect_type(dims, "list")
  expect_true(dims$width > 0)
  expect_true(dims$height > 0)
  expect_null(chanwe_png_dims("nonexistent.png"))
})

test_that("chanwe_kbl emits a raw typst block", {
  skip_if_not_installed("knitr")

  df <- data.frame(
    item = c("Alpha", "Beta"),
    amount = c(1234.5, 678.9)
  )

  out <- chanwe_kbl(
    df,
    title = "Test table",
    subtitle = "Sub line",
    eyebrow = "SECTION",
    caption = "Source: test",
    col_labels = c(item = "Item", amount = "Amount (USD)")
  )

  expect_s3_class(out, "knit_asis")
  txt <- as.character(out)
  expect_match(txt, "```\\{=typst\\}")
  expect_match(txt, "#table\\(", perl = TRUE)
  expect_match(txt, "Test table", fixed = TRUE)
  expect_match(txt, "ITEM", fixed = TRUE)
  expect_match(txt, "AMOUNT (USD)", fixed = TRUE)
})

test_that("chanwe_kbl escapes typst markup characters in cells", {
  skip_if_not_installed("knitr")

  df <- data.frame(x = "value_with [brackets] #hash *stars*")
  txt <- as.character(chanwe_kbl(df))

  expect_match(txt, "value\\_with \\[brackets\\] \\#hash \\*stars\\*", fixed = TRUE)
})

test_that("col_colors receives pre-format values even when fmt renders text", {
  skip_if_not_installed("knitr")

  df <- data.frame(metric = c("Revenue", "EBITDA"), delta = c(2.5, -1.25))
  seen <- NULL

  txt <- as.character(chanwe_kbl(
    df,
    fmt = list(delta = function(x) sprintf("%+.2f%%", x)),
    col_colors = list(delta = function(x) {
      seen <<- x
      ifelse(x < 0, 'rgb("#B03A2E")', 'rgb("#2D7A4F")')
    })
  ))

  # the color function saw the raw numeric column, not fmt's strings
  expect_identical(seen, df$delta)
  # each sign got its color, and fmt's text rendering still applies
  expect_match(txt, 'rgb("#2D7A4F")', fixed = TRUE)
  expect_match(txt, 'rgb("#B03A2E")', fixed = TRUE)
  expect_match(txt, "+2.50%", fixed = TRUE)
  expect_match(txt, "-1.25%", fixed = TRUE)
})

test_that("chanwe_kbl auto-aligns numeric columns right", {
  skip_if_not_installed("knitr")

  df <- data.frame(name = "a", num = 1)
  txt <- as.character(chanwe_kbl(df))

  expect_match(txt, "align: (left, right,)", fixed = TRUE)
})
