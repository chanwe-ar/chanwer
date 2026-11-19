// Simple numbering for non-book documents
#let equation-numbering = "(1)"
#let callout-numbering = "1"
#let subfloat-numbering(n-super, subfloat-idx) = {
  numbering("1a", n-super, subfloat-idx)
}

// Theorem configuration for theorion
// Simple numbering for non-book documents (no heading inheritance)
#let theorem-inherited-levels = 0

// Theorem numbering format (can be overridden by extensions for appendix support)
// This function returns the numbering pattern to use
#let theorem-numbering(loc) = "1.1"

// Default theorem render function
#let theorem-render(prefix: none, title: "", full-title: auto, body) = {
  if full-title != "" and full-title != auto and full-title != none {
    strong[#full-title.]
    h(0.5em)
  }
  body
}
// Some definitions presupposed by pandoc's typst output.
#let content-to-string(content) = {
  if content.has("text") {
    content.text
  } else if content.has("children") {
    content.children.map(content-to-string).join("")
  } else if content.has("body") {
    content-to-string(content.body)
  } else if content == [ ] {
    " "
  }
}

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms.item: it => block(breakable: false)[
  #text(weight: "bold")[#it.term]
  #block(inset: (left: 1.5em, top: -0.4em))[#it.description]
]

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let fields = old_block.fields()
  let _ = fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => {
          let subfloat-idx = quartosubfloatcounter.get().first() + 1
          subfloat-numbering(n-super, subfloat-idx)
        })
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => block({
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          })

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let children = old_title_block.body.body.children
  let old_title = if children.len() == 1 {
    children.at(0)  // no icon: title at index 0
  } else {
    children.at(1)  // with icon: title at index 1
  }

  // TODO use custom separator if available
  // Use the figure's counter display which handles chapter-based numbering
  // (when numbering is a function that includes the heading counter)
  let callout_num = it.counter.display(it.numbering)
  let new_title = if empty(old_title) {
    [#kind #callout_num]
  } else {
    [#kind #callout_num: #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block,
    block_with_new_content(
      old_title_block.body,
      if children.len() == 1 {
        new_title  // no icon: just the title
      } else {
        children.at(0) + new_title  // with icon: preserve icon block + new title
      }))

  align(left, block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1)))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color,
        width: 100%,
        inset: 8pt)[#if icon != none [#text(icon_color, weight: 900)[#icon] ]#title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}



// =============================================================
// chanwe-studio/chanwe-report - typst-template.typ
// Page setup, design tokens, and global show rules.
// =============================================================

// ---------- Design tokens ------------------------------------
// The token table is generated (brand-v2 T7.1): chanwe-brand-tokens.typ is the hub's
// tokens.typ and chanwe-tokens.typ builds `_t` on it (scripts/generate-brand.rb).
// Generated from brand/ui/tokens/tokens.json by scripts/brand-tokens.mjs. Do not edit; change tokens.json and run npm run brand:tokens.
// Lengths are px numbers (multiply by 0.75pt in print); colours are rgb().
#let chanwe-colors = (
  "primary": rgb("#FD3810"),
  "primary-text": rgb("#FD3810"),
  "primary-active": rgb("#FD3810"),
  "ink": rgb("#111319"),
  "ink-light": rgb("#232A35"),
  "ink-soft": rgb("#37393F"),
  "ink-fg": rgb("#64748B"),
  "ink-subtle": rgb("#646464"),
  "rule-ink": rgb("#434D5D"),
  "fg": rgb("#111319"),
  "body-fg": rgb("#475569"),
  "fg-muted": rgb("#475569"),
  "fg-subtle": rgb("#5B6677"),
  "emphasis": rgb("#484848"),
  "paper": rgb("#F8FAFC"),
  "callout-surface": rgb("#F8FAFC"),
  "surface-sunken": rgb("#F1F5F9"),
  "surface-slate": rgb("#EBF0F6"),
  "surface-raised": rgb("#FFFFFF"),
  "callout-header": rgb("#EBF0F6"),
  "pure-white": rgb("#FFFFFF"),
  "pure-black": rgb("#000000"),
  "rule": rgb("#E2E8F0"),
  "rule-cool": rgb("#C6CDD6"),
  "border-cool": rgb("#CFD6DF"),
  "border": rgb("#1113191A"),
  "neutral-300": rgb("#D4D4D4"),
  "neutral-700": rgb("#525252"),
  "chart-blue": rgb("#007AFF"),
  "chart-green": rgb("#34C759"),
  "chart-indigo": rgb("#5856D6"),
  "chart-orange": rgb("#FF9500"),
  "chart-red": rgb("#FF3B30"),
  "chart-teal": rgb("#00C7BE"),
  "chart-purple": rgb("#AF52DE"),
  "callout-note": rgb("#007AFF"),
  "callout-tip": rgb("#00C7BE"),
  "callout-warning": rgb("#FF9500"),
  "callout-important": rgb("#FD3810"),
  "callout-caution": rgb("#AF52DE"),
  "callout-do": rgb("#34C759"),
  "callout-dont": rgb("#FF3B30"),
  "research-muted": rgb("#99999E"),
  "kpi-green": rgb("#147705"),
  "kpi-red": rgb("#CC1914"),
  "exec-status-good": rgb("#15803D"),
  "exec-status-regular": rgb("#D97706"),
  "exec-status-bad": rgb("#CC1914"),
  "code-keyword": rgb("#FD3810"),
  "code-string": rgb("#15803D"),
  "code-number": rgb("#7C3AED"),
  "code-operator": rgb("#0758E5"),
  "code-function": rgb("#475569"),
  "code-type": rgb("#353535"),
  "code-comment": rgb("#928D86"),
  "status-success": rgb("#1EB508"),
  "status-success-soft": rgb("#C9FFC0"),
  "status-error": rgb("#D32F2F"),
  "status-error-bg": rgb("#FDECEA"),
  "status-warning": rgb("#F9E710"),
  "status-warning-bg": rgb("#FFF8B8"),
  "status-info": rgb("#0C48ED"),
  "status-info-bg": rgb("#B8CEFF"),
  "chart-cyan": rgb("#11F7E6"),
  "chart-cyan-soft": rgb("#B6FFF8"),
  "chart-magenta": rgb("#EB03F2"),
  "chart-gray": rgb("#71706C"),
  "violet": rgb("#7C3AED"),
  "violet-soft": rgb("#EFE7FD"),
  "canvas": rgb("#E9EEF4"),
  "pane": rgb("#FFFFFF"),
  "favorite": rgb("#FFCC00"),
)
#let chanwe-colors-dark = (
  "ink": rgb("#F4F6F9"),
  "ink-fg": rgb("#94A3B8"),
  "ink-subtle": rgb("#A1A6AE"),
  "fg": rgb("#F4F6F9"),
  "body-fg": rgb("#C3CAD4"),
  "fg-muted": rgb("#C3CAD4"),
  "fg-subtle": rgb("#8A94A6"),
  "emphasis": rgb("#DDE2E9"),
  "paper": rgb("#111319"),
  "callout-surface": rgb("#161B23"),
  "surface-sunken": rgb("#0B0D12"),
  "surface-slate": rgb("#1F2631"),
  "surface-raised": rgb("#1A1F28"),
  "callout-header": rgb("#232A35"),
  "rule": rgb("#2B333D"),
  "rule-cool": rgb("#3A4555"),
  "border-cool": rgb("#3F4A5B"),
  "border": rgb("#F4F6F91A"),
  "neutral-300": rgb("#3A4150"),
  "neutral-700": rgb("#CDD3DB"),
  "status-success-soft": rgb("#14361A"),
  "status-error-bg": rgb("#3A1A1A"),
  "status-warning-bg": rgb("#3A3512"),
  "status-info-bg": rgb("#15274D"),
  "violet-soft": rgb("#2C2150"),
  "chart-cyan-soft": rgb("#0E3B38"),
  "code-type": rgb("#D4D4D8"),
  "code-function": rgb("#C3CAD4"),
  "code-comment": rgb("#7E8A99"),
  "research-muted": rgb("#7E8390"),
  "canvas": rgb("#232A35"),
  "pane": rgb("#111319"),
  "favorite": rgb("#FFD60A"),
)
#let chanwe-radii = (
  "hair": 2,
  "card": 4,
  "control": 4,
  "window": 8,
  "pane": 12,
  "row": 8,
  "pill": 999,
  "surface": 16,
  "band": 24,
)
#let chanwe-space = (
  "2xs": 4,
  "xs": 8,
  "sm": 12,
  "md": 16,
  "lg": 24,
  "xl": 32,
  "2xl": 48,
  "3xl": 80,
  "section": 120,
)
#let chanwe-control = (
  "xs": 28,
  "sm": 32,
  "md": 40,
  "lg": 48,
)
#let chanwe-type = (
  "label": 10,
  "caption": 11,
  "control": 12.5,
  "button": 13,
  "small": 13,
  "body": 14,
  "title": 14,
  "lead": 15,
  "h4": 18,
  "h3": 22,
  "h2": 28,
  "h1": 36,
  "display": 48,
)
#let chanwe-plot = (
  "focus": rgb("#FD3810"),
  "slate": (rgb("#232A35"), rgb("#475569"), rgb("#64748B"), rgb("#8A94A6"), rgb("#C6CDD6"),),
  "categorical": (rgb("#FD3810"), rgb("#007AFF"), rgb("#00C7BE"), rgb("#5856D6"), rgb("#AF52DE"), rgb("#34C759"), rgb("#FF9500"), rgb("#FF3B30"),),
  "grid": rgb("#64748B40"),
  "axis-text": rgb("#64748B"),
  "title": rgb("#111319"),
  "background": rgb("#FFFFFF"),
  "grid-width": 1,
  "line-width": 2,
  "point-size": 3,
  "bar-radius": 3,
)
#let chanwe-layout = (
  "shell-bar": 56,
)
#let chanwe-state = (
  "primary-hover": rgb("#EA3511"),
  "primary-pressed": rgb("#D73211"),
)
#let chanwe-fonts = (
  "display": "Schibsted Grotesk",
  "body": "Satoshi",
  "mono": "JetBrains Mono",
)
#let chanwe-callout = (
  "dot": 7,
  "label-tracking": "0.14em",
  "radius": 12,
)
#let chanwe-eyebrow = (
  "dot": 7,
  "tracking": "0.14em",
)
#let chanwe-code = (
  "surface": rgb("#232A35"),
  "fg": rgb("#C6CDD6"),
  "label": rgb("#8A94A6"),
  "output": rgb("#8A94A6"),
  "prompt": rgb("#FD3810"),
  "radius": 12,
)
#let chanwe-syntax = (
  "keyword": rgb("#FD3810"),
  "string": rgb("#34C759"),
  "number": rgb("#AF52DE"),
  "operator": rgb("#00C7BE"),
  "function": rgb("#F8FAFC"),
  "type": rgb("#FF9500"),
  "comment": rgb("#8A94A6"),
  "function-weight": 700,
  "comment-style": "italic",
)
#let chanwe-dots = (
  "step": 18,
  "size": 1,
  "on-light": "color-mix(in srgb, #111319 7%, transparent)",
  "on-ink": "color-mix(in srgb, #FFFFFF 5%, transparent)",
  "origin": "100% 0%",
  "fade-reach": "70%",
  "fade-soft": "100%",
)// Generated by scripts/generate-brand.rb from brandbook/tokens.json: do not edit, run the script.
// The `_t` table of every CHANWE Typst format. It is built on chanwe-brand-tokens.typ (the
// hub's tokens.typ, copied byte for byte): colours by name from `chanwe-colors`, the v2
// lengths from `chanwe-radii` / `chanwe-space` / `chanwe-type` in pt (a token px is 0.75pt),
// plus the role weights (brand.yml meta.weights) and the two editorial serifs.
#let _cw-pt(px) = px * 0.75pt
#let chanwe-tokens = chanwe-colors + (
  // `white` / `black` read `pure-white` / `pure-black`: no partial writes either word.
  white: chanwe-colors.at("pure-white"),
  black: chanwe-colors.at("pure-black"),
  // v2 slate tint (depth.light): the text slate over the pane, for headers and grouping.
  tint: chanwe-colors.at("ink-fg").transparentize(87%),
  tint-strong: chanwe-colors.at("ink-fg").transparentize(79%),
  band-sheen: chanwe-colors.at("pure-white").transparentize(95%),
  band-edge: chanwe-colors.at("pure-white").transparentize(90%),
  weight-hairline: 100,
  weight-thin: 200,
  weight-body: 300,
  weight-body-plus: 400,
  weight-regular: 400,
  weight-medium: 500,
  weight-display: 600,
  weight-bold: 700,
  font-display: (chanwe-fonts.display, "Helvetica Neue", "Arial"),
  font-sans: (chanwe-fonts.body, "Helvetica Neue", "Arial"),
  font-mono: (chanwe-fonts.mono, "Menlo", "Courier New"),
  font-serif: ("Cormorant Garamond", "Georgia", "Times New Roman"),
  font-serif-display: ("Instrument Serif", "Georgia", "Times New Roman"),
  radius-hair: _cw-pt(chanwe-radii.at("hair")),
  radius-row: _cw-pt(chanwe-radii.at("row")),
  radius-pane: _cw-pt(chanwe-radii.at("pane")),
  radius-surface: _cw-pt(chanwe-radii.at("surface")),
  radius-band: _cw-pt(chanwe-radii.at("band")),
  radius-pill: _cw-pt(chanwe-radii.at("pill")),
  space-2xs: _cw-pt(chanwe-space.at("2xs")),
  space-xs: _cw-pt(chanwe-space.at("xs")),
  space-sm: _cw-pt(chanwe-space.at("sm")),
  space-md: _cw-pt(chanwe-space.at("md")),
  space-lg: _cw-pt(chanwe-space.at("lg")),
  space-xl: _cw-pt(chanwe-space.at("xl")),
  space-2xl: _cw-pt(chanwe-space.at("2xl")),
  space-3xl: _cw-pt(chanwe-space.at("3xl")),
  space-section: _cw-pt(chanwe-space.at("section")),
  text-label: _cw-pt(chanwe-type.at("label")),
  text-caption: _cw-pt(chanwe-type.at("caption")),
  text-control: _cw-pt(chanwe-type.at("control")),
  text-button: _cw-pt(chanwe-type.at("button")),
  text-small: _cw-pt(chanwe-type.at("small")),
  text-body: _cw-pt(chanwe-type.at("body")),
  text-title: _cw-pt(chanwe-type.at("title")),
  text-lead: _cw-pt(chanwe-type.at("lead")),
  text-h4: _cw-pt(chanwe-type.at("h4")),
  text-h3: _cw-pt(chanwe-type.at("h3")),
  text-h2: _cw-pt(chanwe-type.at("h2")),
  text-h1: _cw-pt(chanwe-type.at("h1")),
  text-display: _cw-pt(chanwe-type.at("display")),
)

// expose tokens as a global so partials and user code can use them
#let _t = chanwe-tokens// =============================================================
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
    if line.starts-with("$") {
      text(fill: _t.primary, "$")
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

// El punto bermellón dibujado que cierra un titular principal: la portada,
// el H1. A escala del titular, como el de la portada (36pt → disco de 8pt,
// 3pt de aire, base corrida 2pt): 0.22 del cuerpo, 0.083 de aire. Sin glue
// entre el titular y la caja, para que el punto nunca quede solo en un
// renglón. Solo el H1 lo lleva; el H2 y los de abajo, no.
#let _chanwe-title-dot(size, fill: _t.primary) = box(baseline: -size * 2 / 36, {
  h(size * 3 / 36)
  circle(radius: size * 4 / 36, fill: fill, stroke: none)
})

// El tamaño de hoja del formato. Vive en una sola constante porque las
// páginas a sangre (portadas, contratapa, divisores, citas a página
// completa) tienen que declararlo aparte: un `set page` con margen 0 no
// hereda el papel del documento. Los parciales de abajo la leen.
#let _chanwe-paper = "a4"

// Las medidas de la hoja, explícitas. La portada research venía con la
// geometría clavada a US Letter (215.9 x 279.4mm): al pasar el formato a A4
// se desbordaba a lo ancho y quedaba corta a lo alto. Ahora todo lo que
// dependía del papel se deriva de estas dos, y el reparto de columnas
// (74 / 26, el de la referencia) se expresa como fracción en vez de en
// milímetros. La banda de arte de la portada ya era `1fr`, asi que el alto
// extra de A4 lo absorbe ella sola.
#let _chanwe-page-w = 210mm
#let _chanwe-page-h = 297mm

// assets path — override with chanwe-assets: in document YAML if the
// extension installed to a different path (e.g. _extensions/chanwe-report/)
#let _chanwe-assets = "\_extensions/chanwe-report/assets/".replace("\\_", "_")

// ---------- Small primitives ---------------------------------
#let chanwe-glyph(size: 7pt, color: _t.primary) = box(
  width: size, height: size, baseline: 1pt,
)[
  #place(center + horizon, rotate(45deg, square(size: size * 0.72, fill: color)))
]

// The eyebrow, unified with the kit (Ale, 2026-11-18): an orange dot and a
// JetBrains Mono uppercase label in slate (`fill`: `fg-muted` on paper,
// `rule-cool` on ink). Documents may opt into the orange rule with an
// orange label, the eyebrow of before, for covers, openers and bands:
// `chanwe: eyebrow-style: rule`, or `style: "rule"` on one call.
#let chanwe-eyebrow(body, dot: _t.primary, fill: _t.fg-muted, size: 8.5pt, style: auto) = context {
  let style = if style == auto { cw-style("eyebrow-style", "dot") } else { style }
  if style == "rule" {
    box(width: size * 2.6, height: 0.75pt, fill: dot, baseline: -size * 0.35)
    h(size * 0.95)
  } else {
    box(baseline: -size * 0.12, circle(radius: size * 0.26, fill: dot, stroke: none))
    h(size * 0.7)
  }
  text(
    font: _t.font-mono,
    size: size,
    weight: _t.weight-medium,
    tracking: 0.16em,
    fill: if style == "rule" { dot } else { fill },
    upper(body),
  )
}

#let chanwe-section-eyebrow(body, fill: _t.fg-muted) = chanwe-eyebrow(body, fill: fill)

// El `---` de markdown. Pandoc lo escribe como `#horizontalrule`, que Quarto
// define en su `definitions.typ` (cargado antes que este archivo) como una
// línea negra al ancho del medio. Se vuelve a definir acá, y gana ésta:
// misma geometría, filete fino en naranja.
#let horizontalrule = cw-horizontal-rule

#let chanwe-meta-row(label, value, sub: none) = {
  grid(
    columns: (18mm, 1fr),
    column-gutter: 4mm,
    align: (left + top, left + top),
    text(font: _t.font-mono, size: 7pt, tracking: 0.20em, fill: _t.fg-muted, upper(label)),
    block(spacing: 0pt)[
      #set par(spacing: 0pt, leading: 0.9em)
      #text(font: _t.font-display, tracking: -0.05em, size: 10pt, weight: _t.weight-display, fill: _t.fg, value)
      #if sub != none {
        linebreak()
        text(font: _t.font-sans, size: 8.5pt, fill: _t.fg-muted, sub)
      }
    ],
  )
}

// ---------- Running header / footer --------------------------
// La paleta del renglón de servicio. `inverse` es `none` sobre la hoja y
// "dark" o "primary" en las páginas que pintan la hoja entera. Sobre naranja
// el texto y el acento pasan a blanco, y el wordmark al corte `Papel`
// (`Logo_Papel.svg`, #F8FAFC): `Blanco` nunca es el logo. Sobre obsidiana el
// texto y el acento se quedan como están y sólo el wordmark cambia al corte
// gris de la portada (rule-cool): el renglón de servicio es un riel.
#let _hf-palette(inverse) = if inverse == "primary" {
  (text: _t.white, strong: _t.white, accent: _t.white, rule: _t.white.transparentize(60%), logo: "Logo_Papel.svg")
} else if inverse == "dark" {
  (text: _t.fg-subtle, strong: _t.white, accent: _t.primary, rule: _t.rule-ink, logo: "Logo_Papel.svg")
} else {
  (text: _t.fg-muted, strong: _t.fg, accent: _t.primary, rule: _t.border, logo: "Logo_Negro.svg")
}

#let chanwe-header(section, topic, inverse: none) = context {
  let c = _hf-palette(inverse)
  block(height: 100%, width: 100%)[
    #grid(
      rows: (1fr, auto),
      align(horizon, {
        set text(font: _t.font-mono, size: 6pt, tracking: 0.14em)
        grid(
          columns: (1fr, auto),
          align: (left + horizon, right + horizon),
          [
            #text(weight: _t.weight-bold, fill: c.accent, "//")
            #h(5pt)
            #text(fill: c.text, upper(section))
            #if topic != "" [#text(fill: c.text, upper(" · " + topic))]
          ],
          image(_chanwe-assets + c.logo, height: 3.5mm, fit: "contain"),
        )
      }),
      // Edge to edge: the service rule belongs to the page, not to the text block.
      pad(x: -18mm, line(length: 100% + 36mm, stroke: 0.5pt + c.rule)),
    )
  ]
}

#let chanwe-footer(doc-id, edition, inverse: none) = context {
  let c = _hf-palette(inverse)
  // line pins to top; text row grows to fill space → text centers
  block(height: 100%, width: 100%)[
    #grid(
      rows: (auto, 1fr),
      // Mismo filete que cierra el encabezado.
      pad(x: -18mm, line(length: 100% + 36mm, stroke: 0.5pt + c.rule)),
      align(horizon, {
        // Mismo tono que el encabezado: el pie es la otra mitad del mismo
        // renglón de servicio. Un solo tono para todo el renglón, el que ya
        // tenía la edición; los `fill` por tramo desaparecieron con eso.
        set text(font: _t.font-mono, size: 6pt, tracking: 0.14em, fill: c.text)
        grid(
          columns: (1fr, auto),
          align: (left + horizon, right + horizon),
          [#upper[#doc-id #h(8pt) #edition]],
          cw-folio(strong: c.strong, soft: c.text),
        )
      }),
    )
  ]
}

// Global state - set by chanwe-report() and read by components
#let _chanwe-doc = state("chanwe-doc", (
  doc-id:    "CHW · DOC",
  edition:   "",
  taggy:     "CW- MACRO LAB",
  meta-rows: (),
  section:   "",
  topic:     "",
))

// El renglón de servicio leído del estado del documento, para las páginas
// que vuelven a fijar `page` (resumen ejecutivo, resumen doble) y necesitan
// el encabezado y el pie en su versión invertida.
#let chanwe-header-auto(inverse: none) = context {
  let d = _chanwe-doc.get()
  chanwe-header(d.section, d.topic, inverse: inverse)
}
#let chanwe-footer-auto(inverse: none) = context {
  let d = _chanwe-doc.get()
  // El estado ya guarda doc-id y edición limpios del escape de Pandoc.
  chanwe-footer(d.doc-id, d.edition, inverse: inverse)
}
#let _chanwe-inverse-of(color) = if color == "dark" { "dark" } else if color == "primary" { "primary" } else { none }

// Tracks the active chapter-divider section (set in chanwe-chapter-divider)
#let _chanwe-cur-part = state("chanwe-cur-part", none)

// =============================================================
// PARTIAL INCLUDES (qr, cover, elements, pages)
// Each file uses _t which is defined above.
// =============================================================
// =================================================================
// chanwe-qr.typ — El QR de contacto, enmarcado.
//
// Componente compartido, como `chanwe-cards.*` y `chanwe-lists.*`: se
// incluye por ruta padre —`- ../chanwe-report/chanwe-qr.typ` bajo
// `template-partials`, y la llamada al parcial después de la tabla `_t` del
// formato. (No se escribe acá con su sintaxis real: el motor de plantillas
// de Pandoc la expandiría dentro de este mismo comentario.)
// Lo usan la portada research y la contratapa del reporte, el memo, la
// propuesta y el fondo de pantalla de reMarkable. No se copia.
//
// El marco es el de la contratapa, punto por punto: filete de 0.5pt,
// esquina exterior de 1.4mm, y adentro una tarjeta clara con esquina de
// 0.8mm. El código queda siempre oscuro sobre claro, que es lo único que
// los lectores levantan de forma confiable.
//
// Ningún trazo escribe un color: `edge` y `card` los pasa el formato desde
// su propia tabla de tokens, y por eso no tienen default. Sobre obsidiana
// el filete es blanco al 16% (`_t.white.transparentize(84%)`); sobre papel
// es el 16% del negro de marca (`_t.ink.transparentize(84%)`) —la misma
// presencia visual con la polaridad dada vuelta, porque un blanco al 16%
// sobre papel no se ve.
//
// El asset por defecto es `assets/contact-qr.svg`, que codifica
// https://chanwe.ar (nivel H). Lo genera
// `scripts/make-qr-svg.mjs`; no se edita a mano.
// =================================================================

#let chanwe-qr-frame(
  path,
  size:         11.4mm,   // lado del código, sin contar marco ni tarjeta
  edge:         none,     // color del filete exterior — lo pasa el formato
  card:         none,     // color de la tarjeta interior — idem
  pad-outer:    2mm,      // aire entre el filete y la tarjeta
  pad-inner:    0.8mm,    // zona tranquila de la tarjeta alrededor del código
  radius-outer: 3pt,
  radius-inner: 1.5pt,
) = box(
  stroke: 0.5pt + edge,
  radius: radius-outer,
  inset: pad-outer,
  box(
    fill: card,
    radius: radius-inner,
    inset: pad-inner,
    image(path, width: size, fit: "contain"),
  ),
)// =============================================================
// chanwe-cover.typ — portadas de Chanwe Report
// =============================================================
// La portada research (por defecto) y, al final del archivo, las v2
// (`paper`, `photo-obsidian`, `series`). La "hero" se retiro el 2026-11-18.
//
// La research sigue la geometría de reports-covers.pdf:
//   532 px editorial field | 34 px legal gutter | 250 px black rail
//   700 px artwork/title header | 304 px title slab | 52 px footer
// at a 96 dpi, 816 x 1056 px US Letter canvas.
// =============================================================

// Pandoc/Quarto escapes underscores and hyphens in YAML values.
#let _chanwe-clean-path(p) = if p == none { none } else { p.replace("\\_", "_").replace("\\-", "-") }

// Pandoc's typst writer escapes markup characters inside YAML metadata
// strings (@ → \@, _ → \_, # → \#, / → \/); strip those so they never
// print literally.
#let _chanwe-clean-str(s) = if s == none { none } else if type(s) == str {
  s.replace("\\@", "@").replace("\\_", "_").replace("\\-", "-").replace("\\#", "#").replace("\\/", "/")
} else { s }

// Los tonos de la portada research, todos leídos de la tabla de tokens.
// Antes había tres constantes más —un papel de arte #FAF9F7, un naranja
// #F4380F y un metálico #AFAFAF— que ningún trazo usaba; se fueron.
#let _publication-paper = _t.callout-surface
#let _publication-ink = _t.ink
#let _publication-rule = _t.rule
#let _publication-muted = _t.research-muted

// Decorative bar pattern for the footer's series stamp. Not a scannable
// code — a print-editorial flourish, same spirit as the rotated legal rail.
#let _publication-barcode(height: 2.6mm) = {
  let widths = (1.4pt, 0.7pt, 0.7pt, 2.1pt, 0.7pt, 1.4pt, 0.7pt, 2.1pt, 1.4pt, 0.7pt, 0.7pt, 2.1pt, 0.7pt, 1.4pt, 0.7pt)
  box(height: height, stack(
    dir: ltr,
    spacing: 0.6pt,
    // En el slate del texto de servicio que lo acompaña, no en tinta: es un
    // sello decorativo, no un dato.
    ..widths.map(w => rect(width: w, height: 100%, fill: _t.fg-muted, stroke: none)),
  ))
}

// Campo de puntos de contratapa: trama pareja sobre obsidiana y un foco donde
// los mismos puntos se encienden. El foco se dibuja punto por punto — un
// tiling no se puede enmascarar con un degradado.
#let _chanwe-dot-field(
  width: _chanwe-page-w,
  height: _chanwe-page-h,
  step: 3.8mm,
  dot: 0.55pt,
  focus: (0.74, 0.40),
  focus-radius: 0.34,
  peak: 75%,
  base: 72%,
  color: _t.ink-fg,
  // (izquierda, derecha) en transparencia: la trama se va abriendo de un lado
  // al otro. Con `ramp` no sirve el tiling, que es parejo por definición.
  ramp: none,
) = {
  if ramp != none {
    let (l, r) = ramp
    let s = step / 1mm
    for i in range(int(width / step)) {
      let x = (i + 0.5) * s
      let t = x * 1mm / width
      let a = l + (r - l) * t
      for j in range(int(height / step)) {
        place(top + left, dx: x * 1mm, dy: (j + 0.5) * s * 1mm,
          circle(radius: dot, fill: color.transparentize(a)))
      }
    }
    return
  }

  place(top + left, rect(
    width: width, height: height, stroke: none,
    fill: tiling(size: (step, step))[
      #place(dx: step / 2, dy: step / 2, circle(radius: dot, fill: color.transparentize(base)))
    ],
  ))

  let fx = focus.at(0) * width / 1mm
  let fy = focus.at(1) * height / 1mm
  let r = focus-radius * width / 1mm
  let s = step / 1mm
  for i in range(int(width / step)) {
    for j in range(int(height / step)) {
      let x = (i + 0.5) * s
      let y = (j + 0.5) * s
      let d = calc.sqrt(calc.pow(x - fx, 2) + calc.pow(y - fy, 2))
      if d >= r { continue }
      // Caída suave: encendido en el centro, apagado en el borde.
      let t = calc.pow(1 - d / r, 1.5)
      place(top + left, dx: x * 1mm, dy: y * 1mm,
        circle(radius: dot, fill: color.transparentize(100% - t * peak)))
    }
  }
}


