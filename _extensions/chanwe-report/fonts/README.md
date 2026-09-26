# Shared Typst fonts

This pool is used by `chanwe-report` and the other Chanwe Typst formats.
It mirrors the five active families in `chanwe-brand/brand.yml`:

| Family | Role | Static weights |
|---|---|---|
| Schibsted Grotesk | Display and headings | 400, 500, 600, 700, 800; upright only |
| Inter | Body and UI | 100–900, upright and italic |
| JetBrains Mono | Code and metadata | 100–800, upright and italic |
| Cormorant Garamond | Editorial serif | 300–700, upright and italic |
| Instrument Serif | Display serif and numerals | 400, upright and italic |

Keep the complete cuts of these active families, even when a particular
starter does not exercise every weight. Schibsted Grotesk files are static
instances; do not replace them with a variable font.

Archivo, Satoshi, Fraunces 9pt, Plus Jakarta Sans, Cabinet Grotesk, Manrope,
and IBM Plex Mono were removed from this pool because no active Typst source
uses them. Historical copies remain recoverable from Git. Webfont archives
outside this folder are independent and unchanged.

Typst's built-in math fonts are not legacy brand fonts; formulas still use
them. System fallback lists in the templates are also deliberately retained.
