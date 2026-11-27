# Series over time (3.6.0): numbers as the web kit prints them, period axes, chanwe_timeseries() and the annotation
# layer for time, the wrapped pill legend, and chanwe_save()'s SVG and PDF with the brand fonts.

test_that("numbers read as Intl.NumberFormat('es-AR', { maximumFractionDigits: 2 }) prints them", {
  # Node 26: new Intl.NumberFormat("es-AR", { maximumFractionDigits: 2 }).format(v) for each v.
  v <- c(0, -0, 1234.5, 12345.678, 0.125, 1.005, 2.675, -0.004, 0.1 + 0.2, 99.995, 999.995, 1e6, 1234567.891, -25.04)
  want <- c("0", "-0", "1.234,5", "12.345,68", "0,13", "1,01", "2,68", "-0", "0,3", "100", "1.000", "1.000.000",
            "1.234.567,89", "-25,04")
  expect_identical(chanwe_format_number(v), want)
  expect_identical(chanwe_format_number(c(33.44, NA, Inf), suffix = " %"), c("33,44 %", NA, NA))
  expect_identical(chanwe_format_number(c(2.5, -1, 0), digits = 1, sign = TRUE, suffix = " p.p."), c("+2,5 p.p.", "-1,0 p.p.", "0,0 p.p."))
  expect_identical(chanwe_format_number(NA, missing = "—"), "—")
  expect_identical(label_chanwe_number(suffix = " %")(c(0, 12.5, 1000)), c("0 %", "12,5 %", "1.000 %"))
})

test_that("periods read as their first day", {
  expect_equal(chanwe_period_date(c("2026-11-13", "2026-11", "2026-Q4", "2026-S2", "2026-S1", "2026", "x")),
               as.Date(c("2026-11-13", "2026-11-01", "2026-10-01", "2026-07-01", "2026-01-01", "2026-01-01", NA)))
})

test_that("a period axis ticks inside its window: a daily one by the kit's rule, the rest by whole periods", {
  d <- function(a, b) as.Date(c(a, b))
  expect_equal(breaks_chanwe_period("D")(d("2026-01-10", "2026-06-30")), as.Date(sprintf("2026-%02d-01", 2:6)))
  expect_equal(breaks_chanwe_period("D")(d("2024-11-21", "2026-11-20")), as.Date(c("2025-01-01", "2025-04-01", "2025-07-01",
                                         "2025-10-01", "2026-01-01", "2026-04-01", "2026-07-01", "2026-10-01")))
  expect_equal(format(breaks_chanwe_period("D")(d("2019-03-02", "2026-11-20")), "%m-%d"), rep("01-01", 7))
  expect_equal(breaks_chanwe_period("M")(d("2026-01-01", "2026-06-01")), as.Date(sprintf("2026-%02d-01", 1:6)))
  expect_equal(breaks_chanwe_period("M")(d("2023-10-01", "2026-10-01")), as.Date(c("2024-01-01", "2024-07-01", "2025-01-01",
                                         "2025-07-01", "2026-01-01", "2026-07-01")))
  expect_equal(breaks_chanwe_period("S")(d("2024-01-01", "2026-01-01")), chanwe_period_date(c("2024-S1", "2024-S2", "2025-S1", "2025-S2", "2026-S1")))
  expect_lte(length(breaks_chanwe_period("A")(d("1990-01-01", "2026-01-01"))), 8)
  expect_length(breaks_chanwe_period("M")(as.Date(c(NA, "2026-01-01"))), 0)
})

test_that("period labels: months, quarters, half-years and years, in Spanish or English", {
  expect_equal(label_chanwe_period("M")(as.Date(c("2025-06-01", "2025-07-01"))), c("jun-25", "jul-25"))
  expect_equal(label_chanwe_period("Q")(as.Date(c("2025-04-01", "2025-07-01"))), c("T2-25", "T3-25"))
  expect_equal(label_chanwe_period("Q", "en")(as.Date(c("2025-04-01", "2025-07-01"))), c("Q2-25", "Q3-25"))
  expect_equal(label_chanwe_period("S")(as.Date(c("2025-01-01", "2025-07-01"))), c("S1-25", "S2-25"))
  expect_equal(label_chanwe_period("S", "en")(as.Date(c("2025-01-01", NA))), c("H1-25", NA))
  expect_equal(label_chanwe_period("M")(as.Date(c("2024-01-01", "2026-01-01"))), c("2024", "2026"))
  expect_equal(label_chanwe_period("A")(as.Date("2025-01-01")), "2025")
  s <- scale_x_chanwe_period("M", limits = as.Date(c("2026-01-15", "2026-04-01")))
  expect_equal(s$breaks, as.Date(c("2026-02-01", "2026-03-01", "2026-04-01")))
})

ts_data <- function() {
  months <- chanwe_period_date(sprintf("2025-%02d", 1:12))
  rbind(data.frame(t = months, v = seq(2, 24, 2), s = "IPC", f = FALSE),
        data.frame(t = months, v = rep(c(-1, 2), 6), s = "EMAE", f = FALSE),
        data.frame(t = chanwe_period_date(c("2026-01", "2026-02")), v = c(25, 26), s = "IPC", f = TRUE))
}