#let chanwe-cover-page(
  title: "Untitled",
  subtitle: none,
  doc-id: "SERIES-A #0934",
  edition: "Edition 01 / 2026",
  hero-image: none,
  wordmark: none,
  hero-caption-1: "32°53'24.8\"S  68°50'45.6\"W",
  hero-caption-2: "ELEV: 6967M // CERRO ACONCAGUA",
  hero-caption-3: "CORDILLERA PRINCIPAL · MENDOZA, AR",
  meta-rows: (),
  date: "",
  show-date-strip: false,
  cover-edge: none,
  publication-period: none,
  // Lo que dice la pastilla del masthead.
  badge: "CW- MACRO LAB",
  publication-edition: none,
  publication-art: none,
  publication-audience: "PÚBLICO",
  publication-series: "CHANWE / RESEARCH",
  publication-location: "MENDOZA / ARGENTINA",
  publication-qr: none,
  publication-copyright: "PROHIBIDA SU REPRODUCCIÓN SIN AUTORIZACIÓN | TODOS LOS DERECHOS RESERVADOS",
) = {
  let art = if publication-art != none {
    _chanwe-clean-path(publication-art)
  } else if hero-image != none {
    _chanwe-clean-path(hero-image)
  } else {
    _chanwe-assets + "cover-snow-ridge.jpg"
  }
  let period = if publication-period != none { publication-period } else { date }
  let edition-label = if publication-edition != none { publication-edition } else { edition }
  let copyright = if cover-edge != none { cover-edge } else { publication-copyright }
  let rail-wordmark = if wordmark == none {
    // The Papel cut on the obsidian rail, with the rail's white text
    // (2026-11-19; it was the cool grey `Logo_Gris`).
    _chanwe-assets + "Logo_Papel.svg"
  } else {
    _chanwe-clean-path(wordmark)
  }
  let qr = if publication-qr == none {
    _chanwe-assets + "contact-qr.svg"
  } else {
    _chanwe-clean-path(publication-qr)
  }

  // La serie y la ubicación llevan la barra en bermellón, así que se parten
  // por ella: "CHANWE / RESEARCH" y "MENDOZA / ARGENTINA".
  let split-slash(value, fallback) = {
    let parts = _chanwe-clean-str(value).split("/")
    if parts.len() >= 2 { (parts.at(0).trim(), parts.at(1).trim()) } else { (parts.at(0).trim(), fallback) }
  }
  let (series-1, series-2) = split-slash(publication-series, "")
  let (rail-location-1, rail-location-2) = split-slash(publication-location, "")

  // Geometría en cuatro bandas: masthead 26.6mm, campo de arte `1fr`, losa
  // de datos y titular `auto`, pie 13.758mm. Masthead y pie son bandas de
  // contenido y quedan en milímetros; el arte es elástico y se come la
  // diferencia de alto entre un papel y otro. El reparto de columnas es
  // 74 / 26, el de la referencia, ahora como fracción del ancho de hoja.
  let field-w = _chanwe-page-w * 0.74
  let rail-w = _chanwe-page-w * 0.26
  let pad = 10.583mm
  let content-w = field-w - pad * 2
  // v2: the rail is a floating band, 6mm from three paper edges (brand-v2 §2:
  // "bands float with a margin, never edge to edge"). The field's foot band
  // grows by the same 6mm, so its hairline still meets the rail's.
  let rail-gap = 6mm
  let rail-band-w = rail-w - rail-gap
  let rail-band-h = _chanwe-page-h - rail-gap * 2
  let foot-h = 13.758mm

  set page(
    paper: _chanwe-paper,
    margin: 0pt,
    header: none,
    footer: none,
    fill: _publication-paper,
    background: none,
    foreground: none,
  )
  set block(spacing: 0pt)

  block(width: 100%, height: _chanwe-page-h, breakable: false)[
    #grid(
      columns: (field-w, rail-w),
      rows: (_chanwe-page-h,),
      column-gutter: 0pt,

      // ══ Campo editorial ═════════════════════════════════════
      block(width: 100%, height: _chanwe-page-h)[

        // ── Masthead: período y edición a la izquierda, la posición
        // del observatorio a la derecha, repartida en la altura.
        #let masthead-h = 11.4mm
        #grid(
          rows: (26.6mm, 1fr, auto, foot-h + rail-gap),
          row-gutter: 0pt,

          block(
          width: 100%,
          height: 26.6mm,
          // The masthead's top is the rail's top (rail-gap), 2026-11-19.
          inset: (left: pad, right: pad, top: rail-gap, bottom: 26.6mm - rail-gap - 11.4mm),
        )[
          #grid(
            columns: (1fr, auto),
            block(width: 100%, height: masthead-h)[
              // El período va en pastilla gris. El cuerpo baja para que la
              // pastilla entera ocupe el espacio que ocupaba el texto solo.
              #place(bottom + left,
                // Misma pastilla que la serie del pie, en tinta y con el
                // texto en blanco.
                box(
                  stroke: 0.5pt + _publication-muted,
                  radius: _t.radius-pill,
                  inset: (x: 3.06mm, y: 1.44mm),
                  text(
                    font: _t.font-mono, size: 6.5pt, weight: _t.weight-regular,
                    tracking: 0.18em, fill: _publication-muted, upper(_chanwe-clean-str(badge)),
                  ),
                ))
              #place(top + left,
                box(
                  fill: _publication-ink,
                  radius: _t.radius-pill,
                  inset: (x: 3.06mm, y: 1.44mm),
                  // Texto sobre tinta en blanco (Ale, 2026-11-19).
                  text(
                    font: _t.font-mono, size: 6.5pt, weight: _t.weight-regular,
                    tracking: 0.18em, fill: _t.white, upper(edition-label),
                  ),
                ))
            ],
            // Ancho fijo: el contenido va posicionado, así que no aporta
            // ancho intrínseco y la columna colapsaría.
            block(width: 60mm, height: masthead-h)[
              // Las tres filas comparten exactamente el mismo estilo: una
              // sola declaración, aplicada a las tres.
              #set text(
                font: _t.font-mono, size: 5.4pt, weight: _t.weight-body,
                tracking: 0.18em, fill: _publication-muted,
              )
              // Las tres filas como un bloque compacto, centrado contra la
              // columna de la izquierda: antes se estiraban de borde a borde.
              #place(horizon + right, block(spacing: 0pt)[
                #set align(right)
                #text(upper(hero-caption-1))
                #v(0.5mm)
                #text(upper(hero-caption-2))
                #v(0.5mm)
                #text(upper(hero-caption-3))
              ])
            ],
          )
        ],

          // ── Campo de arte: la fila elástica. v2: the photograph floats inside
          // the margins with the band's 24px corners, and the veil drops from
          // 80% to 45% of paper: bleeding behind a heavy veil it read as a
          // white page.
          block(width: 100%, height: 100%, inset: (x: pad, bottom: 8mm))[
            // No border round the photograph (Ale, 2026-11-19): the light veil
            // keeps its edge.
            #block(width: 100%, height: 100%, clip: true, radius: _t.radius-band)[
              // 190% deja 45% de sobrante por lado; el corrimiento no puede
              // pasar de eso sin destapar el papel por abajo.
              #place(center + horizon, dy: -39%,
                     image(art, width: 190%, height: 190%, fit: "cover"))
              // Typst no expone opacidad sobre imágenes: el velo es el papel
              // encima, a esa opacidad. 15% since 2026-11-19 (it was 45%): under
              // the heavier veil the photograph's snow melted into the page and
              // its edges read as rough.
              #place(top + left, rect(width: 100%, height: 100%, stroke: none,
                                      fill: _publication-paper.transparentize(85%)))
            ]
          ],

          // ── Losa: ledger de datos y, debajo, el titular con su línea
          // bermellón. De alto automático: crece con el titular.
          block(width: 100%, inset: (left: pad, right: pad, top: 0mm, bottom: 10.5mm))[
          #if meta-rows.len() > 0 {
            // The hairline runs from the content margin to the rail, like the
            // photograph and the text above it (2026-11-19: it started at the
            // paper's edge, the one line on the cover that did).
            move(dx: 0pt, block(
              width: field-w - pad,
              stroke: (bottom: 0.5pt + _publication-rule),
              inset: (left: 0pt, right: pad, top: 0mm, bottom: 8.4mm),
              spacing: 0pt,
            )[
              // The ledger (Ale's pick, 2026-11-19): up to three columns, label
              // over value, as on the v2 covers.
              #grid(
                columns: range(calc.min(3, meta-rows.len())).map(_ => 1fr),
                column-gutter: 6mm,
                ..meta-rows.slice(0, calc.min(3, meta-rows.len())).map(((label, value, sub)) => block({
                  text(font: _t.font-mono, size: 6.4pt, weight: _t.weight-medium, tracking: 0.18em,
                       fill: _publication-muted, upper(_chanwe-clean-str(label)))
                  v(2.2mm)
                  text(font: _t.font-sans, size: 10pt, weight: _t.weight-regular, fill: _t.fg, _chanwe-clean-str(value))
                  if sub != none and sub != "" { linebreak(); text(font: _t.font-sans, size: 8.5pt, fill: _t.fg-muted, _chanwe-clean-str(sub)) }
                })),
              )
            ])
            v(11mm)
          }

          // El titular y su bajada, sin filete al costado desde 2026-11-07. El texto
            // mide de altura de mayúscula a línea de base (top-edge / bottom-edge).
            #block(
              width: content-w,
              spacing: 0pt,
            )[
              #set text(top-edge: "cap-height", bottom-edge: "baseline")
              #block(width: 100%, spacing: 0pt)[
                #set par(leading: 0.74em, spacing: 0pt)
                #text(
                  font: _t.font-display, size: 34pt, weight: _t.weight-display,
                  tracking: -0.05em, fill: _publication-ink, title,
                )#box(baseline: -1pt, {
                  h(3.5pt)
                  circle(radius: 3.9pt, fill: _t.primary, stroke: none)
                })
              ]
              #v(5.2mm)
              #block(width: 100%, spacing: 0pt)[
                #set par(leading: 0.62em, spacing: 0pt)
                #text(
                  font: _t.font-serif, size: 15pt, weight: _t.weight-body,
                  style: "italic", fill: _t.fg-muted, subtitle,
                )
              ]
            ]
        ],

          // ── Pie del campo: la pastilla de serie y, a la derecha, el doc-id
          // con su sello. Comparte banda con el pie del riel.
          block(
          width: 100%,
          height: foot-h + rail-gap,
          fill: _publication-paper,
          inset: (left: pad, right: 11.112mm, bottom: rail-gap),
        )[
          // The foot hairline starts at the margin too and meets the rail's.
          #place(top + left, dy: 0pt, line(length: field-w - pad, stroke: 0.5pt + _publication-rule))
          #align(horizon, grid(
            columns: (1fr, auto),
            align: (left + horizon, right + horizon),
            box(fill: _t.primary, radius: _t.radius-pill, inset: (x: 3.4mm, y: 1.6mm))[
              #set text(font: _t.font-mono, size: 7.2pt, weight: _t.weight-medium, tracking: 0.18em, fill: _t.white)
              #text(weight: _t.weight-bold, "//")
              #h(3.2mm)
              #upper(series-1)
              #text(fill: _t.white.transparentize(35%), " / ")
              #upper(series-2)
            ],
            grid(
              columns: (auto, auto),
              column-gutter: 4.5mm,
              align: horizon,
              text(font: _t.font-mono, size: 6.4pt, weight: _t.weight-regular, tracking: 0.1em,
                   fill: _publication-muted, upper(_chanwe-clean-str(doc-id))),
              _publication-barcode(),
            ),
          ))
        ],
        )
      ],

      // ══ Riel obsidiana ══════════════════════════════════════
      block(width: 100%, height: _chanwe-page-h, inset: (top: rail-gap, right: rail-gap))[
      #cw-band(width: rail-band-w, height: rail-band-h, inset: 0pt)[

        // ── QR: tarjeta blanca arriba, con el dominio debajo.
        // El QR va centrado en el riel. Llevaba 3mm a la derecha para caer
        // sobre el centro óptico del wordmark rotado —que no es el de su
        // caja, porque el ® cuelga a un costado—, pero el corrimiento se
        // leía como un error de alineación contra los bordes del riel, que
        // es con lo que el ojo lo compara. Manda el riel.
        // El marco es el del QR de la contratapa —filete blanco al 16%,
        // tarjeta blanca adentro—, al tamaño del riel: el código de 20.5mm
        // de la contratapa pesaba demasiado en una columna de 55mm.
        #place(top + center, dy: 7.3mm)[
          #chanwe-qr-frame(
            qr,
            size: 11.4mm,
            edge: _t.white.transparentize(84%),
            card: _t.white,
          )
        ]

        // ── Legal rotado, a mitad de camino entre el borde del riel y el
        // wordmark (2026-11-19: iba pegado al borde).
        #place(center + horizon, dx: -14.5mm,
          rotate(-90deg, origin: center + horizon,
            box(width: 175mm)[
              #set align(center)
              #text(
                font: _t.font-mono, size: 6.2pt, weight: _t.weight-regular,
                tracking: 0.24em, fill: _t.fg-subtle, upper(copyright),
              )
            ]
          )
        )

        // ── El wordmark, rotado y grande.
        #place(center + horizon,
          rotate(-90deg, origin: center + horizon,
            image(rail-wordmark, width: 52mm, fit: "contain")
          )
        )

        // ── Pie del riel, con su filete.
        #place(bottom + left, dy: 0mm,
          block(
            width: rail-band-w,
            height: foot-h,
            stroke: (top: 0.5pt + _t.rule-ink),
          )[
            #align(center + horizon, {
              set text(font: _t.font-mono, size: 5.6pt, weight: _t.weight-regular, tracking: 0.16em)
              // En blanco, la regla de la marca para texto sobre tinta (2026-11-19).
              text(fill: _t.white, upper(rail-location-1))
              text(fill: _t.primary, " / ")
              text(fill: _t.white, upper(rail-location-2))
            })
          ])
      ]],
    )
  ]

  // ---- Blank interstitial page (same behavior as chanwe-report)
  set page(
    paper: _chanwe-paper, margin: 0pt, header: none, footer: none,
    fill: _publication-paper, foreground: none,
    background: _chanwe-dot-field(color: _publication-muted, base: 74%, focus-radius: 0),
  )
  set block(spacing: 0pt)
  block(width: 100%, height: _chanwe-page-h)[]
}

// =============================================================
// BACK COVER — retained from chanwe-report, sized to US Letter
// =============================================================
#let _chanwe-blank-interstitial() = {
  set page(paper: _chanwe-paper, margin: 0pt, header: none, footer: none, fill: _publication-paper,
           foreground: none,
           background: _chanwe-dot-field(color: _publication-muted, base: 74%, focus-radius: 0))
  set block(spacing: 0pt)
  block(width: 100%, height: _chanwe-page-h)[]
}

#let chanwe-back-cover-page(
  wordmark-light: none,
  tagline-1: "Less template,",
  tagline-2: "more report.",
  back-cols: (),
  cover-edge: none,
  // Las mismas tres filas que el masthead de la portada.
  caption-1: "",
  caption-2: "",
  caption-3: "",
  // Pie de contratapa.
  series: "CHANWE · RESEARCH & ADVISORY",
  doc-ref: "SERIES-A #0934",
  place-label: "MENDOZA · ARGENTINA",
  qr-art: none,
) = {
  // On obsidian the wordmark is the Papel cut, with the white text (2026-11-19).
  let wl = if wordmark-light != none { _chanwe-clean-path(wordmark-light) } else { _chanwe-assets + "Logo_Papel.svg" }
  let qr = if qr-art != none { _chanwe-clean-path(qr-art) } else { _chanwe-assets + "contact-qr.svg" }

  _chanwe-blank-interstitial()

  set page(
    paper: _chanwe-paper, margin: 0pt, header: none, footer: none, fill: _t.ink,
    // Obsidian with the dot field only (Ale, 2026-11-13). From 3.1 until then
    // the series contour art (`01-radar-macro-dark.svg`) ran off the top right.
    background: _chanwe-dot-field(),
    foreground: if cover-edge != none {
      place(right + top, dx: -3mm, dy: 14mm,
        rotate(-90deg, origin: right + horizon,
          text(font: _t.font-mono, size: 7pt, weight: _t.weight-thin, tracking: 0.5em,
               fill: _t.white.transparentize(25%), upper(cover-edge))
        )
      )
    },
  )
  set block(spacing: 0pt)

  block(
    width: 100%, height: _chanwe-page-h, breakable: false,
    inset: (x: 16mm, top: 14mm, bottom: 14mm),
  )[
    #grid(
      rows: (auto, 1fr, auto),
      row-gutter: 0pt,

      align(left + top, block(width: 100%, spacing: 0pt)[
        // Wordmark a la izquierda y, enfrentadas, las tres filas del
        // masthead de la portada. Mismo estilo, en tono claro sobre tinta.
        #grid(
          columns: (1fr, auto),
          align: (left + bottom, right + bottom),
          if wl != none {
            image(wl, height: 10.1mm, fit: "contain")
          } else {
            text(font: _t.font-display, size: 36pt, weight: _t.weight-display,
                 tracking: -0.05em, fill: _t.white, "chanwe")
          },
          block(spacing: 0pt)[
            // La fila del medio manda: más clara y un punto más grande. Las
            // otras dos se corren atrás, como en la referencia, en `fg-subtle`,
            // el slate de los rótulos del pie (hasta 2026-11-13 `ink-subtle`,
            // un gris neutro que sobre la obsidiana tiraba a marrón).
            #set align(right)
            #set text(font: _t.font-mono, weight: _t.weight-body, tracking: 0.16em)
            #text(size: 5.9pt, fill: _t.fg-subtle, upper(caption-1))
            #v(0.9mm)
            #text(size: 5.9pt, weight: _t.weight-regular, fill: _t.white, upper(caption-2))
            #v(0.9mm)
            #text(size: 5.9pt, fill: _t.fg-subtle, upper(caption-3))
          ],
        )
          #v(11mm)
          // Filete de acento bajo el masthead, del mismo grosor que el
          // eyebrow de la portada.
          #rect(width: 100%, height: 0.4pt, fill: _t.primary, stroke: none)
      ]),

      [],

      block[
        // Bajada a la izquierda y el QR enmarcado a la derecha, apoyados en
        // la misma línea de base.
        #grid(
          columns: (1fr, auto),
          align: (left + bottom, right + bottom),
          block(spacing: 0pt)[
            #set par(leading: 0.8em, justify: false)
            #text(font: _t.font-serif-display, style: "italic", size: 43.4pt,
                  weight: _t.weight-regular, tracking: -0.02em, fill: _t.white, tagline-1)
            #linebreak()
            #text(font: _t.font-serif-display, style: "italic", size: 43.4pt,
                  weight: _t.weight-regular, tracking: -0.02em, fill: _t.primary, tagline-2)
          ],
          // El marco imita la referencia; el código queda oscuro sobre claro,
          // que es lo único que los lectores levantan de forma confiable.
          chanwe-qr-frame(
            qr,
            size: 20.5mm,
            edge: _t.white.transparentize(84%),
            card: _t.white,
            pad-outer: 2.6mm,
            pad-inner: 1mm,
          ),
        )
        #v(11mm)
        // v2: the document's details sit in a frame at the foot: the `rule-ink`
        // hairline only, no fill, so the obsidian and its dot field show through
        // (Ale, 2026-11-13; until then an `ink-light` pane). Labels on ink read
        // `fg-subtle` (6:1); `ink-subtle` was too faint at 6pt.
        #block(
          width: 100%, fill: none, radius: _t.radius-surface,
          stroke: cw-hairline + _t.rule-ink,
          inset: (x: 7mm, top: 6mm, bottom: 6mm),
        )[
          #if back-cols.len() > 0 {
            grid(
              columns: back-cols.map(_ => 1fr),
              column-gutter: 8mm,
              ..back-cols.map(col => {
                let (label, value, sub) = col
                block(spacing: 0pt, width: 100%)[
                  #set par(spacing: 0pt, leading: 0pt)
                  #text(font: _t.font-mono, size: 6pt, weight: _t.weight-regular, tracking: 0.20em,
                        fill: _t.fg-subtle, upper(_chanwe-clean-str(label)))
                  #v(3mm)
                  #text(font: _t.font-mono, size: 6.4pt, weight: _t.weight-regular, tracking: 0.12em,
                        fill: _t.white, upper(_chanwe-clean-str(value)))
                  #if sub != none and sub != "" {
                    v(3mm)
                    text(font: _t.font-mono, size: 6pt, weight: _t.weight-body, tracking: 0.12em,
                         fill: _t.fg-subtle, upper(_chanwe-clean-str(sub)))
                  }
                ]
              })
            )
            v(5mm)
            line(length: 100%, stroke: 0.5pt + _t.rule-ink)
            v(4mm)
          }
          // Pie en tres partes: serie, referencia del documento y plaza.
          #grid(
            columns: (1fr, 1fr, 1fr),
            align: (left + horizon, center + horizon, right + horizon),
            {
              set text(font: _t.font-mono, size: 6pt, weight: _t.weight-body, tracking: 0.12em)
              text(fill: _t.primary, "//")
              h(2.2mm)
              text(fill: _t.fg-subtle, upper(_chanwe-clean-str(series)))
            },
            text(font: _t.font-mono, size: 6pt, weight: _t.weight-body, tracking: 0.08em,
                 fill: _t.fg-subtle, _chanwe-clean-str(doc-ref)),
            text(font: _t.font-mono, size: 6pt, weight: _t.weight-body, tracking: 0.12em,
                 fill: _t.fg-subtle, upper(_chanwe-clean-str(place-label))),
          )
        ]
      ],
    )
  ]
}

// =============================================================
// BACK COVER — full-bleed black page
// =============================================================
// Campo de puntos de contratapa: trama pareja sobre obsidiana y un foco donde
// los mismos puntos se encienden. El foco se dibuja punto por punto — un
// tiling no se puede enmascarar con un degradado.

// =============================================================
// v2 COVERS (2026-11-18) — `chanwe.cover-variant` and
// `chanwe.back-cover-variant`. Today's research cover and back cover stay the
// default; these are the hub's v2 document covers
// (brand/applications/documentos/covers/cover-*-a4) with the document's text
// on them. Every one carries the super subtle dot field.
// =============================================================

// The ledger of the v2 covers: up to three meta rows, label over value.
#let _v2-ledger(rows, label-fill, value-fill, rule) = if rows.len() > 0 {
  let rows = rows.slice(0, calc.min(3, rows.len()))
  block(width: 100%, spacing: 0pt, stroke: (top: 0.5pt + rule), inset: (top: 5mm), grid(
    columns: range(rows.len()).map(_ => 1fr),
    column-gutter: 6mm,
    row-gutter: 2.4mm,
    ..rows.map(((l, ..)) => cw-label(_chanwe-clean-str(l), fill: label-fill, size: 6pt)),
    ..rows.map(((_, val, ..)) => text(font: _t.font-sans, size: 9pt, weight: _t.weight-regular, fill: value-fill, _chanwe-clean-str(val))),
  ))
}

#let _v2-title(title, subtitle, fill, soft, size: 52pt) = {
  set par(leading: 0.16em, justify: false)
  text(font: _t.font-display, size: size, weight: _t.weight-display, tracking: -0.045em, fill: fill, title)
  _chanwe-title-dot(size)
  if subtitle != none {
    v(5mm)
    set par(leading: 0.42em)
    block(width: 85%, text(font: _t.font-serif, style: "italic", size: 19pt, weight: _t.weight-body, fill: soft, subtitle))
  }
}

#let _v2-foot(mark-cut, label, rule, quiet, qr: none) = block(width: 100%, spacing: 0pt,
  stroke: (top: 0.5pt + rule), inset: (top: 6mm), grid(
    columns: (auto, 1fr, auto),
    column-gutter: 6mm,
    align: (left + horizon, right + horizon, right + horizon),
    cw-wordmark(cut: mark-cut, height: 6.6mm),
    cw-label(label, fill: quiet, size: 6.2pt),
    if qr != none { image(qr, width: 17mm) },
  ))

// `paper`: the hub's paper cover. The Aspa large at the top left, the title
// block low, the wordmark at the foot.
#let chanwe-cover-paper(title: none, subtitle: none, eyebrow: none, top-lines: (), meta-rows: (), place-label: "") = page(
  paper: _chanwe-paper, margin: 18mm, header: none, footer: none, numbering: none, fill: _t.paper,
  background: cw-dot-gradient(),
  {
    set block(spacing: 0pt)
    place(top + left, cw-icon("Aspa", fill: _t.primary, width: 46mm))
    place(top + right, align(right, {
      set par(leading: 0.9em)
      for l in top-lines { cw-label(l, size: 6.2pt); linebreak() }
    }))
    place(bottom + left, block(width: 100%, {
      if eyebrow != none { chanwe-eyebrow(eyebrow, size: 7.5pt); v(6mm) }
      _v2-title(title, subtitle, _t.fg, _t.fg-muted)
      v(11mm)
      _v2-ledger(meta-rows, _t.fg-muted, _t.fg, _t.rule)
      v(22mm)
      _v2-foot("Negro", place-label, _t.rule, _t.fg-muted)
    }))
  },
)

// `photo-obsidian`: the hub's photo cover. The photograph on the top half,
// the title on obsidian below it.
#let chanwe-cover-photo-obsidian(title: none, subtitle: none, eyebrow: none, image-path: none, edition: "", meta-rows: ()) = page(
  paper: _chanwe-paper, margin: 0pt, header: none, footer: none, numbering: none, fill: _t.ink,
  background: cw-dot-gradient(),
  {
    set block(spacing: 0pt)
    context {
      let src = if image-path != none { image-path } else { cw-style("assets", "") + "v2/alps-blue-hour.jpg" }
      // The photograph melts into the obsidian (Ale, 2026-11-18: the hard
      // edge read as a cut). A light veil at the top, clear through the
      // middle, then an eased fade that reaches full ink before the box ends,
      // so no edge is left where the photo stops.
      place(top + left, box(width: 100%, height: 62%, clip: true, {
        image(src, width: 100%, height: 100%, fit: "cover")
        place(top + left, rect(width: 100%, height: 100%, stroke: none, fill: gradient.linear(
          (_t.ink.transparentize(70%), 0%),
          (_t.ink.transparentize(100%), 22%),
          (_t.ink.transparentize(100%), 38%),
          (_t.ink.transparentize(82%), 55%),
          (_t.ink.transparentize(50%), 70%),
          (_t.ink.transparentize(18%), 84%),
          (_t.ink, 96%),
          (_t.ink, 100%),
          angle: 90deg)))
      }))
    }
    place(bottom + left, block(width: 100%, inset: (x: 18mm, bottom: 18mm), {
      if eyebrow != none { chanwe-eyebrow(eyebrow, fill: _t.white, size: 7.5pt); v(6mm) }
      _v2-title(title, subtitle, _t.white, _t.white)
      v(10mm)
      _v2-ledger(meta-rows, _t.fg-subtle, _t.white, _t.rule-ink)
      v(18mm)
      _v2-foot("Papel", edition, _t.rule-ink, _t.fg-subtle)
    }))
  },
)

// `series`: today's research layout with v2 parts. The field is the series'
// Fundido icon on slate (no photograph); the rail carries the QR and the
// wordmark, upright, instead of the turned one.
#let chanwe-cover-series(title: none, subtitle: none, series: "", place-label: "", icon: "Onda") = page(
  paper: _chanwe-paper, margin: 10mm, header: none, footer: none, numbering: none, fill: _t.paper,
  background: cw-dot-gradient(),
  {
    set block(spacing: 0pt)
    grid(
      columns: (1fr, 46mm),
      column-gutter: 6mm,
      // the field and the title
      grid(
        rows: (64%, 1fr),
        block(width: 100%, height: 100%, radius: _t.radius-band, clip: true, fill: _t.surface-slate, {
          place(top + left, cw-dot-gradient())
          place(top + right, dx: 58mm, dy: 26mm, cw-icon(icon, fill: _t.ink, width: 200mm))
        }),
        block(width: 100%, height: 100%, inset: (x: 4mm, bottom: 2mm), align(bottom + left, {
          _v2-title(title, subtitle, _t.fg, _t.fg-muted, size: 40pt)
          v(7mm)
          box(fill: _t.primary, radius: _t.radius-pill, inset: (x: 3mm, y: 1.8mm),
            text(font: _t.font-mono, size: 6.4pt, weight: _t.weight-medium, tracking: 0.14em, fill: _t.white, "// " + upper(series)))
        })),
      ),
      // the rail
      block(width: 100%, height: 100%, radius: _t.radius-band, clip: true, fill: _t.ink, inset: (x: 7mm, y: 8mm), {
        place(top + left, dx: -7mm, dy: -8mm, block(width: 46mm, height: 297mm, cw-dot-gradient(from: (1.0, 0.0))))
        grid(
          rows: (auto, 1fr, auto, auto),
          row-gutter: 6mm,
          context image(cw-style("assets", "") + "v2/contact-qr-papel.svg", width: 100%),
          [],
          align(center, cw-wordmark(cut: "Papel", width: 28mm)),
          align(center, cw-label(place-label, fill: _t.fg-subtle, size: 5.6pt)),
        )
      }),
    )
  },
)

// ---- back covers -------------------------------------------------------
#let _v2-contact(cols, place-label) = {
  let cols = if cols.len() > 0 { cols.slice(0, calc.min(2, cols.len())).map(((lab, val, ..)) => (lab, val)) }
    else { (("Contacto", "hola@chanwe.ar"), ("Sede", place-label)) }
  cols
}
#let _v2-tagline(t1, t2, display: false, fill: _t.white, accent: _t.primary) = {
  set par(leading: 0.2em)
  if display {
    text(font: _t.font-display, size: 34pt, weight: _t.weight-display, tracking: -0.04em, fill: fill, t1)
    linebreak()
    text(font: _t.font-display, size: 34pt, weight: _t.weight-display, tracking: -0.04em, fill: accent, t2)
  } else {
    text(font: _t.font-serif, style: "italic", size: 38pt, weight: _t.weight-body, tracking: -0.02em, fill: fill, t1)
    linebreak()
    text(font: _t.font-serif, style: "italic", size: 38pt, weight: _t.weight-body, tracking: -0.02em, fill: accent, t2)
  }
}
#let _v2-frame(cols, qr, stroke, label-fill, value-fill) = block(width: 100%, radius: _t.radius-pane,
  stroke: 0.6pt + stroke, inset: 6mm, grid(
    columns: (1fr, 1fr, auto),
    column-gutter: 6mm,
    align: (left + bottom, left + bottom, right + bottom),
    ..cols.map(((lab, val)) => block({
      cw-label(_chanwe-clean-str(lab), fill: label-fill, size: 5.8pt)
      v(2mm)
      text(font: _t.font-sans, size: 9pt, fill: value-fill, _chanwe-clean-str(val))
    })),
    ..range(2 - cols.len()).map(_ => []),
    box(stroke: 0.8pt + _t.white, radius: 1.6mm, clip: true, image(qr, width: 24mm)),
  ))

// `aspa`: obsidian; the Aspa in `ink-light` bleeds off the corner, as the
// series art does; the wordmark top left; the tagline and the contact frame.
#let chanwe-back-cover-aspa(tagline-1: "", tagline-2: "", back-cols: (), place-label: "") = page(
  paper: _chanwe-paper, margin: 18mm, header: none, footer: none, numbering: none, fill: _t.ink,
  background: {
    place(top + left, cw-dot-gradient())
    place(bottom + right, dx: 50mm, dy: 42mm, cw-icon("Aspa", fill: _t.ink-light, width: 196mm))
  },
  context {
    set block(spacing: 0pt)
    let a = cw-style("assets", "")
    place(top + left, cw-wordmark(cut: "Papel", height: 7.4mm))
    place(bottom + left, block(width: 100%, {
      _v2-tagline(tagline-1, tagline-2)
      v(16mm)
      _v2-frame(_v2-contact(back-cols, place-label), a + "v2/contact-qr-papel.svg", _t.rule-ink, _t.fg-subtle, _t.white)
    }))
  },
)

// `orange`: the brand orange as the ground of an identity piece (orange may
// be the background of identity tiles, CLAUDE.md): the Papel wordmark, tagline and
// frame, the orange contact code.
#let chanwe-back-cover-orange(tagline-1: "", tagline-2: "", back-cols: (), place-label: "") = page(
  paper: _chanwe-paper, margin: 18mm, header: none, footer: none, numbering: none, fill: _t.primary,
  background: cw-dot-gradient(color: _t.white),
  context {
    set block(spacing: 0pt)
    let a = cw-style("assets", "")
    place(top + left, cw-wordmark(cut: "Papel", height: 7.4mm))
    place(bottom + left, block(width: 100%, {
      _v2-tagline(tagline-1, tagline-2, display: true, fill: _t.white, accent: _t.white)
      v(16mm)
      _v2-frame(_v2-contact(back-cols, place-label), a + "v2/contact-qr-naranja.svg",
        _t.white.transparentize(45%), _t.white.transparentize(20%), _t.white)
    }))
  },
)

// `mark`: the mirror of the hub's obsidian cover. The orange Aspa top left;
// at the foot the wordmark, the address and a small code. No tagline.
#let chanwe-back-cover-mark(place-label: "") = page(
  paper: _chanwe-paper, margin: 18mm, header: none, footer: none, numbering: none, fill: _t.ink,
  background: cw-dot-gradient(),
  context {
    set block(spacing: 0pt)
    let a = cw-style("assets", "")
    place(top + left, cw-icon("Aspa", fill: _t.primary, width: 46mm))
    place(bottom + left, _v2-foot("Papel", "chanwe.ar  ·  " + place-label, _t.rule-ink, _t.fg-subtle,
      qr: a + "v2/contact-qr-obsidiana.svg"))
  },
)// =============================================================
// chanwe-elements.typ — callouts, pull quotes, great quote pages
// Available to authors as #callout, #pullquote, #great-quote
// =============================================================

// La ficha de rótulo: marco slate, fondo transparente, mono en versalita. La
// llevan el tema del hallazgo y la procedencia del KPI, así que vive en un solo
// lugar —son el mismo objeto y no tienen por qué separarse con el tiempo—.
// `tone` pinta marco y texto del mismo color, para las superficies donde el
// slate del marco y el fg-muted del texto no se leen: border-cool sobre
// obsidiana, blanco sobre naranja.
#let _chip-label(body, tone: none, size: 5.2pt, inset: (x: 1.8mm, y: 1.2mm)) = box(
  stroke: 0.3pt + (if tone != none { tone } else { _t.border-cool }),
  // v2: every chip is a pill.
  radius: _t.radius-pill,
  inset: inset,
  text(font: _t.font-mono, size: size, weight: _t.weight-medium, tracking: 0.1em,
       fill: if tone != none { tone } else { _t.fg-muted }, upper(body)),
)

// Stubs for Quarto's font-awesome callout icon calls
#let fa-info() = []
#let fa-lightbulb() = []
#let fa-exclamation() = []
#let fa-exclamation-triangle() = []
#let fa-fire() = []

// Accepts both our API (#callout(kind: "note")[body]) and
// Quarto's generated API (#callout(body: [...], icon: fa-info(), ...))
#let callout(
  kind: "note",
  eyebrow: none,
  title: none,
  body: none,
  background_color: none,
  icon_color: none,
  icon: none,
  body_background_color: none,
  ..args,
) = {
  let content = if body != none { body } else if args.pos().len() > 0 { args.pos().first() } else { [] }

  // Derive accent color + type label from icon_color (Quarto native) or kind (our API)
  let (accent, auto-label) = if icon_color != none {
    let lbl = if icon_color == _t.callout-note      { "NOTE" }
         else if icon_color == _t.callout-tip       { "TIP" }
         else if icon_color == _t.callout-warning       { "WARNING" }
         else if icon_color == _t.callout-important       { "IMPORTANT" }
         else if icon_color == _t.callout-caution       { "CAUTION" }
         else                                       { "NOTE" }
    (icon_color, lbl)
  } else if kind == "warn" or kind == "warning" {
    (_t.callout-warning, "WARNING")
  } else if kind == "tip" {
    (_t.callout-tip, "TIP")
  } else if kind == "caution" {
    (_t.callout-caution, "CAUTION")
  } else if kind == "important" {
    (_t.callout-important, "IMPORTANT")
  } else if kind == "note" {
    (_t.callout-note, "NOTE")
  } else if kind == "do" {
    (_t.callout-do, "DO")
  } else if kind == "dont" {
    (_t.callout-dont, "DON'T")
  } else {
    (_t.primary, upper(kind))
  }

  let type-label = if eyebrow != none { upper(eyebrow) } else { auto-label }
  let display-title = if title != none { title } else { type-label }

  // v2-print (brand-v2 §7): the callout is a pane — white on paper, the
  // 1px hairline, 16px corners, no shadow. Its first line is the kind: a dot
  // in its role colour and the mono label; then the title, then the body. No
  // tinted title row (the last 1.x trace, dropped 2026-11-18), no side bar.
  // The title row shows only a real title: Quarto's native callouts send
  // their default title ("Note", "Tip"...), which the label already says.
  let _plain(x) = if type(x) == str { x } else if type(x) == content and x.has("text") { x.text } else { none }
  let pt = if title != none { _plain(title) } else { none }
  let show-title = title != none and (pt == none or (lower(pt) != lower(auto-label) and pt != type-label))
  // Radius `pane` 12px on paper and screen alike (unified with the kit, 2026-11-18).
  cw-pane(
    fill: _t.pane,
    radius: _t.radius-pane,
    inset: (x: _t.space-lg, y: _t.space-md),
    above: 10mm,
    below: 10mm,
    breakable: false,
  )[
    #set block(spacing: 0pt)
    #grid(
      columns: (auto, 1fr),
      column-gutter: _t.space-xs,
      align: left + horizon,
      cw-dot(accent, size: 5.5pt, baseline: 0pt),
      cw-label(type-label, fill: _t.fg-muted, size: 7pt, tracking: 0.14em),
    )
    #if show-title {
      v(2.4mm)
      text(font: _t.font-display, size: 11pt, weight: _t.weight-display, tracking: -0.02em, fill: _t.fg, title)
    }
    #v(2mm)
    #block[
      #set block(spacing: 0.85em)
      #set text(fill: _t.fg-muted, size: 9.5pt)
      #content
    ]
  ]
}

