#' ChanWe Theme for reactable
#'
#' Returns a [reactable::reactableTheme()] object with ChanWe typography,
#' neutral surfaces, and orange accents.
#'
#' @return A reactable theme object.
#' @export
#'
#' @examples
#' if (requireNamespace("reactable", quietly = TRUE)) {
#'   tbl <- reactable::reactable(head(mtcars), theme = reactable_theme_chanwe())
#' }
reactable_theme_chanwe <- function() {
  chanwe_require_package("reactable")

  colors <- chanwe_get_colors()

  reactable::reactableTheme(
    color = colors[["typst-fg"]],
    backgroundColor = colors[["typst-white"]],
    borderColor = colors[["typst-neutral-200"]],
    stripedColor = colors[["typst-neutral-100"]],
    highlightColor = grDevices::adjustcolor(
      colors[["typst-primary"]],
      alpha.f = 0.06
    ),
    inputStyle = list(
      borderColor = colors[["typst-neutral-300"]],
      borderRadius = "2px",
      boxShadow = "none",
      fontFamily = "Satoshi"
    ),
    pageButtonHoverStyle = list(
      backgroundColor = colors[["typst-neutral-100"]],
      color = colors[["typst-ink"]],
      borderRadius = "2px"
    ),
    pageButtonActiveStyle = list(
      backgroundColor = colors[["typst-primary"]],
      color = colors[["typst-white"]],
      fontWeight = "600",
      border = sprintf("1px solid %s", colors[["typst-primary"]]),
      borderRadius = "2px"
    ),
    pageButtonCurrentStyle = list(
      backgroundColor = colors[["typst-primary"]],
      color = colors[["typst-white"]],
      fontWeight = "600",
      border = sprintf("1px solid %s", colors[["typst-primary"]]),
      borderRadius = "2px"
    ),
    style = list(
      fontFamily = "Satoshi",
      fontSize = "13px",
      lineHeight = "1.5",
      borderRadius = "0px",
      boxShadow = "none"
    ),
    tableStyle = list(
      borderCollapse = "separate",
      borderSpacing = 0
    ),
    headerStyle = list(
      background = colors[["typst-white"]],
      color = colors[["typst-ink"]],
      fontFamily = "Archivo",
      fontWeight = 600,
      paddingTop = "10px",
      paddingBottom = "10px",
      borderTop = sprintf("1px solid %s", colors[["typst-neutral-300"]]),
      borderBottom = sprintf("2px solid %s", colors[["typst-neutral-900"]])
    ),
    cellStyle = list(
      borderBottom = sprintf("1px solid %s", colors[["typst-neutral-200"]])
    ),
    rowStyle = list(
      "&:hover[aria-selected='false']" = list(
        backgroundColor = colors[["typst-neutral-100"]]
      )
    )
  )
}
