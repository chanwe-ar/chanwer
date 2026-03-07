#' ChanWe Reporting CSS for Quarto
#'
#' Returns the path to the bundled ChanWe reporting stylesheet for Quarto.
#' The stylesheet includes chunk block styling, callout accents, caption styles,
#' and orange section numbering markers.
#'
#' @return A string path to `inst/quarto/chanwe-reporting.scss` in an installed
#'   package.
#' @export
#'
#' @examples
#' chanwe_reporting_css()
chanwe_reporting_css <- function() {
  system.file("quarto", "chanwe-reporting.scss", package = "chanweThemes")
}