// La cita corta desde Typst crudo es la misma cita en bloque de markdown
// (`> …`): se emite como `quote` y la viste la regla `show quote` del
// formato —panel slate, canto naranja, Cormorant en cursiva y la atribución
// debajo—, así las dos salen idénticas. Antes tenía su propio panel sin
// fondo y la atribución en mono.
#let pullquote(body, attribution: none) = quote(
  block: true, attribution: attribution, body,
)

// v2-print: an insert floats inside the text block. Until 3.0.2 the quote,
// figure, summary and zone inserts bled to both paper edges with square
// corners, while the chapter band of the same page floated with 24px ones;
// now they are the same family (brand-v2 §2: "bands float with a margin,
// never edge to edge"). Obsidian is the band itself (dot field, sheen);
// slate and orange take its corners; white is a pane with the hairline.
// `gap` is the air above and below: two inserts in a row no longer touch
// (edge to edge they read as one striped band; floating, as a collision).
// An insert never splits across two pages (it did not when it was a `move`).
// Orange is a signal, not a fill (decided 2026-11-18): `primary` is the
// obsidian band with one orange Aspa in its top right corner, where the
// insert's padding leaves room for it.
#let _cw-signal-mark(inset) = {
  let _get(k, d) = if type(inset) == dictionary { inset.at(k, default: d) } else { inset }
  let r = _get("right", _get("x", 12mm))
  let t = _get("top", _get("y", 12mm))
  place(top + right, dx: r - 4mm, dy: if t > 6mm { -t + 4mm } else { 4mm },
    cw-icon("Aspa", fill: _t.primary, width: 7mm))
}
#let _cw-insert(color, bg, inset, gap: 8mm, body) = if color == "dark" or color == "primary" {
  cw-band(inset: inset, above: gap, below: gap, breakable: false, {
    if color == "primary" { _cw-signal-mark(inset) }
    body
  })
} else {
  block(
    width: 100%, fill: bg, radius: _t.radius-band, inset: inset, above: gap, below: gap,
    breakable: false, clip: true,
    stroke: if bg == _t.white { cw-hairline + _t.rule } else { none },
    body,
  )
}

// `light` va sobre surface-slate (#EBF0F6), el mismo slate del abstract y
// de los paneles de código; `slate` vale igual.
#let _gq-scheme(color, inset: false) = if color == "light" or color == "slate" {
  (
    bg:     _t.surface-slate,
    eyebrow: _t.primary,
    quote:  _t.fg,
    emph:   _t.primary,
    attr:   _t.fg,
    source: _t.fg-muted,
    line:   _t.primary,
    rule:   _t.rule-cool,
    art:    _t.pane,
    label:  _t.fg-muted,
  )
} else if color == "white" {
  (
    bg:     _t.white,
    eyebrow: _t.primary,
    quote:  _t.fg,
    emph:   _t.primary,
    attr:   _t.fg,
    source: _t.fg-muted,
    line:   _t.primary,
    rule:   _t.rule,
    art:    _t.surface-slate,
    label:  _t.fg-muted,
  )
} else {
  // `dark`, and `primary`, which is the same band with the orange as a signal.
  (
    bg:     _t.ink,
    eyebrow: _t.primary,
    // Texto sobre obsidiana en blanco (Ale, 2026-11-19).
    quote:  _t.white,
    emph:   _t.primary,
    attr:   _t.white,
    source: _t.fg-subtle,
    line:   _t.primary,
    rule:   _t.rule-ink,
    art:    _t.ink-light,
    label:  _t.white,
  )
}

// The quote's text in one of the three styles (`quote-style`, or the Div's
// `style`): `serif` (Cormorant italic, the default), `display` (Schibsted 600,
// as the v2 band sets display type) and `serif-art` (the serif, with a
// Fundido icon bleeding off the corner).
#let _gq-text(style, size, fill, body) = if style == "display" {
  text(font: _t.font-display, size: size * 0.86, weight: _t.weight-display, tracking: -0.035em,
       fill: fill)[\u{201C}#body\u{201D}]
} else {
  text(font: _t.font-serif, size: size, style: "italic", weight: _t.weight-body,
       tracking: -0.025em, fill: fill)[\u{201C}#body\u{201D}]
}

// The signature, the v2 way (2026-11-18): a hairline across the measure, then
// a dot and the name, and the source as a mono label under it. No pill, no
// short orange rule: the dot is the one orange.
#let _gq-attribution(caption, source, s, big: false) = {
  set block(spacing: 0pt)
  set par(spacing: 0pt)
  line(length: 100%, stroke: 0.5pt + s.rule)
  if caption != none or source != none {
    v(if big { 6mm } else { 4mm })
    let dot = if big { 6pt } else { 4.6pt }
    let gap = if big { 3mm } else { 2.2mm }
    grid(
      columns: (auto, 1fr),
      column-gutter: gap,
      row-gutter: if big { 3mm } else { 2mm },
      align: (left + horizon, left + horizon),
      cw-dot(_t.primary, size: dot, baseline: 0pt),
      if caption != none {
        text(font: _t.font-sans, size: if big { 15pt } else { 9.6pt }, weight: _t.weight-medium,
             tracking: -0.01em, fill: s.attr, caption)
      } else { cw-label(source, fill: s.source, size: if big { 7pt } else { 6pt }) },
      [],
      if caption != none and source != none { cw-label(source, fill: s.source, size: if big { 7pt } else { 6pt }) },
    )
  }
}

#let page-great-quote(caption: none, source: none, color: "dark", eyebrow: "Verbatim", style: auto, body) = context {
  let style = if style == auto { cw-style("quote-style", "serif") } else { style }
  let s = _gq-scheme(color)
  set page(paper: _chanwe-paper, margin: 0pt, header: none, footer: none, fill: s.bg)
  block(width: 100%, height: 100%, fill: s.bg, clip: true)[
    #if style == "serif-art" {
      place(bottom + right, dx: 46mm, dy: 40mm, cw-icon("Onda", fill: s.art, width: 190mm))
    }
    #if color == "primary" {
      place(top + right, dx: -22mm, dy: 22mm, cw-icon("Aspa", fill: _t.primary, width: 14mm))
    }
    #if color == "dark" or color == "primary" { place(top + left, cw-dot-gradient()) }
    #block(width: 100%, height: 100%, inset: (x: 22mm, top: 40mm, bottom: 30mm))[
      #show emph: it => text(fill: s.emph, style: "italic", it.body)
      #chanwe-eyebrow(eyebrow, fill: s.label, size: 12pt)
      // Misma estructura que el inserto —5mm y la cita dentro de un bloque— para
      // que el aire entre rótulo y cita sea el mismo.
      #v(5mm)
      #set par(leading: 0.32em)
      // The quote takes the page: the largest of these sizes that keeps it
      // within 150mm of height, so a short line is set at 64pt and a long
      // paragraph falls back to 32.2pt.
      #layout(size => {
        let q(sz) = block(width: 100%, _gq-text(style, sz, s.quote, body))
        let fit = (64pt, 56pt, 48pt, 40pt).find(sz => measure(q(sz), width: size.width).height <= 150mm)
        q(if fit == none { 32.2pt } else { fit })
      })
      #v(1fr)
      #_gq-attribution(caption, source, s, big: true)
    ]
  ]
}

#let inset-great-quote(caption: none, source: none, color: "dark", eyebrow: "Verbatim", style: auto, body) = context {
  let style = if style == auto { cw-style("quote-style", "serif") } else { style }
  let s = _gq-scheme(color, inset: true)
  _cw-insert(color, s.bg, (x: 12mm, top: 12mm, bottom: 12mm))[
      #if style == "serif-art" {
        place(bottom + right, dx: 12mm + 22mm, dy: 12mm + 24mm, cw-icon("Onda", fill: s.art, width: 92mm))
      }
      #show emph: it => text(fill: s.emph, style: "italic", it.body)
      #set par(leading: 0.32em)
      #chanwe-eyebrow(eyebrow, fill: s.label)
      #v(5mm)
      // La cita no usa los 166mm del bloque: a 122mm rompe en dos renglones
      // parejos y deja aire a la derecha, que es lo que la separa de un párrafo.
      #block(width: 122mm, _gq-text(style, 28pt, s.quote, body))
      #v(14mm)
      #_gq-attribution(caption, source, s)
    ]
}

#let inset-great-figure(
  eyebrow: none,
  title: "",
  source: none,
  source-label: none,
  layout: "center",
  position: "right",
  color: "dark",
  caption: [],
  body,
) = {
  let s = _gq-scheme(color, inset: true)
  let on-dark = color == "dark" or color == "primary"
  let col-widths = if layout == "left" {
    (3fr, 7fr)
  } else if layout == "right" {
    (7fr, 3fr)
  } else {
    (1fr, 1fr)
  }

  let text-col = block(width: 100%)[
    #if eyebrow != none {
      block(below: 8mm)[
        // Un 20% por debajo del rótulo estándar (8.5pt): acompaña al titular
        // de 14pt en vez de competir con él.
        #chanwe-eyebrow(eyebrow, fill: s.label, size: 6.8pt)
      ]
    }
    #if title != "" {
      block(below: 5mm, above: if eyebrow != none { 8mm } else { 0mm })[
        #set par(leading: 0.64em)
        #text(font: _t.font-display, size: 14pt, weight: _t.weight-display,
              tracking: -0.05em, fill: s.quote, title)
      ]
    }
    #set text(font: _t.font-sans, size: 7.5pt, fill: s.source)
    #caption
  ]

  // El pie de la figura repite el de una imagen del cuerpo: filete arriba, mono
  // chico en versalita y contra el margen izquierdo. Sobre obsidiana el filete
  // pasa a `rule-ink`, que es el que se dibuja sobre oscuro.
  let plot-col = block(width: 100%)[
    // Adentro del inserto la imagen no trae su propio marco: el pie del bloque
    // ya es el pie de la figura. Sin esto arrastraba los filetes, el rótulo y
    // los 26mm de aire del `show figure` del cuerpo —sobre obsidiana, tinta
    // sobre tinta: un rótulo invisible—, y el pie quedaba flotando lejos de la
    // imagen.
    #show figure.where(kind: image): it => it.body
    // Sin aire de bloque ni de párrafo adentro de la columna: el espaciado de
    // párrafo del cuerpo (2.6em) se sumaba debajo de la imagen y a cada `v`,
    // y el filete quedaba flotando a un centímetro del sello. Así la imagen
    // arranca arriba con el eyebrow y el pie va pegado, como en el marco.
    // El cuerpo además fija `show figure: set block(above: 11mm, below: 12mm)`
    // para las figuras corrientes, y esa regla sigue viva adentro de la
    // figura aunque aquí se dibuje sólo su cuerpo: hay que apagarla aparte.
    #show figure: set block(above: 0pt, below: 0pt)
    #set block(spacing: 0pt)
    #set par(spacing: 0pt)
    #body
    // El pie es el del marco de figura: filete slate, sello naranja a la
    // izquierda y la glosa contra el margen derecho. Sobre obsidiana el filete
    // pasa a `rule-ink`, que es el que se dibuja sobre oscuro.
    #if source != none or source-label != none {
      // The foot of a figure: quiet mono over a hairline, in the tone of the surface.
      let foot-tone = if on-dark { s.source } else { _t.fg-muted }
      v(2.6mm)
      line(length: 100%, stroke: 0.5pt
        + (if on-dark { _t.rule-ink } else { _t.rule }))
      v(1.8mm)
      grid(
        columns: (auto, 1fr),
        column-gutter: 7mm,
        align: (left + top, right + top),
        if source-label != none {
          cw-label(source-label, size: 5.6pt, weight: _t.weight-regular, fill: foot-tone)
        } else { [] },
        if source != none {
          text(font: _t.font-sans, size: 7.2pt, weight: _t.weight-body-plus, fill: foot-tone, source)
        } else { [] },
      )
    }
  ]

  let (first-col, second-col) = if position == "left" {
    (plot-col, text-col)
  } else {
    (text-col, plot-col)
  }

  _cw-insert(color, s.bg, (x: 12mm, y: 14mm))[
      #show emph: it => text(fill: s.emph, style: "italic", it.body)
      #grid(
        columns: col-widths,
        column-gutter: 12mm,
        align: (left + top, left + top),
        first-col,
        second-col,
      )
    ]
}

#let inset-great-summary(
  eyebrow: "Executive Summary",
  title: "",
  color: "white",
  body,
) = {
  // Cuatro variantes: white (hoja), light (panel editorial), dark (obsidiana,
  // texto en blanco) y primary (la banda de obsidiana con el naranja como
  // señal: el Aspa en la esquina, 2026-11-18).
  let s = if color == "dark" or color == "primary" {
    (bg: _t.ink, eyebrow: _t.primary, title: _t.white, rule: _t.primary, body: _t.white)
  } else if color == "light" or color == "slate" {
    (bg: _t.surface-slate, eyebrow: _t.primary, title: _t.ink, rule: _t.primary, body: _t.body-fg)
  } else {
    (bg: _t.white, eyebrow: _t.primary, title: _t.ink, rule: _t.primary, body: _t.body-fg)
  }
  let borders = not ("white", "light", "slate", "dark", "primary").contains(color)
  _cw-insert(color, s.bg, (x: 12mm, top: 0pt, bottom: 0pt))[
      #if borders { line(length: 100%, stroke: 0.5pt + _t.ink) }
      #block(width: 100%, inset: (top: 12mm, bottom: 14mm))[
        #grid(
          columns: (4fr, 6fr),
          column-gutter: 14mm,
          align: (left + top, left + top),
          text(
            font: _t.font-mono, size: 8.5pt, weight: _t.weight-medium,
            tracking: -0.05em, fill: s.eyebrow,
            "// " + upper(eyebrow),
          ),
          block(width: 100%)[
            #if title != "" {
              block(below: 7mm)[
                #set par(leading: 0.72em)
                #text(font: _t.font-display, tracking: -0.05em, size: 14pt, weight: _t.weight-display, fill: s.title, title)
              ]
              line(length: 18mm, stroke: 1pt + s.rule)
              v(4mm)
            }
            // Cuerpo en el slate de la prosa, no en el negro del titular.
            #set text(size: 10pt, fill: s.body)
            #set par(leading: 0.75em)
            #body
          ],
        )
      ]
      #if borders { line(length: 100%, stroke: 0.5pt + _t.ink) }
    ]
}

// El hallazgo se reparte en cuatro franjas: el numeral suelto contra el margen,
// un filete naranja que abre la columna de texto, la glosa a medida corta, y el
// tema al otro extremo.
//
// Las columnas van en porcentaje del ancho disponible, no en milímetros: el
// reparto tiene que sobrevivir a que el bloque se dibuje dentro de un panel con
// sangría, y a que la fila con tema y la fila sin tema queden alineadas entre
// sí —con una columna `auto` a la derecha, un ítem sin tema ensancharía su
// texto y las dos filas dejarían de coincidir—.
#let _gf-columns = (8%, 60%, 1fr)
#let _gf-gutter  = (4%, 6%)
// Aire arriba y abajo de cada fila. Es la mitad de la separación entre filas,
// así que la divisoria queda centrada entre las dos.
#let _gf-pad-y   = 5mm

// La paleta de la lista por variante: `white` es la hoja con filetes, `light`
// el panel editorial y `dark` obsidiana con el texto en blanco. `primary`
// es obsidiana también: el naranja queda como señal (el numeral), no de fondo
// (2026-11-18).
#let _gf-scheme(color) = if color == "dark" or color == "primary" {
  (bg: _t.ink, numeral: _t.primary, title: _t.white, body: _t.white,
   accent: _t.primary, rule: _t.rule-ink, label: _t.white.transparentize(35%), chip: _t.white)
} else if color == "light" or color == "slate" {
  (bg: _t.surface-slate, numeral: _t.primary, title: _t.ink, body: _t.fg-muted,
   accent: _t.primary, rule: _t.rule, label: _t.fg-muted, chip: none)
} else {
  (bg: none, numeral: _t.primary, title: _t.ink, body: _t.fg-muted,
   accent: _t.primary, rule: _t.rule, label: _t.fg-muted, chip: none)
}

// `height` fija el alto de la fila: la celda del texto —y con ella el filete
// naranja, que es su borde izquierdo— se estira hasta ahí. `auto` mide sola.
#let _great-findings-row(number: "01", title: "", topic: "", topic-label: "Tema", height: auto, scheme: _gf-scheme("white"), numeral: auto, body) = context {
  // The numeral (2026-11-18): Schibsted 600, tabular. `orange` (the default)
  // or `slate`; the Div's `numeral` or the document's `findings-numeral`.
  let numeral = if numeral == auto { cw-style("findings-numeral", "orange") } else { numeral }
  let num-fill = if numeral == "slate" { if scheme.bg == _t.ink { _t.fg-subtle } else { _t.fg-muted } } else { scheme.numeral }
  let s = scheme
  grid(
    columns: _gf-columns,
    rows: (height,),
    column-gutter: _gf-gutter,
    align: (left + top, left + top, right + top),

    // Instrument Serif trae un solo corte, 400: pedirle 300 se renderiza igual
    // pero miente sobre lo que pasa. El numeral no se alinea al título sino que
    // cuelga —con las dos celdas al borde de arriba, su propio cuerpo lo deja
    // caer casi hasta la base que pide el reparto—. El inset de arriba es lo
    // que falta: medido, no elegido, y hay que volver a medirlo si cambia el
    // cuerpo del numeral o el del título.
    grid.cell(inset: (top: 0.2mm), text(
      font: _t.font-display, size: 22pt, weight: _t.weight-display, tracking: -0.03em,
      number-type: "lining", number-width: "tabular", fill: num-fill, number,
    )),

    // v2 (Ale, 2026-10-30, opción C): sin filete lateral; el hallazgo es un panel
    // y el numeral naranja es la única señal.
    grid.cell(inset: (left: 0mm))[
      #block(below: 3.4mm)[
        #set par(leading: 0.45em)
        #text(font: _t.font-display, tracking: -0.05em, size: 10.8pt, weight: _t.weight-display, fill: s.title, title)
      ]
      // El interlineado se mide contra el renglón real, no contra el cuerpo: el
      // documento recorta el alto de línea a la altura de mayúscula, así que
      // `leading` arranca desde 0.72em y no desde 1.2em como haría el ajuste
      // por defecto. 0.95em deja los dos renglones a 1.67 cuerpos de distancia.
      #set text(size: 8pt, fill: s.body)
      #set par(leading: 0.95em)
      #body
    ],

    // El tema arriba a la derecha, alineado con el título: la etiqueta mono y
    // debajo, pegada, la pill.
    if topic != "" {
      align(right + top, stack(dir: ttb, spacing: 1.4mm,
        align(right, text(font: _t.font-mono, size: 5.2pt, weight: _t.weight-regular, tracking: 0.18em,
              fill: s.label, upper(topic-label))),
        align(right, _chip-label(topic, tone: s.chip)),
      ))
    } else { [] },
  )
}

// El marco de la lista: los filetes de cierre son los mismos que la divisoria
// entre ítems —mismo grosor, mismo tono—, así que la lista se lee como un
// pentagrama parejo y no como una banda con bordes pesados. `color` mantiene
// las variantes en panel para los documentos que ya las usan.
#let _gf-panes(color) = color in ("white", "light", "slate")
#let _gf-frame(color, body) = {
  let s = _gf-scheme(color)
  if _gf-panes(color) {
    block(width: 100%, fill: _t.surface-slate, radius: _t.radius-surface, inset: 4mm,
      above: 10mm, below: 10mm)[#body]
  } else if s.bg == none {
    block(width: 100%, inset: 0pt, above: 10mm, below: 10mm,
      stroke: (top: 0.3pt + s.rule, bottom: 0.3pt + s.rule))[#body]
  } else {
    block(width: 100%, fill: s.bg, radius: _t.radius-surface, inset: (x: 6mm),
      above: 10mm, below: 10mm)[#body]
  }
}

#let great-findings(number: "01", title: "", topic: "", topic-label: "Tema", color: "white", numeral: auto, body) = {
  let row = _great-findings-row(number: number, title: title, topic: topic, topic-label: topic-label, scheme: _gf-scheme(color), numeral: numeral, body)
  _gf-frame(color, if _gf-panes(color) {
    cw-pane(inset: (x: 6mm, y: _gf-pad-y), spacing: 0pt, row)
  } else {
    block(width: 100%, inset: (y: _gf-pad-y), spacing: 0pt, row)
  })
}

// item used inside a great-findings-grid (the frame is the wrapper's job)
#let great-findings-item(number: "01", title: "", topic: "", topic-label: "Tema", height: auto, scheme: _gf-scheme("white"), numeral: auto, body) = {
  block(width: 100%, inset: (y: _gf-pad-y), spacing: 0pt)[
    #_great-findings-row(number: number, title: title, topic: topic, topic-label: topic-label, height: height, scheme: scheme, numeral: numeral, body)
  ]
}

// La divisoria entre ítems. Va envuelta en un bloque sin espaciado porque una
// `line` suelta cobra el espaciado de bloque del cuerpo a cada lado, y eso era
// lo que abría el hueco muerto entre un hallazgo y el siguiente.
#let _gf-rule(s) = block(spacing: 0pt, line(length: 100%, stroke: 0.3pt + s.rule))

// wrapper that frames the list and separates items with a hairline
// La lista recibe los ítems como lista de contenidos, no como un cuerpo
// suelto, para poder medirlos: todas las filas miden lo mismo —la más alta
// manda—, así una lista de tres hallazgos no cambia de ritmo porque uno lleve
// dos renglones más. `row-height` pone un piso en milímetros por si hace
// falta emparejar dos listas distintas.
#let great-findings-grid(color: "white", row-height: none, numeral: auto, items) = {
  // Un ítem es un diccionario (number, title, topic, topic-label, body): así
  // se puede dibujar dos veces, una para medirlo y otra a la altura pareja,
  // y el filete naranja acompaña esa altura.
  let s = _gf-scheme(color)
  let render(it, h) = great-findings-item(
    number: it.at("number", default: "01"), title: it.at("title", default: ""),
    topic: it.at("topic", default: ""), topic-label: it.at("topic-label", default: "Tema"),
    height: h, scheme: s, numeral: numeral, it.at("body", default: []),
  )
  _gf-frame(color, layout(size => {
    let floor = if row-height != none { row-height } else { 0pt }
    let w = if _gf-panes(color) { size.width - 12mm } else { size.width }
    let h = calc.max(floor, ..items.map(it => measure(block(width: w, render(it, auto))).height))
    // La fila mide el bloque menos el aire de arriba y abajo.
    let row-h = h - 2 * _gf-pad-y
    for (i, it) in items.enumerate() {
      if _gf-panes(color) {
        if i > 0 { v(3mm) }
        cw-pane(inset: (x: 6mm, y: 0mm), spacing: 0pt, render(it, row-h))
      } else {
        if i > 0 { _gf-rule(s) }
        render(it, row-h)
      }
    }
  }))
}

// =============================================================
// KPI cards
// =============================================================

// "green"/"red" resolve to the canonical signed tokens so KPI cards, chart
// arrows, and table deltas share one positive/negative pair. Raw "#RRGGBB"
// strings pass through for self-describing swatches.
#let _kpi-color(name) = {
  if name == "primary" { _t.primary }
  else if name == "green" { _t.kpi-green }
  else if name == "red" { _t.kpi-red }
  else if name == "ink" { _t.ink }
  else if type(name) == str and name.starts-with("#") { rgb(name) }
  else { _t.fg-muted }
}

// El alto de la celda, su aire vertical y la canaleta entre columnas viven en
// constantes porque `kpi-grid` necesita las tres para dibujar las divisorias a
// la altura exacta de la banda: la ficha no las puede medir sola.
#let _kpi-card-h = 44mm
#let _kpi-pad-y  = 6.5mm
// Alto fijo de la fila ficha+glosa: entran dos renglones de glosa y la ficha
// queda centrada contra ellos sin moverse de columna a columna.
#let _kpi-chip-row-h = 7mm

// La sparkline del KPI. Recibe los valores en crudo y los normaliza sola, asi
// que la serie se escribe con los numeros del dato y no con fracciones.
//
// Solo la curva, la base y el punto del final: la trama de rayas verticales
// que llenaba el area bajo la curva se fue —ensuciaba mas de lo que decia.
#let _kpi-spark(values, height: 12mm) = {
  if values.len() < 2 { return }
  let lo = calc.min(..values)
  let hi = calc.max(..values)
  let mid = (hi + lo) / 2
  // Normalizar contra el rango propio de la serie convierte cualquier ruido en
  // una montaña rusa: reservas que se mueven 0,4 sobre 28 dibujarian el mismo
  // relieve que una inflacion que cae 2,7 sobre 4,8. El rango se ensancha
  // hasta un 15% del nivel, asi que una serie que casi no se mueve se dibuja
  // casi plana y el grafico dice lo que dice el dato.
  let floor-span = calc.abs(mid) * 0.15
  let raw-span = hi - lo
  let span = calc.max(raw-span, floor-span)
  // El 0.14/0.72 deja aire arriba y abajo: la curva no toca los bordes.
  let norm = values.map(v =>
    if span == 0 { 0.5 } else { 0.5 + 0.72 * (v - mid) / span })

  layout(size => {
    let n = values.len()
    // El area de dibujo se achica el radio del punto final, que si no queda
    // medio afuera de la celda.
    let pw = size.width - 3pt
    let step = pw / (n - 1)
    let y = i => height * (1 - norm.at(i))

    block(width: 100%, height: height, {
      // La curva.
      for i in range(n - 1) {
        place(top + left, dx: step * i, dy: y(i),
          line(end: (step, y(i + 1) - y(i)), stroke: 0.6pt + _t.ink))
      }
      place(bottom + left, line(length: 100%, stroke: 0.3pt + _t.border))
      // El punto del ultimo dato, con halo. `circle` mide 2r, asi que se corre
      // el radio para que el centro caiga sobre el dato.
      place(top + left, dx: step * (n - 1) - 2.6pt, dy: y(n - 1) - 2.6pt,
        circle(radius: 2.6pt, fill: _t.primary.transparentize(78%), stroke: none))
      place(top + left, dx: step * (n - 1) - 1.3pt, dy: y(n - 1) - 1.3pt,
        circle(radius: 1.3pt, fill: _t.primary, stroke: none))
    })
  })
}

#let kpi-card(
  title: "",
  main: "",
  prefix: "",
  unit: "",
  unit-note: "",
  source: "",
  main-color: "ink",
  secondary: "",
  secondary-color: "muted",
  direction: "none",
  delta: "",
  series: (),
  from-label: "",
  state-label: "",
  to-label: "",
) = {
  let mc = if main-color == "ink" { _t.fg } else { _kpi-color(main-color) }
  let dir-symbol = {
    if direction == "up" { "↑" }
    else if direction == "down" { "↓" }
    else if direction == "neutral" { "—" }
    else { "" }
  }
  // The variation is a signed pill (option A, 2026-11-07): the sign's colour
  // as text on the same colour at 10%, as chanwer's KPI pane and table deltas.
  // `secondary-color` names the valence when it is not the direction's
  // ("green" / "red"); otherwise up is green, down is red, no move is slate.
  let valence = if secondary-color == "green" or secondary-color == "red" { secondary-color }
    else if direction == "up" { "green" } else if direction == "down" { "red" } else { "muted" }
  let chip-fg = _kpi-color(valence)
  let chip-bg = chip-fg.transparentize(90%)

  // Alto fijo: las tres celdas miden lo mismo pase lo que pase con el largo de
  // la glosa, asi las series quedan alineadas entre columnas y nada se
  // desborda por debajo del filete de cierre.
  block(width: 100%, height: _kpi-card-h)[
    #stack(dir: ttb, spacing: 0pt,
      // ── rotulo + procedencia ──────────────────────────────────
      // A tres columnas la fila entera entra en ~51mm, asi que el rotulo y el
      // sello van al cuerpo mas chico que los deja en un solo renglon.
      // Al eje y no a la base: la procedencia es una ficha con marco, así que
      // lo que tiene que coincidir con el rótulo es su centro, no su borde
      // de abajo.
      grid(
        columns: (auto, 1fr),
        align: (left + horizon, right + horizon),
        {
          // The figure head's gesture: a dot and the mono label.
          cw-dot(_t.primary, size: 4pt)
          h(1.8mm)
          cw-label(title, fill: _t.fg, size: 6pt)
        },
        if source != "" { _chip-label(source) } else { [] },
      ),
      v(5.5mm),

      // ── la cifra ──────────────────────────────────────────────
      // El numeral y la unidad se alinean por la base; la aclaracion de la
      // unidad cuelga de la unidad, no del numeral.
      grid(
        columns: (auto, auto),
        column-gutter: 2mm,
        align: (left + bottom, left + bottom),
        {
          if prefix != "" {
            text(font: _t.font-display, size: 18pt, weight: _t.weight-display,
                 tracking: -0.05em, fill: mc, prefix)
            h(0.8mm)
          }
          text(font: _t.font-display, size: 36pt, weight: _t.weight-display,
               tracking: -0.05em, fill: mc, main)
        },
        block(spacing: 0pt)[
          #set par(spacing: 0pt, leading: 0pt)
          #if unit != "" {
            text(font: _t.font-display, size: 10.8pt, weight: _t.weight-display,
                 tracking: -0.05em, fill: mc, unit)
          }
          #if unit-note != "" {
            v(2.2mm)
            text(font: _t.font-mono, size: 5.4pt, weight: _t.weight-regular, tracking: 0.14em,
                 fill: _t.fg-muted, upper(unit-note))
          }
        ],
      ),
      v(5mm),

      // ── ficha de variacion + glosa ────────────────────────────
      // La fila va a alto fijo y las dos celdas al eje: asi la glosa queda
      // centrada contra la ficha lleve uno o dos renglones, y la ficha cae a la
      // misma altura en las tres columnas. Centrar dentro de una fila de alto
      // automatico no alcanzaba: una glosa de dos renglones estiraba la fila y
      // bajaba la ficha, y las columnas dejaban de coincidir.
      block(width: 100%, height: _kpi-chip-row-h)[
        #grid(
          columns: (auto, 1fr),
          column-gutter: 3mm,
          align: (left + horizon, left + horizon),
          if delta != "" {
            box(fill: chip-bg, radius: _t.radius-pill, inset: (x: 2.4mm, y: 1.15mm),
              text(font: _t.font-mono, size: 5.9pt, weight: _t.weight-medium, tracking: 0.06em,
                   fill: chip-fg,
                   if dir-symbol != "" { dir-symbol + " " + delta } else { delta }))
          } else { [] },
          if secondary != "" {
            block(spacing: 0pt)[
              #set par(leading: 0.6em, spacing: 0pt)
              #text(font: _t.font-sans, size: 6.6pt, weight: _t.weight-body,
                    fill: _t.body-fg, secondary)
            ]
          } else { [] },
        )
      ],

      // ── serie ─────────────────────────────────────────────────
      v(1fr),
      if series.len() > 1 { _kpi-spark(series) } else { [] },
      if from-label != "" or state-label != "" or to-label != "" {
        v(2.6mm)
        grid(
          columns: (auto, 1fr, auto),
          align: (left + horizon, center + horizon, right + horizon),
          ..(from-label, state-label, to-label).map(l =>
            text(font: _t.font-mono, size: 4.4pt, weight: _t.weight-regular, tracking: 0.16em,
                 fill: _t.fg-muted, upper(l))),
        )
      } else { [] },
    )
  ]
}

// La grilla de KPIs no son tarjetas sino una banda: cuatro filetes del mismo
// grosor y del mismo tono —dos cerrando arriba y abajo, y uno entre columna y
// columna—, así que la retícula se lee entera y no como un marco con tabiques.
//
// Las divisorias no se cuelgan de la celda sino que se dibujan en el medio de
// la canaleta: si se pusieran como borde izquierdo, la primera columna seria
// la unica sin sangria y quedaria 7mm mas ancha que las demas —una serie
// visiblemente mas larga que las otras dos—. Asi las tres columnas miden lo
// mismo y la primera sigue alineada al margen del texto, como el cuerpo.
#let kpi-grid(cols: 4, rows: auto, items) = {
  // Option A (2026-11-07): one pane, with a hairline between the tiles. Four
  // panes in a row was the one place the pane language got loud.
  let n-rows = calc.ceil(items.len() / cols)
  block(width: 100%, above: 11mm, below: 12mm,
    cw-pane(inset: 0pt, breakable: false, grid(
      columns: range(cols).map(_ => 1fr),
      inset: (x: _t.space-md, y: _kpi-pad-y),
      stroke: none,
      ..range(1, cols).map(i => grid.vline(x: i, stroke: cw-hairline + _t.rule)),
      ..range(1, n-rows).map(i => grid.hline(y: i, stroke: cw-hairline + _t.rule)),
      ..items,
    )))
}