test_that("chanwe_timeseries(): the focus in orange, the rest slate; a right axis aligned on zero", {
  p <- chanwe_timeseries(ts_data(), "t", "v", "s", mark = c(EMAE = "bar"), side = c(EMAE = "right"), forecast = "f",
                         events = data.frame(x = as.Date("2025-06-01"), label = "Hito"),
                         references = data.frame(y = 0, label = "", side = "right"))
  expect_s3_class(p, "ggplot")
  cols <- attr(p, "chanwe_colours")
  expect_identical(names(cols), c("IPC", "EMAE"))
  expect_identical(unname(cols[["IPC"]]), chanwe_tokens$plot$focus)
  expect_true(cols[["EMAE"]] %in% chanwe_tokens$plot$slate)
  expect_equal(attr(p, "chanwe_secondary"), 26 / 2)
  expect_true(all(c("chanwe_bars_right", "chanwe_lines", "chanwe_forecast") %in% names(p$layers)))
  b <- ggplot2::ggplot_build(p)
  bars <- b$data[[match("chanwe_bars_right", names(p$layers))]]
  expect_equal(sort(unique(bars$y / 13)), c(-1, 2))
  fc <- b$data[[match("chanwe_forecast", names(p$layers))]]
  expect_equal(nrow(fc), 3)
  expect_equal(unique(fc$linetype), "22")
  expect_false(is.null(b$layout$panel_params[[1]]$y.sec))
})

test_that("chanwe_timeseries(): stacked bars from the first series up, half-years marked, direct labels", {
  d <- data.frame(t = rep(chanwe_period_date(c("2025-S1", "2025-S2", "2026-S1")), 3), v = c(1, 2, 3, 2, -1, 1, 3, 1, 4),
                  s = factor(rep(c("Total", "A", "B"), each = 3), c("Total", "A", "B")))
  p <- chanwe_timeseries(d, "t", "v", "s", frequency = "S", mark = c(A = "bar", B = "bar"), stacked = TRUE, labels = "direct",
                         main = FALSE)
  b <- ggplot2::ggplot_build(p)
  bars <- b$data[[match("chanwe_bars_left", names(p$layers))]]
  first <- bars[bars$x == min(bars$x), ]
  expect_equal(first$ymin[first$group == 1], 0)
  expect_equal(first$ymin[first$group == 2], 2)
  expect_true("chanwe_points" %in% names(p$layers))
  expect_true("chanwe_ends" %in% names(p$layers))
  expect_error(chanwe_timeseries(d, "t", "v", "s", mark = "pie"), "pie is not one of")
})

test_that("the time annotations: an event, a reference level and a break", {
  expect_length(annotate_chanwe_event(as.Date("2025-01-01"), "Hito"), 2)
  expect_length(annotate_chanwe_event(as.Date("2025-01-01")), 1)
  expect_length(annotate_chanwe_hline(0, "Cero"), 2)
  expect_length(annotate_chanwe_break(as.Date("2024-12-01")), 2)
})

test_that("the pill legend wraps keys that do not fit into more rows", {
  skip_if_not_installed("ragg")
  chanwe_load_fonts()
  ragg::agg_png(tempfile(fileext = ".png"))
  on.exit(grDevices::dev.off())
  keys <- stats::setNames(rep(chanwe_tokens$plot$focus, 7), c("Asalariados privados", "Asalariados públicos",
                          "Casas particulares", "Autónomos", "Monotributo", "Monotributo social", "Total"))
  expect_gt(length(chanwer:::.cwf_legend_rows(keys, 255, 8)), 1)
  expect_length(chanwer:::.cwf_legend_rows(keys[1:2], 255, 8), 1)
  expect_identical(unlist(chanwer:::.cwf_legend_rows(keys, 255, 8)), seq_along(keys))
})

test_that("chanwe_save() writes an SVG with the brand fonts inside and a PDF with them embedded", {
  skip_if_not_installed("svglite")
  skip_if_not_installed("base64enc")
  p <- chanwe_timeseries(ts_data(), "t", "v", "s")
  f <- chanwe_figure(p, title = "Precios", subtitle = "Variación, %", source = "INDEC", id = "CHW")
  dir <- tempfile("chanwe-save-"); dir.create(dir); on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  svg <- chanwe_save(f, file.path(dir, "f.svg"), width = 3.54, height = 2.9)
  text <- paste(readLines(svg, warn = FALSE), collapse = "\n")
  expect_match(text, "@font-face", fixed = TRUE)
  expect_match(text, "data:font/woff2;base64,", fixed = TRUE)
  skip_if(is.null(.cw_typst()), "no Typst on the PATH")
  pdf <- chanwe_save(f, file.path(dir, "f.pdf"), width = 3.54, height = 2.9)
  expect_identical(readBin(pdf, "raw", 4), charToRaw("%PDF"))
  skip_if(!nzchar(Sys.which("pdffonts")), "no pdffonts")
  listed <- system2(Sys.which("pdffonts"), pdf, stdout = TRUE)
  expect_true(any(grepl("Satoshi", listed)))
  expect_true(any(grepl("JetBrainsMono", listed)))
})
