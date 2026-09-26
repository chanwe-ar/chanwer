#' Load Chanwe Fonts into systemfonts
#'
#' Registers the brand font families declared in the chanwe-brand
#' `brand.yml` with [systemfonts::register_font()], making them available to
#' the ragg and svglite devices and to ggplot2. Call once per session before
#' creating plots with [theme_chanwe()].
#'
#' Registered families:
#' - `"Inter"` — body text; Regular / Bold / Italic / BoldItalic
#' - `"Inter Light"` — plain face = Light (300), the brand body weight
#' - `"Inter Medium"` — plain face = Medium (500)
#' - `"Schibsted Grotesk"` — display; Regular / Bold
#' - `"Schibsted Grotesk Medium"` — plain face = Medium (500)
#' - `"Schibsted Grotesk SemiBold"` — plain face = SemiBold (600), the brand
#'   display weight; used by [chanwe_title()]
#' - `"Instrument Serif"` — Regular / Italic
#' - `"Cormorant Garamond"` — Regular / Bold / Italic / BoldItalic; used by
#'   the KPI hero value and subtitle notes
#' - `"JetBrains Mono"` — Regular / Bold / Italic / BoldItalic
#' - `"JetBrains Mono Medium"` — plain face = Medium (500); used by the
#'   caption stamp
#' - `"JetBrains Mono Thin"` — plain face = Thin (100); used by axis titles /
#'   facet labels
#'
#' @param path Directory containing the font files. Defaults to the fonts
#'   bundled with the chanwe-report Quarto extension, searched relative to the
#'   working directory (`_extensions/chanwe-report/fonts`).
#'
#' @return Invisibly, the resolved fonts directory path.
#' @export
#'
#' @examples
#' \dontrun{
#' chanwe_load_fonts()
#' }
chanwe_load_fonts <- function(path = NULL) {
  if (isTRUE(getOption("chanwer.fonts_loaded")) && is.null(path)) {
    return(invisible(NULL))
  }

  if (!requireNamespace("systemfonts", quietly = TRUE)) {
    warning("chanwe_load_fonts() requires the 'systemfonts' package.")
    return(invisible(NULL))
  }

  if (is.null(path)) {
    candidates <- c(
      "_extensions/chanwe-report/fonts",
      file.path(getwd(), "_extensions/chanwe-report/fonts"),
      system.file("fonts", package = "chanwer")
    )
    path <- Find(function(p) nzchar(p) && dir.exists(p), candidates)
  }

  if (is.null(path) || !dir.exists(path)) {
    warning(
      "chanwe_load_fonts(): fonts directory not found. ",
      "Pass `path` explicitly or install the chanwe-report Quarto extension."
    )
    return(invisible(NULL))
  }

  # systemfonts only snaps to the registered plain (400) and bold (700)
  # faces, so every other weight is registered as its own family, named the
  # way gridtext and the CSS font-family lookup expect.
  .reg <- function(name, plain, bold = NULL, italic = NULL, bolditalic = NULL) {
    fp <- function(f) {
      if (is.null(f)) return(NULL)
      p <- file.path(path, f)
      if (file.exists(p)) p else NULL
    }
    pp <- fp(plain)
    if (is.null(pp)) return(invisible(NULL))
    tryCatch(
      systemfonts::register_font(
        name       = name,
        plain      = pp,
        bold       = fp(bold),
        italic     = fp(italic),
        bolditalic = fp(bolditalic)
      ),
      error = function(e) NULL
    )
  }

  .reg("Inter",
    plain      = "Inter-Regular.ttf",
    bold       = "Inter-Bold.ttf",
    italic     = "Inter-Italic.ttf",
    bolditalic = "Inter-BoldItalic.ttf"
  )
  .reg("Inter Light", plain = "Inter-Light.ttf", italic = "Inter-LightItalic.ttf")
  .reg("Inter Medium", plain = "Inter-Medium.ttf", italic = "Inter-MediumItalic.ttf")

  .reg("Schibsted Grotesk",
    plain = "SchibstedGrotesk-Regular.ttf",
    bold  = "SchibstedGrotesk-Bold.ttf"
  )
  .reg("Schibsted Grotesk Medium", plain = "SchibstedGrotesk-Medium.ttf")
  .reg("Schibsted Grotesk SemiBold", plain = "SchibstedGrotesk-SemiBold.ttf")

  .reg("Instrument Serif",
    plain  = "InstrumentSerif-Regular.ttf",
    italic = "InstrumentSerif-Italic.ttf"
  )
  # Cormorant ships two ways: as a variable font, or as static OTFs (the way
  # the chanwe-report extension carries it). Whichever is there is used.
  if (file.exists(file.path(path, "CormorantGaramond[wght].ttf"))) {
    .reg("Cormorant Garamond",
      plain      = "CormorantGaramond[wght].ttf",
      bold       = "CormorantGaramond[wght].ttf",
      italic     = "CormorantGaramond-Italic[wght].ttf",
      bolditalic = "CormorantGaramond-Italic[wght].ttf"
    )
  } else {
    .reg("Cormorant Garamond",
      plain      = "CormorantGaramond-Regular.otf",
      bold       = "CormorantGaramond-Bold.otf",
      italic     = "CormorantGaramond-Italic.otf",
      bolditalic = "CormorantGaramond-BoldItalic.otf"
    )
  }

  .reg("JetBrains Mono",
    plain      = "JetBrainsMono-Regular.ttf",
    bold       = "JetBrainsMono-Bold.ttf",
    italic     = "JetBrainsMono-Italic.ttf",
    bolditalic = "JetBrainsMono-BoldItalic.ttf"
  )
  .reg("JetBrains Mono Medium",
    plain  = "JetBrainsMono-Medium.ttf",
    italic = "JetBrainsMono-MediumItalic.ttf"
  )
  .reg("JetBrains Mono Thin",
    plain      = "JetBrainsMono-Thin.ttf",
    bold       = "JetBrainsMono-ExtraLight.ttf",
    italic     = "JetBrainsMono-ThinItalic.ttf",
    bolditalic = "JetBrainsMono-ExtraLightItalic.ttf"
  )

  options(chanwer.fonts_loaded = TRUE)
  invisible(path)
}