// =============================================================
// ZONE HIGHLIGHT — a floating background colour zone (v2: 24px corners)
// =============================================================
// color: "light" (por defecto) | "white" | "dark" | "primary"
// ("slate" vale por light, "orange" por primary y "metallic", que
// era la hoja misma, ahora cae en light).
// `margin` es el aire adentro del panel, arriba y abajo del texto: a 2mm el
// cuerpo tocaba el borde de la banda. Se mide contra el ancho de la columna,
// no contra el cuerpo del texto, así que no cambia con `body-size`.
#let zone-highlight(color: "light", margin: 8mm, above: 3mm, below: 3mm, col-gutter: 14mm, ..bodies) = {
  // La zona `light` va un paso más abajo que los demás paneles light
  // (surface-slate en vez del beige): corre dentro del cuerpo y sobre la
  // hoja necesita un poco más de contraste para leerse como banda.
  let bg = if color == "light" or color == "slate" or color == "metallic" { _t.surface-slate }
    // `primary` is obsidian with the orange Aspa as its signal (2026-11-18).
    else if color == "dark" or color == "primary" or color == "orange" { _t.ink }
    else if color.starts-with("#")       { rgb(color)     }
    else                                 { _t.white          }
  let on-dark = color == "dark" or color == "primary" or color == "orange"
  // Sobre obsidiana el texto va en blanco, como en todo el formato; sobre
  // naranja, en blanco.
  let on-color = _t.white

  if above != none { v(above) }
  _cw-insert(if color == "orange" { "primary" } else { color }, bg, (x: 10mm, top: margin, bottom: margin), gap: 0pt)[
      // Un `set` adentro de un `if` no llega a ninguna parte: el bloque del
      // `if` termina en esa misma línea y la regla muere con él. La forma que
      // sí aplica es `set ... if`. Y `strong` necesita su propia regla porque
      // el cuerpo del documento lo fija en `body-fg` pase lo que pase, así que
      // sobre obsidiana o naranja la negrita seguía siendo slate.
      #set text(fill: on-color) if on-dark
      #show strong: it => text(
        weight: _t.weight-display,
        fill: if on-dark { on-color } else { _t.body-fg },
        it.body,
      )
      #let parts = bodies.pos()
      #if parts.len() > 1 {
        grid(
          columns: range(parts.len()).map(_ => 1fr),
          column-gutter: col-gutter,
          align: left + top,
          ..parts,
        )
      } else if parts.len() == 1 {
        parts.first()
      }
    ]
  if below != none { v(below) }
}

// =============================================================
// FIGURE FRAME — figure-local footer + alt-footer treatment
// top-left/top-right form the upper footer; bottom-left/bottom-right
// form the lower alt-footer. The body may contain a Markdown image,
// generated plot, table, or raw Typst figure.
// =============================================================
// The frame's two rows are the shared footer language (chanwe-v2.typ).
#let _chanwe-frame-top(top-left, top-right) = if top-left != none {
  cw-figure-head(top-left, gloss: top-right)
} else if top-right != none {
  text(font: _t.font-sans, size: 7.6pt, weight: _t.weight-body-plus, fill: _t.fg-muted, top-right)
  v(3mm)
}

#let _chanwe-frame-bottom(bottom-left, bottom-right) = cw-figure-foot(bottom-left, bottom-right)

#let chanwe-figure-frame(
  top-left: none,
  top-right: none,
  bottom-left: none,
  bottom-right: none,
  body,
) = {
  let has-top = top-left != none or top-right != none
  let has-bottom = bottom-left != none or bottom-right != none

  figure(
    block(
      width: 100%,
      breakable: false,
    )[
    #set block(spacing: 0pt)
    #if has-top { _chanwe-frame-top(top-left, top-right) }

    #block(width: 100%)[
      #show figure.where(kind: image): it => block(width: 100%)[#it.body]
      #show figure.where(kind: table): it => block(width: 100%)[#it.body]
      #show figure: it => block(width: 100%)[#it.body]
      #body
    ]

    #if has-bottom { _chanwe-frame-bottom(bottom-left, bottom-right) }
    ],
    kind: "chanwe-figure-frame",
    supplement: [Figure],
    numbering: "1",
  )
}

// Figura nativa de Quarto — `![pie](…){#fig-x}` o una tabla con
// `: pie {#tbl-x}` — vestida con la cabeza del marco: "FIGURA 1" / "TABLA 1" (el
// suplemento sigue a `lang`) y el pie al lado. Nada debajo: lo que cierra una
// figura es su fuente, y esa la escribe el autor. La numeración y las referencias
// cruzadas (`@fig-x`) no cambian: el contador es el de Quarto. `it` es el `figure`
// de tipo `quarto-float-*`.
#let chanwe-native-figure(it) = block(
  width: 100%, breakable: false, above: 11mm, below: 12mm,
)[
  #set block(spacing: 0pt)
  #_chanwe-frame-top(
    upper(it.supplement) + " " + it.counter.display(),
    if it.caption != none { it.caption.body } else { none },
  )
  #block(width: 100%, it.body)
]

// El marco sin casilleros: un filete arriba y otro abajo, del mismo tono y
// grosor que el que abre el pie de página (`border`, 0.5pt), y adentro sólo
// el cuerpo de la figura. La regla del cuerpo para `figure` —filetes en
// tinta y pie en mono— no entra acá, igual que en `.chanwe-figure-frame`:
// antes se colaba y el marco salía con dos filetes de cada lado, uno slate y
// otro negro, más un pie numerado por el contador suelto de Typst.
#let fig-border(body) = {
  v(4mm, weak: true)
  block(breakable: false, width: 100%)[
    #set block(spacing: 0pt)
    #line(length: 100%, stroke: 0.5pt + _t.border)
    #block(width: 100%, inset: (y: 4mm))[
      #show figure: it => block(width: 100%, align(center, it.body))
      #body
    ]
    #line(length: 100%, stroke: 0.5pt + _t.border)
  ]
  v(4mm, weak: true)
}// =============================================================
// chanwe-cards.typ — tarjetas destacadas (`.card-highlight`)
//
// Un panel slate con una barra de color a la izquierda. Solo, a todo el
// ancho, lleva sólo el cuerpo (la bajada de un memo); dentro de un
// `.card-highlight-set` cada tarjeta suma un rótulo en mono y un título, y
// todas las tarjetas de una fila miden lo mismo.
//
// El archivo es compartido: el reporte y el memo lo incluyen como parcial
// después de su tabla `_t`, así lee los mismos tokens en los dos formatos.
// La barra es una celda pintada, no un `stroke`: el trazo de un borde se
// dibuja centrado en el canto y asoma medio grosor por arriba y por abajo
// del panel; dos celdas en la misma fila miden exactamente lo mismo.
// =============================================================

// A card is a pane, so `white` is the default since 2026-11-05 (it was
// `light`, the slate tint, which on a memo's first page —lede plus four
// cards— read as a grey block); `light` is still there for grouping.
// Esquema por variante: white · light · dark · primary, como el resto de los
// Divs del reporte. La barra usa el mismo vocabulario que el panel: `accent`
// toma `primary`, `light` (slate) o `dark` (obsidiana), resuelto contra el
// fondo para que siempre se vea.
// `primary` is the dark card: orange is a signal (the bar, the dot), not a
// fill (2026-11-18).
#let _ch-scheme(color) = if color == "dark" or color == "primary" {
  (bg: _t.ink, eyebrow: _t.fg-subtle, title: _t.white, body: _t.white,
   bar-primary: _t.primary, bar-light: _t.rule-cool, bar-dark: _t.rule-ink)
} else if color == "white" {
  (bg: _t.white, eyebrow: _t.fg-muted, title: _t.ink, body: _t.fg-muted,
   bar-primary: _t.primary, bar-light: _t.rule-cool, bar-dark: _t.ink)
} else {
  (bg: _t.tint, eyebrow: _t.fg-muted, title: _t.ink, body: _t.fg-muted,
   bar-primary: _t.primary, bar-light: _t.rule-cool, bar-dark: _t.ink)
}

// Sin `accent`, la tarjeta suelta lleva la barra `light`; en un set, la
// primera va en `primary` y el resto en `dark`.
// (En llaves: a nivel de archivo un `else` en la línea siguiente ya no es
// parte de la expresión y Typst lo imprime como texto.)
#let _ch-bar(accent, s, index) = {
  if accent == "primary" { s.bar-primary }
  else if accent == "light" { s.bar-light }
  else if accent == "dark" { s.bar-dark }
  else if index == none { s.bar-light }
  else if index == 0 { s.bar-primary }
  else { s.bar-dark }
}

#let _ch-cell(eyebrow, title, body, s, wide: false, dot: none) = block(
  width: 100%,
  inset: if wide { (left: 5mm, right: 5mm, top: 3.4mm, bottom: 3.4mm) }
         else { (left: 4mm, right: 4mm, top: 3.4mm, bottom: 3.4mm) },
)[
  #set block(spacing: 0pt)
  #set par(leading: 0.68em, spacing: 0.7em)
  #if eyebrow != none {
    if dot != none { cw-dot(dot, size: 4.5pt, baseline: -0.6pt); h(1.6mm) }
    text(font: _t.font-mono, size: 5.9pt, weight: _t.weight-medium, tracking: 0.18em,
         fill: s.eyebrow, upper(eyebrow))
    v(2.2mm)
  }
  #if title != none {
    text(font: _t.font-display, size: 9.2pt, weight: _t.weight-display, tracking: -0.05em,
         fill: s.title, title)
    v(1.8mm)
  }
  #set text(font: _t.font-sans, size: if wide { 0.97em } else { 7.4pt },
            weight: _t.weight-regular, fill: s.body)
  #body
]

// La tarjeta suelta: a todo el ancho, cuerpo al tamaño del texto corrido.
// v2-print: a card is a pane with 16px corners (hairline on the white and
// light schemes), and its accent is a dot before the eyebrow instead of the
// side bar of v1.
#let _ch-card(s, accent, index, wide, eyebrow, title, body) = block(
  width: 100%, fill: s.bg, radius: _t.radius-surface, clip: true, breakable: false,
  stroke: if s.bg == _t.ink or s.bg == _t.primary { none } else { cw-hairline + _t.rule },
  inset: 0pt,
  _ch-cell(eyebrow, title, body, s, wide: wide, dot: _ch-bar(accent, s, index)),
)

#let card-highlight(eyebrow: none, title: none, accent: none, color: "white", body) = {
  let s = _ch-scheme(color)
  block(width: 100%, above: 5mm, below: 5mm, breakable: false,
    _ch-card(s, accent, none, true, eyebrow, title, body))
}

#let card-highlight-set(color: "white", cols: none, items) = {
  let s = _ch-scheme(color)
  let n = if cols == none { items.len() } else { cols }
  let n = calc.max(1, calc.min(n, items.len()))
  block(width: 100%, above: 6mm, below: 6mm, grid(
    columns: range(n).map(_ => 1fr),
    column-gutter: 4mm,
    row-gutter: 4mm,
    ..items.enumerate().map(((i, c)) => _ch-card(s, c.at("accent", default: none), i, false,
      c.at("eyebrow", default: none), c.at("title", default: none), c.at("body", default: []))),
  ))
}// =============================================================
// chanwe-lists.typ — listas de tareas (`- [ ]` / `- [x]`)
//
// Compartido por el reporte y el memo, incluido como parcial después de la
// tabla `_t`. El filtro `chanwe-lists.lua` convierte una lista de tareas
// de markdown en `#task-list(((hecho, cuerpo), …))`: la casilla es la
// viñeta, no va una viñeta y además una casilla. Antes Pandoc escribía los
// glifos ☐ y ☒ dentro de una lista común y cada ítem salía con dos marcas.
// =============================================================

// The box is the bullet. `square` (the default since the kit and the formats
// were unified, 2026-11-18): a hairline square, filled obsidian with a white
// tick when done, and the done item struck through in `fg-subtle`. `round`:
// a circle in the control hairline, an orange disc when done.
// The document picks with `chanwe: task-style:` (cw-style, chanwe-v2.typ).
#let _task-tick = {
  place(top + left, line(start: (1.6pt, 3.7pt), end: (3.0pt, 5.2pt),
    stroke: (paint: _t.white, thickness: 0.9pt, cap: "round")))
  place(top + left, line(start: (3.0pt, 5.2pt), end: (5.7pt, 2.0pt),
    stroke: (paint: _t.white, thickness: 0.9pt, cap: "round")))
}
#let _task-box(done) = context {
  let round = cw-style("task-style", "square") == "round"
  box(
    width: 7.2pt, height: 7.2pt,
    radius: if round { 3.6pt } else { 1.8pt },
    stroke: if done { none } else if round { 0.7pt + _t.rule-cool } else { 0.7pt + _t.fg-muted },
    fill: if done { if round { _t.primary } else { _t.ink } } else { none },
    if done { _task-tick },
  )
}

// `items`: tupla de `(hecho, cuerpo)`. La casilla ocupa la columna de la
// viñeta y el cuerpo cuelga a su derecha; con `align: top` la casilla se
// apoya en la altura de las versales de la primera línea.
#let task-list(items, spacing: 0.7em, gutter: 5pt) = block(width: 100%, grid(
  columns: (auto, 1fr),
  column-gutter: gutter,
  row-gutter: spacing,
  align: (top, top),
  ..items.map(((done, body)) => (_task-box(done), if done { text(fill: _t.fg-subtle, strike(stroke: 0.5pt + _t.fg-subtle, body)) } else { body })).flatten(),
))// =============================================================
// chanwe-pages.typ — editorial pages 1:1 to HTML
// AGENDA · ABSTRACT · CHAPTER SEPARATOR · BACK COVER
// =============================================================

#let _pad2(n) = if n < 10 { "0" + str(n) } else { str(n) }

// Ancho de la columna del numeral en el indice. El titulo del H1 arranca
// aca, y el bloque de subniveles se sangra lo mismo para que el riel caiga
// justo debajo del titulo. Una sola constante para que no se separen.
//
// El numeral a 22pt mide ~5.5mm de glifo, asi que de estos 30mm quedan 24mm
// de aire entre el numero y el titulo: el doble del hueco anterior, que era
// de 12mm con la columna a 18mm. Si se cambia el cuerpo del numeral, el
// hueco se mueve con el —la constante fija la columna, no la separacion.
#let _toc-indent = 30mm

// La guia que lleva del subnivel al folio. Mismo filete que todas las
// divisiones del documento —encabezado, pie, cierre de capitulo—: `border` a
// 0.5pt. Antes iba en `rule-cool`, que al lado del cierre de capitulo se leia
// mas oscura.
#let _toc-leader = 0.5pt + _t.border

// El filete que cierra un capitulo: arranca donde arranca el titulo del H1 y
// llega hasta el folio. Va en el mismo `border` a 0.5pt que el resto de las
// divisiones del documento.
//
// Se dibuja *antes* del capitulo siguiente, no despues del propio: desde
// adentro del `outline` cada entrada se emite suelta y un subnivel no sabe si
// es el ultimo de su capitulo.
#let _toc-chapter-rule = block(spacing: 0pt,
  pad(left: _toc-indent, line(length: 100%, stroke: 0.5pt + _t.border)))

// El cuerpo del titulo de capitulo en el indice, y el de seccion derivado de
// el: cinco puntos por encima y un 15% mas (23.23pt). La relacion vive en el
// codigo para que mover uno mueva el otro.
#let _toc-h1-size      = 15.2pt
#let _toc-section-size = (_toc-h1-size + 5pt) * 1.15

// Todos los folios del indice —rango de la seccion, rango del capitulo y
// pagina del subnivel— comparten un solo estilo, el del capitulo. Un helper
// en vez de tres copias, para que no vuelvan a separarse. Sin `weight`: asi
// los tres heredan el mismo del cuerpo.
#let _toc-folio(body) = text(
  font: _t.font-mono, size: 7pt, tracking: 0.17em, fill: _t.fg-muted, body,
)

// ---------- AGENDA / TABLE OF CONTENTS -----------------------

// Recuento del documento para la losa del índice: secciones (las portadillas
// de `chanwe-chapter-divider`), capítulos (los H1) y páginas. Se cuenta solo,
// nadie lo escribe en el YAML. Va sobre obsidiana: el rótulo en `fg-subtle`
// (el slate de los rótulos sobre tinta; hasta 2026-11-13 `ink-subtle`, un gris
// neutro que tiraba a marrón) y el número en blanco, que es la regla para
// texto sobre tinta (2026-11-19).
#let _chanwe-agenda-counts(on-ink: true) = context {
  let rows = (
    ("Secciones", query(<chanwe-part>).len()),
    ("Capítulos", query(heading.where(level: 1)).len()),
    ("Páginas",   counter(page).final().first()),
  )
  // Se omiten los renglones en cero: un documento sin portadillas no debería
  // anunciar "SECCIONES 00".
  let rows = rows.filter(((_, n)) => n > 0)
  if rows.len() == 0 { return }
  grid(
    columns: (auto, auto),
    column-gutter: 7mm,
    row-gutter: 4.2mm,
    align: (left + horizon, right + horizon),
    ..rows.map(((label, n)) => (
      text(font: _t.font-mono, size: 8.05pt, weight: _t.weight-regular, tracking: 0.18em,
           fill: if on-ink { _t.fg-subtle } else { _t.fg-muted }, upper(label)),
      text(font: _t.font-mono, size: 8.05pt, weight: _t.weight-body, tracking: 0.18em,
           fill: if on-ink { _t.white } else { _t.fg }, _pad2(n)),
    )).flatten(),
  )
}
// Los renglones de subnivel cuelgan de un riel naranja continuo: cada uno
// dibuja su propio tramo y, al ir pegados (`spacing: 0pt` y el aire adentro
// del bloque), los tramos se sueldan en una sola línea. La guía lleva el ojo
// hasta el folio sin necesidad de un filete por renglón.
// La sangría va en un bloque exterior con `spacing: 0pt` y no en un `pad()`:
// el `pad` es un elemento de bloque propio y los renglones consecutivos se
// separaban con el espaciado de párrafo, que partía el riel en tramos.
#let chanwe-toc-subrow(num: "", label: "", page: "") = block(
  width: 100%,
  spacing: 0pt,
  inset: (left: _toc-indent),
)[
  #block(
  width: 100%,
  spacing: 0pt,
  // The rail and the sub-level number are slate since 2026-11-05: in the
  // agenda orange is the chapter numeral's alone.
  stroke: (left: 1pt + _t.rule-cool),
  inset: (left: 7mm, top: 3mm, bottom: 3mm),
)[
  #set par(spacing: 0pt, leading: 0pt)
  #grid(
    columns: (12mm, auto, 1fr, auto),
    column-gutter: 3mm,
    align: (left + horizon, left + horizon, center + horizon, right + horizon),
    text(font: _t.font-mono, size: 7.5pt, tracking: 0.1em, weight: _t.weight-regular, fill: _t.fg-muted, num),
    // Mismo tono y peso que el texto corrido: el subnivel acompaña, no titula.
    text(font: _t.font-sans, size: 9.5pt, weight: _t.weight-body, fill: _t.body-fg, label),
    // La guía se dibuja en el hueco elástico, así que se estira sola.
    box(width: 100%, inset: (x: 3mm), line(length: 100%, stroke: _toc-leader)),
    _toc-folio(page),
  )
]
]

#let chanwe-toc-row(num: "", label: "", page: "", sub: false) = block(spacing: 0pt)[
  #set par(spacing: 0pt, leading: 0pt)
  #if sub {
    chanwe-toc-subrow(num: num, label: label, page: page)
  } else {
    grid(
      columns: (14mm, 1fr, 12mm),
      column-gutter: 4mm,
      align: (left + bottom, left + bottom, right + bottom),
      text(font: _t.font-mono, size: 7.5pt, tracking: 0.12em, weight: _t.weight-hairline, fill: _t.fg-muted, num),
      text(font: _t.font-mono, size: 7.5pt, weight: _t.weight-hairline, fill: _t.ink, label),
      text(font: _t.font-mono, size: 7.5pt, tracking: 0.14em, weight: _t.weight-hairline, fill: _t.fg-muted, page),
    )
  }
]

#let chanwe-toc-group(numeral: "01", title: "", pages: "", rows: ()) = {
  block(above: 0mm, below: 8mm)[
    // group head: giant italic numeral · title · page range
    #grid(
      columns: (20mm, 1fr, 30mm),
      column-gutter: 4mm,
      align: (left + bottom, left + bottom, right + bottom),
      text(
        font: _t.font-display, weight: _t.weight-display,
        size: 22pt, tracking: -0.03em, number-type: "lining", fill: _t.primary,
        numeral,
      ),
      text(
        font: _t.font-display, size: 14pt, weight: _t.weight-display,
        tracking: -0.05em, fill: _t.fg, title,
      ),
      text(
        font: _t.font-mono, size: 8pt, tracking: 0.18em,
        fill: _t.fg-muted, upper(pages),
      ),
    )
    #v(2mm)
    #line(length: 100%, stroke: 0.5pt + _t.ink)
    // rows with explicit spacing and light gray separator after each
    #for (i, r) in rows.enumerate() {
      let is_sub = r.at("sub", default: false)
      v(if i == 0 { 0.1mm } else if is_sub { 0mm } else { 0.1mm })
      chanwe-toc-row(..r)
      v(0.1mm)
      line(length: 100%, stroke: 0.5pt + _t.border)
    }
  ]
}

// The timeline agenda (Ale's pick "inline", 2026-11-19; `chanwe: agenda-style:
// timeline`): under the band head, the document as a line. Page numbers on the
// left of one hairline rail, a ring per chapter with its sections in one muted
// line, and each part as a stop of its own on the same rail: a larger orange
// dot and its number (1, 2, 3) in orange before its name, nothing stacked above.
#let _chanwe-agenda-timeline() = context {
  let h1s = query(heading.where(level: 1)).filter(h => h.outlined)
  if h1s.len() == 0 { return }
  let parts = query(<chanwe-part>)
  let pg(loc) = counter(page).at(loc).first()
  let rows = ()
  let seen-parts = ()
  let n = 0
  for (i, h) in h1s.enumerate() {
    let hp = pg(h.location())
    // a part opens before the first chapter that follows its divider
    let before = parts.filter(p => pg(p.location()) <= hp)
    if before.len() > 0 {
      let part = before.last()
      if part.value.number not in seen-parts {
        seen-parts.push(part.value.number)
        // parts count 1, 2, 3 here, not in roman numerals (Ale, 2026-11-19)
        rows.push((kind: "part", num: str(seen-parts.len()), title: part.value.title,
                   page: pg(part.location()) + 1, loc: part.location()))
      }
    }
    let numbered = h.numbering != none
    if numbered { n += 1 }
    let next = if i + 1 < h1s.len() { h1s.at(i + 1).location() } else { none }
    let subs = query(heading.where(level: 2).after(h.location(), inclusive: false))
      .filter(x => x.outlined and (next == none or x.location().position().page < next.position().page
        or (x.location().position().page == next.position().page and x.location().position().y < next.position().y)))
    rows.push((kind: "chapter", num: if numbered { _pad2(n) } else { none }, title: h.body,
               page: hp, loc: h.location(), subs: subs.map(x => x.body)))
  }
  // The rail is the left edge of every row's text cell: with no row gutter the
  // edges meet, one hairline from the first stop to the last. The stops sit on
  // it. (The rows are not links: the report underlines every link in orange.)
  let rail = 0.6pt + _t.rule-cool
  let pad = 7mm
  let last = rows.len() - 1
  grid(
    columns: (12mm, 1fr),
    column-gutter: 4mm,
    row-gutter: 0pt,
    ..rows.enumerate().map(((i, r)) => {
      let part = r.kind == "part"
      // more air above every new part (Ale, 2026-11-19)
      let lift = if part and i > 0 { 10mm } else { 0mm }
      let page-cell = block(inset: (top: lift + (if part { 2.4mm } else { 0.9mm })), width: 100%,
        align(right, text(font: _t.font-mono, size: 7.5pt, tracking: 0.12em, weight: _t.weight-regular,
          fill: _t.fg-muted, _pad2(r.page))))
      let dot = if part {
        circle(radius: 2.4mm, fill: _t.primary, stroke: none)
      } else {
        circle(radius: 1.25mm, fill: _t.paper, stroke: 0.9pt + _t.ink)
      }
      let r-dot = if part { 2.4mm } else { 1.25mm }
      let body = block(width: 100%, stroke: (left: rail), inset: (left: pad, top: lift, bottom: if i == last { 0mm } else if part { 5mm } else { 6mm }), {
        place(top + left, dx: -pad - r-dot, dy: if part { 0.9mm } else { 0.75mm }, dot)
        // the body's 2.6em paragraph spacing would push the sections away
        set par(spacing: 0pt)
        if part {
          text(font: _t.font-display, size: 21pt, weight: _t.weight-display, tracking: -0.04em,
               number-type: "lining", fill: _t.primary, r.num)
          h(3.5mm)
          text(font: _t.font-display, size: 21pt, weight: _t.weight-display, tracking: -0.04em, fill: _t.fg, r.title)
        } else {
          if r.num != none {
            text(font: _t.font-display, size: 13.5pt, weight: _t.weight-display, number-width: "tabular",
                 fill: _t.fg-muted, r.num)
            h(2.6mm)
          }
          text(font: _t.font-display, size: 13.5pt, weight: _t.weight-display, tracking: -0.025em, fill: _t.fg, r.title)
          if r.subs.len() > 0 {
            v(2.2mm)
            set par(leading: 0.55em)
            text(font: _t.font-sans, size: 9pt, weight: _t.weight-body, fill: _t.fg-muted,
                 r.subs.join([ #h(0.25em)·#h(0.25em) ]))
          }
        }
      })
      (page-cell, body)
    }).flatten(),
  )
}

#let chanwe-agenda(
  eyebrow: "Document map",
  title: "Agenda",
  lede: none,
  groups: none,
  parts: none,
) = {
  // The agenda's head (v2, 2026-11-18), `chanwe: agenda-style:`. `band`
  // (default): the obsidian band of the H1, floating inside the margins with
  // its 24px corners (until then it bled edge to edge, which v2 rules out).
  // `paper`: no band, the title at display size on the page. `timeline`: the
  // band head, and the list as a line (`_chanwe-agenda-timeline`).
  let head(on-ink) = {
    chanwe-section-eyebrow(eyebrow, fill: if on-ink { _t.white } else { _t.fg-muted })
    v(7.5mm)
    // El titular a la izquierda y el recuento del documento a la derecha,
    // alineados por la base.
    grid(
      columns: (1fr, auto),
      align: (left + bottom, right + bottom),
      block(spacing: 0pt)[
        #text(
          font: _t.font-display, size: 72.8pt, weight: _t.weight-display,
          tracking: -0.05em, fill: if on-ink { _t.white } else { _t.fg }, title,
        )#_chanwe-title-dot(72.8pt)
      ],
      block(spacing: 0pt, _chanwe-agenda-counts(on-ink: on-ink)),
    )
  }
  context if cw-style("agenda-style", "band") == "paper" {
    v(10mm)
    head(false)
  } else {
    v(-2mm)
    cw-band(inset: (left: 12mm, right: 12mm, top: 12mm, bottom: 13mm), head(true))
  }
  v(12mm)

  if lede != none {
    v(15mm)
    block(width: 130mm)[
      #set par(leading: 0.55em)
      #set text(font: _t.font-sans, size: 10pt, weight: _t.weight-regular, fill: _t.fg-muted)
      #lede
    ]
  }

  v(14mm)

  context if groups == none and parts == none and cw-style("agenda-style", "band") == "timeline" {
    _chanwe-agenda-timeline()
  } else if groups != none {
    // --- manual groups mode ---
    for g in groups { chanwe-toc-group(..g) }
  } else if parts != none {
    // --- simple parts list ---
    for part in parts {
      let (num, ptitle, desc, pg) = part
      grid(
        columns: (16mm, 1fr, 20mm),
        column-gutter: 5mm,
        align: (right + top, left + top, right + top),
        text(font: _t.font-display, weight: _t.weight-display, size: 20pt, tracking: -0.03em, number-type: "lining", fill: _t.primary, num),
        {
          text(font: _t.font-display, size: 13pt, weight: _t.weight-display, tracking: -0.05em, fill: _t.fg, ptitle)
          linebreak()
          v(1.5mm)
          text(font: _t.font-sans, size: 9.5pt, fill: _t.fg-muted, desc)
        },
        text(font: _t.font-mono, size: 8pt, tracking: 0.12em, fill: _t.fg-muted, upper(pg)),
      )
      v(3mm)
      line(length: 100%, stroke: 0.5pt + _t.border)
      v(4mm)
    }
  } else {
    // --- AUTO mode: driven by outline() with independent counters ---
    // Part labels (from chanwe-chapter-divider) are injected between groups
    // without changing the H1 group-header hierarchy.
    // La agenda lista capítulos (H1) y secciones (H2). Los H3 quedan fuera:
    // son subdivisiones de lectura, no puntos de entrada del documento.
    let _h1 = counter("_chanwe-toc-h1")
    let _h2 = counter("_chanwe-toc-h2")

    show outline.entry: it => {
      if it.level == 1 {
        // Un capítulo sin numerar no avanza el contador: en lugar del "01"
        // lleva el filete corto que el cuerpo le pone a la losa.
        let numbered = it.element.numbering != none
        if numbered { _h1.step() }
        _h2.update(0)
        context {
          let n   = _h1.get().first()
          let pg  = counter(page).at(it.element.location()).first()
          let next_h1s = query(heading.where(level: 1).after(it.element.location(), inclusive: false))
          let end_pg = if next_h1s.len() > 0 {
            let np = counter(page).at(next_h1s.first().location()).first()
            if np > pg { np - 1 } else { pg }
          } else {
            counter(page).final().first()
          }
          let pages_str = if end_pg > pg {
            _pad2(pg) + " — " + _pad2(end_pg)
          } else { _pad2(pg) }
          let prev_h1s = query(heading.where(level: 1).before(it.element.location(), inclusive: false))
          let is-first = prev_h1s.len() == 0

          // Cierra el capitulo anterior antes de abrir este, incluso si el
          // que sigue abre una seccion nueva: el filete pertenece al capitulo
          // que termina, no al que empieza. Solo si ese capitulo no tuvo
          // subniveles: cuando los tuvo, el riel naranja de los renglones ya
          // lo cierra y el filete sobraba.
          if not is-first {
            let prev-loc = prev_h1s.last().location()
            let prev-had-sub = query(
              heading.where(level: 2)
                .after(prev-loc, inclusive: false)
                .before(it.element.location(), inclusive: false)
            ).len() > 0
            v(7mm)
            if not prev-had-sub { _toc-chapter-rule }
          }

          // Inject part label when a new chapter-divider section starts.
          // Filter by page number — avoids any selector.before() ambiguity.
          let h-loc   = it.element.location()
          let h-page  = counter(page).at(h-loc).first()
          let all-parts = query(<chanwe-part>)
          let cur-part = {
            let before = all-parts.filter(p => counter(page).at(p.location()).first() <= h-page)
            if before.len() > 0 { before.last().value } else { none }
          }

          let prev-part = if is-first { none } else {
            let ph = counter(page).at(prev_h1s.last().location()).first()
            let before = all-parts.filter(p => counter(page).at(p.location()).first() <= ph)
            if before.len() > 0 { before.last().value } else { none }
          }

          let cur-num  = if cur-part  != none { cur-part.number  } else { none }
          let prev-num = if prev-part != none { prev-part.number } else { none }

          if cur-part != none and cur-num != prev-num {
            // La banda de parte ya no lleva rectángulo de fondo: el renglón
            // se apoya en la columna de texto y cierra con un filete. La
            // jerarquía se la da el cuerpo del titular, no el filete: éste es
            // el mismo `border` a 0.5pt que usan el encabezado, el pie y el
            // cierre del titular del abstract.
            v(if is-first { 0mm } else { 14mm })
            block(width: 100%, spacing: 0pt)[
              #grid(
                // El numeral vive en la misma columna que el del capitulo, asi
                // que el titulo de la seccion arranca exactamente donde arranca
                // el del H1. Sin separacion en el primer hueco: la alineacion
                // la da el ancho de la columna, no el gutter.
                columns: (_toc-indent, auto, 1fr, auto),
                column-gutter: (0mm, 6mm, 6mm),
                align: (left + bottom, left + bottom, left + bottom, right + bottom),
                text(font: _t.font-display, weight: _t.weight-display, tracking: -0.03em,
                     number-type: "lining", size: 32pt, fill: _t.primary, cur-part.number),
                {
                  // Misma familia y tracking que el H1 del índice, un paso más
                  // liviano (700 -> 600) y con más cuerpo: la sección pesa por
                  // tamaño, no por trazo. El numeral sigue en la serif
                  // itálica, que es lo que separa sección de capítulo.
                  text(font: _t.font-display, weight: _t.weight-display,
                       size: _toc-section-size, tracking: -0.05em,
                       fill: _t.fg, cur-part.title)
                  _chanwe-title-dot(_toc-section-size)
                },
                [],
                {
                  // Rango de la parte: de esta portadilla hasta la anterior a
                  // la siguiente, o hasta el final si es la última.
                  let part-loc = all-parts.filter(p => p.value.number == cur-num).first().location()
                  let start-pg = counter(page).at(part-loc).first() + 1
                  let later = all-parts.filter(p =>
                    counter(page).at(p.location()).first() > counter(page).at(part-loc).first())
                  let end-pg = if later.len() > 0 {
                    counter(page).at(later.first().location()).first() - 1
                  } else {
                    counter(page).final().first()
                  }
                  let range = if end-pg > start-pg {
                    _pad2(start-pg) + " — " + _pad2(end-pg)
                  } else { _pad2(start-pg) }
                  _toc-folio(upper(range))
                },
              )
              // 4.8mm arriba y 2.7mm abajo, no 3.5 y 4: el filete queda
              // opticamente centrado entre los dos titulares. La asimetria
              // compensa el hueco que cada caja deja alrededor de su tinta
              // —debajo del titular de seccion entra el descendente de una
              // itálica a 38pt, y encima del H1 sobra el ascendente a 19.2pt—.
              // Medido sobre el PDF: 8.00mm de tinta a tinta de cada lado.
              #v(4.8mm)
              // Mismo filete que el resto del documento: encabezado, pie y el
              // que cierra el titular del abstract. Un solo tono y un solo
              // grosor para todas las divisiones.
              #line(length: 100%, stroke: 0.5pt + _t.border)
            ]
            // El capitulo que abre la seccion arranca pegado a su filete: el
            // bloque del H1 entra con `above: 0mm` y aporta 4mm propios, asi
            // que el aire total es este mas esos cuatro.
            v(2.7mm)
          }

          block(above: if cur-part != none and cur-num != prev-num { 0mm } else if is-first { 0mm } else { 12mm }, below: 0pt)[
            #v(4mm)
            #grid(
              // El folio se dimensiona solo, como el de la seccion: ahora
              // lleva rotulo delante y ya no entra en un ancho fijo.
              columns: (_toc-indent, 1fr, auto),
              column-gutter: 0mm,
              align: (left + bottom, left + bottom, right + bottom),
              if numbered {
                text(font: _t.font-display, weight: _t.weight-display, tracking: -0.03em,
                     number-type: "lining", number-width: "tabular", size: 17pt, fill: _t.primary, _pad2(n))
              } else {
                box(width: 22pt * 1.5, height: 0.5pt + 22pt * 0.03, fill: _t.primary, baseline: -5pt)
              },
              // Un paso mas liviano que el H1 del cuerpo (800 -> 700): el
              // cuerpo ya le da la jerarquia sobre el subnivel.
              text(font: _t.font-display, size: _toc-h1-size, weight: _t.weight-display,
                   tracking: -0.05em, fill: _t.fg, it.body()),
              // Solo el rango, sin rotulo: el renglon ya dice que es.
              _toc-folio(upper(pages_str)),
            )
            #v(3mm)
          ]
        }
      } else if it.level == 2 {
        // Un H2 sin numerar no avanza el contador ni lleva numeral: en su
        // lugar va el mismo filete corto que el cuerpo le pone al titular.
        let numbered = it.element.numbering != none
        if numbered { _h2.step() }
        context {
          let h1n = _h1.get().first()
          let n   = _h2.get().first()
          let pg  = counter(page).at(it.element.location()).first()
          // Numeración relativa al capítulo: 2.1, 2.2 — no un contador suelto.
          // Sin filete por renglón: el riel del subrenglón ya agrupa.
          // El aire va solo antes del primero, para que el riel salga entero.
          if n == 1 and numbered { v(3mm) }
          if n == 0 { v(3mm) }
          chanwe-toc-subrow(
            num: if numbered { str(h1n) + "." + str(n) }
                 else { box(width: 7mm, height: 0.75pt, fill: _t.fg-muted, baseline: -2pt) },
            label: it.element.body,
            page: _pad2(pg),
          )
        }
      }
    }
    // The agenda ends on its last row: a closing rule after it had nothing to
    // separate, and on a full page it opened an empty one.
    outline(title: none, depth: 2)
  }
}

