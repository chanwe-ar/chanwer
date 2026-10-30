# brand-v2 Q3 / C1: the chart look and the colour rule

test_that("theme_chanwe follows the Q3 look", {
  th <- theme_chanwe()

  # horizontal slate grid only, 1px of plot.grid (ink-fg at 25%)
  expect_identical(th$panel.grid.major.y$colour, chanwe_tokens$plot$grid)
  expect_s3_class(th$panel.grid.major.x, "element_blank")
  expect_s3_class(th$panel.grid.minor, "element_blank")
  px <- 6.75 / chanwe_tokens$type$body
  expect_equal(th$panel.grid.major.y$linewidth, px / ggplot2::.pt)
  # no axis lines, no ticks
  expect_s3_class(th$axis.line, "element_blank")
  expect_s3_class(th$axis.ticks, "element_blank")
  # mono labels at the compact size in plot.axis-text
  compact <- chanwe_tokens$type$caption * px
  expect_equal(th$axis.text$size, compact)
  expect_identical(th$axis.text$colour, chanwe_tokens$plot$`axis-text`)
  expect_equal(th$legend.text$size, compact)
  expect_equal(th$plot.caption$size, compact)
  expect_false(th$plot.caption$stamp)
  expect_identical(th$plot.title$colour, chanwe_tokens$plot$title)

  # vertical grid for horizontal bars, or none
  th_x <- theme_chanwe(grid = "x")
  expect_s3_class(th_x$panel.grid.major.y, "element_blank")
  expect_identical(th_x$panel.grid.major.x$colour, chanwe_tokens$plot$grid)
  expect_s3_class(theme_chanwe(grid = "none")$panel.grid.major.y, "element_blank")

  # the 2.x stamp stays available
  th_s <- theme_chanwe(caption_style = "stamp")
  expect_true(th_s$plot.caption$stamp)
  expect_identical(th_s$plot.caption$colour, "#FFFFFF")
})

test_that("chanwe_focus_colors: orange for the focus, slate for the rest", {
  cols <- chanwe_focus_colors(c("b", "a", "c"), focus = "a")
  expect_named(cols, c("b", "a", "c"))
  expect_identical(cols[["a"]], chanwe_tokens$plot$focus)
  expect_true(all(cols[c("b", "c")] %in% chanwe_tokens$plot$slate))
  expect_false(cols[["b"]] == cols[["c"]])
  # one context series takes the middle of the ramp
  expect_identical(chanwe_focus_colors(c("a", "b"), "a")[["b"]], chanwe_tokens$plot$slate[[3]])
  # factors use their levels
  expect_named(chanwe_focus_colors(factor(c("x", "y"), levels = c("y", "x")), "x"), c("y", "x"))
  # many series interpolate the ramp
  expect_length(unique(chanwe_focus_colors(letters[1:9], "a")), 9L)
  expect_warning(chanwe_focus_colors(c("a", "b"), "z"), "not among")
  expect_warning(chanwe_focus_colors(c("a", "b", "c"), c("a", "b")), "More than one")
  expect_identical(
    unname(chanwe_focus_colors(c("a", "b"), "a", others = "#111319")[["b"]]),
    "#111319"
  )
})

test_that("focus scales colour the focus level wherever it falls", {
  df <- data.frame(x = 1:3, y = 1:3, g = c("Brasil", "Argentina", "Chile"))
  p <- ggplot2::ggplot(df, ggplot2::aes(x, y, colour = g, fill = g)) +
    ggplot2::geom_point() +
    scale_color_chanwe_focus("Chile") +
    scale_fill_chanwe_focus("Chile")
  b <- ggplot2::ggplot_build(p)$data[[1]]
  expect_identical(b$colour[df$g == "Chile"], chanwe_tokens$plot$focus)
  expect_true(all(b$colour[df$g != "Chile"] %in% chanwe_tokens$plot$slate))
  expect_identical(b$fill, b$colour)
  expect_error(scale_color_chanwe_focus(), "focus")
})

