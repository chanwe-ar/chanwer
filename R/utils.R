# Brand font families and the files behind them. Every file ships in
# inst/fonts (identical to chanwe-brandbook brand/fonts/print, plus the
# JetBrains Mono Thin cut the chanwe-report Typst pool carries), and the
# chanwe-report extension's fonts folder uses the same file names, so either
# directory can be passed to chanwe_load_fonts(path = ).
#
# systemfonts only snaps to the registered plain (400) and bold (700) faces,
# so every other weight is registered as its own family, named the way
# gridtext and the CSS font-family lookup expect.
.chanwe_font_files <- list(
  # Satoshi: body text and UI (brand guide, 03 Tipografia)
  "Satoshi" = c(
    plain = "Satoshi-Regular.ttf", bold = "Satoshi-Bold.ttf",
    italic = "Satoshi-Italic.ttf", bolditalic = "Satoshi-BoldItalic.ttf"
  ),
  # the document body weight (300); Satoshi has no light italic
  "Satoshi Light" = c(plain = "Satoshi-Light.ttf", italic = "Satoshi-Italic.ttf"),
  "Satoshi Medium" = c(plain = "Satoshi-Medium.ttf"),
  "Satoshi SemiBold" = c(plain = "Satoshi-SemiBold.ttf"),
  # Schibsted Grotesk: titles, headings, big numbers (display weight 600)
  "Schibsted Grotesk" = c(
    plain = "SchibstedGrotesk-Regular.ttf", bold = "SchibstedGrotesk-Bold.ttf"
  ),
  "Schibsted Grotesk Medium" = c(plain = "SchibstedGrotesk-Medium.ttf"),
  "Schibsted Grotesk SemiBold" = c(plain = "SchibstedGrotesk-SemiBold.ttf"),
  # JetBrains Mono: eyebrows, labels, metadata, counters
  "JetBrains Mono" = c(
    plain = "JetBrainsMono-Regular.ttf", bold = "JetBrainsMono-Bold.ttf"
  ),
  "JetBrains Mono Medium" = c(plain = "JetBrainsMono-Medium.ttf"),
  "JetBrains Mono Thin" = c(plain = "JetBrainsMono-Thin.ttf"),
  # Editorial serifs: italics and numerals only. Cormorant ships as one
  # variable italic file, so every face of the family is that italic.
  "Cormorant Garamond" = c(
    plain = "CormorantGaramond-Italic-wght.ttf",
    bold = "CormorantGaramond-Italic-wght.ttf",
    italic = "CormorantGaramond-Italic-wght.ttf",
    bolditalic = "CormorantGaramond-Italic-wght.ttf"
  ),
  "Instrument Serif" = c(
    plain = "InstrumentSerif-Regular.ttf", italic = "InstrumentSerif-Italic.ttf"
  )
)

# Families retired from the brand, mapped to the family that replaces them.
# Inter was the body face until 2026-10-01 (brand guide: "Se retiran Inter").
.chanwe_retired_families <- c(
  "Inter" = "Satoshi",
  "Inter Light" = "Satoshi Light",
  "Inter Medium" = "Satoshi Medium"
)

# Swap a retired family for its brand replacement, with a deprecation
# warning that names the argument the caller passed it through.
chanwe_resolve_family <- function(family, arg = "family") {
  if (length(family) == 1L && family %in% names(.chanwe_retired_families)) {
    new <- unname(.chanwe_retired_families[[family]])
    warning(
      sprintf(
        paste0(
          "`%s = \"%s\"` is deprecated: Inter was retired from the CHANWE ",
          "brand. Using \"%s\" instead."
        ),
        arg, family, new
      ),
      call. = FALSE
    )
    return(new)
  }
  family
}