// =============================================================
// ABSTRACT WITH DROP-CAP
// =============================================================
// HTML structure:
//   .abstract-wrap  (60mm side rail | 1fr body)
//     .abstract-side  (label-row × N, hairline border-right)
//     .abstract-body
//       h2 (Schibsted Grotesk 28pt 700)
//       p.lead   (Satoshi 12pt body, ::first-letter 56pt Schibsted drop-cap)
//       p · p · ... (Satoshi 12pt body)
// El cuerpo iba en Cormorant Garamond redonda: texto corrido en serif, que
// la guía de marca no le da a la serif (solo itálicas y números
// editoriales), y un corte redondo que el brandbook no trae. Ahora es el
// cuerpo de la marca, y la capitular, una letra de display, va en Schibsted.
// =============================================================
// El rotulo va en `fg-muted`, el tono de toda la metadata sobre papel
// (`fg-subtle` da 2,9:1 y la guia lo deja para texto grande o decorativo), y
// el valor entra en el mismo chip contorneado que la portada
// usa para el taggy: filete de 0.5pt, radio 2pt, mono en versalitas. Es un
// `block` y no un `box` a proposito: asi un valor largo parte de linea dentro
// del chip en vez de desbordar el riel de 60mm.
#let chanwe-side-row(label: "", value: "", dark: false, accent: _t.primary) = {
  // Sobre la hoja: rótulo y texto del chip en el mismo fg-muted, el marco
  // del chip en border-cool.
  let lc = if dark { _t.white.transparentize(62%) } else { _t.fg-muted }
  let vc = if dark { _t.white                     } else { _t.fg-muted }
  let pc = if dark { _t.white.transparentize(75%) } else { _t.border-cool }
  // El aire interior del chip vive en una constante porque el rotulo se
  // sangra lo mismo: asi el rotulo se alinea con el texto del chip y no con
  // el borde, y los dos se mueven juntos si cambia el inset.
  let pill-pad = (x: 4mm, y: 2.2mm)
  let chip-text(t) = text(font: _t.font-mono, size: 6.75pt, weight: _t.weight-regular,
                          tracking: 0.18em, fill: vc, upper(t))
  // Todos los chips del riel miden lo mismo: el ancho del riel. Un valor suelto
  // parte de linea adentro del chip en vez de desbordar, y una lista —los
  // keywords— apila un chip por item en vez de dejarlos fluir con el ancho de
  // su texto, que era lo unico que rompia la columna.
  let pill(t) = block(width: 100%, stroke: 0.5pt + pc, radius: _t.radius-pill,
                      inset: pill-pad, chip-text(t))
  let values = if type(value) == array {
    stack(dir: ttb, spacing: 4pt, ..value.map(pill))
  } else {
    pill(value)
  }
  stack(dir: ttb, spacing: 8pt,
    // El punto bermellon vive en la canaleta que deja la sangria del rotulo,
    // asi que queda alineado con el borde del chip mientras el rotulo sigue
    // alineado con su texto.
    grid(
      columns: (pill-pad.x, auto),
      align: (left + horizon, left + horizon),
      circle(radius: 1.15pt, fill: accent, stroke: none),
      text(font: _t.font-mono, size: 7.5pt, weight: _t.weight-medium,
           tracking: 0.18em, fill: lc, upper(label)),
    ),
    values,
  )
}

#let chanwe-abstract(
  // new compact call style: eyebrow / title / meta
  eyebrow: none,
  title: none,
  meta: none,            // array of (label, value, sub) 3-tuples
  takeaway: none,
  dark: false,           // true → inverted text colors for dark backgrounds
  accent: _t.primary,    // the one accent: white on a primary page
  on-primary: false,
  body,
) = {
  // Without an eyebrow or a title the page draws none: a sample text must
  // never print in a real document (it used to fall back to one).
  let resolved-rows    = if meta    != none {
    // El tercer campo de la tupla es un subtitulo opcional. Solo se concatena
    // si el valor es texto: los keywords llegan como lista y pasan enteros.
    meta.map(((lbl, val, ..rest)) => (
      label: lbl,
      value: if type(val) == str and rest.len() > 0 and rest.at(0) != none {
        val + "\n" + rest.at(0)
      } else { val },
    ))
  } else { () }

  // color scheme shortcuts
  let title-color  = if dark { _t.white                     } else { _t.fg }
  // El filete vertical del riel de metadata es el unico acento de la pagina.
  let rail-stroke  = accent
  let body-color   = if dark { _t.white.transparentize(15%) } else { _t.fg-muted    }
  let takwy-color  = if dark { _t.white                     } else { _t.ink         }
  // Filete bajo el titular: sangra hasta el borde del papel y usa el mismo
  // tono y grosor que el filete que cierra el encabezado. Sobre tinta pasa al
  // filete de obsidiana, que ahi si se ve.
  let under-rule   = if on-primary { _t.white.transparentize(60%) } else if dark { _t.rule-ink } else { _t.border }

  v(10mm)
  if eyebrow != none {
    chanwe-eyebrow(eyebrow, dot: accent, fill: if dark { _t.white } else { _t.fg-muted })
    v(7.5mm)
  }
  if title != none {
    block[
      #text(
        font: _t.font-display, size: 56pt, weight: _t.weight-display,
        tracking: -0.05em, fill: title-color, title,
      )
      #box(width: 10pt, height: 10pt, baseline: 0pt,
        circle(fill: accent, stroke: none))
    ]
    v(13mm)
  }
  // Mismo truco de sangrado que el encabezado: el margen lateral es 18mm, asi
  // que el filete se corre -18mm y mide 100% + 36mm para llegar a los bordes.
  block(spacing: 0pt,
    pad(x: -18mm, line(length: 100% + 36mm, stroke: 0.5pt + under-rule)))
  v(14mm)

  grid(
    columns: (60mm, 1fr),
    column-gutter: 14mm,
    align: (left + top, left + top),
    // side rail: meta rows
    block(
      stroke: (right: 0.5pt + rail-stroke),
      inset: (right: 10mm),
      width: 100%,
    )[
      #stack(
        dir: ttb, spacing: 9mm,
        ..resolved-rows.map(r => chanwe-side-row(..r, dark: dark, accent: accent))
      )
    ],
    // body block
    block[
      #set par(leading: 0.65em, justify: true)
      #set text(font: _t.font-sans, size: 10pt, weight: _t.weight-regular, fill: body-color)
      #show emph: it => if dark { text(font: _t.font-serif, style: "italic", weight: _t.weight-body, size: 1.25em, fill: body-color, it.body) } else { it }
      #if takeaway != none {
        let s = str(takeaway)
        let parts = s.split(" ")
        let first-word = parts.at(0)
        let rest = if parts.len() > 1 { " " + parts.slice(1).join(" ") } else { "" }
        block(below: 6mm)[
          #text(font: _t.font-serif, size: 32pt, weight: _t.weight-body, style: "italic", fill: accent, first-word)#text(weight: _t.weight-bold, fill: takwy-color, rest)
        ]
      }
      #body
    ],
  )
}

// =============================================================
// EXECUTIVE SUMMARY PAGE — same layout as the abstract page,
// callable inline from ::: {.chanwe-executive-summary ...} divs.
// Pulls meta-rows from doc state automatically.
// =============================================================
// The `brief` executive summary (Ale's pick, 2026-11-19; `chanwe: exec-style:
// brief` or `style="brief"` on the Div): the details as a ledger column (label
// over value, hairlines, no pills), and beside it a smaller title, the takeaway
// as a quote with an orange rule, then the body. A task list in the body reads
// as the recommendations.
#let _chanwe-exec-brief(eyebrow: none, title: none, takeaway: none, meta: (), dark: false, body) = {
  let fg    = if dark { _t.white } else { _t.fg }
  let soft  = if dark { _t.white.transparentize(15%) } else { _t.fg-muted }
  let label = if dark { _t.fg-subtle } else { _t.fg-muted }
  let hair  = if dark { _t.rule-ink } else { _t.rule }
  let rows = meta.map(((lbl, val, ..rest)) => (lbl, val, if rest.len() > 0 { rest.at(0) } else { none }))
  v(10mm)
  grid(
    columns: (44mm, 1fr),
    column-gutter: 12mm,
    // the ledger column
    {
      if eyebrow != none { chanwe-eyebrow(eyebrow, fill: label); v(8mm) }
      for (lbl, val, sub) in rows {
        block(width: 100%, spacing: 0pt, stroke: (top: 0.5pt + hair), inset: (top: 3.2mm, bottom: 6mm), {
          text(font: _t.font-mono, size: 6.6pt, weight: _t.weight-medium, tracking: 0.16em, fill: label, upper(lbl))
          v(1.8mm)
          set par(leading: 0.5em, spacing: 0.4em)
          text(font: _t.font-sans, size: 9.5pt, weight: _t.weight-regular, fill: fg, if type(val) == str { val } else { val.join(", ") })
          if sub != none and sub != "" { linebreak(); text(font: _t.font-sans, size: 9.5pt, weight: _t.weight-body, fill: soft, sub) }
        })
      }
    },
    // the message column
    {
      if title != none {
        block(spacing: 0pt, {
          set text(top-edge: "cap-height", bottom-edge: "baseline")
          set par(leading: 0.42em, spacing: 0pt)
          [#text(font: _t.font-display, size: 34pt, weight: _t.weight-display, tracking: -0.045em, fill: fg, title)#_chanwe-title-dot(34pt)]
        })
        v(9mm)
      }
      if takeaway != none and takeaway != "" {
        block(spacing: 0pt, stroke: (left: 1.2pt + _t.primary), inset: (left: 5mm, y: 1mm),
          text(font: _t.font-serif, style: "italic", size: 19pt, weight: _t.weight-body, fill: soft, takeaway))
        v(8mm)
      }
      set par(leading: 0.68em, spacing: 1.1em, justify: false)
      set text(font: _t.font-sans, size: 10.5pt, weight: _t.weight-body, fill: soft)
      body
    },
  )
}

#let chanwe-exec-summary-page(
  eyebrow: "Executive Summary",
  title: none,
  takeaway: none,
  color: none,
  meta: none,
  style: auto,
  body,
) = context {
  let style = if style == auto { cw-style("exec-style", "page") } else { style }
  if style == "brief" {
    let dark = color == "dark" or color == "primary"
    pagebreak(weak: true)
    let inv = _chanwe-inverse-of(if dark { "dark" } else { color })
    set page(fill: if dark { _t.ink } else if color == "light" or color == "slate" { _t.surface-slate } else { _t.paper },
             header: chanwe-header-auto(inverse: inv), footer: chanwe-footer-auto(inverse: inv))
    _chanwe-exec-brief(eyebrow: eyebrow, title: title, takeaway: takeaway,
      meta: if meta != none { meta } else { _chanwe-doc.get().meta-rows }, dark: dark, body)
    pagebreak(weak: true)
    return
  }

  // `primary` is the obsidian page with the orange Aspa as its signal: orange
  // marks, it does not fill (2026-11-18).
  let signal = color == "primary"
  let color = if signal { "dark" } else { color }
  // Sin color, la página va sobre surface-slate, como la del abstract, que
  // es la misma página con otro nombre.
  let bg = if color == "light" or color == "slate" { _t.surface-slate }
      else if color == "dark"   { _t.ink          }
      else if color == "primary" { _t.primary     }
      else if color == "white"  { _t.white           }
      else                      { _t.surface-slate }
  let inverse = color == "dark" or color == "primary"
  let accent  = if color == "primary" { _t.white } else { _t.primary }
  pagebreak(weak: true)
  if bg != none {
    // Sobre obsidiana o naranja el encabezado y el pie se invierten.
    let inv = _chanwe-inverse-of(color)
    set page(fill: bg, header: chanwe-header-auto(inverse: inv), footer: chanwe-footer-auto(inverse: inv))
    if signal { place(top + right, dy: 2mm, cw-icon("Aspa", fill: _t.primary, width: 10mm)) }
    context {
      let doc = _chanwe-doc.get()
      chanwe-abstract(
        eyebrow: eyebrow,
        title: title,
        meta: if meta != none { meta } else { doc.meta-rows },
        takeaway: takeaway,
        dark: inverse,
        accent: accent,
        on-primary: color == "primary",
        body,
      )
    }
  } else {
    context {
      let doc = _chanwe-doc.get()
      chanwe-abstract(
        eyebrow: eyebrow,
        title: title,
        meta: if meta != none { meta } else { doc.meta-rows },
        takeaway: takeaway,
        dark: inverse,
        accent: accent,
        on-primary: color == "primary",
        body,
      )
    }
  }
  pagebreak(weak: true)
}

// =============================================================
// DOUBLE EXECUTIVE SUMMARY — two summary halves filling one page
// =============================================================
// Each half = 140.5mm (= (297 - 8 top - 8 bottom) / 2).
// margin.top=8mm = header height, margin.bottom=8mm ≈ footer height → rules flush with content.
// Internal helper returns a block (no move wrapper — caller stacks both).
#let _chanwe-exec-half(
  eyebrow:          "Executive Summary",
  title:            none,
  takeaway:         none,
  meta:             (),
  // Status section
  status-label:     none,   // small eyebrow above hero word (e.g. "Convicción")
  status-hero:      none,   // large italic serif word (e.g. "Alza")
  status-kind:      none,   // "good" | "regular" | "bad" — determines color
  status-value:     none,   // 1–5: fills that many scale segments
  status-meta-label: "",    // single meta label shown right of hero word
  status-meta-value: "",    // single meta value shown right of hero word
  drivers:          (),     // max 3 × (dir, title, desc, tag, tag-color) tuples
  drivers-label:    "Factores Clave",  // eyebrow above the driver list
  color:            none,
  content:          [],
  divider:          false,
) = {
  // `primary` is the obsidian half: the status bar and the chips are the signal.
  let color = if color == "primary" { "dark" } else { color }
  let bg = if color == "light" or color == "slate" { _t.surface-slate }
      else if color == "dark"   { _t.ink         }
      else if color == "white"  { _t.white          }
      else                      { _t.paper       }
  // Sobre obsidiana y sobre naranja el texto se invierte; sobre naranja el
  // acento pasa a blanco, porque el naranja ya es el fondo.
  let on-primary  = color == "primary"
  let dark        = color == "dark" or on-primary
  let accent      = if on-primary { _t.white } else { _t.primary }
  let title-color = if dark { _t.white                      } else { _t.fg }
  // El riel se separa con el mismo filete slate que las demás bandas; sobre
  // obsidiana, con el que se dibuja encima.
  let rail-stroke = if on-primary { _t.white.transparentize(60%) } else if dark { _t.rule-ink } else { _t.border-cool }
  let body-color  = if dark { _t.white.transparentize(15%)  } else { _t.fg-muted    }
  let takwy-color = if dark { _t.white                      } else { _t.ink         }
  // La divisoria entre las dos mitades es el mismo filete que cierra el
  // encabezado y abre el pie: `border` a 0.5pt, no el negro de la rampa.
  let div-stroke  = if divider { (bottom: 0.5pt + _t.border) } else { none }
  let lc          = if dark { _t.white.transparentize(45%) } else { _t.fg-muted }
  let vc          = if dark { _t.white                     } else { _t.fg }
  let hair        = if on-primary { _t.white.transparentize(60%) } else if dark { _t.rule-ink } else { _t.rule }

  // El riel izquierdo se arma con las piezas de la tarjeta de KPI: el rótulo
  // con las dos barras naranjas y el nombre en mono, la ficha con marco slate
  // —o rellena de naranja cuando marca movimiento— y la cifra en display
  // pesado sobre obsidiana. Aquí la cifra es la palabra de estado.
  // La ficha es la de variación del KPI: naranja cuando hay movimiento y,
  // si no, rellena de slate —el de los filetes— con el texto en obsidiana.
  // Sobre obsidiana el relleno pasa a ink-soft.
  let chip(t, filled: false) = box(
    fill: if filled { accent } else if on-primary { _t.white.transparentize(80%) } else if dark { _t.ink-soft } else { _t.border-cool },
    radius: _t.radius-pill,
    inset: (x: 1.5mm, y: 1.2mm),
    text(font: _t.font-mono, size: 5.2pt, weight: _t.weight-regular, tracking: 0.1em,
         fill: if filled and on-primary { _t.primary } else if filled { _t.paper } else if dark { _t.white.transparentize(15%) } else { _t.fg },
         upper(str(t))),
  )
  let rail-label(t) = {
    text(font: _t.font-mono, size: 6.3pt, weight: _t.weight-display, tracking: 0.1em,
         fill: accent, "//")
    h(1.8mm)
    text(font: _t.font-mono, size: 6.3pt, weight: _t.weight-regular, tracking: 0.12em,
         fill: vc, upper(str(t)))
  }

  // Status color from kind — lo lleva la barra, no la palabra.
  let s-color = if status-kind == "good"    { _t.exec-status-good }
    else if status-kind == "regular"         { _t.exec-status-regular }
    else if status-kind == "bad"             { _t.exec-status-bad }
    else                                     { accent         }

  // 5-segment fill bar: first status-value segments colored, rest slate
  let filled = if status-value != none { status-value } else { 0 }
  let scale-bar = grid(
    columns: range(5).map(_ => 1fr),
    column-gutter: 1.5mm,
    ..range(5).map(i => {
      rect(width: 100%, height: 4pt, radius: 1pt,
           fill: if i < filled { s-color } else { rail-stroke })
    })
  )

  // Pre-compute left rail
  let left-rail = if status-hero != none or drivers.len() > 0 {
    [
      #set block(spacing: 0pt)
      #set par(spacing: 0pt)
      #if status-hero != none {
        if status-label != none {
          rail-label(status-label)
          v(4.5mm)
        }
        text(font: _t.font-display, size: 26pt, weight: _t.weight-display, tracking: -0.05em,
             fill: vc, str(status-hero))
        // El par de contexto va como la fila ficha + glosa del KPI: la
        // etiqueta en la ficha slate y el valor al lado, en sans chico. En la
        // cabecera no entraba: el riel mide 46mm y la ficha partía en dos.
        if status-meta-label != "" {
          v(2.5mm)
          grid(
            columns: (auto, 1fr),
            column-gutter: 2.5mm,
            align: (left + horizon, left + horizon),
            chip(status-meta-label),
            text(font: _t.font-sans, size: 6.6pt, weight: _t.weight-thin, fill: body-color,
                 str(status-meta-value)),
          )
        }
        v(3mm)
        scale-bar
        v(1.8mm)
        // El pie de la barra es el de la serie del KPI: mono chico, el tipo
        // de estado a la izquierda y el nivel sobre cinco a la derecha.
        grid(
          columns: (1fr, auto),
          align: (left + horizon, right + horizon),
          text(font: _t.font-mono, size: 5.85pt, weight: _t.weight-body, tracking: 0.16em,
               fill: lc, if status-kind != none { upper(str(status-kind)) } else { "" }),
          text(font: _t.font-mono, size: 5.85pt, weight: _t.weight-body, tracking: 0.16em,
               fill: lc, str(filled) + " / 5"),
        )
        if drivers.len() > 0 { v(7mm) }
      }
      #if drivers.len() > 0 {
        rail-label(drivers-label)
        v(5mm)
        line(length: 100%, stroke: 0.3pt + hair)
        // Cada driver es una fila entre filetes, como los hallazgos: la
        // dirección va en la ficha —naranja si se mueve, slate si no— y la
        // etiqueta en la ficha de marco, a la derecha.
        for drv in drivers.slice(0, calc.min(drivers.len(), 3)) {
          let (dir, dtitle, ddesc, dtag, dtag-k) = drv
          let moving  = dir == "up" or dir == "down"
          let dir-sym = if dir == "up" { "▲" } else if dir == "down" { "▼" } else { "—" }
          block(width: 100%, inset: (y: 4mm))[
            #grid(
              columns: (auto, 1fr, auto),
              column-gutter: 2.5mm,
              align: (left + top, left + top, right + top),
              chip(dir-sym, filled: moving),
              {
                text(font: _t.font-display, tracking: -0.05em, size: 7.5pt, weight: _t.weight-display, fill: vc, dtitle)
                if ddesc != "" {
                  v(1.6mm)
                  block(spacing: 0pt)[
                    #set par(leading: 0.35em)
                    #text(font: _t.font-sans, size: 6.5pt, weight: _t.weight-thin, fill: body-color, ddesc)
                  ]
                }
              },
              if dtag != "" {
                chip(dtag, filled: dtag-k == "primary" or dtag-k == "orange")
              } else { [] },
            )
          ]
          line(length: 100%, stroke: 0.3pt + hair)
        }
      }
    ]
  } else {
    [
      #stack(
        dir: ttb, spacing: 7mm,
        ..meta.map(((lbl, val, ..rest)) => chanwe-side-row(
          label: lbl,
          value: if rest.len() > 0 { val + "\n" + rest.at(0) } else { val },
          dark: dark, accent: accent,
        ))
      )
    ]
  }

  block(
    width: 210mm,
    height: 140.5mm,
    fill: bg,
    stroke: div-stroke,
    inset: (x: 18mm, top: 10mm, bottom: 10mm),
    clip: true,
  )[
    #chanwe-eyebrow(eyebrow, dot: accent, fill: if dark { _t.white } else { _t.fg-muted })
    // `above: 0pt` en el bloque del titular: sin eso el espaciado de párrafo
    // del cuerpo (2.6em) se sumaba a los 6mm y el rótulo quedaba a 15mm.
    #v(5mm)
    #if title != none {
      block(above: 0pt, below: 0pt)[
        #set par(leading: 0.75em, justify: false)
        #text(
          font: _t.font-display, size: 36pt, weight: _t.weight-display,
          tracking: -0.05em, fill: title-color, title,
        )#box(width: 8pt, height: 8pt, baseline: -1pt,
          circle(fill: accent, stroke: none))
      ]
      v(10mm)
    }
    #grid(
      columns: (56mm, 1fr),
      column-gutter: 14mm,
      align: (left + top, left + top),
      // left rail — status + drivers or meta rows
      block(
        stroke: (right: 0.5pt + rail-stroke),
        inset: (right: 10mm),
        width: 100%,
      )[#left-rail],
      // right body — la misma columna que la página de abstract: palabra de
      // arranque en serif cursiva naranja a 32pt, resto en negrita, cuerpo en
      // sans a 10pt sobre fg-muted.
      block[
        #set par(leading: 0.65em, justify: true)
        #set text(font: _t.font-sans, size: 10pt, weight: _t.weight-regular, fill: body-color)
        // Sobre obsidiana o naranja la cursiva va en el color del cuerpo: la
        // regla global la pinta de naranja y sobre naranja desaparecía.
        #show emph: it => if dark { text(font: _t.font-serif, style: "italic", weight: _t.weight-body, size: 1.25em, fill: body-color, it.body) } else { it }
        #if takeaway != none {
          let s     = str(takeaway)
          let parts = s.split(" ")
          let fw    = parts.at(0)
          let rest  = if parts.len() > 1 { " " + parts.slice(1).join(" ") } else { "" }
          block(below: 6mm)[
            #set text(hyphenate: false)
            #text(font: _t.font-serif, size: 32pt, weight: _t.weight-body,
                  style: "italic", fill: accent, fw
            )#text(weight: _t.weight-bold, fill: takwy-color, rest)
          ]
        }
        #content
      ],
    )
  ]
}

// Public function — call with [top body][bottom body]
#let chanwe-double-exec-summary(
  // top half
  top-eyebrow:           "Executive Summary",
  top-title:             none,
  top-takeaway:          none,
  top-meta:              (),
  top-status-label:      none,
  top-status-hero:       none,
  top-status-kind:       none,
  top-status-value:      none,
  top-status-meta-label: "",
  top-status-meta-value: "",
  top-drivers:           (),
  top-drivers-label:     "Factores Clave",
  top-color:             none,
  // bottom half
  bot-eyebrow:           "Executive Summary",
  bot-title:             none,
  bot-takeaway:          none,
  bot-meta:              (),
  bot-status-label:      none,
  bot-status-hero:       none,
  bot-status-kind:       none,
  bot-status-value:      none,
  bot-status-meta-label: "",
  bot-status-meta-value: "",
  bot-drivers:           (),
  bot-drivers-label:     "Factores Clave",
  bot-color:             none,
  // two positional content blocks [top][bottom]
  ..bodies,
) = {
  let top-content = bodies.pos().at(0, default: [])
  let bot-content = bodies.pos().at(1, default: [])

  pagebreak(weak: true)

  // margin.top=8mm = header height, margin.bottom=8mm ≈ footer height → rules flush with content edges.
  // El encabezado cae sobre la mitad de arriba y el pie sobre la de abajo:
  // cada uno se invierte según el color de su mitad.
  set page(
    margin: (top: 8mm, bottom: 8mm, x: 18mm), header-ascent: 0pt, footer-descent: 0pt,
    header: chanwe-header-auto(inverse: _chanwe-inverse-of(top-color)),
    footer: chanwe-footer-auto(inverse: _chanwe-inverse-of(bot-color)),
  )

  // block(above/below: 0pt) prevents global body-spacing from leaking around the stack
  // without cascading into the exec-half content (unlike set block which would kill internal spacing).
  block(above: 0pt, below: 0pt, move(dx: -18mm,
    stack(
      dir: ttb,
      spacing: 0pt,
      _chanwe-exec-half(
        eyebrow: top-eyebrow, title: top-title,
        takeaway: top-takeaway, meta: top-meta,
        status-label: top-status-label, status-hero: top-status-hero,
        status-kind: top-status-kind, status-value: top-status-value,
        status-meta-label: top-status-meta-label,
        status-meta-value: top-status-meta-value,
        drivers: top-drivers, drivers-label: top-drivers-label,
        color: top-color, content: top-content,
        divider: true,
      ),
      _chanwe-exec-half(
        eyebrow: bot-eyebrow, title: bot-title,
        takeaway: bot-takeaway, meta: bot-meta,
        status-label: bot-status-label, status-hero: bot-status-hero,
        status-kind: bot-status-kind, status-value: bot-status-value,
        status-meta-label: bot-status-meta-label,
        status-meta-value: bot-status-meta-value,
        drivers: bot-drivers, drivers-label: bot-drivers-label,
        color: bot-color, content: bot-content,
        divider: false,
      ),
    )
  ))

  pagebreak(weak: true)
}

// =============================================================
// CHAPTER SEPARATOR (full-page divider)
// =============================================================
// HTML .chapter-cover layout:
//   - slate background (`surface-slate`), no art
//   - .cc-top   : mark left, doc id right (mono micro-type, white/60)
//   - .cc-mid   : eyebrow + cc-num-row (giant 02 + title block)
//   - .cc-bottom: meta items + page number
// =============================================================
#let chanwe-chapter-divider(
  number: "02",
  eyebrow: "Part 02 · Worked Example",
  title: [Mendoza Wine — \ a sample report.],
  blurb: "A short consultancy brief assembled from every component on the previous pages. Real shape; illustrative numbers.",
  top-left-mark: none,
  top-right-mark: none,
  meta: none,
  page-counter: none,
  // v2 (2026-11-18): `numeral` (the default: the slate page and its giant
  // numeral, now in Schibsted), `series` (slate, one Fundido icon bleeding off
  // the right edge, as the publication series art does) and `series-dark`
  // (the same on obsidian, a small orange icon as the signal). The document
  // default is `chanwe: divider-variant:`; `icon` names the Fundido icon
  // (by default one per divider, in a fixed cycle).
  variant: auto,
  icon: auto,
) = {
  _chanwe-cur-part.update(_ => (number: number, title: title, eyebrow: eyebrow))
  counter("cw-divider").step()

  // The whole divider page is the slate `surface-slate`, two steps under the
  // body's paper, so the part reads as a pause on its own tone (Ale,
  // 2026-11-13). From 3.0.2 until then the upper half carried the series
  // contour art (`01-radar-macro.svg`) on body paper; it is gone.
  context {
  let variant = if variant == auto { cw-style("divider-variant", "numeral") } else { variant }
  let dark = variant == "series-dark"
  let icon = if icon == auto {
    cw-icon-names.at(calc.rem(counter("cw-divider").get().first() + 2, cw-icon-names.len()))
  } else { icon }
  set page(
    paper: _chanwe-paper, margin: 0pt, fill: if dark { _t.ink } else { _t.surface-slate },
    header: none, footer: none,
    background: if variant != "numeral" {
      place(top + left, cw-dot-gradient())
      place(top + right, dx: 52mm, dy: -18mm,
        cw-icon(icon, fill: if dark { _t.ink-light } else { _t.ink }, width: 172mm))
      if dark { place(top + left, dx: 18mm, dy: 18mm, cw-icon(icon, fill: _t.primary, width: 18mm)) }
    } else { none },
  )
  set text(fill: _t.fg)
  // The divider is called from the document body, so it would inherit the
  // body's `justify` (`chanwe.body-justify`, on by default): a long part
  // title then broke over three lines with stretched spacing.
  set par(justify: false)

  if variant != "numeral" {
    let doc = _chanwe-doc.get()
    let pages = if page-counter != none { page-counter } else {
      str(counter(page).get().first()) + " / " + str(counter(page).final().first())
    }
    let fg = if dark { _t.paper } else { _t.fg }
    let soft = if dark { _t.white } else { _t.fg-muted }
    let quiet = if dark { _t.fg-subtle } else { _t.fg-muted }
    block(width: 100%, height: 100%, inset: (x: 18mm, top: 18mm, bottom: 18mm))[
      #set block(spacing: 0pt)
      #set par(spacing: 0pt)
      #v(1fr)
      #block(width: 112mm)[
        #chanwe-eyebrow(upper(_chanwe-clean-str(number)) + "  ·  " + upper(_chanwe-clean-str(eyebrow)), fill: if dark { _t.white } else { _t.fg-muted }, size: 8pt)
        #v(7mm)
        #set par(leading: 0.18em)
        #text(font: _t.font-display, weight: _t.weight-display, size: 51.75pt, tracking: -0.05em, fill: fg, title)#_chanwe-title-dot(51.75pt)
        #v(8mm)
        #set par(leading: 0.65em)
        #text(font: _t.font-sans, size: 13pt, weight: _t.weight-thin, fill: soft, blurb)
      ]
      #v(30mm)
      #move(dx: -18mm, line(length: 100% + 36mm, stroke: 0.5pt + if dark { _t.rule-ink } else { _t.border }))
      #v(3mm)
      #grid(
        columns: (1fr, auto),
        align: (left + horizon, right + horizon),
        {
          set text(font: _t.font-mono, size: 8pt, tracking: 0.18em, fill: quiet)
          upper(_chanwe-clean-str(doc.doc-id))
          if doc.edition != "" { h(14mm); upper(_chanwe-clean-str(doc.edition)) }
        },
        text(font: _t.font-mono, size: 8pt, tracking: 0.18em, fill: quiet, upper(pages)),
      )
    ]
  } else {
    let doc = _chanwe-doc.get()
    let _left  = if top-left-mark != none { top-left-mark } else { doc.doc-id }
    let _right = if top-right-mark != none { top-right-mark } else { doc.edition }
    let _meta  = if meta != none { meta } else {
      doc.meta-rows.slice(0, calc.min(3, doc.meta-rows.len())).map(((l, v, ..)) => (l, v))
    }
    let _pages = if page-counter != none { page-counter } else {
      str(counter(page).get().first()) + " / " + str(counter(page).final().first())
    }

  block(
    width: 100%, height: 100%,
    inset: (x: 18mm, top: 18mm, bottom: 18mm),
  )[
    // ---- TOP: la marca a la izquierda ----
    #block(width: 100%)[
      // Mismo tono que el encabezado y el pie del cuerpo.
      #set text(font: _t.font-mono, size: 7pt, tracking: 0.22em,
                fill: _t.fg-muted)
      #upper(_chanwe-clean-str(doc.taggy))
      #h(3mm)
      #text(fill: _t.primary, "//")
      #h(3mm)
      #upper(_chanwe-clean-str(eyebrow))
    ]

    // ---- RIEL: la metadata gira y corre por el margen derecho, arrancando
    // a la misma altura que la marca ----
    #place(top + right,
      block(width: 8mm, height: 52mm)[
        #place(top + right, rotate(-90deg, origin: top + right,
          box(width: 52mm, align(right,
            text(font: _t.font-mono, size: 6.4pt, tracking: 0.22em,
                 fill: _t.fg-muted, upper(_chanwe-clean-str(_right)))))))
      ])

    #v(1fr)

    // La línea que parte la hoja es un filete suave, no el trazo en tinta.
    #move(dx: -18mm, line(length: 100% + 36mm, stroke: 0.5pt + _t.rule-cool))
    #v(14mm)

    // ---- MIDDLE: numeral gigante · filete · (título · bajada) ----
    #grid(
      columns: (auto, 1fr),
      column-gutter: 26mm,
      align: (left + top, left + top),
      // Numeral gigante, alineado por arriba con el bloque de título.
      // v2: Schibsted, the figures' face (it was Cormorant italic at 220pt).
      text(
        font: _t.font-display, weight: _t.weight-display,
        size: 150pt, tracking: -0.04em, number-type: "lining",
        fill: _t.primary,
        number,
      ),
      stack(
        dir: ttb, spacing: 9mm,
        // Misma familia y prosa que el H1: display, peso 700 y su tracking,
        // y su interlineado propio (0.18em), para no heredar el del cuerpo
        // (`chanwe.body-leading`) cuando el título parte de renglón.
        // El numeral gigante se queda en la serif itálica.
        block({
          set par(leading: 0.18em)
          text(
            font: _t.font-display, weight: _t.weight-display,
            size: 51.75pt, tracking: -0.05em, fill: _t.fg,
            title,
          )
        }),
        // La bajada va en el slate de marca, un escalón más fina.
        block(width: 78mm, text(
          font: _t.font-sans, size: 14pt, weight: _t.weight-thin,
          fill: _t.fg-muted,
          blurb,
        )),
      ),
    )

    #v(24.75mm)

    // ---- BOTTOM: doc-id · edition ----
    #move(dx: -18mm, line(length: 100% + 36mm, stroke: 0.5pt + _t.border))
    #v(3mm)
    #grid(
      columns: (1fr, auto),
      align: (left + horizon, right + horizon),
      {
        // Todo el pie en el mismo tono que el del cuerpo.
        set text(font: _t.font-mono, size: 8pt, tracking: 0.18em,
                 fill: _t.fg-muted)
        upper(_chanwe-clean-str(doc.doc-id))
        if doc.edition != "" {
          h(14mm)
          upper(_chanwe-clean-str(doc.edition))
        }
      },
      text(font: _t.font-mono, size: 8pt, tracking: 0.18em,
           fill: _t.fg-muted, upper(_pages)),
    )
  ]
  }
  }
}

