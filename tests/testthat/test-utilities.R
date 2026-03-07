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
  skip_if_not_installed("ggtext")

  txt <- chanwe_title("Performance overview")
  bundled <- system.file("assets", "Estrategia_Color1.png", package = "chanwer")

  expect_match(txt, "<img")
  expect_match(txt, "Performance overview")
  expect_match(txt, "src='")
  src <- sub("^.*<img src='([^']+)'.*$", "\\1", txt)
  expect_true(nzchar(src))
  expect_identical(normalizePath(src, winslash = "/", mustWork = TRUE), normalizePath(bundled, winslash = "/", mustWork = TRUE))
  if (startsWith(src, "data:")) {
    expect_match(src, "data:image/", fixed = TRUE)
  } else {
    expect_true(file.exists(src))
    expect_match(src, "\\.png$")
  }
})

test_that("chanwe_title errors when marker_path is missing", {
  skip_if_not_installed("ggtext")
  missing_marker <- "DOES_NOT_EXIST_chanwer_marker.png"
  unlink(missing_marker, force = TRUE)

  expect_snapshot(
    error = TRUE,
    chanwe_title("Performance overview", marker_path = missing_marker)
  )
})