# Named surfaces, all brand.yml tokens, with the grid colours theme_chanwe()
# pairs with each: the major grid one hairline step darker than the surface,
# the minor grid half a step. `metallic`, `white-ivory` and `gray` are the
# pre-slate names, kept as aliases of the nearest brand surface.
.chanwe_surfaces <- list(
  paper  = c(fill = "#F8FAFC", major = "#CFD6DF", minor = "#EBF0F6"),
  white  = c(fill = "#FFFFFF", major = "#CFD6DF", minor = "#F1F5F9"),
  sunken = c(fill = "#F1F5F9", major = "#C6CDD6", minor = "#E2E8F0"),
  slate  = c(fill = "#EBF0F6", major = "#C6CDD6", minor = "#E2E8F0")
)

.chanwe_surface_aliases <- c(
  "paper" = "paper", "metallic" = "paper", "silver" = "paper",
  "white-ivory" = "paper", "ivory" = "paper",
  "white" = "white",
  "sunken" = "sunken",
  "slate" = "slate", "gray" = "slate", "grey" = "slate"
)

# Surface name for a named background, or NA for a raw colour / transparent.
chanwe_surface_name <- function(bg_color) {
  key <- tolower(trimws(bg_color))
  if (key %in% c("beige", "cream")) {
    stop(
      "The beige surface was retired from the Chanwe brand; ",
      "use \"slate\" or \"paper\" instead.",
      call. = FALSE
    )
  }
  unname(.chanwe_surface_aliases[key])
}

chanwe_resolve_bg <- function(bg_color) {
  if (identical(tolower(trimws(bg_color)), "transparent")) {
    return("transparent")
  }
  surface <- chanwe_surface_name(bg_color)
  if (is.na(surface)) {
    return(bg_color)
  }
  .chanwe_surfaces[[surface]][["fill"]]
}

chanwe_require_package <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop(
      sprintf("Package '%s' is required for this function.", pkg),
      call. = FALSE
    )
  }
}

