---
target: chanwer-examples.qmd plots & tables (chanwe-brand critique)
total_score: 23
max_score: 32
na_heuristics: 3,9
p0_count: 0
p1_count: 3
timestamp: 2026-08-24T06-36-06Z
slug: chanwer-examples-qmd
---
# Critique: chanwe-brand usage in the plots & tables of chanwer-examples

Method: dual-agent (A: design-review agent, 28-page visual inspection + brand sources · B: detector/token-scan agent, deterministic evidence). Browser overlay not applicable (print PDF target).

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Footer n/28 + TOC ranges good; running header never reflects current section |
| 2 | Match System / Real World | 2 | Implementation jargon printed as figure captions (p21); signed colors invert real-world valence (p17-18) |
| 3 | User Control and Freedom | n/a | Static PDF |
| 4 | Consistency and Standards | 2 | Two caption regimes; inconsistent figure widths; off-token cover font |
| 5 | Error Prevention | 2 | Good preventive callouts, violated by adjacent examples |
| 6 | Recognition Rather Than Recall | 4 | Code above every render, hexes in swatches, concept eyebrows |
| 7 | Flexibility and Efficiency | 3 | Skimmable; tables numbered but never cross-referenced, no index |
| 8 | Aesthetic and Minimalist Design | 3 | Premium type system; docked by rainbow bar, doubled table rules, six near-empty pages |
| 9 | Error Recovery | n/a | Static PDF |
| 10 | Help and Documentation | 4 | The artifact is the docs; closing "one system" callout is checkable |
| **Total** | | **23/32 (72%)** | **Good** |

## Design Specificity Verdict

Authored-for-this-brand, to unusual depth. Nothing reads default-ggplot or default-Typst; chart headers and Typst table headers are the same object in two engines; chart typography is document typography. Detector ran clean (exit 0, zero findings). Token audit: 0 strict hardcoded-color violations; all 14 ggplot chunks themed; all colors via scale_*_chanwe_*/chanwe_palette (one token-valued literal #F7F7F7 at qmd:335); all 4 tables via chanwe_kbl(). Signed trio passes WCAG 4.5:1 on all brand surfaces (5.27-5.74), as claimed. All plot fonts within document font set.

Brand drift found mechanically: white-ivory #FAF9F7 (R/utils.R:214) vs #FAFAFA (chanwe-elements.typ:456); callout colors #00A047/#FC5300 in elements.typ have no palette.R counterpart while chanwe_brand_tokens() maps callouts to p14 accents. Two document tokens fail AA everywhere: typst-primary #FD3810 (eyebrows, ~3.4-3.65:1) and typst-fg-subtle #928D86 (captions, ~3.1-3.3:1).

## Priority Issues

- [P1] Showcase violates its own palette rules: p9 ordinal band colored with categorical palette (one page before the rule); p10 7-series rainbow bar under a "six series max" subtitle, redundant-ink coloring by own axis. Fix: recolor p9 nominal or p15 ramp; cut p10 to <=6 or single-hue or frame as counter-example. (/impeccable polish)
- [P1] Signed colors follow arithmetic sign, not valence, in the signed-system section: p17 unemployment falling = red, rising = green; p18 Opex up = green, Churn down = red. chanwe_col_signed() flip is per-column only; chanwe_kpi() has no flip, hence hardcoded signed hexes in KPI divs (qmd:385-389), the only executed hardcoded colors found. Fix: add valence/flip semantics to chanwe_kpi() and per-row col_colors; pick sign=valence demo metrics or demo flip=TRUE. (/impeccable harden)
- [P1] Rendering defects on highest-value pages: p28 back cover prints "contacto\@chanwe.com.ar" (escape leaks); p16 KPI cards render color-naming secondary lines in report-orange (kpi-card default secondary-color: "primary"); all four tables carry dangling empty "TABLE n ·" auto-captions (tbl- labels without tbl-cap) plus doubled top rules. Fix: strip escape in back-cover partial; per-card colors on p16; add tbl-caps or rename labels; one caption policy. (/impeccable polish)
- [P2] Page rhythm collapses mid-book: pages 11/13/15/23 60-85% empty, closing callout alone on p26, permanent ~77%-width figures with dead right rail. Mechanical cause: 19 of 20 figure chunks lack fig-width; YAML fig-dpi 600 silently overridden to dpi=320 in setup. Fix: standard fig-width matched to measure or claim rail as marginalia; unbreakable code+figure groups; reconcile dpi. (/impeccable layout)
- [P2] Legibility floor: light ramp poles (#B8E7EE, #F8DDD9) vanish on #F7F7F7 (p12-13); ghost near-zero diverging bars (p15); sub-AA orange eyebrows and gray captions; 3-4pt JetBrains Mono Thin labels; p14 heatmap labels integer weeks as 0.0/2.5/5.0. Fix: clamp ramp light ends ~shade-04 or stroke light marks; darken/enlarge accent text; raise thin-mono type floor; integer breaks. (/impeccable audit)

## Persona Red Flags

- Jordan (first-time user): copies p9/p10 verbatim, ships rule-breaking rainbow; empty "TABLE 1 ·" caption reads as their own misconfiguration; learns green = any positive number.
- Alex (power user): no flip on chanwe_kpi(), so hardcodes hexes like the showcase; cannot mix valences in one col_colors column; must hand-set fig-width everywhere; no cross-refs/index across 28 pages.
- Sam (CVD/low-vision): flagship diverging scale is red-green (deutan trap) with no named escape hatch; sub-4.5:1 eyebrows/captions at small sizes; invisible light ramp segments carry data (p13, 2000-2004).

## Minor Observations

- Cover meta sub-lines hardcoded "IBM Plex Mono" (chanwe-pages.typ:43), off-token on page 1.
- chanwe_kbl docstring says "Satoshi body" but sets JetBrains Mono for data cells (kbl-theme.R:439).
- Hardcoded #DADADA/#E9E9E9/#F3F3F3 inside chanwe_kbl, outside the token system.
- Palette previews titled "ChanWe Palette" (camel-case off-brand); letterbox bands from coord_equal (p7-8).
- p11 reverse=TRUE ordinal bars never reach dark for n<5; sample ramp extremes.
- Compact table p25: mixed raw decimals, equal 1fr columns wrap names while HP has slack.
- _extension.yml mainfont "Inter" vs template font-sans leading Satoshi; chanwe_load_fonts() only searches chanwe-report/fonts; Fraunces registered+shipped, used by nothing.
- Interstitial pages 2 and 27 read as accidental blanks on screen.

## Questions to Consider

1. Should valence be a first-class argument everywhere signed tokens appear?
2. What is the sanctioned CVD escape hatch for the red-green diverging scale, and why doesn't the reference name it?
3. The permanent empty right column: unclaimed marginalia grid or unchosen default? Claim it or close it.
