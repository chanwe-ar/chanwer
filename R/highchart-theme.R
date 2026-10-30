#' Chanwe Layout for highcharter Charts (HTML)
#'
#' Applies the Chanwe header grammar and chart chrome to an existing
#' `highcharter` object: eyebrow / title / subtitle block anchored top-left
#' in Schibsted Grotesk, Satoshi body font, JetBrains Mono axis ticks, no axis lines or
#' ticks, hairline y-grid, an ink tooltip in mono, no exporting menu or
#' credits, and an optional caption drawn as the chanwe-report figure stamp
#' (a square orange box with white mono caps) under a slate hairline.
#' The y-axis title moves into the top-left corner of the plot area,
#' rotated 90 degrees, on the same vertical line as the tick numbers rather
#' than sitting to the left of them; the x-axis title stays on its own row
#' below the tick labels but flushes right against the plot area's right
#' edge instead of centering under the axis. A hairline divider closes off
#' the header (below the subtitle) and opens the caption (above the stamp
#' line), each spanning from the header/caption's own left edge to the
#' plot area's right edge, in a light neutral gray.
#'
#' Fonts: the brand faces come from the bundled WOFF2 (the `chanwe-fonts`
#' dependency), and highcharter's own Google Fonts loader is switched off,
#' so the widget makes no font request. Call `chanwe_highchart()` last in
#' the pipe: a later `hc_*()` call re-enables highcharter's loader.
#'
#' Colour (v2 rule C1): with `focus`, the named series is orange and every
#' other series sits on the slate ramp ([chanwe_focus_colors()]); without
#' it, the categorical palette (`chanwe_palette("chart")`) is applied as the
#' widget's series colours. Columns and bars take the 3px `plot.bar-radius`,
#' the y grid is `plot.grid`, axis labels are mono at the compact size and
#' legend symbols are pills.
#'
#' @param hc A `highcharter` object (from `highcharter::highchart()`).
#' @param title,subtitle,eyebrow Header block rendered top-left, stacked as
#'   one `useHTML` chart title.
#' @param caption Source note rendered bottom-left as a mono label (or the
#'   orange stamp, see `caption_style`).
#' @param legend Logical. Show the legend (vertical, right, centered on the
#'   plot body)? Default `FALSE`.
#' @param height Widget height in pixels, passed to
#'   `highcharter::hc_size()` -- needed because `hc_chart(height = )` alone
#'   only sets Highcharts' internal chart option; the htmlwidget itself
#'   stays in "fill" sizing mode and renders at zero height outside a
#'   dashboard layout until `hc_size()` sets the widget's own height field.
#' @param bg Chart and plot background. Named shorthand accepted by
#'   [theme_chanwe()] or any hex string. Default `"white"`.
#' @param focus Optional name of the series that matters: it turns orange
#'   (and is drawn on top), the others go on the slate ramp. Applies to the
#'   series already added to `hc`.
#' @param caption_style `"mono"` (v2 default) or `"stamp"` (the orange stamp
#'   of chanwer 2.x). `NULL` reads `getOption("chanwer.caption_style",
#'   "mono")`.
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
  bg = "white",
  focus = NULL,
  caption_style = NULL
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
  # chanwer's mono stack single-quotes its face (`'JetBrains Mono'`), and
  # that embedded quote breaks out of Highcharts' selector and throws,
  # aborting the chart's render with a blank widget. Double quotes are
  # equally valid CSS and don't collide with it.
  hc_sans <- gsub("'", "\"", .cw_font_sans, fixed = TRUE)
  hc_mono <- gsub("'", "\"", .cw_font_mono, fixed = TRUE)

  header <- NULL
  if (!is.null(title) || !is.null(subtitle) || !is.null(eyebrow)) {
    # Divs, not spans joined by <br/>: a <br/> line break can't carry its
    # own margin, so the eyebrow-title gap couldn't be tuned independently
    # of the title-subtitle one.
    parts <- c(
      if (!is.null(eyebrow)) {
        # The brand eyebrow: an orange rule, then JetBrains Mono caps with
        # wide tracking (same as chanwe_html_header_tag()).
        sprintf(
          paste0(
            "<div style='font-size:10px;font-weight:500;font-family:%1$s;",
            "color:%2$s;letter-spacing:.18em;text-transform:uppercase;",
            "margin-bottom:9px'><span style='display:inline-block;width:22px;",
            "height:1px;background:%2$s;vertical-align:middle;",
            "margin-right:8px'></span>%3$s</div>"
          ),
          hc_mono, tk$accent, chanwe_html_escape(eyebrow)
        )
      },
      if (!is.null(title)) {
        sprintf(
          "<div style='font-size:24px;font-weight:600;color:%s;font-family:%s'>%s</div>",
          tk$title, .cw_font_display, chanwe_html_escape(title)
        )
      },
      if (!is.null(subtitle)) {
        sprintf(
          "<div style='font-size:12px;color:%s;font-family:%s;margin-top:6px'>%s</div>",
          tk$fg_muted, hc_sans, chanwe_html_escape(subtitle)
        )
      }
    )
    header <- paste(parts, collapse = "")
  }

  # v2 axis labels: mono at the compact size (type.caption) in
  # plot.axis-text; the grid is plot.grid (ink-fg at 25%, as rgba because
  # Highcharts 9 reads no 8-digit hex).
  axis_style <- list(style = list(
    fontFamily = hc_mono, fontSize = paste0(tk$type$caption, "px"),
    color = tk$axis_text
  ))
  hc_rgba <- function(hex) {
    v <- grDevices::col2rgb(hex, alpha = TRUE)
    sprintf("rgba(%d,%d,%d,%s)", v[1], v[2], v[3], format(round(v[4] / 255, 2)))
  }

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
        tk$hairline
      )))
    ) |>
    highcharter::hc_colors(unname(chanwe_palette("chart"))) |>
    highcharter::hc_legend(
      enabled = isTRUE(legend), align = "right", verticalAlign = "middle",
      layout = "vertical",
      itemStyle = list(
        fontFamily = hc_mono, fontSize = paste0(tk$type$caption, "px"),
        color = tk$fg_muted, fontWeight = "normal"
      ),
      itemHoverStyle = list(color = tk$ink),
      # v2 legend keys are pills
      symbolWidth = 16, symbolHeight = 8, symbolRadius = 4,
      squareSymbol = FALSE
    ) |>
    highcharter::hc_tooltip(
      shared = TRUE, xDateFormat = "%Y-%m-%d", borderWidth = 0,
      borderRadius = chanwe_tokens$radii$row, backgroundColor = tk$ink,
      style = list(
        color = tk$white, fontFamily = hc_mono,
        fontSize = paste0(tk$type$caption, "px")
      )
    ) |>
    highcharter::hc_exporting(enabled = FALSE) |>
    highcharter::hc_credits(enabled = FALSE) |>
    highcharter::hc_plotOptions(
      series = list(
        marker = list(enabled = FALSE),
        lineWidth = chanwe_tokens$plot$`line-width`,
        states = list(hover = list(lineWidthPlus = 0))
      ),
      # v2 bars: plot.bar-radius (Highcharts 9 rounds every corner)
      column = list(borderRadius = tk$bar_radius, borderWidth = 0),
      bar = list(borderRadius = tk$bar_radius, borderWidth = 0)
    ) |>
    highcharter::hc_xAxis(
      gridLineWidth = 0, lineWidth = 0, tickLength = 0, labels = axis_style,
      title = list(style = axis_style$style, align = "high", x = 20)
    ) |>
    highcharter::hc_yAxis(
      gridLineColor = hc_rgba(tk$grid),
      gridLineWidth = chanwe_tokens$plot$`grid-width`, lineWidth = 0,
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
          "<span class='chanwe-stamp' style='%s'>%s</span>",
          chanwe_html_stamp_style(caption_style), chanwe_html_escape(caption)
        ),
        useHTML = TRUE, align = "left", margin = caption_margin,
        style = list(fontFamily = hc_mono)
      )
  }

  # The v2 colour rule: the focus series in orange, the rest on the slate
  # ramp, by series name (series added before this call).
  if (!is.null(focus)) {
    series <- hc$x$hc_opts$series
    nms <- vapply(series, function(x) as.character(x$name %||_% ""), character(1))
    cols <- chanwe_focus_colors(nms, focus)
    for (i in seq_along(series)) {
      hc$x$hc_opts$series[[i]]$color <- unname(cols[[nms[i]]])
      if (nms[i] %in% focus) hc$x$hc_opts$series[[i]]$zIndex <- 10
    }
  }

  hc$dependencies <- c(hc$dependencies, chanwe_html_fonts_dependency())
  # highcharter collects every fontFamily in the options into `x$fonts` and
  # its JavaScript binding requests each one from Google Fonts. The brand
  # faces come from the local dependency above, so that list is dropped:
  # the widget makes no font request. A later hc_*() call re-collects it, so
  # call chanwe_highchart() last.
  hc$x$fonts <- NULL
  hc
}