// =============================================================
// BACK COVER
// =============================================================
// HTML .back-cover layout:
//   - black bg + gray radial halo (centered)
//   - top: bc-mark (white wordmark)
//   - middle: italic 36pt tagline ("Less template, more report.")
//   - bc-rule (orange short bar)
//   - bc-grid (3 items: Studio · Web · Document)
//   - bc-arrow (small arrow logo)
//   - bc-bottom (legal · page num)
// =============================================================
#let chanwe-back-cover(
  wordmark-white: none,
  arrow-icon: none,
  tagline-line1: "Less template,",
  tagline-line2: "more report.",
  grid-items: (
    ("Studio",   "Chanwe — Estrategia Activa", "Mendoza · Argentina"),
    ("Web",      "chanwe.com.ar",              "contacto@chanwe.com.ar"),
    ("Document", "CHW-RPT-2026-04",            "Rev. A · 17·04·2026"),
  ),
  legal: "Información confidencial · Prohibida su distribución sin autorización",
  page-counter: "17 / 19",
) = {
  set page(
    paper: _chanwe-paper, margin: 0pt, fill: _t.ink,
    header: none, footer: none,
    background: place(center + horizon,
      circle(radius: 105mm,
        fill: gradient.radial(
          _t.white.transparentize(90%),
          _t.black.transparentize(100%),
        ),
        stroke: none,
      )
    ),
  )
  set text(fill: _t.white)

  block(
    width: 100%, height: 100%,
    inset: (x: 22mm, top: 22mm, bottom: 22mm),
  )[
    // ---- TOP: white wordmark ----
    #if wordmark-white != none {
      image(wordmark-white, height: 14mm)
    } else {
      text(font: _t.font-display, size: 28pt, weight: _t.weight-display, tracking: -0.05em,
           fill: _t.white, "chanwe")
    }

    #v(1fr)

    // ---- TAGLINE: italic 36pt, orange on second line ----
    #block[
      #set par(leading: 0.45em)
      #text(
        font: _t.font-serif, style: "italic", weight: _t.weight-body,
        size: 36pt, tracking: -0.025em, fill: _t.white,
        tagline-line1,
      )
      \
      #text(
        font: _t.font-serif, style: "italic", weight: _t.weight-body,
        size: 36pt, tracking: -0.025em, fill: _t.primary,
        tagline-line2,
      )
    ]

    #v(8mm)
    #line(length: 30mm, stroke: 1.5pt + _t.primary)
    #v(10mm)

    // ---- INFO GRID: 3 columns ----
    #grid(
      columns: (1fr, 1fr, 1fr),
      column-gutter: 8mm,
      ..grid-items.map(((label, val, sub)) => {
        stack(
          dir: ttb, spacing: 3mm,
          text(font: _t.font-mono, size: 7.5pt, weight: _t.weight-medium,
               tracking: -0.05em, fill: _t.white.transparentize(45%),
               upper(label)),
          stack(
            dir: ttb, spacing: 2pt,
            text(font: _t.font-display, tracking: -0.05em, size: 12pt, weight: _t.weight-display,
                 fill: _t.white, val),
            text(font: _t.font-sans, size: 9pt, weight: _t.weight-regular,
                 fill: _t.white.transparentize(35%), sub),
          ),
        )
      })
    )

    #v(1fr)

    // ---- ARROW ICON (small, left-aligned, above bottom) ----
    #if arrow-icon != none {
      image(arrow-icon, width: 14mm)
      v(4mm)
    }

    // ---- BOTTOM: legal + page num + hairline rule ----
    #line(length: 100%, stroke: 0.5pt + _t.white.transparentize(80%))
    #v(3mm)
    #grid(
      columns: (1fr, auto),
      align: (left + horizon, right + horizon),
      text(font: _t.font-mono, size: 7.5pt, weight: _t.weight-medium,
           tracking: 0.18em, fill: _t.white.transparentize(45%),
           upper(legal)),
      text(font: _t.font-mono, size: 7.5pt, weight: _t.weight-medium,
           tracking: 0.18em, fill: _t.white.transparentize(45%),
           upper(page-counter)),
    )
  ]
}// =============================================================
// chanwe-charts.typ — reusable data-viz primitives
// All components consume _t tokens — no hardcoded colors.
// =============================================================

// ---- BAR CHART ----------------------------------------------
// data: array of (label, value) tuples, value ∈ [0, 1]
// threshold: bars at or above this value get full opacity
// label-color: auto resolves to _t.fg-muted
#let chanwe-bar-chart(
  data,
  height:      50mm,
  bar-width:   18mm,
  gap:         5mm,
  label-size:  7.5pt,
  label-color: auto,
  threshold:   0.7,
) = {
  let lc = if label-color == auto { _t.fg-muted } else { label-color }
  align(center,
    stack(dir: ltr, spacing: gap,
      ..data.map(((lbl, val)) =>
        stack(dir: ttb, spacing: 2mm,
          rect(width: bar-width, height: height * (1 - val), fill: none, stroke: none),
          rect(
            width: bar-width,
            height: height * val,
            fill: _t.primary.transparentize(if val >= threshold { 10% } else { 45% }),
            stroke: none,
            // v2 (Q3): bars with the plot's rounded ends.
            radius: chanwe-plot.at("bar-radius") * 0.75pt,
          ),
          align(center, text(size: label-size, fill: lc, lbl)),
        )
      ),
    )
  )
}

// ---- LINE CHART ---------------------------------------------
// series: array of (label, values-array) — all series same length
// x-labels: array of strings for x-axis ticks
#let chanwe-line-chart(
  series,
  x-labels:    (),
  width:       auto,
  height:      60mm,
  label-size:  7pt,
  y-min:       0,
  y-max:       1,
  colors:      auto,
) = {
  // By default the chart takes the width it is given, like a figure.
  if width == auto {
    return layout(s => chanwe-line-chart(series, x-labels: x-labels, width: s.width, height: height,
      label-size: label-size, y-min: y-min, y-max: y-max, colors: colors))
  }
  // The hub's categorical order (tokens.typ `chanwe-plot.categorical`, v2):
  // the accent first, `chart-red` last, away from `primary` (dE00 5.0). Pass
  // `colors:` for a focus chart (orange plus the slate ramp, Q3 C1).
  let palette = if colors == auto {
    chanwe-plot.at("categorical")
  } else { colors }
  let n = if series.len() > 0 { series.first().at(1).len() } else { 0 }
  if n == 0 { return [] }
  let x-step = if n > 1 { width / (n - 1) } else { width }
  let y-range = y-max - y-min

  // v2 chart grammar, the same as chanwer: horizontal slate gridlines only, no
  // frame, round line ends, mono axis labels, a dot legend over the plot.
  // Sin cortar: el gráfico se dibuja con `place` dentro de un bloque de alto
  // fijo, así que partirlo no reparte el contenido —lo deja colgando fuera de
  // la caja de texto—. Si no entra, pasa entero a la página siguiente.
  let named = series.filter(((name, _)) => name != none and name != "")
  block(width: width, breakable: false, below: 6mm)[
    #set block(spacing: 0pt)
    #if named.len() > 0 {
      for (si, (name, _)) in series.enumerate() {
        box(cw-dot(palette.at(calc.rem(si, palette.len()))))
        h(1.4mm)
        text(font: _t.font-mono, size: label-size - 1pt, tracking: 0.08em, fill: _t.fg-muted, upper(name))
        h(4mm)
      }
      v(3mm)
    }
    #block(width: width, height: height + 6mm)[
      #for g in range(5) {
        place(top + left, dy: height * g / 4,
          line(length: width, stroke: 0.5pt + _t.rule))
      }
      #for (si, (name, vals)) in series.enumerate() {
        let col = palette.at(calc.rem(si, palette.len()))
        for i in range(vals.len() - 1) {
          let x1 = x-step * i
          let y1 = height * (1 - (vals.at(i) - y-min) / y-range)
          let x2 = x-step * (i + 1)
          let y2 = height * (1 - (vals.at(i + 1) - y-min) / y-range)
          place(top + left, dx: x1, dy: y1,
            line(end: (x2 - x1, y2 - y1), stroke: (paint: col, thickness: 1.5pt, cap: "round")))
        }
      }
      #for (i, lbl) in x-labels.enumerate() {
        let edge = if i == 0 { left } else if i == x-labels.len() - 1 { right } else { center }
        let slot = 24mm
        let dx = if i == 0 { 0mm } else if i == x-labels.len() - 1 { width - slot } else { x-step * i - slot / 2 }
        place(top + left, dx: dx, dy: height + 2.2mm,
          box(width: slot, align(edge,
            text(font: _t.font-mono, size: label-size - 1pt, tracking: 0.04em, fill: _t.fg-muted, lbl))))
      }
    ]
  ]
}// =================================================================
// chanwe-site.typ — the blocks of chanwe.ar's home, for paper.
//
// A shared partial + filter pair (chanwe-site.lua), read by the report and the
// book; the HTML format draws the same Divs from chanwe-brand-rules.scss.
//
//   chanwe-chapter-label  a short rule, `/ 07` and the name in mono
//   chanwe-statement-rows giant numerals beside statements, hairlines between
//   chanwe-proof-card     the obsidian band: a huge figure, its label, a story
//   chanwe-photo-hero     a rounded photo band with white display type
//   chanwe-giant-word     the real wordmark, huge, with the photo inside it
//   chanwe-photo-cover-page  the book's cover, and `chanwe.cover-variant: photo`
//
// White type is for the photograph only; on plain obsidian text stays
// white (CLAUDE.md, "Text on obsidian", 2026-11-19). No colour or weight is written.
// =================================================================

#let _site-art = _chanwe-assets + "bg_mountains.jpg"

#let chanwe-chapter-label(number: none, body) = block(above: 12mm, below: 3mm, sticky: true,
  grid(columns: (8mm, auto), column-gutter: 3mm, align: (left + horizon, left + horizon),
    rect(width: 100%, height: 0.75pt, fill: _t.primary, stroke: none),
    {
      set text(font: _t.font-mono, size: 7.5pt, weight: _t.weight-medium, tracking: 0.14em, fill: _t.fg-muted)
      if number != none { text(fill: _t.fg, "/ " + number); h(3mm) }
      upper(body)
    }))

#let chanwe-statement-rows(items) = block(above: 8mm, below: 8mm, {
  for (i, it) in items.enumerate() {
    if i > 0 { line(length: 100%, stroke: cw-hairline + _t.rule) }
    block(width: 100%, inset: (y: 7mm), breakable: false,
      grid(columns: (42mm, 1fr), align: (left + top, left + top),
        text(font: _t.font-display, size: 58pt, weight: _t.weight-bold, tracking: -0.05em, fill: _t.fg,
          top-edge: "cap-height", bottom-edge: "baseline",
          if i < 9 { "0" + str(i + 1) } else { str(i + 1) }),
        {
          set par(justify: false, leading: 0.5em, spacing: 0.8em)
          set text(font: _t.font-sans, size: 14pt, weight: _t.weight-regular, fill: _t.fg, hyphenate: false)
          show strong: set text(fill: _t.fg)
          it
        }))
  }
  line(length: 100%, stroke: cw-hairline + _t.rule)
})

#let chanwe-proof-card(figure: none, label: none, kicker: none, title: none, body) = block(above: 8mm, below: 8mm, breakable: false,
  cw-band(inset: (x: 10mm, y: 10mm), grid(columns: (58mm, 1fr), column-gutter: 8mm, align: (left + horizon, left + top),
    stack(dir: ttb, spacing: 5mm,
      if figure != none {
        text(font: _t.font-display, size: 62pt, weight: _t.weight-bold, tracking: -0.05em, fill: _t.white,
          top-edge: "cap-height", bottom-edge: "baseline", figure)
      },
      if label != none { cw-label(label, fill: _t.fg-subtle) },
    ),
    {
      set par(justify: false, leading: 0.6em, spacing: 0.8em)
      set block(spacing: 0pt)
      if kicker != none { block(below: 3mm, cw-label(kicker, fill: _t.fg-subtle)) }
      if title != none {
        block(below: 3mm, text(font: _t.font-display, size: 16pt, weight: _t.weight-display, tracking: -0.04em, fill: _t.white, hyphenate: false, title))
      }
      set text(size: 9.5pt, weight: _t.weight-body, fill: _t.white)
      show strong: set text(fill: _t.white)
      body
    })))

// The photograph, covering its box, darkened with obsidian towards the foot.
#let _site-photo(art) = {
  layout(size => {
    let natural = measure(image(art))
    let ratio = natural.width / natural.height
    let w = calc.max(size.width / 1pt, size.height / 1pt * ratio) * 1pt
    let h = w / ratio
    place(top + left, dx: -(w - size.width) * 0.62, dy: -(h - size.height) * 0.4, image(art, width: w, height: h))
  })
  place(top + left, rect(width: 100%, height: 100%, stroke: none, fill: gradient.linear(angle: 90deg,
    (_t.ink.transparentize(14%), 0%), (_t.ink.transparentize(24%), 45%), (_t.ink.transparentize(3%), 100%))))
  // The dot field of every dark surface.
  place(top + left, rect(width: 100%, height: 100%, stroke: none, fill: cw-dot-field()))
}

#let _site-dot-pill(body) = box(stroke: 0.75pt + _t.white.transparentize(55%), radius: _t.radius-pill, inset: (x: 3mm, y: 2mm),
  stack(dir: ltr, spacing: 2mm,
    circle(radius: 1.1pt, fill: _t.primary, stroke: none),
    text(font: _t.font-mono, size: 6.5pt, weight: _t.weight-medium, tracking: 0.16em, fill: _t.white, upper(body))))

#let _site-title(size, body) = {
  set par(justify: false, leading: 0.2em)
  text(font: _t.font-display, size: size, weight: _t.weight-display, tracking: -0.05em, fill: _t.white, hyphenate: false, body)
  _chanwe-title-dot(size)
}

#let chanwe-photo-hero(kicker: none, title: none, lede: none, art: _site-art, height: 92mm) = block(above: 8mm, below: 8mm, breakable: false,
  block(width: 100%, height: height, radius: _t.radius-band, clip: true, fill: _t.ink, {
    _site-photo(art)
    place(top + left, block(width: 100%, height: 100%, inset: 9mm, {
      if kicker != none { _site-dot-pill(kicker) }
      set block(spacing: 0pt)
      set par(spacing: 0pt)
      v(1fr)
      if title != none { _site-title(34pt, title) }
      if lede != none {
        v(3mm)
        set par(justify: false, leading: 0.4em)
        text(font: _t.font-serif, size: 15pt, style: "italic", weight: _t.weight-regular, fill: _t.white, lede)
      }
    }))
  }))

// The real wordmark with the photograph inside it, never a font: a generated
// vector asset (scripts/build-giant-word.rb), shared with the HTML format.
// `variant: "plain"` (2026-11-18): the obsidian wordmark on the faint dot
// field, no photograph and no Aspa.
#let chanwe-giant-word(caption: none, variant: "photo") = block(above: 10mm, below: 8mm, breakable: false, width: 100%, {
  if variant == "plain" {
    layout(size => block(width: 100%, height: size.width * 365 / 1710 + 16mm, spacing: 0pt, {
      place(top + left, cw-dot-gradient())
      pad(y: 8mm, image(_chanwe-assets + "Logo_Negro.svg", width: 100%))
    }))
  } else {
    image(_chanwe-assets + "chanwe-giant-word.svg", width: 100%)
  }
  if caption != none {
    v(6mm)
    align(center, cw-label(caption))
  }
})

// `chanwe.cover-variant: photo`: the whole page is the site's hero.
#let chanwe-photo-cover-page(title: none, subtitle: none, badge: none, doc-id: none, edition: none, date: none,
  meta-rows: (), art: none, wordmark: none) = page(paper: _chanwe-paper, margin: 7mm, header: none, footer: none,
  numbering: none, fill: _t.paper, background: none, foreground: none,
  block(width: 100%, height: 100%, radius: _t.radius-band, clip: true, fill: _t.ink, {
    _site-photo(if art != none { art } else { _site-art })
    place(top + left, block(width: 100%, height: 100%, inset: 12mm, {
      set par(justify: false)
      grid(columns: (1fr, auto), align: (left + horizon, right + horizon),
        image(if wordmark != none { wordmark } else { _chanwe-assets + "Logo_Papel.svg" }, height: 9mm, fit: "contain"),
        if badge != none and badge != "" { _site-dot-pill(_chanwe-clean-str(badge)) })
      v(1fr)
      if title != none { _site-title(54pt, title) }
      if subtitle != none {
        v(5mm)
        set par(leading: 0.42em)
        text(font: _t.font-serif, size: 19pt, style: "italic", weight: _t.weight-regular, fill: _t.white, subtitle)
      }
      v(10mm)
      line(length: 100%, stroke: 0.5pt + _t.white.transparentize(60%))
      v(4mm)
      if meta-rows.len() > 0 {
        grid(columns: (1fr,) * calc.min(meta-rows.len(), 3), column-gutter: 6mm,
          ..meta-rows.slice(0, calc.min(meta-rows.len(), 3)).map(((label, value, ..rest)) => {
            text(font: _t.font-mono, size: 6.5pt, weight: _t.weight-medium, tracking: 0.16em, fill: _t.white.transparentize(25%), upper(_chanwe-clean-str(label)))
            v(1.6mm)
            text(font: _t.font-sans, size: 10pt, weight: _t.weight-regular, fill: _t.white, _chanwe-clean-str(value))
          }))
      }
    }))
  }))