#' Load Chanwe Fonts into systemfonts
#'
#' Registers the CHANWE brand font families with
#' [systemfonts::register_font()], making them available to the ragg and
#' svglite devices and to ggplot2. [theme_chanwe()] calls it automatically;
#' call it yourself only to register fonts from another folder.
#'
#' The fonts ship with the package (`system.file("fonts", package =
#' "chanwer")`), copied from chanwe-brandbook `brand/fonts/print`, so no
#' Quarto extension or system install is needed. They follow the brand
#' guide's roles:
#'
#' - `"Satoshi"` — body text; Regular / Bold / Italic / BoldItalic
#' - `"Satoshi Light"` — plain face = Light (300), the document body weight
#' - `"Satoshi Medium"`, `"Satoshi SemiBold"` — 500 and 600
#' - `"Schibsted Grotesk"` — titles and display; Regular / Bold
#' - `"Schibsted Grotesk Medium"` — plain face = Medium (500)
#' - `"Schibsted Grotesk SemiBold"` — plain face = SemiBold (600), the brand
#'   display weight; used by [chanwe_title()]
#' - `"JetBrains Mono"` — eyebrows, labels, axis text, legends; Regular / Bold
#' - `"JetBrains Mono Medium"` — plain face = Medium (500); used by the
#'   caption stamp
#' - `"JetBrains Mono Thin"` — plain face = Thin (100); used by facet labels
#' - `"Cormorant Garamond"` — editorial italics and numerals only (the KPI
#'   hero value and subtitle notes); every face is the variable italic
#' - `"Instrument Serif"` — display numerals; Regular / Italic
#'
#' Inter is retired and no longer registered. Passing `"Inter"` (or
#' `"Inter Light"` / `"Inter Medium"`) as `theme_chanwe(base_family = )`
#' still works: it warns and uses the Satoshi equivalent.
#'
#' A family that is already installed on the system under the same name (for
#' example JetBrains Mono) is left to the installed copy: systemfonts does not
#' allow a registered font to shadow a system family.
#'
#' Every file the families need is checked. When one is missing the function
#' warns (class `chanwer_missing_font`) and lists the files and families
#' affected; a family whose regular file is missing is not registered, and a
#' missing bold or italic face falls back to the regular one.
#'
#' @param path Directory containing the font files. Defaults to the fonts
#'   bundled with the package; when those are unavailable, the
#'   `_extensions/chanwe-report/fonts` folder of the working directory. The
#'   chanwe-report extension folder and chanwe-brandbook's `brand/fonts/print`
#'   files use the same names.
#'
#' @return Invisibly, the resolved fonts directory path (or `NULL` when no
#'   directory was found or the fonts were already registered).
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
    warning(
      "chanwe_load_fonts() requires the 'systemfonts' package; ",
      "the brand fonts were not registered.",
      call. = FALSE
    )
    return(invisible(NULL))
  }

  if (is.null(path)) {
    candidates <- c(
      system.file("fonts", package = "chanwer"),
      file.path(getwd(), "_extensions", "chanwe-report", "fonts")
    )
    path <- Find(function(p) nzchar(p) && dir.exists(p), candidates)
  }

  if (is.null(path) || !dir.exists(path)) {
    warning(
      "chanwe_load_fonts(): fonts directory not found",
      if (!is.null(path)) paste0(" (", path, ")"),
      ". Reinstall chanwer or pass `path` to a folder with the brand TTFs ",
      "(chanwe-brandbook brand/fonts/print).",
      call. = FALSE
    )
    return(invisible(NULL))
  }

  # systemfonts refuses a registry name that is already an installed system
  # family (e.g. JetBrains Mono from the JetBrains IDEs); the installed copy
  # is the same typeface and serves that family instead.
  installed <- unique(systemfonts::system_fonts()$family)
  missing <- character(0)
  missing_families <- character(0)
  for (family in names(.chanwe_font_files)) {
    if (family %in% installed) {
      next
    }
    files <- .chanwe_font_files[[family]]
    full <- file.path(path, files)
    names(full) <- names(files)
    absent <- stats::setNames(!file.exists(full), names(files))
    if (any(absent)) {
      missing <- union(missing, unname(files[absent]))
      missing_families <- c(missing_families, family)
    }
    if (absent[["plain"]]) {
      next
    }
    face <- function(name) {
      if (name %in% names(full) && !absent[[name]]) full[[name]] else NULL
    }
    tryCatch(
      systemfonts::register_font(
        name = family,
        plain = full[["plain"]],
        bold = face("bold") %||_% full[["plain"]],
        italic = face("italic") %||_% full[["plain"]],
        bolditalic = face("bolditalic") %||_%
          face("bold") %||_% face("italic") %||_% full[["plain"]]
      ),
      error = function(e) {
        warning(
          sprintf(
            "chanwe_load_fonts(): could not register \"%s\": %s",
            family, conditionMessage(e)
          ),
          call. = FALSE
        )
      }
    )
  }

  if (length(missing)) {
    warning(structure(
      class = c("chanwer_missing_font", "warning", "condition"),
      list(
        message = paste0(
          "chanwe_load_fonts(): ", length(missing),
          " brand font file(s) not found in ", path, ": ",
          paste(missing, collapse = ", "), ".\n",
          "Affected families: ", paste(unique(missing_families), collapse = ", "),
          ". A family without its regular file is not registered and falls ",
          "back to the device default; a missing bold or italic face falls ",
          "back to the regular one."
        ),
        call = NULL
      )
    ))
  }

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

  # The repository's top-level assets/ folder holds the pre-2026 brand kit
  # (old logos, Raleway, Google Sans) and is deliberately not searched: the
  # current marks are in inst/assets and the synced extension.
  candidates <- c(
    if (nzchar(src_root)) file.path(src_root, "inst/assets", filename),
    if (nzchar(src_root)) file.path(src_root, "_extensions/chanwe-brand/assets", filename),
    file.path("inst/assets", filename),
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
