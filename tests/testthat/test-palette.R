test_that("chanwe_palette('all') returns the full named color vector", {
  pal <- chanwe_palette("all")

  expect_type(pal, "character")
  expect_true(all(nzchar(names(pal))))
  # brand.yml `border` carries alpha (#RRGGBBAA)
  expect_true(all(grepl("^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$", pal)))
  expect_false(any(grepl("beige", names(pal))))

  # Core brand anchors, resolved to brand.yml
  expect_identical(pal[["primary"]], "#FD3810")
  expect_identical(pal[["ink"]], "#111319")
  expect_identical(pal[["paper"]], "#F8FAFC")
  expect_identical(pal[["brand-orange"]], pal[["primary"]])
  expect_identical(pal[["brand-black"]], pal[["ink"]])
  expect_identical(pal[["typst-primary"]], pal[["primary"]])
  expect_identical(pal[["typst-ink"]], pal[["ink"]])
})

test_that("chanwe_palette(NULL) returns all colors plus grouped palettes", {
  grouped <- chanwe_palette()

  expect_named(grouped, c("all", "groups"))
  expect_identical(grouped$all, chanwe_palette("all"))
  expect_true(all(
    c(
      "core", "brand", "p13_orange", "p13_gray", "p14_accents",
      "p15_coral", "p15_vermillion", "p15_green", "p15_magenta",
      "p15_blue", "p15_yellow", "p15_cyan", "p15_mustard",
      "p15_violet", "p15_teal", "p15_ink",
      "mb_orange", "mb_dark",
      "semantic", "chart"
    ) %in% names(grouped$groups)
  ))

  # Each p15 family carries a 5-shade ramp; each mb ramp has 10 or 5 shades
  expect_length(grouped$groups$p15_coral, 5L)
  expect_length(grouped$groups$mb_orange, 10L)
  expect_false(any(grepl("beige", names(grouped$groups))))
})

test_that("chart palette follows brand.yml meta.chart-palette-order", {
  chart <- chanwe_palette("chart")

  expect_named(
    chart,
    c(
      "primary", "chart-blue", "chart-green", "chart-indigo",
      "chart-orange", "chart-teal", "chart-purple", "chart-red"
    )
  )
  expect_identical(
    unname(chart),
    c(
      "#FD3810", "#007AFF", "#34C759", "#5856D6",
      "#FF9500", "#00C7BE", "#AF52DE", "#FF3B30"
    )
  )
})

test_that("signed tokens are canonical and mapped into semantic", {
  signed <- chanwe_palette("signed")

  expect_named(signed, c("positive", "negative", "neutral"))
  expect_identical(signed[["positive"]], "#147705")
  expect_identical(signed[["negative"]], "#CC1914")
  expect_identical(signed[["neutral"]], "#475569")

  semantic <- chanwe_palette("semantic")
  expect_identical(semantic[["positive"]], signed[["positive"]])
  expect_identical(semantic[["negative"]], signed[["negative"]])
  expect_identical(semantic[["neutral"]], signed[["neutral"]])
})

test_that("chanwe_palette rejects unknown palette names", {
  expect_error(chanwe_palette("does-not-exist"), "`palette` must be one of")
})

test_that("chanwe_brand_tokens carries semantic mapping and structure", {
  tokens <- chanwe_brand_tokens()

  expect_named(
    tokens$semantic,
    c(
      "foreground", "background", "primary", "secondary",
      "success", "warning", "danger", "info",
      "positive", "negative", "neutral"
    )
  )
  expect_identical(tokens$semantic[["primary"]], "#FD3810")
  expect_identical(tokens$semantic[["foreground"]], "#475569")
  expect_identical(tokens$semantic[["background"]], "#F8FAFC")

  expect_true(all(
    c("name", "colors", "semantic", "chart_order", "typography", "geometry", "reporting") %in%
      names(tokens)
  ))
  expect_identical(tokens$chart_order, chanwe_palette("chart"))
  expect_identical(tokens$typography$family, "Inter")
  expect_identical(tokens$typography$display_family, "Schibsted Grotesk")
  expect_named(
    tokens$reporting$callouts,
    c("note", "info", "tip", "success", "warning", "important", "caution", "alert")
  )
})