chanwe_logo_path <- function(filename = "Logo_Color1.png") {
  installed <- system.file(file.path("assets", filename), package = "chanwer")
  if (nzchar(installed) && file.exists(installed)) {
    return(installed)
  }

  src_root <- ""
  src_file <- tryCatch(
    utils::getSrcFilename(chanwe_logo_path, full.names = TRUE),
    error = function(...) ""
  )
  if (nzchar(src_file)) {
    src_root <- normalizePath(
      file.path(dirname(src_file), ".."),
      winslash = "/",
      mustWork = FALSE
    )
  }

  candidates <- c(
    if (nzchar(src_root)) file.path(src_root, "inst/assets", filename),
    if (nzchar(src_root)) file.path(src_root, "assets", filename),
    if (nzchar(src_root)) file.path(src_root, "_extensions/assets", filename),
    if (nzchar(src_root)) file.path(src_root, "_extensions/chanwe-brand/assets", filename),
    file.path("inst/assets", filename),
    file.path("assets", filename),
    file.path("_extensions/assets", filename),
    file.path("_extensions/chanwe-brand/assets", filename)
  )
  existing <- candidates[file.exists(candidates)]

  if (!length(existing)) {
    return("")
  }

  normalizePath(existing[[1]], winslash = "/", mustWork = FALSE)
}

chanwe_logo_src <- function(path, embed = TRUE) {
  if (!nzchar(path)) {
    return("")
  }

  if (isTRUE(embed) && requireNamespace("knitr", quietly = TRUE)) {
    return(knitr::image_uri(path))
  }

  if (isTRUE(embed) && file.exists(path)) {
    ext <- tolower(tools::file_ext(path))
    mime <- switch(
      ext,
      png = "image/png",
      jpg = "image/jpeg",
      jpeg = "image/jpeg",
      gif = "image/gif",
      svg = "image/svg+xml",
      "application/octet-stream"
    )

    bytes <- readBin(path, what = "raw", n = file.info(path)$size)
    encoded <- chanwe_base64_encode(bytes)
    if (nzchar(encoded)) {
      return(paste0("data:", mime, ";base64,", encoded))
    }
  }

  normalizePath(path, winslash = "/", mustWork = FALSE)
}

chanwe_base64_encode <- function(bytes) {
  if (!length(bytes)) {
    return("")
  }

  alphabet <- c(LETTERS, letters, as.character(0:9), "+", "/")
  values <- as.integer(bytes)
  pad <- (3L - (length(values) %% 3L)) %% 3L
  if (pad > 0L) {
    values <- c(values, rep.int(0L, pad))
  }

  triplets <- matrix(values, ncol = 3L, byrow = TRUE)
  idx1 <- bitwShiftR(triplets[, 1L], 2L)
  idx2 <- bitwOr(
    bitwShiftL(bitwAnd(triplets[, 1L], 0x03L), 4L),
    bitwShiftR(triplets[, 2L], 4L)
  )
  idx3 <- bitwOr(
    bitwShiftL(bitwAnd(triplets[, 2L], 0x0FL), 2L),
    bitwShiftR(triplets[, 3L], 6L)
  )
  idx4 <- bitwAnd(triplets[, 3L], 0x3FL)

  out <- c(
    rbind(
      alphabet[idx1 + 1L],
      alphabet[idx2 + 1L],
      alphabet[idx3 + 1L],
      alphabet[idx4 + 1L]
    )
  )

  if (pad > 0L) {
    out[(length(out) - pad + 1L):length(out)] <- "="
  }

  paste0(out, collapse = "")
}

chanwe_png_dims <- function(path) {
  if (!nzchar(path) || !file.exists(path)) {
    return(NULL)
  }

  con <- file(path, "rb")
  on.exit(close(con), add = TRUE)
  bytes <- readBin(con, what = "raw", n = 24)
  if (length(bytes) < 24) {
    return(NULL)
  }

  png_sig <- as.raw(c(137, 80, 78, 71, 13, 10, 26, 10))
  if (!all(bytes[1:8] == png_sig)) {
    return(NULL)
  }
  if (!identical(rawToChar(bytes[13:16]), "IHDR")) {
    return(NULL)
  }

  width <- readBin(bytes[17:20], what = "integer", n = 1, size = 4, endian = "big")
  height <- readBin(bytes[21:24], what = "integer", n = 1, size = 4, endian = "big")
  if (is.na(width) || is.na(height) || width <= 0 || height <= 0) {
    return(NULL)
  }

  list(width = width, height = height)
}