// =============================================================
// MAIN TEMPLATE FUNCTION (called by typst-show.typ)
// =============================================================
#let chanwe-report(
  // metadata
  title: "Untitled",
  subtitle: none,
  author: "Chanwe Studio",
  date: "",
  lang: "en",           // Quarto's `lang:` — hyphenation, smart quotes; crossref labels follow it too
  doc-id: "SERIES-A #0934",
  edition: "Edition 01 / 2026",
  chapter: "Chapter",
  section: "",
  topic: "",
  rail-eyebrow: "SEC.01",
  taggy: "CW- MACRO LAB",
  // Las tres filas del masthead: las usan la portada y la contratapa.
  hero-caption-1: "32°53'24.8\"S  68°50'45.6\"W",
  hero-caption-2: "ELEV: 6967M // CERRO ACONCAGUA",
  hero-caption-3: "CORDILLERA PRINCIPAL · MENDOZA, AR",
  cover-eyebrow: none,      // overrides rail-eyebrow on the cover page only
  // assets
  hero-image: none,
  wordmark: none,
  meta-rows: (
    ("Author", "Chanwe Studio", "Estrategia Activa"),
  ),
  // toggles
  cover: true,
  // toc
  toc-eyebrow: "Document map",
  toc-title: "Agenda",
  toc-lede: none,
  toc: true,
  // abstract
  abstract: true,
  abstract-eyebrow: "Abstract",
  abstract-title: none,
  abstract-text: none,
  abstract-keywords: (),
  abstract-status: none,
  abstract-show: (),
  abstract-takeaway: none,   // string — first letter gets drop-cap treatment
  // back cover
  back-cover: true,
  back-cover-tagline-1: "Less template,",
  back-cover-tagline-2: "more report.",
  back-cover-cols: (),
  // edge label (vertical text on right side of cover + back cover)
  cover-edge: none,
  // ── portada ──────────────────────────────────────────────────
  // research (default) | photo | paper | photo-obsidian | series.
  // "hero" se retiro el 2026-11-18.
  cover-variant: "research",
  cover-icon: none,                 // the Fundido icon of the `series` cover (default Onda)
  // ── variantes v2 (2026-11-18): cada una es una opción del YAML (`chanwe:`)
  // con la de hoy como valor por defecto ───────────────────────────
  back-cover-variant: "research",   // research | aspa | orange | mark
  chapter-band: "numeral",          // numeral | icon (un ícono Fundido fantasma en la banda)
  agenda-style: "band",             // band | paper | timeline
  findings-numeral: "orange",       // orange | slate
  task-style: "square",             // square | round (unified with the kit, 2026-11-18)
  table-style: "open",              // open | pane
  eyebrow-style: "dot",             // dot | rule (the orange rule, opt-in for documents)
  divider-variant: "numeral",       // numeral | series | series-dark
  quote-style: "serif",             // serif | display | serif-art
  exec-style: "page",               // page | brief (the executive summary page)
  // publication cover
  publication-period: none,
  publication-edition: none,
  publication-art: none,
  publication-audience: "PÚBLICO",
  publication-series: "CHANWE / RESEARCH",
  publication-location: "MENDOZA / ARGENTINA",
  publication-copyright: "PROHIBIDA SU REPRODUCCIÓN SIN AUTORIZACIÓN | TODOS LOS DERECHOS RESERVADOS",
  // page
  page-bg: _t.paper,
  second-page-bg: _t.paper,   // fill for the TOC/abstract page (metallic default)
  // body text
  body-size:    none,   // e.g. 10pt — overrides default 11pt
  body-leading: none,   // e.g. 0.9em — overrides default 0.85em
  body-justify: none,   // true / false — overrides default false
  body-color:   none,   // rgb color — overrides default _t.fg
  body-spacing: none,   // e.g. 2.4em — space between body paragraphs
  // body
  body,
) = {
  // Pandoc escapes `/`, `-`, `_` inside quoted YAML strings (`\/\/` for a
  // `//`); the captions are printed as text, so they go through the clean
  // helper once, here, like doc-id and edition below.
  let hero-caption-1 = _chanwe-clean-str(hero-caption-1)
  let hero-caption-2 = _chanwe-clean-str(hero-caption-2)
  let hero-caption-3 = _chanwe-clean-str(hero-caption-3)
  // ---- store metadata in global state -----------------------
  _chanwe-doc.update((doc-id: _chanwe-clean-str(doc-id), edition: _chanwe-clean-str(edition), taggy: taggy, meta-rows: meta-rows, section: section, topic: topic))

  _cw-style.update(s => s + (
    assets: _chanwe-assets, findings-numeral: findings-numeral, task-style: task-style,
    quote-style: quote-style, chapter-band: chapter-band, divider-variant: divider-variant,
    agenda-style: agenda-style, table-style: table-style, eyebrow-style: eyebrow-style,
    exec-style: exec-style,
  ))

  // ---- global text + page defaults ---------------------------
  set page(fill: page-bg)
  set text(font: _t.font-sans, size: 11pt, weight: _t.weight-body, fill: _t.body-fg, lang: lang)
  set par(leading: 0.85em, justify: false, spacing: 1.0em)
  // El código lo colorea Typst con el tema de marca (assets/chanwe.tmTheme):
  // palabras clave en naranja, cadenas y nombres en obsidiana, comentarios en
  // fg-subtle. El texto base hereda body-fg, como la prosa.
  set raw(theme: _chanwe-assets + "chanwe.tmTheme")
  // The code block is dark (brand-v2 §6) and takes the dark theme; inline code
  // stays the slate pill with the light one.
  show raw.where(block: true): set raw(theme: _chanwe-assets + "chanwe-dark.tmTheme")
  set heading(numbering: "1.1.1.")

  // ---- inline rules (apply to entire document) ---------------
  // La cursiva cambia de familia —Satoshi a Cormorant Garamond—, y la serif
  // tiene una altura de x menor: 0.386em contra 0.48em (Satoshi Light, el
  // corte del cuerpo). Al mismo cuerpo se leia mas chica que el texto que la
  // rodea. El factor iguala esas dos alturas (0.48 / 0.386 ≈ 1.25). Con
  // Inter (0.546em) era 1.414.
  show emph: it => text(font: _t.font-serif, style: "italic", weight: _t.weight-body,
                        size: 1.25em, fill: _t.body-fg, it.body)
  show strong: it => text(weight: _t.weight-display, fill: _t.body-fg, it.body)
  // La matemática en línea va en el negro de los titulares, no en el slate
  // del cuerpo, y un décimo más grande: Computer Modern tiene la x más baja
  // que Satoshi y a cuerpo igual se veía chica. La de bloque conserva su panel
  // y su gris apagado.
  show math.equation.where(block: false): set text(fill: _t.fg, size: 1.1em)
  // Superíndice y subíndice un poco más grandes que el 0.6em de fábrica.
  set super(size: 0.68em)
  set sub(size: 0.68em)
  // v2: a pane on the slate tint, 16px corners.
  show math.equation.where(block: true): it => block(
    width: 100%,
    fill: _t.tint,
    stroke: cw-hairline + _t.rule,
    radius: _t.radius-surface,
    inset: (x: 10mm, y: 8mm),
  )[
    #set text(fill: _t.fg-muted, weight: _t.weight-thin)
    #align(center, it)
  ]
  show link: it => underline(stroke: 0.6pt + _t.primary, offset: 2pt, text(fill: _t.primary, it))
  // El chip de codigo en linea. Un `box` inline no conserva la base de su
  // contenido: el inset vertical la empuja hacia arriba, asi que la mono
  // quedaba flotando sobre la base del cuerpo. `baseline` la baja 1 a 1, y
  // este valor sale de medir el PDF: depende del inset y del cuerpo, asi que
  // si se toca cualquiera de los dos hay que volver a medirlo.
  //
  // El alto de la pastilla (12.48pt) queda por debajo del alto de linea del
  // cuerpo, asi que un renglon con chip no separa mas que uno sin chip.
  // Medido: 17.64pt de interlineado en ambos casos. Subir mas el inset o el
  // cuerpo rompe esa paridad.
  // Inline code, unified with the kit (2026-11-18): orange mono, no pill.
  show raw.where(block: false): it => text(font: _t.font-mono, size: 0.95em, fill: _t.primary, it)

  // El panel de código va con el mismo marco slate que el chip en línea y el
  // callout —un filete fino a todo el contorno, no un canto naranja— y con
  // las esquinas a 3pt (los 4px de la marca), que es el radio de todos los paneles del reporte.
  // Entero o a la página siguiente: partido, el rótulo "# python · N lines"
  // quedaba solo al pie de una página y el código arrancaba en la otra con un
  // marco nuevo, como si fueran dos paneles.
  // v2: the code block is the lighter obsidian (cw-code-block, chanwe-v2.typ).
  show raw.where(block: true): cw-code-block

  // ---- notas al pie -------------------------------------------
  // Typst las deja en negro y con un filete negro al 30%. La nota es material
  // de servicio, como el pie de pagina: mismo tono (`ink-fg`) y un filete
  // slate en vez del negro.
  set footnote.entry(separator: line(length: 12mm, stroke: 0.5pt + _t.rule-cool), gap: 0.7em, clearance: 4mm)
  show footnote.entry: it => {
    set text(font: _t.font-sans, size: 7.6pt, weight: _t.weight-body, fill: _t.fg-muted)
    set par(leading: 0.55em, spacing: 0.6em)
    it
  }

  // ---- headings ----------------------------------------------
  // Un encabezado sin numerar (`{.unnumbered}` → `numbering: none`) no
  // muestra el contador: en el lugar del numeral va un filete corto en
  // naranja, centrado en la altura de mayúsculas del titular y a la escala
  // del numeral que reemplaza —largo 1.5× su cuerpo, grosor con él—, así el
  // H1 lo lleva grande y el H4 chico. Antes el numeral salía igual y
  // mostraba el valor del último encabezado numerado.
  //
  // Orange is the chapter's alone (decided 2026-11-05): the H1 keeps its
  // numeral —or its rule— in `primary`; from the H2 down the numeral and the
  // rule are `fg-muted`. With every level in orange nothing on the page was
  // the accent, and the agenda repeated it line after line.
  let _h-mark(it, numeral, size, fill: _t.fg-muted) = if it.numbering != none {
    (align: left + bottom, body: numeral)
  } else {
    (align: left + horizon,
     body: box(width: size * 1.5, height: 0.5pt + size * 0.03, fill: fill))
  }
  show heading.where(level: 1): it => {
    pagebreak(weak: true)
    // The header's rule sits 7mm above the text block; the band floats 5mm under it.
    v(-2mm)
    // v2-print: the chapter opener is the obsidian band (brand-v2 §2, §7):
    // floating inside the text block with its 24px corners, the dot field and
    // the neutral sheen — no longer a slab bled from edge to edge. The eyebrow
    // rule, the numeral and the title stay inside.
    cw-band(inset: (left: 12mm, right: 12mm, top: 12mm, bottom: 11mm))[
      #block(above: 0pt, below: 0pt, rect(width: 50pt, height: 0.9pt, fill: _t.primary, stroke: none))
      #v(10mm)
      // v2: the numeral is Schibsted (figures are display type), orange, at
      // the title's size; it was Cormorant italic at 50pt until 2026-11-18.
      #let mark = _h-mark(it, text(font: _t.font-display, weight: _t.weight-display,
        size: 33pt, tracking: -0.03em, fill: _t.primary, number-type: "lining", number-width: "tabular",
        _pad2(counter(heading).get().first())), 33pt, fill: _t.primary)
      // `chapter-band: icon`: the chapter's Fundido icon, in `ink-light`, cut
      // by the band's right corner. One icon per chapter, in a fixed cycle.
      #if cw-style("chapter-band", chapter-band) == "icon" {
        let n = counter(heading).get().first()
        place(top + right, dx: 12mm + 14mm, dy: -12mm - 18mm,
          cw-icon(cw-icon-names.at(calc.rem(calc.max(n, 1) - 1, cw-icon-names.len())), fill: _t.ink-light, width: 62mm))
      }
      #grid(
        columns: (auto, 1fr),
        column-gutter: 8mm,
        align: (mark.align, left + bottom),
        mark.body,
        block()[
          #set par(leading: 0.18em)
          // Mismo peso que el titular de portada.
          #text(font: _t.font-display, size: 33pt, weight: _t.weight-display,
               tracking: -0.05em, fill: _t.white, it.body)#_chanwe-title-dot(33pt)
        ],
      )
    ]
    // The air between the band and the first paragraph.
    v(12mm)
  }
  show heading.where(level: 2): it => block(above: 12mm, below: 6mm)[
    #set par(leading: 0.2em)
    #let mark = _h-mark(it, text(font: _t.font-display, weight: _t.weight-medium,
      size: 19pt, tracking: -0.02em, fill: _t.fg-muted, number-type: "lining", number-width: "tabular",
      counter(heading).display("1.1")), 19pt)
    #grid(
      columns: (auto, 1fr),
      column-gutter: 6mm,
      align: (mark.align, left + bottom),
      mark.body,
      text(font: _t.font-display, size: 19pt, weight: _t.weight-display,
           tracking: -0.05em, fill: _t.fg, it.body),
    )
    #v(0mm)
    #line(length: 100%, stroke: 0.5pt + _t.neutral-300)
  ]
  // H3 y H4 son el H2 a menor cuerpo: mismo numeral serif en cursiva, mismo
  // peso del titular, y el numeral a la misma proporción del titular que en
  // el H2 (18.75 sobre 19). Antes el H3 llevaba el numeral en mono y el H4 en
  // Cormorant y a peso 700, y la escala se rompía a cada nivel.
  show heading.where(level: 3): it => block(above: 10mm, below: 5.5mm)[
    #set par(leading: 0.2em)
    #let mark = _h-mark(it, text(font: _t.font-display, weight: _t.weight-medium,
      size: 15pt, tracking: -0.02em, fill: _t.fg-muted, number-type: "lining", number-width: "tabular",
      counter(heading).display("1.1.1")), 15pt)
    #grid(
      columns: (auto, 1fr),
      column-gutter: 4.7mm,
      align: (mark.align, left + bottom),
      mark.body,
      text(font: _t.font-display, size: 15pt, weight: _t.weight-display,
           tracking: -0.05em, fill: _t.fg, it.body),
    )
  ]
  show heading.where(level: 4): it => block(above: 8mm, below: 4mm)[
    #set par(leading: 0.2em)
    // Dos puntos por debajo del titular: a cuatro cifras el numeral ya
    // pesa bastante y a la proporción del H2 se comía el título.
    #let mark = _h-mark(it, text(font: _t.font-display, weight: _t.weight-medium,
      size: 14pt, tracking: -0.02em, fill: _t.fg-muted, number-type: "lining", number-width: "tabular",
      counter(heading).display("1.1.1.1")), 14pt)
    #grid(
      columns: (auto, 1fr),
      column-gutter: 4.4mm,
      align: (mark.align, left + bottom),
      mark.body,
      text(font: _t.font-display, size: 14pt, weight: _t.weight-display,
           tracking: -0.05em, fill: _t.fg, it.body),
    )
  ]
  // H5 y H6 son rótulos de bloque: punto y versalita en mono, sin filete.
  // El punto y el texto van en una grilla a `horizon`: el cuadro del texto
  // corre de la línea base a la altura de mayúsculas (los bordes por
  // defecto de Typst), así que el centro del punto cae exactamente en el
  // centro de las versales. Con un `box` en línea y `baseline` a mano
  // quedaba medio punto bajo. El H6 es el mismo rótulo con el punto en slate.
  let _label-heading(body, dot: _t.primary) = grid(
    columns: (auto, 1fr),
    column-gutter: 6pt,
    align: (horizon, horizon),
    circle(radius: 2.5pt, fill: dot),
    text(font: _t.font-mono, size: 8pt, weight: _t.weight-medium,
         tracking: 0.18em, fill: _t.fg, upper(body)),
  )
  show heading.where(level: 5): it => block(above: 10mm, below: 4mm,
    _label-heading(it.body))
  show heading.where(level: 6): it => block(above: 10mm, below: 4mm,
    _label-heading(it.body, dot: _t.fg-muted))

  // ---- lists -------------------------------------------------
  // Satoshi no trae el `◦` (U+25E6) y Typst lo buscaba en la fuente que
  // hubiera: era Inter mientras estuvo en el pool, y sin ella, Arial del
  // sistema. JetBrains Mono, de la marca, lo trae.
  set list(marker: ([•], text(font: _t.font-mono, [◦]), [–]))

  // ---- quote (Pandoc/Quarto blockquotes) ---------------------
  // Panel en el slate hundido con el canto naranja: la cita de terceros se
  // lee como un aparte, no como un renglón con un filete al lado. El aire
  // vertical triplica el alto de una sola línea.
  // El panel va un paso de slate más claro que el abstract y el código
  // (`surface-sunken`, no `surface-slate`): la cita es un aparte, no un
  // bloque de interfaz. Vale igual para `> …` y para `#pullquote`, que
  // emite este mismo `quote`.
  // v2-print: the quote is a pane (white, hairline, 16px), no orange edge.
  // The orange is one dot before the attribution.
  // The pull quote, unified with the kit (2026-11-18): display type
  // (Schibsted 600, no serif) on a pane, the attribution an orange dot and a
  // mono label. The serif stays for the great quotes' `serif` styles.
  show quote: it => cw-pane(
    above: 6mm, below: 6mm,
    radius: _t.radius-pane,
    inset: (x: _t.space-lg, y: _t.space-md + 1mm),
  )[
    #set par(leading: 0.42em, spacing: 0.5em)
    #text(font: _t.font-display, size: 12.5pt, weight: _t.weight-display, tracking: -0.02em, fill: _t.fg, it.body)
    #if it.attribution != none {
      v(2.6mm)
      cw-dot(_t.primary, size: 4pt, baseline: -1pt)
      h(_t.space-xs)
      cw-label(it.attribution, size: 6.5pt)
    }
  ]

  // ---- tables -----------------------------------------------
  // Los dos filetes que encierran el encabezado van en slate, no en el negro
  // de la rampa: la tabla se lee con el mismo peso de línea que la banda de
  // hallazgos y el marco del callout.
  // v2-print: a table is a pane (white, hairline, the dense 12px corners)
  // with its header row on the slate tint and hairline rows; no outer rules.
  // Tables (unified with the kit, 2026-11-18): `open` by default (no pane,
  // no fill, the header a mono label in `fg-subtle`, hairlines between rows);
  // `chanwe: table-style: pane` keeps the framed pane with the tint header.
  let _pane-tables = table-style == "pane"
  set table(
    fill: (col, row) => if _pane-tables and row == 0 { _t.tint } else { none },
    stroke: (col, row) => (
      bottom: if row == 0 { 0.5pt + _t.rule } else { 0.3pt + _t.rule },
    ),
    inset: if _pane-tables { (x: 4mm, y: 3.5mm) } else { (x: 2.5mm, y: 3mm) },
  )
  // Pandoc writes a bare `table.hline()` under the header row, which Typst
  // draws 1pt black; it is the same hairline as the header's own rule.
  set table.hline(stroke: 0.5pt + _t.rule)
  // The pane takes the table's own width (a narrow table does not get a
  // full-width frame) and keeps the table breakable.
  show table: it => if _pane-tables { layout(size => {
    let w = calc.min(measure(it, width: size.width).width, size.width)
    block(
      stroke: cw-hairline + _t.rule, radius: _t.radius-pane, clip: true,
      fill: _t.pane, width: w, breakable: true, it,
    )
  }) } else { it }
  show table.cell: set text(
    size: 7pt, weight: _t.weight-thin, fill: _t.fg,
  )
  // Los nombres de columna en mono y negrita: son rótulos, no prosa. Un punto
  // por debajo del cuerpo, así el peso los distingue sin que el cuerpo mande.
  show table.cell.where(y: 0): set text(
    font: _t.font-mono, size: 6pt, weight: _t.weight-medium,
    tracking: 0.1em, fill: if _pane-tables { _t.fg-muted } else { _t.fg-subtle },
  )
  // A cell across the whole table is a title row (chanwe_kbl), not a column label.
  show table.cell.where(y: 0): it => if it.colspan > 1 { it } else { upper(it) }
  show figure.where(kind: table): it => {
    v(12mm, weak: true)
    it.body
    v(2mm)
    it.caption
    v(12mm, weak: true)
  }
  show figure.where(kind: image): it => {
    v(12mm, weak: true)
    it.body
    v(2.6mm)
    it.caption
    v(12mm, weak: true)
  }
  // Las figuras y tablas nativas de Quarto (las que llevan pie, con o sin
  // identificador) salen con el marco de `.chanwe-figure-frame`: rótulo y pie
  // arriba, sello de la serie abajo. Quarto las emite con `kind:
  // "quarto-float-fig"` / `"quarto-float-tbl"`, no como `image` / `table`,
  // así que las dos reglas de arriba no las alcanzan.
  show figure.where(kind: "quarto-float-fig"): it => chanwe-native-figure(it)
  show figure.where(kind: "quarto-float-tbl"): it => chanwe-native-figure(it)
  // Keep 3× more clear space after a figure or table footer before prose resumes.
  show figure: set block(above: 11mm, below: 12mm)
  show figure.caption: cw-figure-caption

  // ---- COVER (optional) -------------------------------------
  let _v2-eyebrow = if cover-eyebrow != none { cover-eyebrow } else { rail-eyebrow }
  let _v2-meta = meta-rows.map(((l, v, ..)) => (l, v))
  if cover and cover-variant == "paper" {
    chanwe-cover-paper(title: title, subtitle: subtitle, eyebrow: _v2-eyebrow,
      top-lines: (_chanwe-clean-str(edition), _chanwe-clean-str(publication-series)),
      meta-rows: _v2-meta, place-label: _chanwe-clean-str(publication-location))
  } else if cover and cover-variant == "photo-obsidian" {
    chanwe-cover-photo-obsidian(title: title, subtitle: subtitle, eyebrow: _v2-eyebrow,
      image-path: if hero-image != none { _chanwe-clean-path(hero-image) } else { none },
      edition: _chanwe-clean-str(edition), meta-rows: _v2-meta)
  } else if cover and cover-variant == "series" {
    chanwe-cover-series(title: title, subtitle: subtitle,
      series: _chanwe-clean-str(publication-series), place-label: _chanwe-clean-str(publication-location),
      icon: if cover-icon != none { cover-icon } else { "Onda" })
  } else if cover and cover-variant == "photo" {
    // The site's hero as the whole page (chanwe-site.typ).
    chanwe-photo-cover-page(
      title: title, subtitle: subtitle, badge: taggy, doc-id: doc-id, edition: edition,
      date: date, meta-rows: meta-rows, art: hero-image, wordmark: wordmark,
    )
  } else if cover {
    chanwe-cover-page(
      badge: taggy,
      hero-caption-1: hero-caption-1,
      hero-caption-2: hero-caption-2,
      hero-caption-3: hero-caption-3,
      title: title,
      subtitle: subtitle,
      doc-id: doc-id,
      edition: edition,
      hero-image: hero-image,
      wordmark: wordmark,
      meta-rows: meta-rows,
      date: date,
      cover-edge: cover-edge,
      publication-period: publication-period,
      publication-edition: publication-edition,
      publication-art: publication-art,
      publication-audience: publication-audience,
      publication-series: publication-series,
      publication-location: publication-location,
      publication-copyright: publication-copyright,
    )
  }

  // ---- body pages -------------------------------------------
  // `background: none` clears the corner logo Quarto's own template stamps
  // on every page when the project declares a `brand:` with a logo (a book
  // that also renders to HTML needs one). The format draws its own marks.
  set page(
    paper: _chanwe-paper,
    // Room between the service lines and the page: the rule sits 7mm above the
    // text block, where a heading at the top of a page used to touch it.
    margin: (top: 19mm, bottom: 17mm, x: 18mm),
    header-ascent: 7mm,
    footer-descent: 5mm,
    background: none,
    header: chanwe-header(section, topic),
    footer: chanwe-footer(_chanwe-clean-str(doc-id), _chanwe-clean-str(edition)),
  )

  // ---- auto TOC (optional) ----------------------------------
  if toc {
    {
      set page(fill: second-page-bg)
      chanwe-agenda(
        eyebrow: toc-eyebrow,
        title: toc-title,
        lede: toc-lede,
      )
      pagebreak()
    }
  }

  // ---- auto abstract (optional) ----------------------------
  if abstract and abstract-text != none {
    // La página del abstract va sobre slate, como la del índice: el `set`
    // vive en este bloque y solo alcanza a la página que abre aquí.
    set page(fill: _t.surface-slate)
    // Todos estos llegan como argumento, no como contenido, asi que arrastran
    // el escape de Pandoc: sin limpiar, `SERIES-A #0934` sale `SERIES-A \#0934`.
    let all-meta = (
      "document": ("Document", _chanwe-clean-str(doc-id), none),
      "edition":  ("Edition",  _chanwe-clean-str(edition), none),
      "author":   ("Author",   _chanwe-clean-str(author),  none),
      "status":   ("Status",   if abstract-status != none { _chanwe-clean-str(abstract-status) } else { "" }, none),
      // Los keywords viajan como lista: el riel les da un chip a cada uno.
      "keywords": ("Keywords", abstract-keywords.map(_chanwe-clean-str), none),
    )
    let fields = if abstract-show.len() > 0 { abstract-show } else { all-meta.keys() }
    let meta-items = fields
      .filter(k => all-meta.at(k, default: none) != none)
      .map(k => all-meta.at(k))
      // Descarta tanto el valor vacio como la lista vacia.
      .filter(((_, v, ..)) => if type(v) == array { v.len() > 0 } else { v != "" })
    chanwe-abstract(
      eyebrow: abstract-eyebrow,
      title: abstract-title,
      meta: meta-items,
      takeaway: _chanwe-clean-str(abstract-takeaway),
      abstract-text,
    )
    pagebreak()
  }

  // ---- user body (paragraph overrides scoped here only) ----
  {
    set text(
      size: if body-size  != none { body-size  } else { 10pt    },
      fill: if body-color != none { body-color } else { _t.body-fg },
    )
    let _body-spacing = if body-spacing != none { body-spacing } else { 2.6em }
    set par(
      leading: if body-leading != none { body-leading } else { 0.85em },
      justify: if body-justify != none { body-justify } else { false  },
      spacing: _body-spacing,
    )
    // A heading is never justified: `body-justify: true` reached the H1 band
    // and the H2–H4 rows and spread a short title across the measure, with
    // hyphens («Net-works»). Hyphenation follows `justify`, so it stops too.
    show heading: set par(justify: false)
    // Listas de definición. Quarto trae en su `definitions.typ` una regla
    // `show terms.item` que apila el término y, en un bloque aparte, la
    // definición: ese bloque hereda el aire de párrafo del cuerpo (2.6em) y
    // el término quedaba a un renglón entero de su definición. Esta regla,
    // definida después, gana: mismo término en negrita y misma sangría, con
    // la definición a medio cuerpo del término. El aire entre ítems sigue
    // siendo el del cuerpo.
    set terms(spacing: _body-spacing, separator: h(0.6em))
    show terms.item: it => block(breakable: false)[
      #text(weight: _t.weight-bold, it.term)
      #block(above: 0.9em, inset: (left: 1.5em), it.description)
    ]
    body
  }

  // ---- back cover (optional) --------------------------------
  let _bt1 = _chanwe-clean-str(back-cover-tagline-1)
  let _bt2 = _chanwe-clean-str(back-cover-tagline-2)
  let _bplace = _chanwe-clean-str(publication-location)
  if back-cover and back-cover-variant == "aspa" {
    chanwe-back-cover-aspa(tagline-1: _bt1, tagline-2: _bt2, back-cols: back-cover-cols, place-label: _bplace)
  } else if back-cover and back-cover-variant == "orange" {
    chanwe-back-cover-orange(tagline-1: _bt1, tagline-2: _bt2, back-cols: back-cover-cols, place-label: _bplace)
  } else if back-cover and back-cover-variant == "mark" {
    chanwe-back-cover-mark(place-label: _bplace)
  } else if back-cover {
    chanwe-back-cover-page(
      tagline-1: back-cover-tagline-1,
      tagline-2: back-cover-tagline-2,
      back-cols: back-cover-cols,
      cover-edge: cover-edge,
      caption-1: hero-caption-1,
      caption-2: hero-caption-2,
      caption-3: hero-caption-3,
      series: publication-series,
      doc-ref: doc-id,
      place-label: publication-location,
    )
  }
}
#let brand-color = (:)
#let brand-color-background = (:)
#let brand-logo = (:)

#set page(
  paper: "a4",
  margin: (x: 18mm,y: 22mm,),
  numbering: "1",
  columns: 1,
)

// =============================================================
// typst-show.typ - Quarto metadata -> chanwe-report() template call
// =============================================================
// This is the bridge: Quarto fills chanwer Showcase, Every palette, scale, header treatment, surface, chart form and native Typst table pattern in the chanwer R package --- static output for chanwe-report-typst, etc. from
// the YAML front-matter of the .qmd file. Custom keys live under
// `chanwe:` and are mapped here.
// =============================================================

#show: doc => chanwe-report(
  title: [chanwer Showcase],
  subtitle: [Every palette, scale, header treatment, surface, chart form and native Typst table pattern in the chanwer R package --- static output for chanwe-report-typst],
  author: "Alejandro Abraham",
  date: "2026-11-19",
  doc-id: "CHW · DEV",
  edition: "SHOWCASE / 2026",
  chapter: "Design System",
  section: "R Package",
  topic: "chanwer v3.2",
  rail-eyebrow: "VISUAL REFERENCE",
  cover: true,
  toc: true,
  toc-eyebrow: "Document map",
  toc-title: "Contents",
  toc-lede: [The complete static reference for chanwer: the brand color system and its validated palettes, the four scale jobs (categorical, ordinal, sequential, diverging), the signed system, every theme\_chanwe() header treatment and surface, the chart forms, and the full native-Typst table API --- all on the chanwe-report-typst tokens.],
  abstract-eyebrow: "TLDR;",
  abstract-title: [Static Reference],
  abstract-text: [This showcase covers every static output in the chanwer package: palette previews, categorical / ordinal / sequential / diverging scales, the signed positive-negative system with its KPI scoreboard, all header treatments (eyebrow, subtitle, note, KPI, title-only, no header line, compact and spacious), all four brand surfaces plus transparent, framed variants, the chart forms (scatter, bar, line, area, distribution, error bars, heatmap, facets), and every chanwe\_kbl() pattern --- surfaces, densities, totals, highlights, vertical rules, signed deltas, title-only and header-less tables. The interactive counterparts (gt, highcharter, reactable) live in chanwer-showcase-html.qmd.],
  abstract-status: "Stable · Internal",
  abstract-show: ("document", "edition", "author", "status"),
  abstract-takeaway: "One color system and one header grammar, mapped to every chart and table: the same tokens drive eyebrows, KPI arrows, table deltas, and this document.",
  meta-rows: (
    ("Package", "chanwer v3.2", "R design system"),
    ("Format", "chanwe-report-typst", "Quarto extension"),
    ("Author", "Chanwe", "Alejandro Abraham"),
  ),
  back-cover: true,
  back-cover-tagline-1: "Estrategia Activa,",
  back-cover-tagline-2: "Codo a codo.",
  back-cover-cols: (
    ("Web", "chanwe.com.ar", "contacto\@chanwe.com.ar"),
    ("Repo", "chanwe-ar/chanwer", "github.com"),
    ("Document", "CHW · DEV", "Showcase / 2026"),
  ),
  publication-art: "\_extensions/chanwe-report/assets/cover-snow-ridge.jpg",
  page-bg: rgb("#F8FAFC"),
  doc,
)

= CHANWE v2 in charts
<chanwe-v2-in-charts>
chanwer 3.0.0 brings the charts and tables to the CHANWE v2 language (brand-v2 Q3, colour rule C1). Every value comes from the generated `chanwe_tokens` (chanwe-brandbook `tokens.json`): slate gridlines, horizontal only; no axis lines or ticks; Schibsted Grotesk titles; JetBrains Mono axis labels, legends and captions at the compact size; legend keys as pills; bars with 3px rounded ends (`geom_chanwe_col()`, `geom_chanwe_bar()`); tables as panes.

#strong[Orange is the one signal.] The series that matters takes the focus orange and every other series sits on the slate ramp (`scale_fill_chanwe_focus()`, `scale_color_chanwe_focus()`, `chanwe_focus_colors()`). The categorical palette is for charts with no focus series.

#box(image("chanwer-showcase-pdf_files/figure-typst/v2-focus-palette-1.png"))

#box(image("chanwer-showcase-pdf_files/figure-typst/v2-focus-bars-1.png"))

#box(image("chanwer-showcase-pdf_files/figure-typst/v2-focus-lines-1.png"))

= The Color System
<the-color-system>
Every color in `chanwer` is a named token. `chanwe_palette()` returns the full inventory; `chanwe_palette("<group>")` returns one group; `chanwe_preview_palette("<group>")` draws its swatch grid. The values are read from the generated `chanwe_tokens` (chanwe-brandbook `tokens.json`), never written by hand.

#callout(kind: "note", eyebrow: "BRAND ROLES", title: "The manual assigns each family a job")[
Orange is the one accent, blue is structural, green is positive, red is
alert, ink is the neutral anchor. The scales below are built on those
roles --- positive/negative is never an arbitrary red/green pair.

]
== The categorical eight
<the-categorical-eight>
The slot order is `plot.categorical` from `tokens.json` --- primary orange, blue, teal, indigo, purple, green, orange, red --- the eight series hues, shared with the callouts. Red sits last: it is nearly the primary, so the two only meet in an eight-series chart. Use it only when no series is the focus.

#box(image("chanwer-showcase-pdf_files/figure-typst/preview-chart-1.png"))

== The signed trio
<the-signed-trio>
The brand's `kpi-green` and `kpi-red` with the slate `fg-muted` as neutral; each passes WCAG 4.5:1 small-text contrast on every brand surface.

#box(image("chanwer-showcase-pdf_files/figure-typst/preview-signed-1.png"))

== Semantic roles and family ramps
<semantic-roles-and-family-ramps>
#box(image("chanwer-showcase-pdf_files/figure-typst/preview-semantic-1.png"))

#box(image("chanwer-showcase-pdf_files/figure-typst/preview-teal-1.png"))

#box(image("chanwer-showcase-pdf_files/figure-typst/preview-mb-1.png"))

= Scales
<scales>
== Categorical
<categorical>
`scale_color_chanwe_d()` / `scale_fill_chanwe_d()` assign the chart palette in slot order, recycling past eight.

#box(image("chanwer-showcase-pdf_files/figure-typst/cat-scatter-1.png"))

#callout(kind: "warning", eyebrow: "SERIES CAP", title: "Scatter, bubble, and maps: three series maximum")[
In those forms any two marks can sit side by side, so the palette must
pass the stricter all-pairs check --- the first three slots do. Fold
extra series into "Other" or facet. Bars, lines, and stacks may use up
to six.

]
#box(image("chanwer-showcase-pdf_files/figure-typst/cat-bars-1.png"))

== Ordinal: one-hue ramp
<ordinal-one-hue-ramp>
When category order carries meaning, use a ramp group so the reader sees the order in the color: `scale_fill_chanwe_d(palette = "ramp_blue", reverse = TRUE)`.

#box(image("chanwer-showcase-pdf_files/figure-typst/ordinal-1.png"))

== Sequential
<sequential>
`scale_color_chanwe_c()` / `scale_fill_chanwe_c()` encode magnitude with one-hue, light-to-dark gradients built from the series hues: `orange` (default), `blue`, `indigo`, `teal`, `green`, `amber`, `red`, `purple`, plus `mustard` and `ink`.

#box(image("chanwer-showcase-pdf_files/figure-typst/seq-teal-1.png"))

#box(image("chanwer-showcase-pdf_files/figure-typst/seq-blue-1.png"))

== Diverging
<diverging>
`scale_fill_chanwe_div()` encodes polarity --- red through a neutral midpoint to green, signed tokens at the poles. Give it symmetric limits so zero lands on the midpoint.

#box(image("chanwer-showcase-pdf_files/figure-typst/div-heat-1.png"))

#box(image("chanwer-showcase-pdf_files/figure-typst/div-heat-cvd-1.png"))

#box(image("chanwer-showcase-pdf_files/figure-typst/div-bars-1.png"))

= The Signed System
<the-signed-system>
One pair everywhere: `chanwe_palette("signed")` drives the KPI arrows, table deltas and the diverging poles. `direction` states the movement (▲/▼); `valence` states whether that movement is good news and drives the color.

#kpi-grid(cols: 4, (
  kpi-card(
    title: "POSITIVE",
    main: "#147705",
    prefix: "",
    unit: "",
    unit-note: "",
    source: "",
    main-color: "#147705",
    secondary: "hue-true brand green",
    secondary-color: "muted",
    direction: "none",
    delta: "",
    series: (),
    from-label: "",
    state-label: "",
    to-label: "",
  ),
  kpi-card(
    title: "NEGATIVE",
    main: "#CC1914",
    prefix: "",
    unit: "",
    unit-note: "",
    source: "",
    main-color: "#CC1914",
    secondary: "hue-true vermillion",
    secondary-color: "muted",
    direction: "none",
    delta: "",
    series: (),
    from-label: "",
    state-label: "",
    to-label: "",
  ),
  kpi-card(
    title: "NEUTRAL",
    main: "#475569",
    prefix: "",
    unit: "",
    unit-note: "",
    source: "",
    main-color: "#475569",
    secondary: "pizarra fg-muted",
    secondary-color: "muted",
    direction: "none",
    delta: "",
    series: (),
    from-label: "",
    state-label: "",
    to-label: "",
  ),
  kpi-card(
    title: "CONTRAST",
    main: "4.9+",
    prefix: "",
    unit: ":1",
    unit-note: "",
    source: "",
    main-color: "ink",
    secondary: "on all five surfaces",
    secondary-color: "muted",
    direction: "up",
    delta: "",
    series: (),
    from-label: "",
    state-label: "",
    to-label: "",
  )
))
== KPI scoreboard with valence
<kpi-scoreboard-with-valence>
#box(image("chanwer-showcase-pdf_files/figure-typst/kpi-valence-1.png"))

== Signed deltas in tables
<signed-deltas-in-tables>
`chanwe_col_signed()` colors by the column's #emph[raw] values; `flip` marks the smaller-is-better rows so color reads as valence, not sign.

#block(above: 2.5em, below: 2.5em)[
#block(inset: (x: 12.5pt, y: 0pt))[
#block(width: 100%, radius: 8pt, clip: true, stroke: 0.5pt + rgb("#E2E8F0"), fill: rgb("#F8FAFC"))[
#{ set text(size: 10pt, fill: _t.ink, weight: "regular", tracking: 0pt, style: "normal"); set table(inset: (x: 2.5mm, y: 10pt), stroke: none, fill: rgb("#F8FAFC"))
  [
  #table(
    columns: (1fr, 1fr, 1fr, 1fr),
    align: (left, right, right, right,),
    table.header(
      table.cell(align: left, colspan: 4, inset: (top: 10pt, bottom: 3pt, x: 2.5mm))[#v(4pt, weak: false)#chanwe-eyebrow(size: 4pt)[SIGNED - TABLES]#v(-6pt, weak: false)#text(font: "Schibsted Grotesk", size: 13pt, fill: _t.ink, weight: "semibold", tracking: -0.05em)[Quarterly performance]],
      table.cell(align: left, colspan: 4, inset: (top: 3pt, bottom: 10pt, x: 2.5mm))[#text(font: "Satoshi", size: 8pt, fill: _t.fg-muted, weight: "regular")[Signed deltas via chanwe\_col\_signed() - flip marks Opex and Churn so color reads as valence]#v(8pt, weak: false)],
      table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
      table.cell(align: left, inset: (top: 20pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[METRIC]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[USD K]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[QOQ]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[YOY]],
    ),
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Revenue]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[1,240.5]],
    table.cell(align: right)[#box(fill: rgb("#147705").transparentize(90%), radius: 99pt, inset: (x: 4pt, y: 2.2pt), baseline: 2.2pt)[#text(font: "JetBrains Mono", size: 6.3pt, fill: rgb("#147705"), weight: "medium")[+12.4%]]],
    table.cell(align: right)[#box(fill: rgb("#147705").transparentize(90%), radius: 99pt, inset: (x: 4pt, y: 2.2pt), baseline: 2.2pt)[#text(font: "JetBrains Mono", size: 6.3pt, fill: rgb("#147705"), weight: "medium")[+28.1%]]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Gross margin]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[682.1]],
    table.cell(align: right)[#box(fill: rgb("#147705").transparentize(90%), radius: 99pt, inset: (x: 4pt, y: 2.2pt), baseline: 2.2pt)[#text(font: "JetBrains Mono", size: 6.3pt, fill: rgb("#147705"), weight: "medium")[+4.2%]]],
    table.cell(align: right)[#box(fill: rgb("#147705").transparentize(90%), radius: 99pt, inset: (x: 4pt, y: 2.2pt), baseline: 2.2pt)[#text(font: "JetBrains Mono", size: 6.3pt, fill: rgb("#147705"), weight: "medium")[+9.6%]]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[EBITDA]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[310.2]],
    table.cell(align: right)[#box(fill: rgb("#CC1914").transparentize(90%), radius: 99pt, inset: (x: 4pt, y: 2.2pt), baseline: 2.2pt)[#text(font: "JetBrains Mono", size: 6.3pt, fill: rgb("#CC1914"), weight: "medium")[-3.1%]]],
    table.cell(align: right)[#box(fill: rgb("#147705").transparentize(90%), radius: 99pt, inset: (x: 4pt, y: 2.2pt), baseline: 2.2pt)[#text(font: "JetBrains Mono", size: 6.3pt, fill: rgb("#147705"), weight: "medium")[+11.2%]]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Opex]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[-420.3]],
    table.cell(align: right)[#box(fill: rgb("#147705").transparentize(90%), radius: 99pt, inset: (x: 4pt, y: 2.2pt), baseline: 2.2pt)[#text(font: "JetBrains Mono", size: 6.3pt, fill: rgb("#147705"), weight: "medium")[-1.9%]]],
    table.cell(align: right)[#box(fill: rgb("#CC1914").transparentize(90%), radius: 99pt, inset: (x: 4pt, y: 2.2pt), baseline: 2.2pt)[#text(font: "JetBrains Mono", size: 6.3pt, fill: rgb("#CC1914"), weight: "medium")[+6.3%]]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Net income]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[185.7]],
    table.cell(align: right)[#box(fill: rgb("#147705").transparentize(90%), radius: 99pt, inset: (x: 4pt, y: 2.2pt), baseline: 2.2pt)[#text(font: "JetBrains Mono", size: 6.3pt, fill: rgb("#147705"), weight: "medium")[+5.8%]]],
    table.cell(align: right)[#box(fill: rgb("#CC1914").transparentize(90%), radius: 99pt, inset: (x: 4pt, y: 2.2pt), baseline: 2.2pt)[#text(font: "JetBrains Mono", size: 6.3pt, fill: rgb("#CC1914"), weight: "medium")[-2.4%]]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Churn]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[42.0]],
    table.cell(align: right)[#box(fill: rgb("#147705").transparentize(90%), radius: 99pt, inset: (x: 4pt, y: 2.2pt), baseline: 2.2pt)[#text(font: "JetBrains Mono", size: 6.3pt, fill: rgb("#147705"), weight: "medium")[-0.8%]]],
    table.cell(align: right)[#box(fill: rgb("#147705").transparentize(90%), radius: 99pt, inset: (x: 4pt, y: 2.2pt), baseline: 2.2pt)[#text(font: "JetBrains Mono", size: 6.3pt, fill: rgb("#147705"), weight: "medium")[-4.1%]]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.footer(
      table.cell(colspan: 4, align: left, inset: (top: 10pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, weight: "regular", tracking: 0.08em, fill: rgb("#64748B"))[#upper[Source: finance close, Q1 - simulated]]],
    )
  )
  ]
}
]
]
]
= Header Treatments
<header-treatments>
The header grammar: mono-caps eyebrow with an orange rule, Schibsted Grotesk title at 1.85x base, Satoshi subtitle, optional note line or KPI scoreboard, and an mono source caption (`caption_style = "stamp"` brings back the orange stamp).

===== Eyebrow · title · subtitle (default)
<eyebrow-title-subtitle-default>
#box(image("chanwer-showcase-pdf_files/figure-typst/hdr-default-1.png"))

===== Subtitle with a note line
<subtitle-with-a-note-line>
#box(image("chanwer-showcase-pdf_files/figure-typst/hdr-note-1.png"))

===== KPI scoreboard
<kpi-scoreboard>
#box(image("chanwer-showcase-pdf_files/figure-typst/hdr-kpi-1.png"))

===== KPI only · no subtitle text
<kpi-only-no-subtitle-text>
#box(image("chanwer-showcase-pdf_files/figure-typst/hdr-kpi-only-1.png"))

===== Title only · has\_subtitle = FALSE
<title-only-has_subtitle-false>
#box(image("chanwer-showcase-pdf_files/figure-typst/hdr-title-only-1.png"))

===== Plain title · no eyebrow
<plain-title-no-eyebrow>
#box(image("chanwer-showcase-pdf_files/figure-typst/hdr-plain-1.png"))

===== No title · no subtitle
<no-title-no-subtitle>
#box(image("chanwer-showcase-pdf_files/figure-typst/hdr-none-1.png"))

== Header line and spacing
<header-line-and-spacing>
#box(image("chanwer-showcase-pdf_files/figure-typst/hdr-line-spacious-1.png"))

#box(image("chanwer-showcase-pdf_files/figure-typst/hdr-line-compact-1.png"))

#box(image("chanwer-showcase-pdf_files/figure-typst/hdr-line-nosub-spacious-1.png"))

#box(image("chanwer-showcase-pdf_files/figure-typst/hdr-line-nosub-compact-1.png"))

#box(image("chanwer-showcase-pdf_files/figure-typst/hdr-compact-false-1.png"))

= Surfaces and Frames
<surfaces-and-frames>
`theme_chanwe()` exposes five named surfaces plus `"transparent"` and raw hex; the v2 grid (`plot.grid`, ink-fg at 25%) is the same on every surface.

===== paper · default
<paper-default>
#box(image("chanwer-showcase-pdf_files/figure-typst/bg-paper-1.png"))

===== white
<white>
#box(image("chanwer-showcase-pdf_files/figure-typst/bg-white-1.png"))

===== sunken
<sunken>
#box(image("chanwer-showcase-pdf_files/figure-typst/bg-sunken-1.png"))

===== slate
<slate>
#box(image("chanwer-showcase-pdf_files/figure-typst/bg-slate-1.png"))

===== white · padding 18
<white-padding-18>
#box(image("chanwer-showcase-pdf_files/figure-typst/bg-white-padding-1.png"))

===== transparent · zone-highlight
<transparent-zone-highlight>
#zone-highlight(color: "metallic", above: -2mm)[
#block[
#block[
#box(image("chanwer-showcase-pdf_files/figure-typst/bg-transparent-1.png"))

]
]
]
== Frames
<frames>
#box(image("chanwer-showcase-pdf_files/figure-typst/frame-true-1.png"))

#box(image("chanwer-showcase-pdf_files/figure-typst/frame-top-bottom-1.png"))

== Inset figure
<inset-figure>
#inset-great-figure(
  eyebrow: "FY 2025",
  title: "Revenue by Segment",
  color: "light",
  layout: "left",
  position: "right",
  source: "Data: FY 2025 — valores normalizados",
  caption: [
La categoría C presenta el valor más alto del conjunto. Los segmentos A
y E muestran rendimiento dentro del rango esperado, mientras que F
establece el piso de referencia para el análisis diferencial.

  ],
)[
#block[
#block[
#box(image("chanwer-showcase-pdf_files/figure-typst/inset-facets-1.png"))

]
]
]
= Chart Forms
<chart-forms>
===== Line · direct labels
<line-direct-labels>
#box(image("chanwer-showcase-pdf_files/figure-typst/form-line-1.png"))

===== Area
<area>
#box(image("chanwer-showcase-pdf_files/figure-typst/form-area-1.png"))

===== Distribution · density
<distribution-density>
#box(image("chanwer-showcase-pdf_files/figure-typst/form-density-1.png"))

===== Error bars · mean ± SD
<error-bars-mean-sd>
#box(image("chanwer-showcase-pdf_files/figure-typst/form-errorbar-1.png"))

===== Focus bar · value labels
<focus-bar-value-labels>
#box(image("chanwer-showcase-pdf_files/figure-typst/form-focus-1.png"))

===== Facets
<facets>
#box(image("chanwer-showcase-pdf_files/figure-typst/form-facets-1.png"))

= Typst Tables
<typst-tables>
`chanwe_kbl()` generates native Typst --- no HTML-to-PDF translation. Both densities, every surface, per-column formatting and coloring, stubs, totals, highlights and vertical rules.

== Surfaces
<surfaces>
===== paper · default
<paper-default-1>
#figure([
#block(above: 2.5em, below: 2.5em)[
#block(inset: (x: 12.5pt, y: 0pt))[
#block(width: 100%, radius: 8pt, clip: true, stroke: 0.5pt + rgb("#E2E8F0"), fill: rgb("#F8FAFC"))[
#{ set text(size: 10pt, fill: _t.ink, weight: "regular", tracking: 0pt, style: "normal"); set table(inset: (x: 2.5mm, y: 10pt), stroke: none, fill: rgb("#F8FAFC"))
  [
  #table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr),
    align: (left, right, left, right, right,),
    table.header(
      table.cell(align: left, colspan: 5, inset: (top: 10pt, bottom: 3pt, x: 2.5mm))[#v(4pt, weak: false)#chanwe-eyebrow(size: 4pt)[TABLE · SPACIOUS · PAPER]#v(-6pt, weak: false)#text(font: "Schibsted Grotesk", size: 13pt, fill: _t.ink, weight: "semibold", tracking: -0.05em)[bg · paper]],
      table.cell(align: left, colspan: 5, inset: (top: 3pt, bottom: 10pt, x: 2.5mm))[#text(font: "Satoshi", size: 8pt, fill: _t.fg-muted, weight: "regular")[density · spacious]#v(8pt, weak: false)],
      table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
      table.cell(align: left, inset: (top: 20pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[MODEL]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[MPG]],
      table.cell(align: left, inset: (top: 20pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[CYL]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[HP]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[WT]],
    ),
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Mazda RX4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[2.62]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Mazda RX4 Wag]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[2.88]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Datsun 710]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[22.80]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[93]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[2.32]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Hornet 4 Drive]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[21.40]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.21]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Hornet Sportabout]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[18.70]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[175]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.44]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Valiant]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[18.10]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[105]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.46]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Duster 360]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[14.30]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[245]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.57]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Merc 240D]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[24.40]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[62]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.19]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.footer(
      table.cell(colspan: 5, align: left, inset: (top: 10pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, weight: "regular", tracking: 0.08em, fill: rgb("#64748B"))[#upper[Source · Motor Trend, 1974 · mtcars dataset.]]],
    )
  )
  ]
}
]
]
]
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-paper>


