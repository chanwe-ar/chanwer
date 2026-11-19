// =============================================================
// chanwe-v2.typ — the CHANWE v2 shapes for paper ("v2-print", Q1 B of the
// brand-v2 plan; the language is chanwe-brandbook brand/guide/guidelines/brand-v2.md).
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
// white for display and `fg-subtle` for labels (CLAUDE.md, 2026-11-19).
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

// ---------- Document-wide choices --------------------------------------
// Each format's template writes its YAML choices here once, at the start of
// the document (`_cw-style.update(...)`): the variant of a component, and the
// assets path, so the shared partials can find the v2 icons. Components read
// them inside `context` with `cw-style(key, default)`.
#let _cw-style = state("cw-style", (:))
#let cw-style(key, default) = _cw-style.get().at(key, default: default)
// Switch a choice from here on, inside the document (raw Typst):
// `#chanwe-use(task-style: "square", quote-style: "display")`. The galleries
// use it to show every variant in one file.
#let chanwe-use(..args) = _cw-style.update(s => s + args.named())

// The faint dot field of the v2 covers, back covers and dividers, as a
// gradient (Ale, 2026-11-18: "more subtle, with a gradient feel"): the dots
// are at their strongest in one corner (`from`, in fractions of the area;
// the bottom right by default) and fade out across the page. Drawn dot by
// dot, because a tiling cannot be masked with a gradient. It fills its
// container: use it as a page `background`, or `place` it in a block.
#let cw-dot-gradient(color: _t.ink-fg, from: (1.0, 1.0), reach: 1.3, peak: 32%, step: 3.4mm, dot: 0.42pt) = layout(size => {
  let (w, h) = (size.width, size.height)
  if w == 0pt or h == 0pt or w == float.inf * 1pt { return }
  let nx = int(w / step)
  let ny = int(h / step)
  for i in range(nx) {
    for j in range(ny) {
      let x = (i + 0.5) * step
      let y = (j + 0.5) * step
      let d = calc.sqrt(calc.pow(x / w - from.at(0), 2) + calc.pow(y / h - from.at(1), 2)) / reach
      if d >= 1 { continue }
      let a = peak * calc.pow(1 - d, 1.8)
      place(top + left, dx: x, dy: y, circle(radius: dot, fill: color.transparentize(100% - a)))
    }
  }
})

// The Fundido icons (brand/assets/patrones in the hub, copied to
// assets/v2/iconos/), in any token colour: the Color cut has one fill, the
// primary, and it is swapped for the colour asked. Names: Aspa, Nudo, Paso,
// Mas, Codo, Reloj, Onda, Traslado, Rombo, Damero, Escala, Cruz.
#let cw-icon-names = ("Nudo", "Paso", "Onda", "Escala", "Reloj", "Traslado", "Codo", "Rombo", "Damero", "Mas")
#let cw-icon(name, fill: _t.primary, width: auto, height: auto) = context {
  let base = cw-style("assets", "")
  let svg = read(base + "v2/iconos/Icono_" + name + "_Color.svg")
  image(bytes(svg.replace("#FD3810", fill.to-hex()).replace("#fd3810", fill.to-hex())),
        format: "svg", width: width, height: height)
}
// The wordmark alone (D-0009, 2026-11-18: the logo almost never goes with
// the Aspa; the Aspa lives on its own as a symbol or a signal). `Negro` on
// paper, `Papel` on obsidian and on orange. No lockup is copied here: a
// piece that needs both takes it from the hub's logo/formatos.
#let cw-wordmark(cut: "Negro", height: auto, width: auto) = context image(
  cw-style("assets", "") + "Logo_" + cut + ".svg", height: height, width: width,
)

// ---------- Base components shared by the Typst formats -----------------
// The code block (brand-v2 §6: a code block stays dark): the lighter obsidian
// (`ink-light`, the owner's choice of 2026-11-18), 12px corners, the language
// as a quiet mono label, the code in the dark theme (assets/chanwe-dark.tmTheme).
// `terminal` (also `console`, `shell-session`): the same block labelled
// «Terminal», the dollar prompt in orange, the command in `rule-cool`, the output
// lines in `fg-subtle` (unified with the kit, 2026-11-18).
#let _cw-terminal-langs = ("terminal", "console", "shell-session")
#let _cw-terminal(it) = {
  for (i, line) in it.text.split("\n").enumerate() {
    if i > 0 { linebreak() }
    if line.starts-with("$$") {
      text(fill: _t.primary, "$$")
      text(fill: _t.rule-cool, line.slice(1))
    } else {
      text(fill: _t.fg-subtle, line)
    }
  }
}
#let cw-code-block(it) = block(
  fill: _t.ink-light,
  stroke: none,
  radius: _t.radius-pane,
  inset: (x: 4.5mm, y: 3.6mm),
  width: 100%,
  breakable: false,
)[
  #set block(fill: none, spacing: 0pt)
  #set par(spacing: 0pt)
  #let term = it.lang != none and lower(it.lang) in _cw-terminal-langs
  #if term {
    cw-label("Terminal", fill: _t.fg-subtle, size: 6pt)
    v(2.6mm)
  } else if it.lang != none {
    cw-label(it.lang + " · " + str(it.lines.len()) + " lines", fill: _t.fg-subtle, size: 6pt)
    v(2.6mm)
  }
  #text(font: _t.font-mono, size: 9pt, weight: _t.weight-body, fill: _t.rule-cool, if term { _cw-terminal(it) } else { it })
]

// The markdown `---`: the `rule` hairline across the measure, broken in the
// middle by the small Más icon in `rule-cool`. Orange is a signal; a section
// break is not one.
#let cw-horizontal-rule = block(above: 11mm, below: 11mm, width: 100%, grid(
  columns: (1fr, auto, 1fr),
  column-gutter: 3mm,
  align: horizon,
  line(length: 100%, stroke: 0.5pt + _t.rule),
  cw-icon("Mas", fill: _t.rule-cool, width: 3.4mm),
  line(length: 100%, stroke: 0.5pt + _t.rule),
))