test_that("geom_chanwe_col rounds only the outer end of each bar", {
  df <- data.frame(
    x = c("a", "a", "b", "c"), y = c(2, 3, 4, -2), g = c("p", "q", "p", "p")
  )
  p <- ggplot2::ggplot(df, ggplot2::aes(x, y, fill = g)) + geom_chanwe_col()
  b <- ggplot2::ggplot_build(p)
  d <- b$data[[1]]
  r <- .cw_bar_radii(d, ggplot2::coord_cartesian(), 2)
  # stacked "a": only the top segment is round; "c" (negative) rounds below
  outer_a <- which(d$x == 1 & d$ymax == max(d$ymax[d$x == 1]))
  inner_a <- which(d$x == 1 & d$ymax != max(d$ymax[d$x == 1]))
  expect_identical(r[outer_a, ], c(0, 0, 2, 2))
  expect_identical(r[inner_a, ], c(0, 0, 0, 0))
  neg <- which(d$ymin < 0)
  expect_identical(r[neg, ], c(2, 2, 0, 0))
  # horizontal on screen: the right end
  r_flip <- .cw_bar_radii(d, ggplot2::coord_flip(), 2)
  expect_identical(r_flip[outer_a, ], c(0, 2, 2, 0))

  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_no_error(suppressWarnings(print(p + theme_chanwe())))
  expect_no_error(suppressWarnings(print(p + ggplot2::coord_polar())))
  bar <- ggplot2::ggplot(mtcars, ggplot2::aes(factor(cyl))) + geom_chanwe_bar()
  expect_no_error(suppressWarnings(print(bar)))
  expect_identical(.cw_bar_radius_pt(), chanwe_tokens$plot$`bar-radius` * 0.75)
})

test_that("rounded corners clamp to the bar", {
  pts <- .cw_round_rect_xy(0, 0, 4, 10, c(0, 0, 3, 3))
  expect_true(all(pts$x >= 0 & pts$x <= 4))
  expect_true(all(pts$y >= 0 & pts$y <= 10))
  expect_equal(max(pts$y), 10)
})

test_that("draw_key_chanwe_pill draws a pill in the fill or the colour", {
  k <- draw_key_chanwe_pill(data.frame(fill = NA, colour = "#FD3810"), list(), 1)
  expect_s3_class(k, "roundrect")
  expect_identical(substr(k$gp$fill, 1, 7), "#FD3810")
})

test_that("chanwe_kbl draws a v2 pane from the tokens", {
  skip_if_not_installed("knitr")
  df <- data.frame(m = c("a", "b"), v = c(1.5, -2))
  txt <- as.character(chanwe_kbl(df, title = "T", caption = "Fuente"))
  expect_match(txt, "radius: 8pt, clip: true", fixed = TRUE)
  expect_match(txt, sprintf('fill: rgb("%s")', chanwe_palette("all")[["tint"]]), fixed = TRUE)
  expect_false(grepl('#box(fill: rgb("#FD3810")', txt, fixed = TRUE))
  expect_match(txt, chanwe_tokens$fonts$display, fixed = TRUE)
  stamp <- as.character(chanwe_kbl(df, caption = "Fuente", caption_style = "stamp", pane = FALSE))
  expect_match(stamp, '#box(fill: rgb("#FD3810")', fixed = TRUE)
  expect_false(grepl("clip: true", stamp, fixed = TRUE))
  withr_opt <- options(chanwer.caption_style = "stamp")
  on.exit(options(withr_opt), add = TRUE)
  expect_match(as.character(chanwe_kbl(df, caption = "F")), "#box(fill:", fixed = TRUE)
})

test_that("HTML helpers draw panes, tint headers and mono captions", {
  skip_if_not_installed("gt")
  skip_if_not_installed("reactable")
  skip_if_not_installed("highcharter")
  tk <- chanwe_html_tokens()
  fleet <- data.frame(model = c("A", "B"), mpg = c(21, 22.8))

  g <- chanwe_gt(fleet, title = "T", caption = "Fuente", id = "cwv2")
  css <- paste(g[["_options"]]$value[[which(g[["_options"]]$parameter == "table_additional_css")]], collapse = "\n")
  expect_match(css, "border-radius:16px", fixed = TRUE)
  expect_match(css, tk$tint, fixed = TRUE)
  html <- as.character(gt::as_raw_html(g, inline_css = FALSE))
  expect_false(grepl("background:#FD3810", html, fixed = TRUE))

  x <- chanwe_reactable(fleet, title = "T", caption = "Fuente")
  th <- x$x$tag$attribs$theme
  expect_identical(th$headerStyle$backgroundColor, tk$tint)
  expect_identical(th$pageButtonStyle$borderRadius, "999px")

  hc <- highcharter::highchart() |>
    highcharter::hc_add_series(data = c(1, 3, 2), type = "column", name = "A") |>
    highcharter::hc_add_series(data = c(2, 1, 2), type = "column", name = "B")
  hc <- chanwe_highchart(hc, title = "T", focus = "B")
  expect_identical(hc$x$hc_opts$series[[2]]$color, chanwe_tokens$plot$focus)
  expect_identical(hc$x$hc_opts$series[[1]]$color, chanwe_tokens$plot$slate[[3]])
  expect_identical(hc$x$hc_opts$plotOptions$column$borderRadius, chanwe_tokens$plot$`bar-radius`)
  expect_match(hc$x$hc_opts$yAxis$gridLineColor, "^rgba\\(100,116,139,0.25\\)$")
})
