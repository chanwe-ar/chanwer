skip_if_not_installed("highcharter")

primary <- chanwer:::chanwe_html_tokens()$primary
opts <- function(w) w$x$hc_opts

test_that("chanwe_hc_bars puts the focus in orange and sorts", {
  d <- data.frame(r = c("B", "A", "C"), v = c(2, 5, 1))
  o <- opts(chanwe_hc_bars(d, "r", "v", focus = "B"))
  expect_equal(unlist(o$xAxis$categories), c("A", "B", "C"))
  s <- o$series[[1]]
  expect_equal(s$colors[[2]], primary)
  expect_false(s$colors[[1]] == primary)
  expect_true(s$dataLabels$enabled)
})

test_that("chanwe_hc_lines names every line at its end and spreads crowded names", {
  d <- data.frame(t = rep(1:3, 2), v = c(1, 2, 10, 1, 2, 10.1), g = rep(c("A", "B"), each = 3))
  o <- opts(chanwe_hc_lines(d, "t", "v", "g", focus = "A"))
  nm <- vapply(o$series, function(s) s$name, character(1))
  expect_equal(o$series[[which(nm == "A")]]$color, primary)
  ends <- o$series[[which(nm == "ends")]]$data
  expect_length(ends, 2)
  ys <- vapply(ends, function(p) p$y, numeric(1))
  expect_gte(abs(diff(ys)), 0.1 * 9.1 - 1e-9)
})

test_that("chanwe_hc_lines spaghetti names only the focus", {
  d <- data.frame(t = rep(1:3, 3), v = 1:9, g = rep(c("A", "B", "C"), each = 3))
  o <- opts(chanwe_hc_lines(d, "t", "v", "g", focus = "C", style = "spaghetti"))
  nm <- vapply(o$series, function(s) s$name, character(1))
  expect_length(o$series[[which(nm == "ends")]]$data, 1)
})

test_that("chanwe_hc_area fills with a fading gradient and pills the last value", {
  o <- opts(chanwe_hc_area(data.frame(t = 1:4, v = c(1, 2, 3, 4.25)), "t", "v"))
  s <- o$series[[1]]
  expect_equal(s$fillColor$stops[[2]][[2]], "rgba(253,56,16,0)")
  expect_equal(s$data[[4]]$dataLabels$format, "4,2")
})

test_that("chanwe_hc_scatter colours focus and highlight", {
  d <- data.frame(x = 1:4, y = c(2, 1, 4, 3), n = c("a", "b", "c", "d"))
  o <- opts(chanwe_hc_scatter(d, "x", "y", "n", focus = "c", highlight = "a", style = "trend"))
  pts <- o$series[[1]]$data
  cols <- setNames(vapply(pts, function(p) p$color, character(1)), vapply(pts, function(p) p$name, character(1)))
  expect_equal(cols[["c"]], primary)
  expect_length(o$series, 2)
})

test_that("chanwe_hc_heatmap is signed and symmetric", {
  d <- expand.grid(x = c("a", "b"), y = c("p", "q")); d$v <- c(-3, 1, 2, 0)
  o <- opts(chanwe_hc_heatmap(d, "x", "y", "v"))
  expect_equal(o$colorAxis$min, -3)
  expect_equal(o$colorAxis$max, 3)
  expect_length(o$colorAxis$stops, 3)
})

test_that("chanwe_hc_stack stacks the focus at the base in orange", {
  d <- data.frame(y = rep(c("1", "2"), each = 2), s = rep(c("A", "B"), 2), v = c(3, 5, 4, 6))
  o <- opts(chanwe_hc_stack(d, "y", "s", "v", focus = "A", style = "share"))
  expect_equal(o$plotOptions$column$stacking, "percent")
  last <- o$series[[length(o$series)]]
  expect_equal(last$name, "A")
  expect_equal(last$color, primary)
})
