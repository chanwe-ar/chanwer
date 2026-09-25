#' Load Chanwe Fonts into systemfonts
#'
#' Registers all Chanwe font families with [systemfonts::register_font()],
#' making them available to the ragg and svglite devices and to ggplot2.
#' Call once per session before creating plots with [theme_chanwe()].
#'
#' Registered families:
#' - `"Satoshi"` — Regular / Bold / Italic / BoldItalic
#' - `"Schibsted Grotesk"` — Regular / Bold (the display face; upright only)
#' - `"Schibsted Grotesk Medium"` — plain face = Medium (500)
#' - `"Schibsted Grotesk SemiBold"` — plain face = SemiBold (600); used by [chanwe_title()]
#' - `"Schibsted Grotesk ExtraBold"` — plain face = ExtraBold (800)
#' - `".chanwe-subtitle"` — plain face = Schibsted Grotesk Regular (400), its
#'   lightest weight
#' - `"Fraunces 9pt"` — Regular / Bold / Italic / BoldItalic
#' - `"Cormorant Garamond"` — variable font; used by the KPI hero value and subtitle notes
#' - `"JetBrains Mono"` — Regular / Bold / Italic / BoldItalic
#' - `"JetBrains Mono Thin"` — plain face = Thin (100); used by axis titles / facet labels
#'
#' @param path Directory containing the TTF files. Defaults to the fonts
#'   bundled with any installed Chanwe Quarto extension, searched relative to
#'   the working directory: `_extensions/chanwe-report/fonts` first, then
#'   `_extensions/chanwe-publications/fonts`.
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
    # system.file(package=) returns the inst/ dir; dirname() gives package root
    pkg_inst <- tryCatch(system.file(package = "chanwer"), error = function(e) "")
    pkg_root <- if (nzchar(pkg_inst)) dirname(pkg_inst) else ""
    candidates <- c(
      if (nzchar(pkg_root)) file.path(pkg_root, "_extensions/chanwe-report/fonts"),
      if (nzchar(pkg_root)) file.path(pkg_root, "_extensions/chanwe-publications/fonts"),
      "_extensions/chanwe-report/fonts",
      "_extensions/chanwe-publications/fonts",
      file.path(getwd(), "_extensions/chanwe-report/fonts"),
      file.path(getwd(), "_extensions/chanwe-publications/fonts"),
      system.file("fonts", package = "chanwer")
    )
    path <- Find(function(p) nzchar(p) && dir.exists(p), candidates)
  }

  if (is.null(path) || !dir.exists(path)) {
    warning(
      "chanwe_load_fonts(): fonts directory not found. ",
      "Pass `path` explicitly or install the chanwe-report-typst Quarto extension."
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
  .reg("Schibsted Grotesk",
    plain      = "SchibstedGrotesk-Regular.ttf",
    bold       = "SchibstedGrotesk-Bold.ttf"
  )
  .reg("Fraunces 9pt",
    plain      = "Fraunces9pt-Regular.ttf",
    bold       = "Fraunces9pt-Bold.ttf",
    italic     = "Fraunces9pt-Italic.ttf",
    bolditalic = "Fraunces9pt-BoldItalic.ttf"
  )
  # Cormorant ships two ways: as a variable font, or as static OTFs (the way
  # the chanwe-report extension carries it). Whichever is there is used; with
  # neither, the KPI value silently fell back to Times.
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

  # Fraunces 9pt weight variants — each as its own family so they can be
  # referenced by name (systemfonts only snaps to 400/700 from the base family)
  .fraunces_weights <- list(
    list(name = "Fraunces 9pt Thin",             plain = "Fraunces9pt-Thin.ttf",            italic = "Fraunces9pt-ThinItalic.ttf"),
    list(name = "Fraunces 9pt ExtraLight",       plain = "Fraunces9pt-ExtraLight.ttf",      italic = "Fraunces9pt-ExtraLightItalic.ttf"),
    list(name = "Fraunces 9pt Light",            plain = "Fraunces9pt-Light.ttf",           italic = "Fraunces9pt-LightItalic.ttf"),
    list(name = "Fraunces 9pt Light Italic",     plain = "Fraunces9pt-LightItalic.ttf",     italic = "Fraunces9pt-LightItalic.ttf"),
    list(name = "Fraunces 9pt Regular",          plain = "Fraunces9pt-Regular.ttf",         italic = "Fraunces9pt-Italic.ttf"),
    list(name = "Fraunces 9pt Italic",           plain = "Fraunces9pt-Italic.ttf",          italic = "Fraunces9pt-Italic.ttf"),
    list(name = "Fraunces 9pt Medium",           plain = "Fraunces9pt-Medium.ttf",          italic = "Fraunces9pt-MediumItalic.ttf"),
    list(name = "Fraunces 9pt SemiBold",         plain = "Fraunces9pt-SemiBold.ttf",        italic = "Fraunces9pt-SemiBoldItalic.ttf"),
    list(name = "Fraunces 9pt Bold",             plain = "Fraunces9pt-Bold.ttf",            italic = "Fraunces9pt-BoldItalic.ttf"),
    list(name = "Fraunces 9pt ExtraBold",        plain = "Fraunces9pt-ExtraBold.ttf",       italic = "Fraunces9pt-ExtraBoldItalic.ttf"),
    list(name = "Fraunces 9pt Black",            plain = "Fraunces9pt-Black.ttf",           italic = "Fraunces9pt-BlackItalic.ttf")
  )
  for (.fw in .fraunces_weights) {
    .pp <- file.path(path, .fw$plain)
    .ip <- file.path(path, .fw$italic)
    if (file.exists(.pp)) {
      tryCatch(
        systemfonts::register_font(
          name   = .fw$name,
          plain  = .pp,
          italic = if (file.exists(.ip)) .ip else NULL
        ),
        error = function(e) NULL
      )
    }
  }
  rm(.fraunces_weights, .fw, .pp, .ip)
  .reg("JetBrains Mono",
    plain      = "JetBrainsMono-Regular.ttf",
    bold       = "JetBrainsMono-Bold.ttf",
    italic     = "JetBrainsMono-Italic.ttf",
    bolditalic = "JetBrainsMono-BoldItalic.ttf"
  )
  .reg("JetBrains Mono Thin",
    plain      = "JetBrainsMono-Thin.ttf",
    bold       = "JetBrainsMono-ExtraLight.ttf",
    italic     = "JetBrainsMono-ThinItalic.ttf",
    bolditalic = "JetBrainsMono-ExtraLightItalic.ttf"
  )

  # The display face at each weight, each registered as its own family:
  # systemfonts only snaps to the 400 / 700 of the base family, and gridtext
  # resolves a face by CSS font-family name (dot-prefixed names fail there).
  .display <- function(name, file) {
    f <- file.path(path, file)
    if (file.exists(f)) {
      tryCatch(systemfonts::register_font(name = name, plain = f), error = function(e) NULL)
    }
  }
  .display("Schibsted Grotesk Medium", "SchibstedGrotesk-Medium.ttf")      # KPI hero value
  .display("Schibsted Grotesk SemiBold", "SchibstedGrotesk-SemiBold.ttf")  # chanwe_title()
  .display("Schibsted Grotesk ExtraBold", "SchibstedGrotesk-ExtraBold.ttf")
  .display(".chanwe-title", "SchibstedGrotesk-ExtraBold.ttf")
  # Schibsted has no Light: the subtitle takes its lightest weight, Regular.
  .display("Schibsted Grotesk Light", "SchibstedGrotesk-Regular.ttf")
  .display(".chanwe-subtitle", "SchibstedGrotesk-Regular.ttf")
  rm(.display)

  options(chanwer.fonts_loaded = TRUE)
  invisible(path)
}

chanwe_resolve_bg <- function(bg_color) {
  switch(
    tolower(trimws(bg_color)),
    white          = "#FFFFFF",
    "white-ivory"  = "#FAF9F7",
    ivory          = "#FAF9F7",
    gray           = "#EDF0F1",
    grey           = "#EDF0F1",
    beige          = "#F5F1EB",
    metallic       = "#F7F7F7",
    silver         = "#F7F7F7",
    transparent    = "transparent",
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
