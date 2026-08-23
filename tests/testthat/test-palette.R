test_that("chanwe_palette('all') returns the full named color vector", {
  pal <- chanwe_palette("all")

  expect_type(pal, "character")
  expect_true(all(nzchar(names(pal))))
  expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", pal)))

  # Core brand anchors
  expect_identical(pal[["brand-orange"]], "#E94B2B")
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

test_that("chart palette is the editorial 8-color set", {
  chart <- chanwe_palette("chart")

  expect_length(chart, 8L)
  expect_identical(
    unname(chart),
    c(
      "#EE5524", "#0C48ED", "#1EB508", "#E8B400",
      "#9B2E8F", "#14A4B8", "#EB03F2", "#141414"
    )
  )
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
      "success", "warning", "danger", "info"
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
    c("note", "info", "success", "warning", "important", "caution", "alert")
  )
})
