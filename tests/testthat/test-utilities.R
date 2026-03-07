test_that("reporting css is bundled", {
  css <- chanwe_reporting_css()

  expect_true(file.exists(css))
  expect_match(css, "chanwe-reporting\\.scss$")
})

test_that("palette preview returns ggplot object", {
  plt <- chanwe_preview_palette("chart")

  expect_s3_class(plt, "ggplot")
})

test_that("chanwe_subtitle builds markdown accent string", {
  txt <- chanwe_subtitle("Performance update")

  expect_match(txt, "Performance update")
  if (requireNamespace("ggtext", quietly = TRUE)) {
    expect_match(txt, "<span")
    expect_match(txt, "#F7F7F7")
  } else {
    expect_false(grepl("<span|<br>", txt))
    expect_identical(txt, "Performance update")
  }
})

test_that("chanwe_title builds image-prefixed title string", {
  txt <- chanwe_title("Performance overview")

  if (requireNamespace("ggtext", quietly = TRUE)) {
    expect_match(txt, "<img")
    expect_match(txt, "Performance overview")
  } else {
    expect_identical(txt, "Performance overview")
  }
})
