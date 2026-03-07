expected_colors <- c(
  "brand-orange" = "#E94B2B",
  "brand-black" = "#101010",
  "brand-white" = "#F7F7F7",
  "brand-pure-white" = "#FFFFFF",
  "brand-beige" = "#F8F8F8",
  "brand-beige-soft" = "#EEEEEE",
  "brand-gray" = "#6B6B6B",
  "brand-silver" = "#C9C9C9",
  "p13-orange-01" = "#E94B2B",
  "p13-orange-02" = "#EA5A3C",
  "p13-orange-03" = "#EC684E",
  "p13-orange-04" = "#ED775F",
  "p13-orange-05" = "#EF8670",
  "p13-orange-06" = "#F09482",
  "p13-orange-07" = "#F2A393",
  "p13-orange-08" = "#F5C0B6",
  "p13-orange-09" = "#F6CFC7",
  "p13-orange-10" = "#F8DDD9",
  "p13-gray-01" = "#101010",
  "p13-gray-02" = "#232323",
  "p13-gray-03" = "#353535",
  "p13-gray-04" = "#484848",
  "p13-gray-05" = "#5B5B5B",
  "p13-gray-06" = "#6D6D6D",
  "p13-gray-07" = "#929292",
  "p13-gray-08" = "#A5A5A5",
  "p13-gray-09" = "#B8B8B8",
  "p13-gray-10" = "#CACACA",
  "p14-yellow-strong" = "#F9E710",
  "p14-yellow-soft" = "#FFF8B8",
  "p14-cyan-strong" = "#11F7E6",
  "p14-cyan-soft" = "#B6FFF8",
  "p14-blue-strong" = "#0C48ED",
  "p14-blue-soft" = "#B8CEFF",
  "p14-magenta-strong" = "#EB03F2",
  "p14-magenta-soft" = "#FDCFFF",
  "p14-green-strong" = "#1EB508",
  "p14-green-soft" = "#C9FFC0",
  "p14-red-strong" = "#F40C0C",
  "p14-red-soft" = "#F9A7A7"
)

test_that("chanwe_palette returns exact source-of-truth colors", {
  pal <- chanwe_palette("all")

  expect_identical(pal, expected_colors)
})

test_that("chanwe_palette grouped palettes are available", {
  grouped <- chanwe_palette()

  expect_named(grouped, c("all", "groups"))
  expect_named(
    grouped$groups,
    c("core", "p13_orange", "p13_gray", "p14_accents", "semantic", "chart")
  )
  expect_identical(
    grouped$groups$chart,
    expected_colors[c(
      "brand-orange",
      "p14-blue-strong",
      "p14-cyan-strong",
      "p14-green-strong",
      "p14-yellow-strong",
      "p14-magenta-strong",
      "p14-red-strong",
      "brand-gray"
    )]
  )
})

test_that("chanwe_brand_tokens carries semantic mapping", {
  tokens <- chanwe_brand_tokens()

  expect_named(
    tokens$semantic,
    c("foreground", "background", "primary", "secondary", "success", "warning", "danger", "info")
  )
  expect_identical(tokens$semantic[["primary"]], "#E94B2B")
  expect_identical(tokens$semantic[["foreground"]], "#5B5B5B")
})
