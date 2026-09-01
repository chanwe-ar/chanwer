#' Chanwe Layout for highcharter Charts (HTML)
#'
#' Applies the Chanwe header grammar and chart chrome to an existing
#' `highcharter` object: eyebrow / title / subtitle block anchored top-left
#' in Archivo, Satoshi body font, JetBrains Mono axis ticks, no axis lines or
#' ticks, hairline y-grid, an ink tooltip in mono, no exporting menu or
#' credits, and an optional `//`-prefixed caption in ink, not muted gray.
#' The y-axis title moves into the top-left corner of the plot area,
#' rotated 90 degrees, on the same vertical line as the tick numbers rather
#' than sitting to the left of them; the x-axis title stays on its own row
#' below the tick labels but flushes right against the plot area's right
#' edge instead of centering under the axis. A hairline divider closes off
#' the header (below the subtitle) and opens the caption (above the `//`
#' line), each spanning from the header/caption's own left edge to the
#' plot area's right edge, in a light neutral gray.
#'
#' Discrete colours are not changed by this function -- the chart palette
#' (`chanwe_palette("chart")`) is applied as the widget's series colours, so
#' series added without an explicit `color` cycle through the brand palette.
#'
#' @param hc A `highcharter` object (from `highcharter::highchart()`).
#' @param title,subtitle,eyebrow Header block rendered top-left, stacked as
#'   one `useHTML` chart title.
#' @param caption Source note rendered bottom-left with a `//` prefix.
#' @param legend Logical. Show the legend (vertical, right, centered on the
#'   plot body)? Default `FALSE`.
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
  chanwe_require_package("htmlwidgets")
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
    # Divs, not spans joined by <br/>: a <br/> line break can't carry its
    # own margin, so the eyebrow-title gap couldn't be tuned independently
    # of the title-subtitle one.
    parts <- c(
      if (!is.null(eyebrow)) {
        sprintf(
          "<div style='font-size:10px;font-weight:500;font-family:%s;color:%s;margin-bottom:9px'>—— %s</div>",
          hc_mono, tk$accent, chanwe_html_escape(eyebrow)
        )
      },
      if (!is.null(title)) {
        sprintf(
          "<div style='font-size:24px;font-weight:600;color:%s;font-family:%s'>%s</div>",
          tk$ink, .cw_font_display, chanwe_html_escape(title)
        )
      },
      if (!is.null(subtitle)) {
        sprintf(
          "<div style='font-size:12px;color:%s;margin-top:6px'>%s</div>",
          tk$fg_muted, chanwe_html_escape(subtitle)
        )
      }
    )
    header <- paste(parts, collapse = "")
  }

  axis_style <- list(style = list(
    fontFamily = hc_mono, fontSize = "10.5px", color = tk$fg_muted
  ))

  # title_margin is wider than a hairline gap: the rotated y-axis title
  # lives in that band too and needs room for its own text length.
  title_margin <- 48L
  caption_margin <- 24L

  hc <- hc |>
    highcharter::hc_size(height = height) |>
    highcharter::hc_chart(
      backgroundColor = bg, style = list(fontFamily = hc_sans),
      spacingTop = 12, spacingRight = 24, spacingLeft = 20,
      spacingBottom = if (is.null(caption)) 20 else 26,
      # The y-axis title keeps the vertical line it always sat on
      # (Highcharts positions it just left of the tick numbers) and only
      # moves up into the top margin, rotated, close to the plot's top edge
      # rather than up near the subtitle; the x-axis title moves right
      # (shifted past the last tick label, whichever one that turns out to
      # be) but stays on its own row below the axis. Neither is a plain
      # config option -- title.x/.y are small *nudges* relative to each
      # title's own default position, not coordinates -- so the reference
      # position is read back at render time and reused here rather than
      # guessed. The two rule lines spanning the plot width are drawn the
      # same way, for the same reason: reused (not re-added) on every call,
      # since render fires again on resize/redraw.
      events = list(render = htmlwidgets::JS(sprintf(
        paste(
          "function () {",
          "  var c = this;",
          "  if (c.yAxis && c.yAxis[0] && c.yAxis[0].axisTitle) {",
          "    var t = c.yAxis[0].axisTitle;",
          "    t.attr({",
          "      x: t.attr('x'), y: c.plotTop - 6, rotation: -90,",
          "      'text-anchor': 'end'",
          "    });",
          "  }",
          "  if (c.xAxis && c.xAxis[0] && c.xAxis[0].axisTitle) {",
          "    c.xAxis[0].axisTitle.attr({",
          "      x: c.plotLeft + c.plotWidth, 'text-anchor': 'end'",
          "    });",
          "  }",
          # Neither getBBox() (returns each group's own *local* box, not its
          # position on the chart -- unreliable for useHTML content besides)
          # nor a fixed offset from plotTop/plotHeight (the x-axis title now
          # has its own row below the ticks, which isn't accounted for in
          # spacing/margin math) land these reliably, so the real rendered
          # position is read via getBoundingClientRect() -- which, unlike
          # getBBox(), works the same for SVG and the useHTML title/caption
          # divs -- and converted into the chart's own coordinate space by
          # subtracting the container's offset.
          # The lines reach all the way to the header/caption's own left
          # edge, not plotLeft -- flush with the eyebrow/title/subtitle text
          # above and the // caption below, rather than stopping short at
          # the y-axis labels' inset.
          "  var contRect = c.container.getBoundingClientRect();",
          "  var ruleAttr = { 'stroke-width': 0.5, stroke: '%1$s' };",
          "  if (c.options.title && c.options.title.text && c.title && c.title.element) {",
          "    var tRect = c.title.element.getBoundingClientRect();",
          "    var tx = tRect.left - contRect.left;",
          "    var ty = (tRect.bottom - contRect.top) + 8;",
          "    var td = ['M', tx, ty, 'L', c.plotLeft + c.plotWidth, ty];",
          "    if (c.__cwHeaderRule) { c.__cwHeaderRule.attr({ d: td }); }",
          "    else { c.__cwHeaderRule = c.renderer.path(td).attr(ruleAttr).add(); }",
          "  }",
          "  if (c.options.caption && c.options.caption.text && c.caption && c.caption.element) {",
          "    var capRect = c.caption.element.getBoundingClientRect();",
          "    var cx = capRect.left - contRect.left;",
          "    var cy = (capRect.top - contRect.top) - 16;",
          "    var cd = ['M', cx, cy, 'L', c.plotLeft + c.plotWidth, cy];",
          "    if (c.__cwCaptionRule) { c.__cwCaptionRule.attr({ d: cd }); }",
          "    else { c.__cwCaptionRule = c.renderer.path(cd).attr(ruleAttr).add(); }",
          "  }",
          "}",
          sep = "\n"
        ),
        tk$n300
      )))
    ) |>
    highcharter::hc_colors(unname(chanwe_palette("chart"))) |>
    highcharter::hc_legend(
      enabled = isTRUE(legend), align = "right", verticalAlign = "middle",
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
      marker = list(enabled = FALSE), lineWidth = 1.2,
      states = list(hover = list(lineWidthPlus = 0))
    )) |>
    highcharter::hc_xAxis(
      gridLineWidth = 0, lineWidth = 0, tickLength = 0, labels = axis_style,
      title = list(style = axis_style$style, align = "high", x = 20)
    ) |>
    highcharter::hc_yAxis(
      gridLineColor = tk$n200, gridLineWidth = 0.75, lineWidth = 0,
      tickLength = 0, labels = axis_style, title = list(style = axis_style$style)
    )

  if (!is.null(header)) {
    hc <- hc |>
      highcharter::hc_title(
        text = header, useHTML = TRUE, align = "left", margin = title_margin,
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
        useHTML = TRUE, align = "left", margin = caption_margin,
        style = list(
          fontFamily = hc_mono, fontSize = "10px", color = tk$ink,
          fontWeight = "300"
        )
      )
  }

  hc$dependencies <- c(hc$dependencies, chanwe_html_fonts_dependency())
  hc
}
