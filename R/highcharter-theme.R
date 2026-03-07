#' ChanWe Theme for highcharter
#'
#' Creates a Highcharts theme list with ChanWe colors and typography.
#'
#' @param add_logo Logical. If `TRUE`, adds the gray ChanWe logo at the
#'   top-right of the chart area.
#' @param logo_width_px Optional logo width in pixels. Use `NULL` (default)
#'   to keep the image's native width.
#' @param logo_height_px Optional logo height in pixels. Use `NULL` (default)
#'   to keep the image's native height.
#'
#' @return A highcharter theme object suitable for
#'   [highcharter::hc_add_theme()].
#' @export
#'
#' @examples
#' if (requireNamespace("highcharter", quietly = TRUE)) {
#'   hc <- highcharter::hchart(
#'     mtcars,
#'     "scatter",
#'     highcharter::hcaes(wt, mpg)
#'   ) |>
#'     highcharter::hc_add_theme(hc_theme_chanwe())
#' }
hc_theme_chanwe <- function(add_logo = TRUE,
                            logo_width_px = NULL,
                            logo_height_px = NULL) {
  chanwe_require_package("highcharter")

  colors <- chanwe_get_colors()
  logo_event <- NULL

  if (isTRUE(add_logo)) {
    logo_path <- chanwe_logo_path("Logo_Beige1.png")
    logo_src <- chanwe_logo_src(logo_path)

    if (nzchar(logo_src)) {
      logo_width_js <- if (is.null(logo_width_px)) {
        "null"
      } else {
        as.character(as.integer(logo_width_px))
      }
      logo_height_js <- if (is.null(logo_height_px)) {
        "null"
      } else {
        as.character(as.integer(logo_height_px))
      }

      logo_event <- highcharter::JS(sprintf(
        "function(){
           var chart = this;
           var pad = 12;
           var top = 10;
           var targetW = %s;
           var targetH = %s;
           var src = '%s';
           var placeLogo = function(iw, ih) {
             var w = (targetW !== null ? targetW : iw);
             var h = (targetH !== null ? targetH : ih);
             if (!(w > 0 && h > 0)) return;
             if (!chart.chanweLogo) {
               chart.chanweLogo = chart.renderer.image(src, 0, 0, w, h).add();
             } else {
               chart.chanweLogo.attr({ width: w, height: h });
             }
             chart.chanweLogo.attr({ x: chart.chartWidth - w - pad, y: top });
           };
           var probe = new window.Image();
           var drawWithProbe = function() {
             var iw = probe.width || 0;
             var ih = probe.height || 0;
             if (chart.chanweLogo) {
               iw = iw || chart.chanweLogo.attr('width') || 0;
               ih = ih || chart.chanweLogo.attr('height') || 0;
             }
             placeLogo(iw, ih);
           };
           probe.onload = drawWithProbe;
           probe.src = src;
           if (probe.complete) {
             drawWithProbe();
           }
         }",
        logo_width_js,
        logo_height_js,
        logo_src
      ))
    }
  }

  highcharter::hc_theme(
    colors = unname(chanwe_get_chart()),
    chart = list(
      backgroundColor = colors[["brand-white"]],
      style = list(
        fontFamily = "DM Sans",
        color = colors[["p13-gray-06"]]
      ),
      borderColor = colors[["brand-beige-soft"]],
      borderWidth = 1,
      borderRadius = 4,
      spacingTop = 28,
      spacingRight = 26,
      spacingBottom = 24,
      spacingLeft = 26,
      events = list(load = logo_event, redraw = logo_event),
      shadow = FALSE
    ),
    title = list(
      style = list(
        color = colors[["brand-black"]],
        fontWeight = "900"
      )
    ),
    subtitle = list(
      style = list(
        color = colors[["p13-gray-06"]],
        fontWeight = "500"
      )
    ),
    xAxis = list(
      gridLineColor = colors[["brand-beige-soft"]],
      gridLineWidth = 1,
      lineColor = colors[["brand-beige-soft"]],
      tickColor = colors[["brand-beige-soft"]],
      labels = list(style = list(color = colors[["p13-gray-06"]])),
      title = list(
        style = list(
          color = colors[["p13-gray-05"]],
          fontWeight = "700"
        )
      )
    ),
    yAxis = list(
      gridLineColor = colors[["brand-beige-soft"]],
      gridLineWidth = 1,
      lineColor = colors[["brand-beige-soft"]],
      tickColor = colors[["brand-beige-soft"]],
      labels = list(style = list(color = colors[["p13-gray-06"]])),
      title = list(
        style = list(
          color = colors[["p13-gray-05"]],
          fontWeight = "700"
        )
      )
    ),
    legend = list(
      itemStyle = list(
        color = colors[["p13-gray-05"]],
        fontWeight = "600"
      ),
      itemHoverStyle = list(
        color = colors[["brand-orange"]]
      )
    ),
    tooltip = list(
      borderColor = colors[["brand-orange"]],
      backgroundColor = colors[["brand-white"]],
      style = list(
        color = colors[["p13-gray-06"]],
        fontFamily = "DM Sans"
      ),
      shadow = FALSE
    ),
    plotOptions = list(
      series = list(
        dataLabels = list(
          style = list(
            color = colors[["p13-gray-06"]],
            textOutline = "none",
            fontWeight = "500"
          )
        ),
        marker = list(lineColor = colors[["brand-pure-white"]])
      )
    )
  )
}
