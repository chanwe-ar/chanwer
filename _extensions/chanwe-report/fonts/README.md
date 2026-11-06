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
| Cormorant Garamond | Editorial italics and numerals only | italic at 300, 400, 500, 600, 700; static instances of the brandbook's variable italic | yes, identical files (brandbook `brand/fonts/print/cormorant-garamond/`) |
| Instrument Serif | Display numerals only | 400, upright and italic | yes, identical files |

Typst does not render the weight axis of a variable font (it warns "variable
fonts are not currently supported and may render incorrectly" and draws the
default instance), so since 2026-10-08 the pool carries static italic cuts
instanced from the brandbook's variable file with
`fontTools.varLib.instancer` at 300–700, with their name tables rewritten to
one family (`Cormorant Garamond`, subfamily `Light Italic` … `Bold Italic`),
like the Schibsted Grotesk cuts. A `weight-body` (300) run is Light Italic; an
italic run with no weight, or `weight-regular`, is Italic 400 again, as it was
before the variable file replaced the old OTF cuts. There is no upright
Cormorant.

Satoshi ships eight static cuts and no 100/200/350: Typst resolves the
`weight-hairline` and `weight-thin` tokens to Light 300 when they land on the
sans, and a light italic to Italic 400. Schibsted Grotesk files are static
instances; do not replace them with a variable font (Typst refuses it).

Retired and gone from this pool: Inter (2026-10-08; it was the fallback behind
Satoshi), the old static Cormorant Garamond OTF cuts, the variable Cormorant
italic (2026-10-08, replaced by its static instances), Archivo, Fraunces 9pt, Plus Jakarta Sans, Cabinet Grotesk,
Manrope and IBM Plex Mono. The brandbook keeps the retired families in
`brand/archive/fonts/` so old documents can be re-rendered; do not reintroduce
them here.

Typst's built-in math fonts are not brand fonts; formulas still use them.
System fallback names in the templates' font lists (Helvetica Neue, Arial,
Georgia, Menlo) are deliberately retained.
