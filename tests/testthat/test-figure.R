test_that("chanwe_figure builds and draws in both styles", {
  skip_if_not_installed("ragg")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
    ggplot2::geom_point() + theme_chanwe(pane = FALSE)
  kpi <- chanwe_kpi("21,4", "MPG", "1974", mtc1_num = "2,1 %", mtc1_label = "m/m")
  for (style in c("card", "editorial")) {
    f <- chanwe_figure(p, title = "Consumo", subtitle = "Millas por galón, 1974", eyebrow = "Autos",
                       tag = "Anexo · 1", numeral = "07", kpi = kpi, source = "Motor Trend",
                       id = "CHW · T-01", style = style)
    expect_s3_class(f, "chanwe_figure")
    file <- tempfile(fileext = ".png")
    expect_silent(chanwe_save(f, file, dpi = 72))
    expect_true(file.exists(file))
  }
})

test_that("chanwe_figure reads the legend keys from the plot", {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) + ggplot2::geom_point()
  f <- chanwe_figure(p, title = "x")
  expect_equal(length(f$keys), 3)
})

test_that("every header kind, fill, legend and KPI position draws", {
  skip_if_not_installed("ragg")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) + ggplot2::geom_point()
  kpi <- chanwe_kpi("21,4", "MPG", "1974", mtc1_num = "2,1 %", mtc1_label = "m/m")
  file <- tempfile(fileext = ".png")
  for (h in c("A", "C", "D", "dark")) for (fl in c("tint", "none")) for (lg in c("pill", "header")) for (kp in c("pane", "strip", "rail")) {
    f <- chanwe_figure(p, title = "Consumo de combustible por peso", subtitle = "Millas por galón", eyebrow = "Autos",
                       tag = "Anexo", numeral = "07", kpi = kpi, kpi_position = kp, header = h, header_fill = fl,
                       legend = lg, source = "Motor Trend", id = "CHW", footer = if (fl == "none") "tint" else "rule",
                       frame = if (h == "dark") "none" else "shadow")
    expect_silent(chanwe_save(f, file, width = 4, height = 3, dpi = 40))
  }
})

test_that("the annotation layers add to a plot", {
  d <- data.frame(x = 1:10, lo = 1:10, hi = (1:10) + 3)
  p <- ggplot2::ggplot(d, ggplot2::aes(x, hi)) + ggplot2::geom_line() +
    annotate_chanwe_gap(d, "x", "lo", "hi") + annotate_chanwe_main(10, 13, "13,0") +
    annotate_chanwe_note(5, 8, "Una nota", dx = -2, dy = 2)
  expect_s3_class(ggplot2::ggplot_build(p), "ggplot_built")
  expect_equal(label_chanwe_month()(as.Date("2025-06-01")), "jun-25")
  expect_equal(label_chanwe_month("en", year = FALSE)(as.Date("2025-12-01")), "dec")
})

test_that("chanwe_kbl takes the figure frame", {
  df <- data.frame(a = c("x", "Total"), b = c(1.5, 2), d = c(1, -2))
  out <- chanwe_kbl(df, title = "T", subtitle = "S", eyebrow = "E", tag = "Tag", header = "A", footer = "rule",
                    caption = "Fuente X", id = "ID-1", frame = "shadow", n_total = 1, total_style = "band",
                    delta_style = "bar", col_colors = list(d = chanwe_col_signed()))
  txt <- as.character(out)
  expect_match(txt, "ID-1", fixed = TRUE)
  expect_match(txt, "fill: _t.ink", fixed = TRUE)
  expect_match(txt, "measure(_cw-card", fixed = TRUE)
  expect_false(grepl("table.cell(align: left, colspan: 3, inset: (top", txt, fixed = TRUE))
})
