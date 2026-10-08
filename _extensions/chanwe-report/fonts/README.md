# Shared Typst fonts

This pool is used by `chanwe-report` and the other Chanwe Typst formats
(memo, propuesta, reMarkable, LinkedIn, Instagram). It carries the brand trio
decided on 2026-10-01 plus the two editorial serifs the brand guide keeps for
documents. Source of truth: chanwe-brandbook `brand/fonts/print/`.

| Family | Role | Cuts | From the brandbook |
|---|---|---|---|
| Satoshi | Body and UI | 300, 400, 500, 600, 700, 900; italic at 400 and 700 | yes, identical files |
| Schibsted Grotesk | Display and headings | 400, 500, 600, 700, 800; upright only | yes, identical files |
| JetBrains Mono | Eyebrows, labels, metadata, code | 100–800, upright and italic | Regular, Medium and Bold identical; the other 13 cuts are the official JetBrains release, which the brandbook does not carry yet |
| Cormorant Garamond | Editorial italics and numerals only | one variable italic file; Typst reads its default instance, Light Italic 300 | yes, identical file |
| Instrument Serif | Display numerals only | 400, upright and italic | yes, identical files |

Typst does not render the weight axis of a variable font, so Cormorant
Garamond is Light Italic 300 everywhere in Typst: there is no upright
Cormorant and no heavier italic. Every serif run in the templates is italic at
`weight-body` (300); a 400 request lands on 300.

Satoshi ships eight static cuts and no 100/200/350: Typst resolves the
`weight-hairline` and `weight-thin` tokens to Light 300 when they land on the
sans, and a light italic to Italic 400. Schibsted Grotesk files are static
instances; do not replace them with a variable font (Typst refuses it).

Retired and gone from this pool: Inter (2026-10-08; it was the fallback behind
Satoshi), the static Cormorant Garamond OTF cuts (replaced by the brandbook's
variable italic), Archivo, Fraunces 9pt, Plus Jakarta Sans, Cabinet Grotesk,
Manrope and IBM Plex Mono. The brandbook keeps the retired families in
`brand/archive/fonts/` so old documents can be re-rendered; do not reintroduce
them here.

Typst's built-in math fonts are not brand fonts; formulas still use them.
System fallback names in the templates' font lists (Helvetica Neue, Arial,
Georgia, Menlo) are deliberately retained.
