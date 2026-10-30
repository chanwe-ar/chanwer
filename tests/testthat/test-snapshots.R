# vdiffr snapshots of the v2 chart look (brand-v2 Q3 / C1). vdiffr draws
# with its own fixed font metrics, so these pin the geometry and colours,
# not the brand typefaces. Update with testthat::snapshot_review().

snap_data <- function() {
  set.seed(42)
  list(
    regions = data.frame(
      region = c("Cuyo", "NOA", "NEA", "Patagonia", "Pampeana"),
      ventas = c(42, 31, 18, 25, 37)
    ),
    series = data.frame(
      year = rep(2018:2025, 3),
      value = c(50, 52, 51, 55, 58, 57, 60, 63, 50, 53, 55, 56, 60, 62, 66, 70,
                50, 49, 52, 54, 53, 55, 57, 58),
      country = rep(c("Argentina", "Brasil", "Chile"), each = 8)
    ),
    stack = data.frame(
      q = rep(c("Q1", "Q2", "Q3"), each = 3),
      seg = rep(c("A", "B", "C"), 3),
      v = c(3, 4, 2, 5, 3, 2, 4, 4, 3)
    )
  )
}

test_that("v2 bar chart with a focus bar", {
  skip_if_not_installed("vdiffr")
  d <- snap_data()$regions
  p <- ggplot2::ggplot(d, ggplot2::aes(region, ventas, fill = region)) +
    geom_chanwe_col(width = 0.6) +
    scale_fill_chanwe_focus("Cuyo") +
    ggplot2::labs(title = "Ventas por region", x = NULL, y = NULL,
                  caption = chanwe_caption("Fuente: simulado")) +
    theme_chanwe(legend_position = "none")
  vdiffr::expect_doppelganger("v2-bar-focus", p)
})

test_that("v2 line chart with a focus series and pill keys", {
  skip_if_not_installed("vdiffr")
  d <- snap_data()$series
  p <- ggplot2::ggplot(d, ggplot2::aes(year, value, colour = country)) +
    ggplot2::geom_line(key_glyph = draw_key_chanwe_pill) +
    scale_color_chanwe_focus("Argentina") +
    ggplot2::labs(title = "Indice", x = NULL, y = NULL, colour = NULL) +
    theme_chanwe(bg_color = "white")
  vdiffr::expect_doppelganger("v2-line-focus", p)
})

test_that("v2 stacked horizontal bars, categorical, x grid", {
  skip_if_not_installed("vdiffr")
  d <- snap_data()$stack
  p <- ggplot2::ggplot(d, ggplot2::aes(v, q, fill = seg)) +
    geom_chanwe_col(width = 0.6) +
    scale_fill_chanwe_d() +
    ggplot2::labs(title = "Stacked", x = NULL, y = NULL, fill = NULL) +
    theme_chanwe(grid = "x")
  vdiffr::expect_doppelganger("v2-bar-stacked-horizontal", p)
})

test_that("v2 caption stamp (opt-in) and palette preview", {
  skip_if_not_installed("vdiffr")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point(colour = chanwe_tokens$plot$focus) +
    ggplot2::labs(title = "Stamp", caption = chanwe_caption("Fuente: mtcars")) +
    theme_chanwe(caption_style = "stamp")
  vdiffr::expect_doppelganger("v2-caption-stamp", p)
  vdiffr::expect_doppelganger("palette-focus", chanwe_preview_palette("focus"))
})
