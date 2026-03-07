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
  expect_match(txt, "<span")
  expect_match(txt, "#E94B2B")
})