===== white
<white-1>
#figure([
#block(above: 2.5em, below: 2.5em)[
#block(inset: (x: 12.5pt, y: 0pt))[
#block(width: 100%, radius: 8pt, clip: true, stroke: 0.5pt + rgb("#E2E8F0"), fill: rgb("#FFFFFF"))[
#{ set text(size: 10pt, fill: _t.ink, weight: "regular", tracking: 0pt, style: "normal"); set table(inset: (x: 2.5mm, y: 10pt), stroke: none, fill: rgb("#FFFFFF"))
  [
  #table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr),
    align: (left, right, left, right, right,),
    table.header(
      table.cell(align: left, colspan: 5, inset: (top: 10pt, bottom: 3pt, x: 2.5mm))[#v(4pt, weak: false)#chanwe-eyebrow(size: 4pt)[TABLE · SPACIOUS · WHITE]#v(-6pt, weak: false)#text(font: "Schibsted Grotesk", size: 13pt, fill: _t.ink, weight: "semibold", tracking: -0.05em)[bg · white]],
      table.cell(align: left, colspan: 5, inset: (top: 3pt, bottom: 10pt, x: 2.5mm))[#text(font: "Satoshi", size: 8pt, fill: _t.fg-muted, weight: "regular")[density · spacious]#v(8pt, weak: false)],
      table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
      table.cell(align: left, inset: (top: 20pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[MODEL]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[MPG]],
      table.cell(align: left, inset: (top: 20pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[CYL]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[HP]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[WT]],
    ),
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Mazda RX4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[2.62]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Mazda RX4 Wag]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[2.88]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Datsun 710]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[22.80]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[93]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[2.32]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Hornet 4 Drive]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[21.40]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.21]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Hornet Sportabout]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[18.70]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[175]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.44]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Valiant]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[18.10]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[105]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.46]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Duster 360]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[14.30]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[245]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.57]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Merc 240D]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[24.40]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[62]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.19]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.footer(
      table.cell(colspan: 5, align: left, inset: (top: 10pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, weight: "regular", tracking: 0.08em, fill: rgb("#64748B"))[#upper[Source · Motor Trend, 1974 · mtcars dataset.]]],
    )
  )
  ]
}
]
]
]
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-white>


===== sunken · top\_border = FALSE
<sunken-top_border-false>
#figure([
#block(above: 2.5em, below: 2.5em)[
#block(inset: (x: 12.5pt, y: 0pt))[
#block(width: 100%, radius: 8pt, clip: true, stroke: 0.5pt + rgb("#E2E8F0"), fill: rgb("#F1F5F9"))[
#{ set text(size: 10pt, fill: _t.ink, weight: "regular", tracking: 0pt, style: "normal"); set table(inset: (x: 2.5mm, y: 10pt), stroke: none, fill: rgb("#F1F5F9"))
  [
  #table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr),
    align: (left, right, left, right, right,),
    table.header(
      table.cell(align: left, colspan: 5, inset: (top: 10pt, bottom: 3pt, x: 2.5mm))[#v(4pt, weak: false)#chanwe-eyebrow(size: 4pt)[TABLE · SPACIOUS · SUNKEN]#v(-6pt, weak: false)#text(font: "Schibsted Grotesk", size: 13pt, fill: _t.ink, weight: "semibold", tracking: -0.05em)[bg · sunken]],
      table.cell(align: left, colspan: 5, inset: (top: 3pt, bottom: 10pt, x: 2.5mm))[#text(font: "Satoshi", size: 8pt, fill: _t.fg-muted, weight: "regular")[top\_border = FALSE]#v(8pt, weak: false)],
      table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
      table.cell(align: left, inset: (top: 20pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[MODEL]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[MPG]],
      table.cell(align: left, inset: (top: 20pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[CYL]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[HP]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[WT]],
    ),
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Mazda RX4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[2.62]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Mazda RX4 Wag]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[2.88]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Datsun 710]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[22.80]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[93]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[2.32]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Hornet 4 Drive]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[21.40]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.21]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Hornet Sportabout]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[18.70]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[175]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.44]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Valiant]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[18.10]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[105]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.46]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Duster 360]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[14.30]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[245]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.57]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Merc 240D]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[24.40]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[62]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.19]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.footer(
      table.cell(colspan: 5, align: left, inset: (top: 10pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, weight: "regular", tracking: 0.08em, fill: rgb("#64748B"))[#upper[Source · Motor Trend, 1974 · mtcars dataset.]]],
    )
  )
  ]
}
]
]
]
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-sunken>


===== slate · padding 0
<slate-padding-0>
#figure([
#block(above: 2.5em, below: 2.5em)[
#block(width: 100%, radius: 8pt, clip: true, stroke: 0.5pt + rgb("#E2E8F0"), fill: rgb("#EBF0F6"))[
#{ set text(size: 10pt, fill: _t.ink, weight: "regular", tracking: 0pt, style: "normal"); set table(inset: (x: 2.5mm, y: 10pt), stroke: none, fill: rgb("#EBF0F6"))
  [
  #table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr),
    align: (left, right, left, right, right,),
    table.header(
      table.cell(align: left, colspan: 5, inset: (top: 10pt, bottom: 3pt, x: 2.5mm))[#v(4pt, weak: false)#chanwe-eyebrow(size: 4pt)[TABLE · SPACIOUS · SLATE]#v(-6pt, weak: false)#text(font: "Schibsted Grotesk", size: 13pt, fill: _t.ink, weight: "semibold", tracking: -0.05em)[bg · slate]],
      table.cell(align: left, colspan: 5, inset: (top: 3pt, bottom: 10pt, x: 2.5mm))[#text(font: "Satoshi", size: 8pt, fill: _t.fg-muted, weight: "regular")[padding = 0  ·  top\_border = FALSE]#v(8pt, weak: false)],
      table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
      table.cell(align: left, inset: (top: 20pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[MODEL]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[MPG]],
      table.cell(align: left, inset: (top: 20pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[CYL]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[HP]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[WT]],
    ),
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Mazda RX4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[2.62]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Mazda RX4 Wag]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[2.88]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Datsun 710]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[22.80]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[93]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[2.32]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Hornet 4 Drive]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[21.40]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.21]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Hornet Sportabout]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[18.70]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[175]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.44]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Valiant]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[18.10]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[105]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.46]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Duster 360]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[14.30]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[245]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.57]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Merc 240D]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[24.40]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[62]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.19]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.footer(
      table.cell(colspan: 5, align: left, inset: (top: 10pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, weight: "regular", tracking: 0.08em, fill: rgb("#64748B"))[#upper[Source · Motor Trend, 1974 · mtcars dataset.]]],
    )
  )
  ]
}
]
]
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-slate>


== Densities and column widths
<densities-and-column-widths>
#figure([
#block(above: 2.5em, below: 2.5em)[
#block(inset: (x: 12.5pt, y: 0pt))[
#block(width: 100%, radius: 8pt, clip: true, stroke: 0.5pt + rgb("#E2E8F0"), fill: rgb("#F8FAFC"))[
#{ set text(size: 10pt, fill: _t.ink, weight: "regular", tracking: 0pt, style: "normal"); set table(inset: (x: 2.5mm, y: 10pt), stroke: none, fill: rgb("#F8FAFC"))
  [
  #table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr),
    align: (left, right, right, right, right,),
    table.header(
      table.cell(align: left, colspan: 5, inset: (top: 10pt, bottom: 3pt, x: 2.5mm))[#v(4pt, weak: false)#chanwe-eyebrow(size: 4pt)[TABLES - SPACIOUS]#v(-6pt, weak: false)#text(font: "Schibsted Grotesk", size: 13pt, fill: _t.ink, weight: "semibold", tracking: -0.05em)[Fleet summary by cylinder count]],
      table.cell(align: left, colspan: 5, inset: (top: 3pt, bottom: 10pt, x: 2.5mm))[#text(font: "Satoshi", size: 8pt, fill: _t.fg-muted, weight: "regular")[Spacious density - the presentation default]#v(8pt, weak: false)],
      table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
      table.cell(align: left, inset: (top: 20pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[CYLINDERS]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[AVG MPG]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[AVG HP]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[AVG WEIGHT]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[VEHICLES]],
    ),
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[26.7]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[83]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[2.29]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[11]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[19.7]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[122]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.12]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[7]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[15.1]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[209]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[4.00]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[14]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.footer(
      table.cell(colspan: 5, align: left, inset: (top: 10pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, weight: "regular", tracking: 0.08em, fill: rgb("#64748B"))[#upper[Source: mtcars]]],
    )
  )
  ]
}
]
]
]
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-spacious-summary>


#figure([
#block(above: 2.5em, below: 2.5em)[
#block(inset: (x: 12.5pt, y: 0pt))[
#block(width: 100%, radius: 8pt, clip: true, stroke: 0.5pt + rgb("#E2E8F0"), fill: rgb("#EBF0F6"))[
#{ set text(size: 10pt, fill: _t.ink, weight: "regular", tracking: 0pt, style: "normal"); set table(inset: (x: 2.5mm, y: 3.4pt), stroke: none, fill: rgb("#EBF0F6"))
  [
  #table(
    columns: (2.2fr, 1fr, 0.8fr, 1fr, 1.1fr, 1.6fr),
    align: (left, right, left, right, right, left,),
    table.header(
      table.cell(align: left, colspan: 6, inset: (top: 3.4pt, bottom: 3pt, x: 2.5mm))[#v(2pt, weak: false)#chanwe-eyebrow(size: 4pt)[TABLES - COMPACT]#v(-6pt, weak: false)#text(font: "Schibsted Grotesk", size: 13pt, fill: _t.ink, weight: "semibold", tracking: -0.05em)[Vehicle detail]],
      table.cell(align: left, colspan: 6, inset: (top: 3pt, bottom: 3.4pt, x: 2.5mm))[#text(font: "Satoshi", size: 8pt, fill: _t.fg-muted, weight: "regular")[Compact density for dense reporting tables - explicit col\_widths]#v(4pt, weak: false)],
      table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
      table.cell(align: left, inset: (top: 14pt, bottom: 3.4pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[MODEL]],
      table.cell(align: right, inset: (top: 14pt, bottom: 3.4pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[MPG]],
      table.cell(align: left, inset: (top: 14pt, bottom: 3.4pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[CYL]],
      table.cell(align: right, inset: (top: 14pt, bottom: 3.4pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[HP]],
      table.cell(align: right, inset: (top: 14pt, bottom: 3.4pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[WEIGHT]],
      table.cell(align: left, inset: (top: 14pt, bottom: 3.4pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[TRANSMISSION]],
    ),
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Mazda RX4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[21.0]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[2.62]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[Manual]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Mazda RX4 Wag]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[21.0]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[2.88]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[Manual]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Datsun 710]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[22.8]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[93]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[2.32]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[Manual]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Hornet 4 Drive]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[21.4]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.21]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[Automatic]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Hornet Sportabout]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[18.7]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[175]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.44]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[Automatic]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Valiant]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[18.1]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[105]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.46]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[Automatic]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Duster 360]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[14.3]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[245]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.57]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[Automatic]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Merc 240D]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[24.4]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[62]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.19]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[Automatic]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.footer(
      table.cell(colspan: 6, align: left, inset: (top: 9pt, bottom: 3.4pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, weight: "regular", tracking: 0.08em, fill: rgb("#64748B"))[#upper[Source: mtcars]]],
    )
  )
  ]
}
]
]
]
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-compact>


== Totals, highlights and rules
<totals-highlights-and-rules>
#figure([
#block(above: 2.5em, below: 2.5em)[
#block(inset: (x: 12.5pt, y: 0pt))[
#block(width: 100%, radius: 8pt, clip: true, stroke: 0.5pt + rgb("#E2E8F0"), fill: rgb("#F8FAFC"))[
#{ set text(size: 10pt, fill: _t.ink, weight: "regular", tracking: 0pt, style: "normal"); set table(inset: (x: 2.5mm, y: 10pt), stroke: none, fill: rgb("#F8FAFC"))
  [
  #table(
    columns: (1fr, 1fr, 1fr, 1fr),
    align: (left, right, right, right,),
    table.vline(x: 3, stroke: 0.4pt + rgb("#E2E8F0")),
    table.header(
      table.cell(align: left, colspan: 4, inset: (top: 10pt, bottom: 3pt, x: 2.5mm))[#v(4pt, weak: false)#chanwe-eyebrow(size: 4pt)[TABLES - TOTALS + HIGHLIGHT]#v(-6pt, weak: false)#text(font: "Schibsted Grotesk", size: 13pt, fill: _t.ink, weight: "semibold", tracking: -0.05em)[Revenue by region]],
      table.cell(align: left, colspan: 4, inset: (top: 3pt, bottom: 10pt, x: 2.5mm))[#text(font: "Satoshi", size: 8pt, fill: _t.fg-muted, weight: "regular")[Total row via n\_total; QoQ column highlighted and signed; vline separates quarters from the delta]#v(8pt, weak: false)],
      table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
      table.cell(align: left, inset: (top: 20pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[REGION]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[Q1 USD K]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[Q2 USD K]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm), fill: rgb("#EBF0F6"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[QOQ %]],
    ),
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[North]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[412.1]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[438.0]],
    table.cell(align: right, fill: rgb("#EBF0F6"))[#box(fill: rgb("#147705").transparentize(90%), radius: 99pt, inset: (x: 4pt, y: 2.2pt), baseline: 2.2pt)[#text(font: "JetBrains Mono", size: 6.3pt, fill: rgb("#147705"), weight: "medium")[+6.3%]]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Center]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[388.4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[371.2]],
    table.cell(align: right, fill: rgb("#EBF0F6"))[#box(fill: rgb("#CC1914").transparentize(90%), radius: 99pt, inset: (x: 4pt, y: 2.2pt), baseline: 2.2pt)[#text(font: "JetBrains Mono", size: 6.3pt, fill: rgb("#CC1914"), weight: "medium")[-4.4%]]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[West]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[251.9]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[266.3]],
    table.cell(align: right, fill: rgb("#EBF0F6"))[#box(fill: rgb("#147705").transparentize(90%), radius: 99pt, inset: (x: 4pt, y: 2.2pt), baseline: 2.2pt)[#text(font: "JetBrains Mono", size: 6.3pt, fill: rgb("#147705"), weight: "medium")[+5.7%]]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[South]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[188.1]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[201.5]],
    table.cell(align: right, fill: rgb("#EBF0F6"))[#box(fill: rgb("#147705").transparentize(90%), radius: 99pt, inset: (x: 4pt, y: 2.2pt), baseline: 2.2pt)[#text(font: "JetBrains Mono", size: 6.3pt, fill: rgb("#147705"), weight: "medium")[+7.1%]]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.hline(stroke: 0.5pt + _t.fg-muted),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Total]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "medium")[1,240.5]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "medium")[1,277.0]],
    table.cell(align: right, fill: rgb("#EBF0F6"))[#box(fill: rgb("#147705").transparentize(90%), radius: 99pt, inset: (x: 4pt, y: 2.2pt), baseline: 2.2pt)[#text(font: "JetBrains Mono", size: 6.3pt, fill: rgb("#147705"), weight: "medium")[+2.9%]]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.footer(
      table.cell(colspan: 4, align: left, inset: (top: 10pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, weight: "regular", tracking: 0.08em, fill: rgb("#64748B"))[#upper[Source: finance close - simulated]]],
    )
  )
  ]
}
]
]
]
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-totals>


== Header variants
<header-variants>
===== Title only
<title-only>
#figure([
#block(above: 2.5em, below: 2.5em)[
#block(inset: (x: 12.5pt, y: 0pt))[
#block(width: 100%, radius: 8pt, clip: true, stroke: 0.5pt + rgb("#E2E8F0"), fill: rgb("#F8FAFC"))[
#{ set text(size: 10pt, fill: _t.ink, weight: "regular", tracking: 0pt, style: "normal"); set table(inset: (x: 2.5mm, y: 10pt), stroke: none, fill: rgb("#F8FAFC"))
  [
  #table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr),
    align: (left, right, left, right, right,),
    table.header(
      table.cell(align: left, colspan: 5, inset: (top: 10pt, bottom: 14pt, x: 2.5mm))[#v(4pt, weak: false)#chanwe-eyebrow(size: 4pt)[TABLE · COMPACT HERO]#v(-6pt, weak: false)#text(font: "Schibsted Grotesk", size: 13pt, fill: _t.ink, weight: "semibold", tracking: -0.05em)[title only · no subtitle]],
      table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
      table.cell(align: left, inset: (top: 18pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[MODEL]],
      table.cell(align: right, inset: (top: 18pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[MPG]],
      table.cell(align: left, inset: (top: 18pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[CYL]],
      table.cell(align: right, inset: (top: 18pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[HP]],
      table.cell(align: right, inset: (top: 18pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[WT]],
    ),
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Mazda RX4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[2.62]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Mazda RX4 Wag]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[2.88]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Datsun 710]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[22.80]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[93]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[2.32]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Hornet 4 Drive]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[21.40]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.21]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Hornet Sportabout]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[18.70]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[175]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.44]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Valiant]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[18.10]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[105]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.46]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Duster 360]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[14.30]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[245]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.57]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Merc 240D]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[24.40]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[62]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.19]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.footer(
      table.cell(colspan: 5, align: left, inset: (top: 10pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, weight: "regular", tracking: 0.08em, fill: rgb("#64748B"))[#upper[Source · Motor Trend, 1974 · mtcars dataset.]]],
    )
  )
  ]
}
]
]
]
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-title-only>


===== Title only · zone-highlight
<title-only-zone-highlight>
#zone-highlight(color: "metallic", above: -2mm)[
#block[
#block[
#block[
#block[
#block(above: 2.5em, below: 2.5em)[
#block(inset: (x: 12.5pt, y: 0pt))[
#block(width: 100%, radius: 8pt, clip: true, stroke: 0.5pt + rgb("#E2E8F0"), fill: none)[
#{ set text(size: 10pt, fill: _t.ink, weight: "regular", tracking: 0pt, style: "normal"); set table(inset: (x: 2.5mm, y: 10pt), stroke: none, fill: none)
  [
  #table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr),
    align: (left, right, left, right, right,),
    table.header(
      table.cell(align: left, colspan: 5, inset: (top: 10pt, bottom: 14pt, x: 2.5mm))[#v(4pt, weak: false)#chanwe-eyebrow(size: 4pt)[TABLE · COMPACT HERO]#v(-6pt, weak: false)#text(font: "Schibsted Grotesk", size: 13pt, fill: _t.ink, weight: "semibold", tracking: -0.05em)[title only · zone-highlight]],
      table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
      table.cell(align: left, inset: (top: 18pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[MODEL]],
      table.cell(align: right, inset: (top: 18pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[MPG]],
      table.cell(align: left, inset: (top: 18pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[CYL]],
      table.cell(align: right, inset: (top: 18pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[HP]],
      table.cell(align: right, inset: (top: 18pt, bottom: 10pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[WT]],
    ),
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Mazda RX4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[2.62]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Mazda RX4 Wag]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[2.88]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Datsun 710]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[22.80]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[93]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[2.32]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Hornet 4 Drive]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[21.40]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.21]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Hornet Sportabout]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[18.70]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[175]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.44]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Valiant]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[18.10]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[105]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.46]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Duster 360]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[14.30]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[245]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.57]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Merc 240D]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[24.40]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[62]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.19]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.footer(
      table.cell(colspan: 5, align: left, inset: (top: 10pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, weight: "regular", tracking: 0.08em, fill: rgb("#64748B"))[#upper[Source · Motor Trend, 1974 · mtcars dataset.]]],
    )
  )
  ]
}
]
]
]
]
]
#block[
]
]
]
]
===== No title · no subtitle
<no-title-no-subtitle-1>
#figure([
#block(above: 2.5em, below: 2.5em)[
#block(inset: (x: 12.5pt, y: 0pt))[
#block(width: 100%, radius: 8pt, clip: true, stroke: 0.5pt + rgb("#E2E8F0"), fill: rgb("#F8FAFC"))[
#{ set text(size: 10pt, fill: _t.ink, weight: "regular", tracking: 0pt, style: "normal"); set table(inset: (x: 2.5mm, y: 10pt), stroke: none, fill: rgb("#F8FAFC"))
  [
  #table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr),
    align: (left, right, left, right, right,),
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Mazda RX4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[2.62]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Mazda RX4 Wag]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[2.88]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Datsun 710]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[22.80]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[93]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[2.32]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Hornet 4 Drive]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[21.40]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.21]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Hornet Sportabout]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[18.70]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[175]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.44]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Valiant]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[18.10]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[105]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.46]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Duster 360]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[14.30]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[245]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.57]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Merc 240D]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[24.40]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[62]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.19]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.footer(
      table.cell(colspan: 5, align: left, inset: (top: 10pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, weight: "regular", tracking: 0.08em, fill: rgb("#64748B"))[#upper[Source · Motor Trend, 1974 · mtcars dataset.]]],
    )
  )
  ]
}
]
]
]
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-no-header>


===== No title · no subtitle · zone-highlight
<no-title-no-subtitle-zone-highlight>
#zone-highlight(color: "metallic", above: -2mm)[
#block[
#block[
#block[
#block[
#block(above: 2.5em, below: 2.5em)[
#block(inset: (x: 12.5pt, y: 0pt))[
#block(width: 100%, radius: 8pt, clip: true, stroke: 0.5pt + rgb("#E2E8F0"), fill: none)[
#{ set text(size: 10pt, fill: _t.ink, weight: "regular", tracking: 0pt, style: "normal"); set table(inset: (x: 2.5mm, y: 10pt), stroke: none, fill: none)
  [
  #table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr),
    align: (left, right, left, right, right,),
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Mazda RX4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[2.62]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Mazda RX4 Wag]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[2.88]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Datsun 710]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[22.80]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[93]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[2.32]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Hornet 4 Drive]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[21.40]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.21]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Hornet Sportabout]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[18.70]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[175]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.44]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Valiant]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[18.10]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[105]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.46]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Duster 360]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[14.30]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[245]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.57]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Merc 240D]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[24.40]],
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "light")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[62]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[3.19]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.footer(
      table.cell(colspan: 5, align: left, inset: (top: 10pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, weight: "regular", tracking: 0.08em, fill: rgb("#64748B"))[#upper[Source · Motor Trend, 1974 · mtcars dataset.]]],
    )
  )
  ]
}
]
]
]
]
]
#block[
]
]
]
]
#callout(kind: "success", eyebrow: "ONE SYSTEM", title: "The same tokens, everywhere")[
The QoQ columns above, the KPI arrows and the diverging heatmap poles
are the exact same three hexes --- `chanwe_palette("signed")`. Change
them once and every chart, table and report follows.

]
= The Figure Frame
<the-figure-frame>
`chanwe_figure()` frames any ggplot: a header card (eyebrow, title, subtitle, a tag for the section), an optional KPI, a legend and a footer with the source and the ID. `style = "editorial"` is the research alternative: a rule, a hanging numeral, direct labels and one annotation.

== Card
<card>
#box(image("chanwer-showcase-pdf_files/figure-typst/frame-card-1.png"))

== Editorial
<editorial>
#box(image("chanwer-showcase-pdf_files/figure-typst/frame-editorial-1.png"))

== A table in the same frame
<a-table-in-the-same-frame>
#block(above: 2.5em, below: 2.5em)[
#block(inset: (x: 12.5pt, y: 0pt))[
#block(width: 100%, radius: 8pt, clip: true, stroke: 0.5pt + rgb("#E2E8F0"), fill: rgb("#F8FAFC"))[
#block(width: 100%, breakable: false)[#set block(spacing: 0pt)
#set par(spacing: 0pt, leading: 0.55em)
#pad(x: 2.4mm, top: 2.4mm, block(width: 100%, fill: none, radius: 2.6mm, inset: (x: 0mm, y: 0.6mm))[#set par(spacing: 0pt, leading: 0.5em);#block(width: 100%, fill: _t.ink, radius: 99pt, inset: (x: 2.6mm, y: 1.2mm), grid(columns: (1fr, auto), align: (left + horizon, right + horizon), [#box(baseline: -0.2pt, cw-dot(_t.primary, size: 3pt))#h(1.4mm)#text(font: _t.font-mono, size: 5pt, tracking: 0.12em, fill: _t.rule-cool)[#upper[Finanzas · Cierre]]], [#text(font: _t.font-mono, size: 4.8pt, tracking: 0.12em, fill: _t.fg-subtle)[#upper[Informe trimestral · 2.4]]]))#v(2.4mm, weak: false)#block(spacing: 0pt)[#text(font: _t.font-display, size: 9.5pt, weight: _t.weight-display, tracking: -0.04em, fill: _t.fg)[Ingresos por región]]#block(above: 1.4mm, spacing: 0pt)[#text(font: _t.font-sans, size: 6pt, fill: _t.fg-muted)[Primer y segundo trimestre de 2026, USD miles]]])
#v(2mm)
#{ set text(size: 10pt, fill: _t.ink, weight: "regular", tracking: 0pt, style: "normal"); set table(inset: (x: 2.5mm, y: 3.4pt), stroke: none, fill: rgb("#F8FAFC"))
  [
  #table(
    columns: (1fr, 1fr, 1fr, 1fr),
    align: (left, right, right, right,),
    table.header(
      table.cell(align: left, inset: (top: 4pt, bottom: 3.4pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[REGION]],
      table.cell(align: right, inset: (top: 4pt, bottom: 3.4pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[Q1]],
      table.cell(align: right, inset: (top: 4pt, bottom: 3.4pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[Q2]],
      table.cell(align: right, inset: (top: 4pt, bottom: 3.4pt, x: 2.5mm), fill: rgb("#11131912"))[#text(font: "JetBrains Mono", size: 5pt, fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[QOQ]],
    ),
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Norte]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[412,1]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[438,0]],
    table.cell(align: right)[#box(fill: rgb("#147705").transparentize(90%), radius: 99pt, inset: (x: 4pt, y: 2.2pt), baseline: 2.2pt)[#text(font: "JetBrains Mono", size: 6.3pt, fill: rgb("#147705"), weight: "medium")[+6,3 %]]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Centro]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[388,4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[371,2]],
    table.cell(align: right)[#box(fill: rgb("#CC1914").transparentize(90%), radius: 99pt, inset: (x: 4pt, y: 2.2pt), baseline: 2.2pt)[#text(font: "JetBrains Mono", size: 6.3pt, fill: rgb("#CC1914"), weight: "medium")[−4,4 %]]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Oeste]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[251,9]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[266,3]],
    table.cell(align: right)[#box(fill: rgb("#147705").transparentize(90%), radius: 99pt, inset: (x: 4pt, y: 2.2pt), baseline: 2.2pt)[#text(font: "JetBrains Mono", size: 6.3pt, fill: rgb("#147705"), weight: "medium")[+5,7 %]]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Sur]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[188,1]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "thin")[201,5]],
    table.cell(align: right)[#box(fill: rgb("#147705").transparentize(90%), radius: 99pt, inset: (x: 4pt, y: 2.2pt), baseline: 2.2pt)[#text(font: "JetBrains Mono", size: 6.3pt, fill: rgb("#147705"), weight: "medium")[+7,1 %]]],
    table.hline(stroke: 0.3pt + rgb("#E2E8F0")),
    table.hline(stroke: 0.5pt + _t.fg-muted),
    table.cell(align: left)[#text(font: "Satoshi", size: 6.3pt, fill: _t.ink, weight: "medium")[Total]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "medium")[1240,5]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 6.3pt, fill: _t.ink, weight: "medium")[1277,0]],
    table.cell(align: right)[#box(fill: rgb("#147705").transparentize(90%), radius: 99pt, inset: (x: 4pt, y: 2.2pt), baseline: 2.2pt)[#text(font: "JetBrains Mono", size: 6.3pt, fill: rgb("#147705"), weight: "medium")[+2,9 %]]],
  )
  ]
}
#block(width: 100%, stroke: (top: 0.5pt + _t.rule), inset: (x: 3.4mm, y: 1.4mm), grid(columns: (1fr, auto), align: (left + horizon, right + horizon), [#text(font: _t.font-sans, size: 6pt, weight: _t.weight-body, fill: _t.fg-subtle)[Fuente]#h(1.2mm)#text(font: _t.font-sans, size: 6pt, weight: _t.weight-body, fill: _t.fg-muted)[Cierre contable]], box(fill: _t.white, radius: 99pt, inset: (x: 1.8mm, y: 0.7mm))[#text(font: _t.font-sans, size: 6pt, weight: _t.weight-body, fill: _t.fg-muted)[CHW · FIN-03 · 2026]]))
]
]
]
]



