#' Chanwe Layout for highcharter Charts (HTML)
#'
#' Applies the Chanwe header grammar and chart chrome to an existing
#' `highcharter` object: eyebrow / title / subtitle block anchored top-left
#' in Archivo, Satoshi body font, JetBrains Mono axis ticks, no axis lines or
#' ticks, hairline y-grid, an ink tooltip in mono, no exporting menu or
#' credits, and an optional `//`-prefixed caption.
#'
#' Discrete colours are not changed by this function -- the chart palette
#' (`chanwe_palette("chart")`) is applied as the widget's series colours, so
#' series added without an explicit `color` cycle through the brand palette.
#'
#' @param hc A `highcharter` object (from `highcharter::highchart()`).
#' @param title,subtitle,eyebrow Header block rendered top-left, stacked as
#'   one `useHTML` chart title.
#' @param caption Source note rendered bottom-left with a `//` prefix.
#' @param legend Logical. Show the legend (vertical, top-right)? Default
#'   `FALSE`.
#' @param height Widget height in pixels, passed to
#'   `highcharter::hc_size()` -- needed because `hc_chart(height = )` alone
#'   only sets Highcharts' internal chart option; the htmlwidget itself
#'   stays in "fill" sizing mode and renders at zero height outside a
#'   dashboard layout until `hc_size()` sets the widget's own height field.
#' @param bg Chart and plot background. Named shorthand accepted by
#'   [theme_chanwe()] or any hex string. Default `"white"`.
#'
#' @return The modified `highcharter` object.
#' @export
#'
#' @examplesIf requireNamespace("highcharter", quietly = TRUE)
#' hc <- highcharter::highchart() |>
#'   highcharter::hc_xAxis(type = "datetime") |>
#'   highcharter::hc_add_series(
#'     data = highcharter::list_parse2(data.frame(x = 1:10, y = rnorm(10))),
#'     type = "line", name = "Series A"
#'   )
#' hc <- chanwe_highchart(
#'   hc,
#'   title = "Fleet overview",
#'   eyebrow = "SECTION · EFFICIENCY",
#'   subtitle = "Simulated values over time.",
#'   caption = "Source · Simulated data."
#' )
chanwe_highchart <- function(
  hc,
  title = NULL,
  subtitle = NULL,
  eyebrow = NULL,
  caption = NULL,
  legend = FALSE,
  height = 440,
  bg = "white"
) {
  chanwe_require_package("highcharter")
  tk <- chanwe_html_tokens()
  bg <- chanwe_resolve_bg(bg)
  if (identical(bg, "transparent")) {
    bg <- "rgba(0,0,0,0)"
  }

  # Highcharts checks every fontFamily it is given against the document's
  # loaded stylesheets by building a `link[href='<fontFamily>']` selector;
  # chanwer's shared font stacks single-quote their fallback face (e.g.
  # `'DM Sans'`), and that embedded quote breaks out of Highcharts' selector
  # and throws, aborting the chart's render with a blank widget. Double
  # quotes are equally valid CSS and don't collide with it.
  hc_sans <- gsub("'", "\"", .cw_font_sans, fixed = TRUE)
  hc_mono <- gsub("'", "\"", .cw_font_mono, fixed = TRUE)

  header <- NULL
  if (!is.null(title) || !is.null(subtitle) || !is.null(eyebrow)) {
    parts <- c(
      if (!is.null(eyebrow)) {
        sprintf(
          "<span style='font-size:10px;color:%s'>—— %s</span>",
          tk$accent, chanwe_html_escape(eyebrow)
        )
      },
      if (!is.null(title)) {
        sprintf(
          "<span style='font-size:19px;color:%s;font-family:%s'>%s</span>",
          tk$ink, .cw_font_display, chanwe_html_escape(title)
        )
      },
      if (!is.null(subtitle)) {
        sprintf(
          "<span style='font-size:12px;color:%s'>%s</span>",
          tk$fg_muted, chanwe_html_escape(subtitle)
        )
      }
    )
    header <- paste(parts, collapse = "<br/>")
  }

  axis_style <- list(style = list(
    fontFamily = hc_mono, fontSize = "10.5px", color = tk$fg_muted
  ))

  hc <- hc |>
    highcharter::hc_size(height = height) |>
    highcharter::hc_chart(
      backgroundColor = bg, style = list(fontFamily = hc_sans),
      spacingTop = 8, spacingRight = 16, spacingLeft = 8,
      spacingBottom = if (is.null(caption)) 16 else 34
    ) |>
    highcharter::hc_colors(unname(chanwe_palette("chart"))) |>
    highcharter::hc_legend(
      enabled = isTRUE(legend), align = "right", verticalAlign = "top",
      layout = "vertical",
      itemStyle = list(
        fontFamily = hc_mono, fontSize = "10.5px", color = tk$fg_muted,
        fontWeight = "normal"
      ),
      itemHoverStyle = list(color = tk$ink),
      symbolWidth = 10, symbolHeight = 10, symbolRadius = 1
    ) |>
    highcharter::hc_tooltip(
      shared = TRUE, xDateFormat = "%Y-%m-%d", borderWidth = 0,
      borderRadius = 4, backgroundColor = tk$ink,
      style = list(
        color = "#FFFFFF", fontFamily = hc_mono, fontSize = "11px"
      )
    ) |>
    highcharter::hc_exporting(enabled = FALSE) |>
    highcharter::hc_credits(enabled = FALSE) |>
    highcharter::hc_plotOptions(series = list(
      marker = list(enabled = FALSE), lineWidth = 1.6,
      states = list(hover = list(lineWidthPlus = 0))
    )) |>
    highcharter::hc_xAxis(
      gridLineWidth = 0, lineWidth = 0, tickLength = 0, labels = axis_style
    ) |>
    highcharter::hc_yAxis(
      gridLineColor = tk$n200, lineWidth = 0, tickLength = 0,
      labels = axis_style, title = list(style = axis_style$style)
    )

  if (!is.null(header)) {
    hc <- hc |>
      highcharter::hc_title(
        text = header, useHTML = TRUE, align = "left",
        style = list(fontFamily = hc_sans)
      )
  }
  if (!is.null(caption)) {
    hc <- hc |>
      highcharter::hc_caption(
        text = sprintf(
          "<span style='color:%s'>//</span>  %s",
          tk$accent, chanwe_html_escape(caption)
        ),
        useHTML = TRUE, align = "left",
        style = list(
          fontFamily = hc_mono, fontSize = "10px", color = tk$fg_muted
        )
      )
  }

  hc$dependencies <- c(hc$dependencies, chanwe_html_fonts_dependency())
  hc
}
