// =============================================================
// chanwe-v2.typ — the CHANWE v2 shapes for paper ("v2-print", Q1 B of the
// brand-v2 plan; the language is chanwe-brandbook brand/guidelines/brand-v2.md).
//
// Shared by every Typst format (listed by parent path under
// `template-partials` and included right after the chanwe-tokens.typ partial).
// It writes no value of its own: every colour, radius, space and size reads
// the generated `_t` table.
//
//   cw-pane     white pane on paper: 1px hairline, 16px corners, no shadow
//   cw-band     obsidian band: 24px corners, the dot field, the neutral sheen
//   cw-dot      the role colour as a dot (callouts, statuses, new items)
//   cw-label    a mono label: the only spaced capitals in v2
//   cw-pill     a pill (chips, tags, deltas); sentence case unless a label
// =============================================================

// 1px, the hairline of a pane at rest (brand-v2 §4: `rest` is the hairline;
// on paper there is no shadow).
#let cw-hairline = 0.75pt

#let cw-pane(
  body,
  fill: _t.pane,
  stroke: cw-hairline + _t.rule,
  radius: _t.radius-surface,
  inset: (x: _t.space-lg, y: _t.space-md),
  width: 100%,
  ..args,
) = block(fill: fill, stroke: stroke, radius: radius, inset: inset, width: width, ..args, body)

#let cw-dot(color, size: 5pt, baseline: -0.4pt) = box(
  baseline: baseline,
  circle(radius: size / 2, fill: color, stroke: none),
)

#let cw-label(body, fill: _t.fg-muted, size: _t.text-label, weight: _t.weight-medium, tracking: 0.14em) = text(
  font: _t.font-mono, size: size, weight: weight, tracking: tracking, fill: fill, upper(body),
)

#let cw-pill(
  body,
  fill: none,
  stroke: cw-hairline + _t.rule,
  inset: (x: _t.space-xs, y: _t.space-2xs),
  baseline: 25%,
) = box(fill: fill, stroke: stroke, radius: _t.radius-pill, inset: inset, baseline: baseline, body)

// The dot field of the band: a flat tiling of `ink-fg` dots, faint. Typst's
// `tiling` keeps the file small (one cell, repeated by the viewer).
#let cw-dot-field(step: 3.8mm, dot: 0.6pt, color: _t.ink-fg, transparency: 35%) = tiling(
  size: (step, step),
  place(center + horizon, circle(radius: dot, fill: color.transparentize(transparency), stroke: none)),
)

// One footer language (2026-11-07): every figure, table and page says the same
// three things the same way. A dot and a mono label name the piece, the caption
// follows it, and what closes a piece is quiet mono over a hairline. No stamp:
// orange is the signal, and a pill under every figure made it wallpaper.
#let cw-figure-head(label, gloss: none) = {
  grid(
    columns: (auto, 1fr),
    column-gutter: 3.5mm,
    align: left + top,
    {
      cw-dot(_t.primary, size: 4.2pt)
      h(1.8mm)
      cw-label(label, fill: _t.fg, size: 6pt)
    },
    if gloss != none {
      text(font: _t.font-sans, size: 7.6pt, weight: _t.weight-body-plus, fill: _t.fg-muted, gloss)
    },
  )
  v(3mm)
}

#let cw-figure-foot(left-slot, right-slot) = {
  v(2.6mm)
  line(length: 100%, stroke: 0.5pt + _t.rule)
  v(1.8mm)
  grid(
    columns: (auto, 1fr),
    column-gutter: 7mm,
    align: (left + top, right + top),
    if left-slot != none { cw-label(left-slot, size: 5.6pt, weight: _t.weight-regular) },
    if right-slot != none {
      text(font: _t.font-sans, size: 7.2pt, weight: _t.weight-body-plus, fill: _t.fg-muted, right-slot)
    },
  )
}

// A loose figure's caption, under it.
#let cw-figure-caption(it) = align(left, text(
  font: _t.font-mono, size: 5.6pt, weight: _t.weight-regular, tracking: 0.1em, fill: _t.fg-muted,
  upper(it.supplement) + " " + it.counter.display() + "  ·  " + upper(it.body),
))

// The folio: where you are in full, the total a step back.
#let cw-folio(strong: _t.fg, soft: _t.fg-muted) = context text(
  font: _t.font-mono, size: 6.5pt, weight: _t.weight-medium, tracking: 0.1em, {
    text(fill: strong, str(counter(page).get().first()))
    text(fill: soft, weight: _t.weight-regular, " / " + str(counter(page).final().first()))
  },
)

// The obsidian band (brand-v2 §2, §7): one per page at most, floating with
// a margin (never edge to edge), 24px corners, the dot field and the neutral
// top sheen over its top 30%, a 1px light edge on top. Text on it is
// `rule-cool` for display and `fg-subtle` for labels (CLAUDE.md).
#let cw-band(
  body,
  inset: (x: _t.space-xl, y: _t.space-xl),
  radius: _t.radius-band,
  width: 100%,
  height: auto,
  dots: true,
  ..args,
) = block(
  fill: _t.ink,
  radius: radius,
  width: width,
  clip: true,
  inset: 0pt,
  stroke: none,
  ..args,
  block(
    width: 100%,
    inset: 0pt,
    spacing: 0pt,
    fill: if dots { cw-dot-field() } else { none },
    block(
      width: 100%,
      height: height,
      spacing: 0pt,
      inset: inset,
      stroke: (top: cw-hairline + _t.band-edge),
      fill: gradient.linear((_t.band-sheen, 0%), (_t.band-sheen.transparentize(100%), 30%), (_t.band-sheen.transparentize(100%), 100%), angle: 90deg),
      body,
    ),
  ),
)
