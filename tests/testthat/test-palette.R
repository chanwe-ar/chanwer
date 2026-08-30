test_that("chanwe_palette('all') returns the full named color vector", {
  pal <- chanwe_palette("all")

  expect_type(pal, "character")
  expect_true(all(nzchar(names(pal))))
  expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", pal)))

  # Core brand anchors
  expect_identical(pal[["brand-orange"]], "#FD3810")
  expect_identical(pal[["brand-black"]], "#101010")
  expect_identical(pal[["typst-primary"]], "#FD3810")
  expect_identical(pal[["typst-ink"]], "#0F0F0F")
})

test_that("chanwe_palette(NULL) returns all colors plus grouped palettes", {
  grouped <- chanwe_palette()

  expect_named(grouped, c("all", "groups"))
  expect_identical(grouped$all, chanwe_palette("all"))
  expect_true(all(
    c(
      "core", "p13_orange", "p13_gray", "p14_accents",
      "p15_coral", "p15_vermillion", "p15_green", "p15_magenta",
      "p15_blue", "p15_yellow", "p15_cyan", "p15_mustard",
      "p15_violet", "p15_teal", "p15_ink",
      "mb_orange", "mb_dark", "mb_beige",
      "semantic", "chart"
    ) %in% names(grouped$groups)
  ))

  # Each p15 family carries a 5-shade ramp; each mb ramp has 10 or 5 shades
  expect_length(grouped$groups$p15_coral, 5L)
  expect_length(grouped$groups$mb_orange, 10L)
  expect_length(grouped$groups$mb_beige, 5L)
})

test_that("chart palette is the editorial 8-color set in CVD-validated order", {
  chart <- chanwe_palette("chart")

  expect_length(chart, 8L)
  # Fixed slot order: coral, blue, teal, green, violet, magenta, mustard, ink.
  # Validated for adjacent-pair CVD separation; mustard and ink deliberately
  # last. Do not re-order without re-running the palette validator.
  expect_identical(
    unname(chart),
    c(
      "#EE5524", "#0C48ED", "#14A4B8", "#1EB508",
      "#9B2E8F", "#EB03F2", "#E8B400", "#141414"
    )
  )
})

test_that("signed tokens are canonical and mapped into semantic", {
  signed <- chanwe_palette("signed")

  expect_named(signed, c("positive", "negative", "neutral"))
  expect_identical(signed[["positive"]], "#147705")
  expect_identical(signed[["negative"]], "#CC1914")
  expect_identical(signed[["neutral"]], "#666666")

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
  expect_identical(tokens$semantic[["foreground"]], "#211F1C")
  expect_identical(tokens$semantic[["background"]], "#F5F5F5")

  expect_true(all(
    c("name", "colors", "semantic", "chart_order", "typography", "geometry", "reporting") %in%
      names(tokens)
  ))
  expect_identical(tokens$chart_order, chanwe_palette("chart"))
  expect_identical(tokens$typography$family, "Satoshi")
  expect_named(
    tokens$reporting$callouts,
    c("note", "info", "tip", "success", "warning", "important", "caution", "alert")
  )
})
