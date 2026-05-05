#' Load ChanWe Fonts into systemfonts
#'
#' Registers Satoshi, Archivo, and Fraunces 9pt font families (plus the
#' `.chanwe-subtitle` ExtraLight Italic variant) with [systemfonts::register_font()],
#' making them available to the ragg device and ggplot2.
#' Call once per session before creating plots with [theme_chanwe()].
#'
#' @param path Directory containing the TTF files. Defaults to
#'   `_extensions/chanwe/fonts` relative to the working directory (i.e. the
#'   fonts bundled with the chanwe-typst Quarto extension).
#'
#' @return Invisibly, the resolved fonts directory path.
#' @export
#'
#' @examples
#' \dontrun{
#' chanwe_load_fonts()
#' }
chanwe_load_fonts <- function(path = NULL) {
  if (isTRUE(.chanwe_env$fonts_loaded) && is.null(path)) {
    return(invisible(NULL))
  }

  if (!requireNamespace("systemfonts", quietly = TRUE)) {
    warning("chanwe_load_fonts() requires the 'systemfonts' package.")
    return(invisible(NULL))
  }

  if (is.null(path)) {
    # system.file(package=) returns the inst/ dir; dirname() gives package root
    pkg_inst <- tryCatch(system.file(package = "chanwer"), error = function(e) "")
    pkg_root <- if (nzchar(pkg_inst)) dirname(pkg_inst) else ""
    candidates <- c(
      if (nzchar(pkg_root)) file.path(pkg_root, "_extensions/chanwe/fonts"),
      "_extensions/chanwe/fonts",
      file.path(getwd(), "_extensions/chanwe/fonts"),
      system.file("fonts", package = "chanwer")
    )
    path <- Find(function(p) nzchar(p) && dir.exists(p), candidates)
  }

  if (is.null(path) || !dir.exists(path)) {
    warning(
      "chanwe_load_fonts(): fonts directory not found. ",
      "Pass `path` explicitly or install the chanwe-typst Quarto extension."
    )
    return(invisible(NULL))
  }

  .reg <- function(name, plain, bold = NULL, italic = NULL, bolditalic = NULL) {
    fp <- function(f) { p <- file.path(path, f); if (!is.null(f) && file.exists(p)) p else NULL }
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

  .reg("Satoshi",
    plain      = "Satoshi-Regular.ttf",
    bold       = "Satoshi-Bold.ttf",
    italic     = "Satoshi-Italic.ttf",
    bolditalic = "Satoshi-BoldItalic.ttf"
  )
  .reg("Archivo",
    plain      = "Archivo-Regular.ttf",
    bold       = "Archivo-Bold.ttf",
    italic     = "Archivo-Italic.ttf",
    bolditalic = "Archivo-BoldItalic.ttf"
  )
  .reg("Fraunces 9pt",
    plain      = "Fraunces9pt-Regular.ttf",
    bold       = "Fraunces9pt-Bold.ttf",
    italic     = "Fraunces9pt-Italic.ttf",
    bolditalic = "Fraunces9pt-BoldItalic.ttf"
  )

  # .chanwe-title / ArchivoTitle: Archivo Black (900) baked as plain face.
  # Two names registered: .chanwe-title for element_markdown family= param,
  # ArchivoTitle as CSS-friendly alias (no leading dot) for use inside HTML
  # spans in ggtext — gridtext CSS lookup silently fails on dot-prefixed names.
  archivo_black <- file.path(path, "Archivo-Black.ttf")
  archivo_title <- if (file.exists(archivo_black)) archivo_black else file.path(path, "Archivo-Bold.ttf")
  if (file.exists(archivo_title)) {
    tryCatch(
      systemfonts::register_font(name = ".chanwe-title", plain = archivo_title),
      error = function(e) NULL
    )
    tryCatch(
      systemfonts::register_font(name = "ArchivoTitle", plain = archivo_title),
      error = function(e) NULL
    )
  }

  # .chanwe-subtitle: Archivo ExtraLight (200) — same family as the title but
  # at weight 200 and no italic, baked into a named family for reliable rendering.
  archivo_el <- file.path(path, "Archivo-ExtraLight.ttf")
  if (file.exists(archivo_el)) {
    tryCatch(
      systemfonts::register_font(name = ".chanwe-subtitle", plain = archivo_el),
      error = function(e) NULL
    )
  }

  .chanwe_env$fonts_loaded <- TRUE
  invisible(path)
}

chanwe_resolve_bg <- function(bg_color) {
  switch(
    tolower(trimws(bg_color)),
    white = "#FFFFFF",
    gray  = "#F5F5F5",
    grey  = "#F5F5F5",
    beige = "#ECE5D8",
    bg_color
  )
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
