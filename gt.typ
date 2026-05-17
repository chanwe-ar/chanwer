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
// chanwe-studio/chanwe — typst-template.typ
// Page setup, design tokens, and global show rules.
// =============================================================

// ---------- Design tokens ------------------------------------
#let chanwe-tokens = (
  paper:       white,
  ink:         rgb("#0F0F0F"),
  fg:          rgb("#211F1C"),
  fg-muted:    rgb("#71706C"),
  fg-subtle:   rgb("#928D86"),
  primary:     rgb("#FB3D0E"),
  primary-dark: rgb("#EE5524"),
  primary-soft: rgb("#FB3D0E1A"),
  beige:       rgb("#F5F1EB"),
  neutral-100: rgb("#F5F5F5"),
  neutral-200: rgb("#E8E8E8"),
  neutral-300: rgb("#D4D4D4"),
  neutral-700: rgb("#525252"),
  neutral-900: rgb("#1F1F1F"),
  border:      rgb("#1F1F1F1A"),
  font-display: ("Archivo", "Helvetica Neue", "Arial"),
  font-serif:   ("Fraunces 9pt", "Georgia", "Times New Roman"),
  font-sans:    ("Satoshi", "Inter", "Helvetica Neue", "Arial"),
  font-mono:    ("JetBrains Mono", "Menlo", "Courier New"),
)

// expose tokens as a global so partials and user code can use them
#let _t = chanwe-tokens

// ---------- Brand palette ------------------------------------
// Three brand color ramps (100 = lightest, 950 = darkest).
#let main_brand = (
  // Orange — primary brand color
  orange-100: rgb("#f8ddd9"),
  orange-200: rgb("#f6cfc7"),
  orange-300: rgb("#f5c0b6"),
  orange-400: rgb("#f2a393"),
  orange-500: rgb("#f09482"),
  orange-600: rgb("#ef8670"),
  orange-700: rgb("#ed775f"),
  orange-800: rgb("#ec684e"),
  orange-900: rgb("#ea5a3c"),
  orange-950: rgb("#e94b2b"),

  // Dark — ink / neutral ramp
  dark-100: rgb("#cacaca"),
  dark-200: rgb("#b8b8b8"),
  dark-300: rgb("#a5a5a5"),
  dark-400: rgb("#929292"),
  dark-500: rgb("#6d6d6d"),
  dark-600: rgb("#5b5b5b"),
  dark-700: rgb("#484848"),
  dark-800: rgb("#353535"),
  dark-900: rgb("#232323"),
  dark-950: rgb("#101010"),

  // Beige — paper / warm neutral ramp
  beige-100: rgb("#F6F1EB"),
  beige-200: rgb("#ECE5D9"),
  beige-300: rgb("#E2DBD0"),
  beige-400: rgb("#D9D2C6"),
  beige-500: rgb("#CFC8BD"),
)

// assets path — override with chanwe-assets: in document YAML if the
// extension installed to a different path (e.g. _extensions/chanwe/)
#let _chanwe-assets = "\_extensions/chanwe/assets/".replace("\\_", "_")

// ---------- Small primitives ---------------------------------
#let chanwe-glyph(size: 7pt, color: _t.primary) = box(
  width: size, height: size, baseline: 1pt,
)[
  #place(center + horizon, rotate(45deg, square(size: size * 0.72, fill: color)))
]

#let chanwe-eyebrow(body, color: _t.primary, with-rule: false, size: 8.5pt) = {
  if with-rule {
    box(width: 22pt, height: 0.75pt, fill: color, baseline: -3pt)
    h(8pt)
  }
  text(
    font: _t.font-mono,
    size: size,
    weight: 500,
    tracking: 0.18em,
    fill: color,
    upper(body),
  )
}

#let chanwe-section-eyebrow(body) = chanwe-eyebrow(body, with-rule: true)

#let chanwe-meta-row(label, value, sub: none) = {
  grid(
    columns: (18mm, 1fr),
    column-gutter: 4mm,
    align: (left + top, left + top),
    text(font: _t.font-mono, size: 7pt, tracking: 0.20em, fill: _t.fg-subtle, upper(label)),
    block(spacing: 0pt)[
      #set par(spacing: 0pt, leading: 0.9em)
      #text(font: _t.font-display, size: 10pt, weight: 600, fill: _t.fg, value)
      #if sub != none {
        linebreak()
        text(font: _t.font-sans, size: 8.5pt, fill: _t.fg-muted, sub)
      }
    ],
  )
}

// ---------- Running header / footer --------------------------
#let chanwe-header(section, topic) = context {
  // header occupies 14mm; remaining margin space becomes gap before content
  block(height: 8mm, width: 100%)[
    #grid(
      rows: (1fr, auto),
      align(horizon, grid(
        columns: (1fr, auto),
        align: (left + horizon, right + horizon),
        {
          set text(font: _t.font-mono, size: 6pt, tracking: 0.14em)
          text(weight: 700, fill: _t.primary, "//")
          h(5pt)
          text(fill: _t.fg-subtle, upper[#section])
          if topic != "" {
            text(fill: _t.fg-subtle, upper[ · #topic])
          }
        },
        image(_chanwe-assets + "Logo_Negro.png", height: 3.5mm, fit: "contain"),
      )),
      pad(x: -18mm, line(length: 100% + 36mm, stroke: 0.5pt + _t.border)),
    )
  ]
}

#let chanwe-footer(doc-id, edition) = context {
  // line pins to top; text row grows to fill space → text centers
  block(height: 100%, width: 100%)[
    #grid(
      rows: (auto, 1fr),
      pad(x: -18mm, line(length: 100% + 36mm, stroke: 0.5pt + _t.border)),
      align(horizon, {
        set text(font: _t.font-mono, size: 6pt, tracking: 0.14em, fill: _t.fg-subtle)
        grid(
          columns: (1fr, auto),
          align: (left + horizon, right + horizon),
          [#upper[#doc-id #h(8pt) #text(fill: _t.neutral-300, edition)]],
          [#text(size: 6.9pt, fill: _t.ink, weight: 600, upper(str(counter(page).get().first())))#text(size: 6.9pt, fill: _t.fg-subtle, upper(" / " + str(counter(page).final().first())))],
        )
      }),
    )
  ]
}

// Global state — set by chanwe() and read by components
#let _chanwe-doc = state("chanwe-doc", (
  doc-id:    "CHW · DOC",
  edition:   "",
  meta-rows: (),
))

// Tracks the active chapter-divider section (set in chanwe-chapter-divider)
#let _chanwe-cur-part = state("chanwe-cur-part", none)

// =============================================================
// PARTIAL INCLUDES (cover, elements, pages)
// Each file uses _t which is defined above.
// =============================================================
// =============================================================
// chanwe-cover.typ — full-bleed A4 cover page (1:1 to HTML)
// =============================================================
// HTML grid:  10mm top bar | 1fr hero (rail 86mm + panel) | 50mm slab
// At A4 (297mm tall) the hero region is 237mm.
// =============================================================

// Pandoc/Quarto escapes underscores in YAML values (bg_x → bg\_x).
// Strip those backslashes so image() gets the real filesystem path.
#let _chanwe-clean-path(p) = if p == none { none } else { p.replace("\\_", "_").replace("\\-", "-") }

#let chanwe-cover-page(
  title: "Untitled",
  subtitle: none,
  doc-id: "CHW · DOC · 2026 · 01",
  edition: "Edition 01 / 2026",
  volume: "Vol. II",
  rail-eyebrow: "Quarto · Style Guide",
  hero-image: none,
  hero-img-position: none,  // 1–10 (left→right); none = fit:cover (centered)
  wordmark: none, // defaults to Logo_Negro.png below
  stamp: ("est.", "mdz", "2026"),
  hero-caption-1: "S 32°53′ · W 68°50′",
  hero-caption-2: "Cordón del Plata · ARG",
  hero-date: "17 · 04 · 2026",
  meta-rows: (),
  date: "",
  show-date-strip: false,
  cover-edge: none,
  cover-edge-color: none,
) = {
  let hero-image = if hero-image == none {
    _chanwe-assets + "hero-img.svg"
  } else {
    _chanwe-clean-path(hero-image)
  }
  let _edge-color = if cover-edge-color != none { cover-edge-color } else { _t.primary }
  let wordmark   = if wordmark == none { _chanwe-assets + "Logo_Negro.png" } else { _chanwe-clean-path(wordmark) }
  set page(
    paper: "a4", margin: 0pt, header: none, footer: none, fill: _t.paper,
    foreground: {
      place(top + left, dx: 50mm, dy: -50mm,
        circle(radius: 110mm,
          fill: gradient.radial(_t.primary.transparentize(78%), black.transparentize(100%)),
          stroke: none,
        )
      )
      if cover-edge != none {
        place(right + top, dx: -3mm, dy: 14mm,
          rotate(-90deg, origin: right + horizon,
            text(font: _t.font-mono, size: 7pt, weight: 200, tracking: 0.5em,
                 fill: _edge-color, upper(cover-edge))
          )
        )
      }
    },
  )
  set block(spacing: 0pt)

  // ---- 1. TOP METADATA BAR (10mm) ---------------------------
  block(
    width: 100%, height: 10mm,
    fill: _t.paper,
    stroke: (bottom: 0.5pt + _t.neutral-900),
    inset: (x: 16mm, y: 0pt),
  )[
    #set align(horizon)
    #grid(
      columns: (1fr, 1fr),
      align: (left + horizon, right + horizon),
      // doc id (left)
      {
        set text(font: _t.font-mono, size: 7pt, tracking: 0.16em, fill: _t.fg)
        text(weight: 700, fill: _t.primary, "//")
        h(6pt)
        upper[#text(weight: 600, fill: _t.fg, doc-id)]
      },
      // edition · volume (right)
      {
        set text(font: _t.font-mono, size: 7pt, tracking: 0.16em)
        upper[#text(weight: 600, fill: _t.fg, edition)]
        h(16pt)
        upper[#text(fill: _t.fg-muted, volume)]
      },
    )
  ]

  // ---- 2. HERO REGION (237mm) -------------------------------
  block(width: 100%, height: 237mm, breakable: false)[
    #grid(
      columns: (136.5mm, 73.5mm),
      rows: (237mm,),
      column-gutter: 0pt,

      // ---------- LEFT RAIL ----------
      block(
        width: 100%, height: 237mm,
        fill: _t.paper,
        stroke: (right: 1pt + _t.neutral-900),
        inset: (left: 16mm, right: 9mm, top: 14mm, bottom: 12mm),
      )[
        // eyebrow with rule
        #chanwe-eyebrow(rail-eyebrow, with-rule: true)

        #v(8mm)

        // big display title — emph parts render in Fraunces italic
        #set par(leading: 0.8em, justify: false)
        #show emph: it => text(font: _t.font-serif, size: 44pt, weight: 200, style: "italic", fill: _t.primary, it.body)
        #block[
          #text(
            font: _t.font-display, size: 36pt, weight: 600,
            tracking: -0.04em, fill: _t.neutral-900,
            title,
          )#h(3pt)#box(width: 8pt, height: 8pt, baseline: -2pt,
            circle(fill: _t.primary, stroke: none))
        ]

        #if subtitle != none {
          v(8mm)
          set par(leading: 0.55em)
          set text(font: _t.font-serif, size: 14pt, weight: 200, style: "italic", fill: _t.fg-subtle)
          subtitle
        }

        #v(1fr)
        #line(length: 100%, stroke: 0.5pt + _t.border)
        #v(6mm)

        // stack of label / value / sub rows
        #stack(
          spacing: 9mm,
          ..meta-rows.map(((label, value, sub)) => chanwe-meta-row(label, value, sub: sub))
        )
      ],

      // ---------- RIGHT HERO PANEL ----------
      box(
        width: 100%, height: 237mm,
        fill: _t.ink,
        clip: true,
      )[
        // hero image fills the panel
        #if hero-img-position == none {
          place(top + left,
            image(hero-image, width: 100%, height: 237mm, fit: "cover"))
        } else {
          // place() must be in direct content flow; context{} computes the
          // shift and returns move(dx, img) which gets placed at top+left
          place(top + left,
            context {
              let pos-frac = calc.clamp((hero-img-position - 1) / 9, 0, 1)
              let img = image(hero-image, height: 237mm)
              let excess = calc.max(measure(img).width - 73.5mm, 0pt)
              move(dx: -pos-frac * excess, img)
            }
          )
        }


        // Bottom-right caption (geographic coords)
        #place(bottom + right, dx: -16mm, dy: -16mm)[
          #box(
            inset: (x: 8pt, y: 4pt),
            fill: white.transparentize(50%),
            stroke: 0.5pt + black.transparentize(90%),
          )[
            #set align(right)
            #set par(leading: 0.4em)
            #text(
              font: _t.font-mono, size: 6.5pt, weight: 500, tracking: 0.20em,
              fill: black.transparentize(35%),
              [
                #upper(hero-caption-1) \
                #upper(hero-caption-2)
              ],
            )
          ]
        ]
      ],
    )
  ]

  // ---- 3. BOTTOM SLAB (50mm) - huge wordmark ----------------
  block(
    width: 100%, height: 50mm,
    fill: _t.paper,
    stroke: (top: 0.5pt + _t.neutral-900),
    inset: (x: 14mm, top: 0mm, bottom: 0mm),
  )[
    #set align(center + horizon)
    #align(center + horizon, image(wordmark, height: 45mm, fit: "contain"))
  ]

  // ---- BLANK INTERSTITIAL PAGE ------------------------------
  set page(paper: "a4", margin: 0pt, header: none, footer: none, fill: rgb("#F7F7F7"), foreground: none)
  set block(spacing: 0pt)

  // centered icon
  place(center + horizon, image(_chanwe-assets + "Iconos_Beige.png", width: 60mm, fit: "contain"))

  // full-height spacer pushes wordmark to bottom
  block(width: 100%, height: 247mm)[]
  block(
    width: 100%, height: 50mm,
    fill: rgb("#F7F7F7"),
    inset: (x: 14mm, top: 0mm, bottom: 0mm),
  )[
    #set align(center + horizon)
    #align(center + horizon, image(_chanwe-assets + "Logo_Beige.png", height: 45mm, fit: "contain"))
  ]
}

// =============================================================
// BACK COVER — full-bleed black page
// =============================================================
#let _chanwe-blank-interstitial() = {
  set page(paper: "a4", margin: 0pt, header: none, footer: none, fill: rgb("#F7F7F7"), foreground: none)
  set block(spacing: 0pt)
  place(center + horizon, image(_chanwe-assets + "Iconos_Beige.png", width: 60mm, fit: "contain"))
  block(width: 100%, height: 297mm)[]
}

#let chanwe-back-cover-page(
  wordmark-light: none,
  tagline-1: "Less template,",
  tagline-2: "more report.",
  back-cols: (),
  cover-edge: none,
) = {
  let wl = if wordmark-light != none { _chanwe-clean-path(wordmark-light) } else { _chanwe-assets + "Logo_Blanco.png" }

  // ---- blank interstitial before back cover -----------------
  _chanwe-blank-interstitial()

  // ---- back cover -------------------------------------------
  set page(
    paper: "a4", margin: 0pt, header: none, footer: none, fill: _t.ink,
    background: place(top + left, dx: -50mm, dy: -50mm,
      circle(radius: 110mm,
        fill: gradient.radial(_t.primary.transparentize(93%), black.transparentize(100%)),
        stroke: none,
      )
    ),
    foreground: if cover-edge != none {
      place(right + top, dx: -3mm, dy: 14mm,
        rotate(-90deg, origin: right + horizon,
          text(font: _t.font-mono, size: 7pt, weight: 200, tracking: 0.5em,
               fill: white.transparentize(25%), upper(cover-edge))
        )
      )
    },
  )
  set block(spacing: 0pt)

  block(
    width: 100%, height: 297mm, breakable: false,
    inset: (x: 16mm, top: 14mm, bottom: 14mm),
  )[
    #grid(
      rows: (auto, 1fr, auto),
      row-gutter: 0pt,

      // Row 1: wordmark
      align(left + top,
        if wl != none {
          image(wl, height: 20.2mm, fit: "contain")
        } else {
          text(font: _t.font-display, size: 36pt, weight: 800,
               tracking: -0.04em, fill: white, "chanwe")
        }
      ),

      // Row 2: spacer
      [],

      // Row 3: icon + tagline + separator + metadata
      block[
        #image(_chanwe-assets + "Estrategia_Color.png", height: 10mm, fit: "contain")
        #v(12mm)
        #set par(leading: 0.8em, justify: false)
        #text(font: _t.font-serif, style: "italic", size: 40pt,
              weight: 200, fill: white, tagline-1)
        #linebreak()
        #text(font: _t.font-serif, style: "italic", size: 40pt,
              weight: 200, fill: _t.primary, tagline-2)
        #v(8mm)
        #line(length: 100%, stroke: 0.5pt + white.transparentize(75%))
        #v(8mm)
        #if back-cols.len() > 0 {
          grid(
            columns: back-cols.map(_ => 1fr),
            column-gutter: 8mm,
            ..back-cols.map(((label, value, sub)) => block(spacing: 0pt)[
              #text(font: _t.font-mono, size: 6pt, tracking: 0.20em,
                    fill: white.transparentize(50%), upper(label))
              #v(2.5mm)
              #text(font: _t.font-display, size: 9.5pt, weight: 700, fill: white, value)
              #if sub != none and sub != "" {
                linebreak()
                v(0.5mm)
                text(font: _t.font-sans, size: 8pt, fill: white.transparentize(40%), sub)
              }
            ])
          )
        }
      ],

    )
  ]
}// =============================================================
// chanwe-elements.typ — callouts, pull quotes, great quote pages
// Available to authors as #callout, #pullquote, #great-quote
// =============================================================

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

  // Derive dot color + type label from icon_color (Quarto native) or kind (our API)
  let (dot-color, auto-label) = if icon_color != none {
    let lbl = if icon_color == rgb("#0758E5")      { "NOTE" }
         else if icon_color == rgb("#00A047")       { "TIP" }
         else if icon_color == rgb("#EB9113")       { "WARNING" }
         else if icon_color == rgb("#CC1914")       { "IMPORTANT" }
         else if icon_color == rgb("#FC5300")       { "CAUTION" }
         else                                       { "NOTE" }
    (icon_color, lbl)
  } else if kind == "warn" or kind == "warning" {
    (rgb("#EB9113"), "WARNING")
  } else if kind == "tip" {
    (rgb("#00A047"), "TIP")
  } else if kind == "caution" {
    (rgb("#FC5300"), "CAUTION")
  } else if kind == "important" {
    (rgb("#CC1914"), "IMPORTANT")
  } else if kind == "note" {
    (rgb("#0758E5"), "NOTE")
  } else if kind == "do" {
    (rgb("#15803D"), "DO")
  } else if kind == "dont" {
    (rgb("#CC1914"), "DON'T")
  } else {
    (_t.primary, upper(kind))
  }

  let type-label = if eyebrow != none { upper(eyebrow) } else { auto-label }
  let display-title = if title != none { title } else { type-label }

  block(
    fill: white,
    stroke: 0.5pt + _t.neutral-300,
    radius: 4pt,
    width: 100%,
    inset: 0pt,
    above: 10mm,
    below: 10mm,
    breakable: false,
    clip: true,
  )[
    #block(fill: rgb("#EDF0F1"), inset: (x: 4.5mm, top: 2.5mm, bottom: 2.5mm), width: 100%, spacing: 0pt)[
      #grid(
        columns: (auto, auto, auto, 1fr),
        column-gutter: 5pt,
        align: left + horizon,
        circle(radius: 3pt, fill: dot-color),
        text(font: _t.font-mono, size: 7pt, fill: _t.fg-subtle, "//"),
        text(font: _t.font-mono, size: 7pt, tracking: 0.14em, fill: _t.fg-subtle, type-label),
        text(font: _t.font-display, size: 8pt, weight: 700, fill: _t.ink, display-title),
      )
    ]
    #block(spacing: 0pt)[#line(length: 100%, stroke: 0.5pt + _t.neutral-300)]
    #block(inset: (x: 4.5mm, y: 5mm), width: 100%, spacing: 0pt)[
      #set block(spacing: 0.85em)
      #set text(fill: _t.fg-muted, size: 9.5pt)
      #content
    ]
  ]
}

#let pullquote(body, attribution: none) = block(
  above: 6mm, below: 6mm,
  inset: (left: 6mm),
  stroke: (left: 2pt + _t.primary),
)[
  #text(font: _t.font-serif, size: 16pt, weight: 300, style: "italic", fill: _t.neutral-900, body)
  #if attribution != none {
    v(3mm)
    text(font: _t.font-mono, size: 8pt, tracking: 0.18em, fill: _t.fg-subtle, upper[— #attribution])
  }
]

#let _gq-scheme(color, inset: false) = if color == "light" {
  (
    bg:     _t.neutral-100,
    eyebrow: _t.primary,
    quote:  _t.neutral-900,
    emph:   _t.primary,
    attr:   _t.fg,
    source: _t.fg-subtle,
    line:   _t.primary,
  )
} else if color == "beige" {
  (
    bg:     _t.beige,
    eyebrow: _t.primary,
    quote:  _t.neutral-900,
    emph:   _t.primary,
    attr:   _t.fg,
    source: _t.fg-subtle,
    line:   _t.primary,
  )
} else if color == "primary" {
  (
    bg:     if inset { _t.primary-dark } else { _t.primary },
    eyebrow: white,
    quote:  white,
    emph:   white,
    attr:   white,
    source: white.transparentize(30%),
    line:   white,
  )
} else {
  (
    bg:     _t.ink,
    eyebrow: _t.primary,
    quote:  white,
    emph:   _t.primary,
    attr:   white,
    source: white.transparentize(40%),
    line:   _t.primary,
  )
}

#let page-great-quote(caption: none, source: none, color: "dark", body) = {
  let s = _gq-scheme(color)
  set page(paper: "a4", margin: 0pt, header: none, footer: none, fill: s.bg)
  block(
    width: 100%, height: 100%,
    inset: (x: 22mm, top: 40mm, bottom: 30mm),
    fill: s.bg,
  )[
    #show emph: it => text(fill: s.emph, style: "italic", it.body)
    #chanwe-eyebrow("Verbatim", color: s.eyebrow, with-rule: true, size: 12pt)
    #v(6mm)
    #set par(leading: 0.64em)
    #text(
      font: _t.font-serif, size: 40pt, style: "italic", weight: 100,
      tracking: -0.01em, fill: s.quote,
    )[\u{201C}#body\u{201D}]
    #v(1fr)
    #if caption != none {
      line(length: 30%, stroke: 1pt + s.line)
      v(5mm)
      text(font: _t.font-display, size: 12pt, weight: 600, tracking: 0.08em, fill: s.attr, caption)
      if source != none {
        v(3mm)
        text(font: _t.font-mono, size: 8pt, tracking: 0.18em, fill: s.source, upper(source))
      }
    }
  ]
}

#let inset-great-quote(caption: none, source: none, color: "dark", body) = {
  let s = _gq-scheme(color, inset: true)
  move(dx: -18mm,
    block(
      width: 210mm,
      fill: s.bg,
      inset: (x: 22mm, top: 12mm, bottom: 14mm),
    )[
      #show emph: it => text(fill: s.emph, style: "italic", it.body)
      #set par(leading: 0.64em)
      #chanwe-eyebrow("Verbatim", color: s.eyebrow, with-rule: true)
      #v(3mm)
      #text(
        font: _t.font-serif, size: 22pt, style: "italic", weight: 100,
        tracking: -0.01em, fill: s.quote,
      )[\u{201C}#body\u{201D}]
      #if caption != none {
        v(8mm)
        line(length: 20%, stroke: 1pt + s.line)
        v(4mm)
        text(font: _t.font-display, size: 10pt, weight: 600, tracking: 0.08em, fill: s.attr, caption)
        if source != none {
          linebreak()
          v(1mm)
          text(font: _t.font-mono, size: 7.5pt, tracking: 0.18em, fill: s.source, upper(source))
        }
      }
    ]
  )
}

#let inset-great-figure(
  eyebrow: none,
  title: "",
  source: none,
  layout: "center",
  position: "right",
  color: "dark",
  caption: [],
  body,
) = {
  let s = _gq-scheme(color, inset: true)
  let col-widths = if layout == "left" {
    (3fr, 7fr)
  } else if layout == "right" {
    (7fr, 3fr)
  } else {
    (1fr, 1fr)
  }

  let text-col = block(width: 100%)[
    #if eyebrow != none {
      block(below: 3mm)[
        #chanwe-eyebrow(eyebrow, color: s.eyebrow, with-rule: true)
      ]
    }
    #if title != "" {
      block(below: 5mm, above: if eyebrow != none { 4mm } else { 0mm })[
        #set par(leading: 0.64em)
        #text(font: _t.font-display, size: 14pt, weight: 700,
              tracking: -0.01em, fill: s.quote, title)
      ]
    }
    #set text(font: _t.font-sans, size: 10pt, fill: s.source)
    #caption
  ]

  let plot-col = block(width: 100%)[
    #body
    #if source != none {
      v(3mm)
      text(font: _t.font-mono, size: 7pt, tracking: 0.16em,
           fill: s.source, upper(source))
    }
  ]

  let (first-col, second-col) = if position == "left" {
    (plot-col, text-col)
  } else {
    (text-col, plot-col)
  }

  move(dx: -18mm,
    block(
      width: 210mm,
      fill: s.bg,
      inset: (x: 22mm, top: 14mm, bottom: 14mm),
    )[
      #show emph: it => text(fill: s.emph, style: "italic", it.body)
      #grid(
        columns: col-widths,
        column-gutter: 14mm,
        align: (left + top, left + top),
        first-col,
        second-col,
      )
    ]
  )
}

#let inset-great-summary(
  eyebrow: "Executive Summary",
  title: "",
  color: "white",
  body,
) = {
  let bg      = if color == "gray" { rgb("#EDF0F1") } else if color == "light" { _t.neutral-100 } else if color == "beige" { _t.beige } else { white }
  let borders = color != "gray" and color != "light" and color != "white" and color != "beige"
  move(dx: -18mm,
    block(
      width: 210mm,
      fill: bg,
      inset: (x: 22mm, top: 0pt, bottom: 0pt),
    )[
      #if borders { line(length: 100%, stroke: 0.5pt + _t.neutral-900) }
      #block(width: 100%, inset: (top: 12mm, bottom: 14mm))[
        #grid(
          columns: (4fr, 6fr),
          column-gutter: 14mm,
          align: (left + top, left + top),
          text(
            font: _t.font-mono, size: 8.5pt, weight: 500,
            tracking: 0.18em, fill: _t.primary,
            "// " + upper(eyebrow),
          ),
          block(width: 100%)[
            #if title != "" {
              block(below: 7mm)[
                #set par(leading: 0.72em)
                #text(font: _t.font-display, size: 14pt, weight: 700, fill: _t.ink, title)
              ]
              line(length: 18mm, stroke: 1.5pt + _t.primary)
              v(4mm)
            }
            #set text(size: 10pt, fill: _t.fg)
            #set par(leading: 0.75em)
            #body
          ],
        )
      ]
      #if borders { line(length: 100%, stroke: 0.5pt + _t.neutral-900) }
    ]
  )
}

#let _great-findings-row(number: "01", title: "", body) = {
  grid(
    columns: (auto, 1fr),
    column-gutter: 6mm,
    align: (left + top, left + top),
    text(
      font: _t.font-serif, size: 38pt, weight: 100, style: "italic",
      fill: _t.primary, number,
    ),
    block(width: 100%)[
      #block(below: 4mm)[
        #text(font: _t.font-display, size: 11.5pt, weight: 700, fill: _t.ink, title)
      ]
      #set text(size: 9pt, fill: _t.fg-muted)
      #set par(leading: 0.72em)
      #body
    ],
  )
}

#let great-findings(number: "01", title: "", color: "white", body) = {
  let bg = if color == "gray" { rgb("#EDF0F1") } else if color == "light" { _t.neutral-100 } else { none }
  block(width: 100%, fill: bg, radius: 4pt, inset: (top: 7mm, bottom: 7mm))[
    #_great-findings-row(number: number, title: title, body)
  ]
}

// item used inside a great-findings-grid (no individual bg)
#let great-findings-item(number: "01", title: "", body) = {
  block(width: 100%, inset: (top: 6mm, bottom: 6mm))[
    #_great-findings-row(number: number, title: title, body)
  ]
}

// wrapper that applies a unified background with dividers between items
#let great-findings-grid(color: "white", body) = {
  let bg = if color == "gray" { rgb("#EDF0F1") } else if color == "light" { _t.neutral-100 } else { none }
  let stroke-top-bottom = if color == "white" { 0.5pt + _t.neutral-900 } else { none }
  block(width: 100%, fill: bg, radius: if bg == none { 0pt } else { 4pt },
    stroke: (top: stroke-top-bottom, bottom: stroke-top-bottom),
    inset: (x: 6mm, y: 5mm))[
    #body
  ]
}

// =============================================================
// KPI cards
// =============================================================

#let _kpi-color(name) = {
  if name == "primary" { _t.primary }
  else if name == "green" { rgb("#15803D") }
  else if name == "red" { rgb("#CC1914") }
  else if name == "ink" { _t.ink }
  else { _t.fg-muted }
}

#let kpi-card(
  title: "",
  main: "",
  prefix: "",
  unit: "",
  main-color: "ink",
  secondary: "",
  secondary-color: "primary",
  direction: "none",
) = {
  let mc = if main-color == "ink" { _t.ink } else { _kpi-color(main-color) }
  let (dir-symbol, dir-color) = {
    if direction == "up" { ("▲", "green") }
    else if direction == "down" { ("▼", "red") }
    else if direction == "neutral" { ("—", "ink") }
    else { ("", secondary-color) }
  }
  let sc = _kpi-color(if direction == "none" { secondary-color } else { dir-color })

  block(
    fill: luma(248),
    stroke: 0.5pt + _t.neutral-300,
    radius: 5pt,
    width: 100%,
    height: 42mm,
    inset: (x: 5mm, top: 5mm, bottom: 5mm),
  )[
    // Direction arrow — top-right corner, outside normal flow
    #if direction != "none" {
      place(top + right,
        text(font: _t.font-sans, size: 9pt, weight: 700, fill: sc, dir-symbol)
      )
    }
    #stack(dir: ttb, spacing: 0pt,
      // title
      block(height: 8mm, width: 100%, clip: false)[
        #set par(leading: 0.7em)
        #text(font: _t.font-mono, size: 7.5pt, weight: 500, fill: _t.primary, "// ")#text(font: _t.font-mono, size: 7.5pt, weight: 500, fill: _t.fg-subtle, upper(title))
      ],
      v(5mm),   // gap: title → main
      // main number
      block(below: 0pt)[
        #if prefix != "" {
          text(font: _t.font-display, size: 14pt, weight: 700, fill: _t.fg-muted, prefix)
          h(0.5mm)
        }
        #text(font: _t.font-serif, size: 32pt, weight: 600, style: "italic", fill: mc, main)
        #if unit != "" {
          h(1mm)
          text(font: _t.font-display, size: 10pt, weight: 600, fill: _t.fg-muted, unit)
        }
      ],
      v(1fr),   // gap: main → secondary (flexible, secondary pinned to bottom)
      // secondary
      if secondary != "" {
        block(below: 0pt)[
          #set text(font: _t.font-sans, size: 8pt, fill: sc)
          #set par(leading: 0.7em)
          #secondary
        ]
      },
    )
  ]
}

#let kpi-grid(cols: 4, rows: auto, items) = {
  grid(
    columns: range(cols).map(_ => 1fr),
    rows: if rows == auto { auto } else { range(rows).map(_ => auto) },
    column-gutter: 4mm,
    row-gutter: 4mm,
    ..items,
  )
}

// =============================================================
// ZONE HIGHLIGHT — full-bleed background color zone
// =============================================================
// color: "metallic" | "white" | "white-ivory" | "beige" | "gray" | "dark" | "orange"
#let zone-highlight(color: "metallic", margin: 2mm, above: 2mm, below: 2mm, body) = {
  let bg = if color == "metallic"        { rgb("#F7F7F7") }
    else if color == "beige"             { _t.beige       }
    else if color == "white-ivory"       { rgb("#FAFAFA") }
    else if color == "gray"              { rgb("#EDF0F1") }
    else if color == "dark"              { _t.ink         }
    else if color == "orange"            { _t.primary     }
    else if color.starts-with("#")       { rgb(color)     }
    else                                 { white          }
  let on-dark = color == "dark" or color == "orange"

  if above != none { v(above) }
  move(dx: -18mm,
    block(
      width: 210mm,
      fill: bg,
      inset: (x: 22mm, top: margin, bottom: margin),
      spacing: 0pt,
    )[
      #if on-dark { set text(fill: white) }
      #body
    ]
  )
  if below != none { v(below) }
}

#let fig-border(body) = {
  v(4mm, weak: true)
  block(breakable: false)[
    #line(length: 100%, stroke: 0.1pt + _t.ink)
    #pad(top: 0mm, bottom: 0mm)[#body]
    #line(length: 100%, stroke: 0.1pt + _t.ink)
  ]
  v(4mm, weak: true)
}// =============================================================
// chanwe-pages.typ — editorial pages 1:1 to HTML
// AGENDA · ABSTRACT · CHAPTER SEPARATOR · BACK COVER
// =============================================================

#let _pad2(n) = if n < 10 { "0" + str(n) } else { str(n) }

// ---------- AGENDA / TABLE OF CONTENTS -----------------------
#let chanwe-toc-row(num: "", label: "", page: "", sub: false) = block(spacing: 0pt)[
  #set par(spacing: 0pt, leading: 0pt)
  #if sub {
    grid(
      columns: (10mm, 14mm, 1fr, 12mm),
      column-gutter: 4mm,
      align: (left + bottom, left + bottom, left + bottom, right + bottom),
      [],
      text(font: _t.font-mono, size: 7.5pt, tracking: 0.12em, weight: 100, fill: _t.fg-subtle, num),
      text(font: _t.font-mono, size: 7.5pt, weight: 100, fill: _t.fg-subtle, label),
      text(font: _t.font-mono, size: 7.5pt, tracking: 0.14em, weight: 100, fill: _t.fg-subtle, page),
    )
  } else {
    grid(
      columns: (14mm, 1fr, 12mm),
      column-gutter: 4mm,
      align: (left + bottom, left + bottom, right + bottom),
      text(font: _t.font-mono, size: 7.5pt, tracking: 0.12em, weight: 100, fill: _t.fg-subtle, num),
      text(font: _t.font-mono, size: 7.5pt, weight: 100, fill: _t.ink, label),
      text(font: _t.font-mono, size: 7.5pt, tracking: 0.14em, weight: 100, fill: _t.fg-muted, page),
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
        font: _t.font-serif, style: "italic", weight: 300,
        size: 28pt, tracking: -0.01em, fill: _t.primary,
        numeral,
      ),
      text(
        font: _t.font-display, size: 14pt, weight: 700,
        tracking: -0.005em, fill: _t.neutral-900, title,
      ),
      text(
        font: _t.font-mono, size: 8pt, tracking: 0.18em,
        fill: _t.fg-subtle, upper(pages),
      ),
    )
    #v(2mm)
    #line(length: 100%, stroke: 0.5pt + _t.neutral-900)
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

#let chanwe-agenda(
  eyebrow: "Document map",
  title: "Agenda",
  lede: none,
  groups: none,
  parts: none,
) = {
  v(10mm)
  // section eyebrow with rule
  chanwe-section-eyebrow(eyebrow)

  v(7.5mm)

  // big page-display title with orange italic period
  block[
    #text(
      font: _t.font-display, size: 56pt, weight: 700,
      tracking: -0.025em, fill: _t.neutral-900, title,
    )
    #box(width: 10pt, height: 10pt, baseline: 0pt,
      circle(fill: _t.primary, stroke: none))
  ]

  if lede != none {
    v(15mm)
    block(width: 130mm)[
      #set par(leading: 0.55em)
      #set text(font: _t.font-sans, size: 10pt, weight: 400, fill: _t.fg-muted)
      #lede
    ]
  }

  v(14mm)

  if groups != none {
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
        text(font: _t.font-serif, style: "italic", weight: 300, size: 24pt, fill: _t.primary, num),
        {
          text(font: _t.font-display, size: 13pt, weight: 700, tracking: -0.005em, fill: _t.neutral-900, ptitle)
          linebreak()
          v(1.5mm)
          text(font: _t.font-sans, size: 9.5pt, fill: _t.fg-muted, desc)
        },
        text(font: _t.font-mono, size: 8pt, tracking: 0.12em, fill: _t.fg-subtle, upper(pg)),
      )
      v(3mm)
      line(length: 100%, stroke: 0.5pt + _t.border)
      v(4mm)
    }
  } else {
    // --- AUTO mode: driven by outline() with independent counters ---
    // Part labels (from chanwe-chapter-divider) are injected between groups
    // without changing the H1 group-header hierarchy.
    let _h1 = counter("_chanwe-toc-h1")
    let _h2 = counter("_chanwe-toc-h2")
    let _h3 = counter("_chanwe-toc-h3")

    show outline.entry: it => {
      if it.level == 1 {
        _h1.step()
        _h2.update(0)
        _h3.update(0)
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
            v(if is-first { 0mm } else { 14mm })
            move(dx: -18mm,
              block(
                width: 210mm,
                fill: _t.neutral-100,
                inset: (x: 18mm, top: 10mm, bottom: 8mm),
              )[
                #grid(
                  columns: (auto, auto),
                  column-gutter: 6mm,
                  align: (left + bottom, left + bottom),
                  text(font: _t.font-serif, style: "italic", weight: 200,
                       size: 32pt, fill: _t.primary, cur-part.number),
                  {
                    text(font: _t.font-serif, style: "italic", weight: 200,
                         size: 26pt, tracking: -0.02em, fill: luma(90),
                         cur-part.title)
                    text(font: _t.font-serif, style: "italic", weight: 200,
                         size: 26pt, fill: _t.primary, ".")
                  },
                )
              ]
            )
            v(8mm)
          }

          block(above: if cur-part != none and cur-num != prev-num { 0mm } else if is-first { 0mm } else { 12mm }, below: 0pt)[
            #v(4mm)
            #grid(
              columns: (18mm, 1fr, 34mm),
              column-gutter: 0mm,
              align: (left + bottom, left + bottom, right + bottom),
              text(font: _t.font-serif, style: "italic", weight: 300,
                   size: 24pt, fill: _t.primary, _pad2(n)),
              text(font: _t.font-display, size: 16pt, weight: 600,
                   fill: _t.neutral-900, it.body()),
              text(font: _t.font-mono, size: 7pt, tracking: 0.18em,
                   fill: _t.fg-subtle, upper(pages_str)),
            )
            #v(4mm)
            #line(length: 100%, stroke: 0.5pt + _t.neutral-900)
            #v(2mm)
          ]
        }
      } else if it.level == 2 {
        _h2.step()
        _h3.update(0)
        context {
          let n  = _h2.get().first()
          let pg = counter(page).at(it.element.location()).first()
          v(1.5mm)
          chanwe-toc-row(num: _pad2(n), label: it.element.body, page: _pad2(pg))
          v(-1.5mm)
          line(length: 100%, stroke: 0.5pt + _t.border)
        }
      } else if it.level == 3 {
        _h3.step()
        context {
          let h2n = _h2.get().first()
          let h3n = _h3.get().first()
          let pg  = counter(page).at(it.element.location()).first()
          v(1.5mm)
          chanwe-toc-row(num: str(h2n) + "." + str(h3n), label: it.element.body, page: _pad2(pg), sub: true)
          v(-1.5mm)
          line(length: 100%, stroke: 0.5pt + _t.border)
        }
      }
    }
    outline(title: none, depth: 3)
  }
}

// =============================================================
// ABSTRACT WITH DROP-CAP
// =============================================================
// HTML structure:
//   .abstract-wrap  (60mm side rail | 1fr body)
//     .abstract-side  (label-row × N, hairline border-right)
//     .abstract-body
//       h2 (Archivo 28pt 700)
//       p.lead   (Fraunces 12pt body, ::first-letter 56pt drop-cap)
//       p · p · ... (Fraunces 12pt body)
// =============================================================
#let chanwe-side-row(label: "", value: "", dark: false) = {
  let lc = if dark { white.transparentize(45%) } else { _t.fg-subtle }
  let vc = if dark { white                     } else { _t.fg        }
  stack(
    dir: ttb, spacing: 8pt,
    text(font: _t.font-mono, size: 7.5pt, weight: 500,
         tracking: 0.18em, fill: lc, upper(label)),
    text(font: _t.font-sans, size: 10pt, weight: 500, fill: vc, value),
  )
}

#let chanwe-abstract(
  // new compact call style: eyebrow / title / meta
  eyebrow: none,
  title: none,
  meta: none,            // array of (label, value, sub) 3-tuples
  takeaway: none,
  dark: false,           // true → inverted text colors for dark backgrounds
  // original verbose style kept for backward compat
  page-eyebrow: "01 · Abstract",
  page-title: "A reference, not a document.",
  side-rows: (),
  abstract-heading: "Abstract",
  lead: none,
  paragraphs: (),
  // captures optional trailing content block [...]
  ..args,
) = {
  let body = if args.pos().len() > 0 { args.pos().at(0) } else { none }
  // resolve aliases
  let resolved-eyebrow = if eyebrow != none { eyebrow } else { page-eyebrow }
  let resolved-title   = if title   != none { title   } else { page-title   }
  let resolved-rows    = if meta    != none {
    meta.map(((lbl, val, ..rest)) => (
      label: lbl,
      value: if rest.len() > 0 { val + "\n" + rest.at(0) } else { val },
    ))
  } else { side-rows }

  // color scheme shortcuts
  let title-color  = if dark { white                     } else { _t.neutral-900 }
  let rail-stroke  = if dark { white.transparentize(70%) } else { _t.neutral-900 }
  let body-color   = if dark { white.transparentize(15%) } else { _t.fg-muted    }
  let takwy-color  = if dark { white                     } else { _t.ink         }

  v(10mm)
  chanwe-section-eyebrow(resolved-eyebrow)
  v(7.5mm)
  block[
    #text(
      font: _t.font-display, size: 56pt, weight: 700,
      tracking: -0.025em, fill: title-color, resolved-title,
    )
    #box(width: 10pt, height: 10pt, baseline: 0pt,
      circle(fill: _t.primary, stroke: none))
  ]
  v(24mm)

  // --- simple body layout when called with eyebrow/title/meta/body ---
  if body != none {
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
          ..resolved-rows.map(r => chanwe-side-row(..r, dark: dark))
        )
      ],
      // body block
      block[
        #set par(leading: 0.65em, justify: true)
        #set text(font: _t.font-sans, size: 10pt, weight: 400, fill: body-color)
        #if takeaway != none {
          let s = str(takeaway)
          let parts = s.split(" ")
          let first-word = parts.at(0)
          let rest = if parts.len() > 1 { " " + parts.slice(1).join(" ") } else { "" }
          block(below: 6mm)[
            #text(font: _t.font-serif, size: 32pt, weight: 300, style: "italic", fill: _t.primary, first-word)#text(weight: 700, fill: takwy-color, rest)
          ]
        }
        #body
      ],
    )
    return
  }

  // --- original verbose layout ---
  grid(
    columns: (60mm, 1fr),
    column-gutter: 14mm,
    align: (left + top, left + top),
    // ---- side rail ----
    block(
      stroke: (right: 0.5pt + _t.border),
      inset: (right: 10mm),
      width: 100%,
    )[
      #stack(
        dir: ttb, spacing: 6mm,
        ..side-rows.map(r => chanwe-side-row(..r))
      )
    ],
    // ---- body with real drop-cap ----
    block[
      // h2 abstract heading
      #block(below: 4mm)[
        #text(font: _t.font-display, size: 28pt, weight: 700,
              tracking: -0.02em, fill: _t.neutral-900, abstract-heading)
      ]

      // Lead paragraph with manual drop-cap
      #if lead != none {
        let first = lead.at(0)
        let rest  = lead.slice(1)
        block(below: 4mm)[
          #place(top + left, dx: 0pt, dy: 8pt)[
            #text(
              font: _t.font-serif, size: 56pt, weight: 300,
              fill: _t.neutral-900, first,
            )
          ]
          #pad(left: 24mm)[
            #set par(leading: 0.62em, justify: true, first-line-indent: 0pt)
            #set text(font: _t.font-serif, size: 12pt, weight: 300, fill: _t.fg)
            #text(weight: 300, fill: _t.neutral-900,
                  rest.slice(0, calc.min(rest.len(), 60)))
            #rest.slice(calc.min(rest.len(), 60))
          ]
        ]
      }

      // remaining paragraphs (no drop cap)
      #set par(leading: 0.62em, justify: true)
      #set text(font: _t.font-serif, size: 12pt, weight: 300, fill: _t.fg)
      #for p in paragraphs {
        block(below: 4mm, p)
      }
    ],
  )
}

// =============================================================
// EXECUTIVE SUMMARY PAGE — same layout as the abstract page,
// callable inline from ::: {.chanwe-executive-summary ...} divs.
// Pulls meta-rows from doc state automatically.
// =============================================================
#let chanwe-exec-summary-page(
  eyebrow: "Executive Summary",
  title: none,
  takeaway: none,
  color: none,
  meta: none,
  body,
) = {
  let bg = if color == "beige"  { _t.beige       }
      else if color == "gray"   { _t.neutral-100   }
      else if color == "dark"   { _t.ink          }
      else if color == "white"  { white           }
      else                      { none            }
  pagebreak(weak: true)
  if bg != none {
    set page(fill: bg)
    context {
      let doc = _chanwe-doc.get()
      chanwe-abstract(
        eyebrow: eyebrow,
        title: title,
        meta: if meta != none { meta } else { doc.meta-rows },
        takeaway: takeaway,
        dark: color == "dark",
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
        dark: color == "dark",
        body,
      )
    }
  }
  pagebreak(weak: true)
}

// =============================================================
// DOUBLE EXECUTIVE SUMMARY — two summary halves filling one page
// =============================================================
// Each half = 129.5mm (= (297 - 22 top - 16 bottom) / 2).
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
  let bg = if color == "beige"  { _t.beige       }
      else if color == "gray"   { _t.neutral-100 }
      else if color == "dark"   { _t.ink         }
      else if color == "white"  { white          }
      else                      { _t.paper       }
  let dark        = color == "dark"
  let title-color = if dark { white                      } else { _t.neutral-900 }
  let rail-stroke = if dark { white.transparentize(60%)  } else { _t.neutral-300 }
  let body-color  = if dark { white.transparentize(15%)  } else { _t.fg-muted    }
  let takwy-color = if dark { white                      } else { _t.ink         }
  let div-stroke  = if divider { (bottom: 0.5pt + _t.neutral-900) } else { none }
  let lc          = if dark { white.transparentize(45%) } else { _t.fg-subtle }
  let vc          = if dark { white                     } else { _t.neutral-900 }
  let border-col  = if dark { white.transparentize(70%) } else { _t.neutral-300 }

  // Status color from kind
  let s-color = if status-kind == "good"    { rgb("#15803D") }
    else if status-kind == "regular"         { rgb("#D97706") }
    else if status-kind == "bad"             { rgb("#CC1914") }
    else                                     { _t.primary     }

  // 5-segment fill bar: first status-value segments colored, rest gray
  let filled = if status-value != none { status-value } else { 0 }
  let scale-bar = grid(
    columns: range(5).map(_ => 1fr),
    column-gutter: 1.5mm,
    ..range(5).map(i => {
      rect(width: 100%, height: 5pt, radius: 1.5pt,
           fill: if i < filled { s-color } else { luma(222) })
    })
  )

  // Meta cell shown to the right of the hero word
  let meta-right = if status-meta-label != "" {
    stack(
      dir: ttb, spacing: 3pt,
      align(right, text(font: _t.font-mono, size: 6pt, tracking: 0.18em, fill: lc,
                        upper(status-meta-label))),
      align(right, text(font: _t.font-display, size: 9pt, weight: 700, fill: vc,
                        status-meta-value)),
    )
  } else { [] }

  // Pre-compute left rail
  let left-rail = if status-hero != none or drivers.len() > 0 {
    [
      #if status-hero != none {
        if status-label != none {
          text(font: _t.font-mono, size: 6.5pt, tracking: 0.18em, fill: lc,
               "// " + upper(str(status-label)))
          v(-1mm)
        }
        // Hero word + right meta in the same baseline row
        grid(
          columns: (1fr, auto),
          column-gutter: 3mm,
          align: (left + bottom, right + bottom),
          text(font: _t.font-serif, size: 24pt, weight: 200,
               style: "italic", fill: s-color, str(status-hero)),
          meta-right,
        )
        v(0mm)
        // Fill bar
        scale-bar
        if drivers.len() > 0 { v(5mm) }
      }
      #if drivers.len() > 0 {
        block(spacing: 0pt)[
          #text(font: _t.font-mono, size: 6.5pt, tracking: 0.18em, fill: lc, "// " + upper(str(drivers-label)))
        ]
        v(0.5mm)
        for (i, drv) in drivers.slice(0, calc.min(drivers.len(), 3)).enumerate() {
          let dir    = drv.at(0)
          let dtitle = drv.at(1)
          let ddesc  = drv.at(2)
          let dtag   = drv.at(3)
          let dtag-k = drv.at(4)
          let dir-col = if dir == "up"   { rgb("#15803D") }
            else if dir == "down"         { rgb("#CC1914") }
            else                          { _t.fg-muted    }
          let dir-sym = if dir == "up"   { "▲" }
            else if dir == "down"         { "▼" }
            else                          { "—" }
          let t-col = if dtag-k == "green"   { rgb("#15803D") }
            else if dtag-k == "red"           { rgb("#CC1914") }
            else if dtag-k == "orange"        { _t.primary     }
            else                              { dir-col        }
          grid(
            columns: (8pt, 1fr, auto),
            column-gutter: 3pt,
            align: (left + top, left + top, right + top),
            text(font: _t.font-sans, size: 7pt, weight: 700, fill: dir-col, dir-sym),
            {
              block(spacing: 0pt)[
                #text(font: _t.font-display, size: 7.5pt, weight: 700, fill: vc, dtitle)
              ]
              if ddesc != "" {
                v(1mm)
                block(spacing: 0pt)[
                  #set par(leading: 0.3em)
                  #text(font: _t.font-sans, size: 6.5pt, fill: lc, ddesc)
                ]
              }
            },
            text(font: _t.font-display, size: 7pt, weight: 700, fill: t-col, dtag),
          )
          if i < calc.min(drivers.len(), 3) - 1 { v(2mm) }
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
          dark: dark,
        ))
      )
    ]
  }

  block(
    width: 210mm,
    height: 133.5mm,
    fill: bg,
    stroke: div-stroke,
    inset: (x: 18mm, top: 10mm, bottom: 10mm),
    clip: true,
  )[
    #chanwe-section-eyebrow(eyebrow)
    #v(3mm)
    #if title != none {
      block(below: 0pt)[
        #set par(leading: 0.75em, justify: false)
        #text(
          font: _t.font-display, size: 36pt, weight: 700,
          tracking: -0.025em, fill: title-color, title,
        )#box(width: 8pt, height: 8pt, baseline: -1pt,
          circle(fill: _t.primary, stroke: none))
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
      // right body
      block[
        #set par(leading: 0.65em, justify: true)
        #if takeaway != none {
          let s     = str(takeaway)
          let parts = s.split(" ")
          let fw    = parts.at(0)
          let rest  = if parts.len() > 1 { " " + parts.slice(1).join(" ") } else { "" }
          block(below: 5mm)[
            #text(font: _t.font-serif, size: 20pt, weight: 300,
                  style: "italic", fill: _t.primary, fw
            )#text(weight: 700, size: 10pt, fill: takwy-color, rest)
          ]
        }
        #set text(font: _t.font-sans, size: 9.5pt, weight: 400, fill: body-color)
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

  // Narrow top margin to the header rule position (14mm) so blocks fill rule-to-rule.
  set page(margin: (top: 14mm, bottom: 16mm, x: 18mm), header-ascent: 0pt, footer-descent: 0pt)

  move(dx: -18mm,
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
  )

  pagebreak(weak: true)
}

// =============================================================
// CHAPTER SEPARATOR (full-page divider)
// =============================================================
// HTML .chapter-cover layout:
//   - black background
//   - subtle gray radial halo (top-left, low opacity)
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
) = {
  _chanwe-cur-part.update(_ => (number: number, title: title, eyebrow: eyebrow))

  set page(
    paper: "a4", margin: 0pt, fill: _t.neutral-100,
    header: none, footer: none,
    background: place(top + left, dx: -50mm, dy: -50mm,
      circle(radius: 110mm,
        fill: gradient.radial(
          _t.primary.transparentize(93%),
          _t.neutral-100.transparentize(100%),
        ),
        stroke: none,
      )
    ),
  )
  set text(fill: _t.neutral-900)

  context {
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
    #v(1fr)

    // ---- MIDDLE: numeral + (eyebrow · title · blurb) ----
    #grid(
      columns: (1fr,),
      box[
        #grid(
          columns: (auto, 1fr),
          column-gutter: 14mm,
          align: (left + bottom, left + bottom),
          // GIANT italic numeral
          text(
            font: _t.font-serif, style: "italic", weight: 100,
            size: 220pt, tracking: -0.04em,
            fill: _t.primary,
            number,
          ),
          // eyebrow · title · rule · blurb stacked in the right column
          stack(
            dir: ttb, spacing: 7mm,
            chanwe-eyebrow(eyebrow, color: _t.primary, with-rule: true),
            text(
              font: _t.font-serif, style: "italic", weight: 300,
              size: 36pt, tracking: -0.02em, fill: _t.neutral-900,
              title,
            ),
            box(width: 18mm, height: 1.5pt, fill: none),
            text(
              font: _t.font-sans, size: 14pt, weight: 300,
              fill: _t.fg-muted,
              blurb,
            ),
          ),
        )
      ],
    )

    #v(10mm)
    #line(length: 100%, stroke: 0.5pt + _t.neutral-900)

    #v(4fr)

    // ---- BOTTOM: doc-id · edition ----
    #line(length: 100%, stroke: 0.5pt + _t.border)
    #v(3mm)
    #grid(
      columns: (1fr, auto),
      align: (left + horizon, right + horizon),
      {
        set text(font: _t.font-mono, size: 8pt, tracking: 0.18em,
                 fill: _t.fg-subtle)
        upper(doc.doc-id)
        if doc.edition != "" {
          h(14mm)
          upper(doc.edition)
        }
      },
      text(font: _t.font-mono, size: 8pt, tracking: 0.18em,
           fill: _t.fg-subtle, upper(_pages)),
    )
  ]
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
    paper: "a4", margin: 0pt, fill: _t.ink,
    header: none, footer: none,
    background: place(center + horizon,
      circle(radius: 105mm,
        fill: gradient.radial(
          white.transparentize(90%),
          black.transparentize(100%),
        ),
        stroke: none,
      )
    ),
  )
  set text(fill: white)

  block(
    width: 100%, height: 100%,
    inset: (x: 22mm, top: 22mm, bottom: 22mm),
  )[
    // ---- TOP: white wordmark ----
    #if wordmark-white != none {
      image(wordmark-white, height: 14mm)
    } else {
      text(font: _t.font-display, size: 28pt, weight: 800, tracking: -0.03em,
           fill: white, "chanwe")
    }

    #v(1fr)

    // ---- TAGLINE: italic 36pt, orange on second line ----
    #block[
      #set par(leading: 0.45em)
      #text(
        font: _t.font-serif, style: "italic", weight: 300,
        size: 36pt, tracking: -0.01em, fill: white,
        tagline-line1,
      )
      \
      #text(
        font: _t.font-serif, style: "italic", weight: 300,
        size: 36pt, tracking: -0.01em, fill: _t.primary,
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
          text(font: _t.font-mono, size: 7.5pt, weight: 500,
               tracking: 0.20em, fill: white.transparentize(45%),
               upper(label)),
          stack(
            dir: ttb, spacing: 2pt,
            text(font: _t.font-display, size: 12pt, weight: 600,
                 fill: white, val),
            text(font: _t.font-sans, size: 9pt, weight: 400,
                 fill: white.transparentize(35%), sub),
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
    #line(length: 100%, stroke: 0.5pt + white.transparentize(80%))
    #v(3mm)
    #grid(
      columns: (1fr, auto),
      align: (left + horizon, right + horizon),
      text(font: _t.font-mono, size: 7.5pt, weight: 500,
           tracking: 0.18em, fill: white.transparentize(45%),
           upper(legal)),
      text(font: _t.font-mono, size: 7.5pt, weight: 500,
           tracking: 0.18em, fill: white.transparentize(45%),
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
// label-color: auto resolves to _t.fg-subtle
#let chanwe-bar-chart(
  data,
  height:      50mm,
  bar-width:   18mm,
  gap:         5mm,
  label-size:  7.5pt,
  label-color: auto,
  threshold:   0.7,
) = {
  let lc = if label-color == auto { _t.fg-subtle } else { label-color }
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
            radius: 1.5pt,
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
  width:       120mm,
  height:      60mm,
  label-size:  7pt,
  y-min:       0,
  y-max:       1,
  colors:      auto,
) = {
  let palette = if colors == auto {
    (_t.primary, _t.fg-muted, _t.neutral-700, _t.fg-subtle)
  } else { colors }
  let n = if series.len() > 0 { series.first().at(1).len() } else { 0 }
  if n == 0 { return [] }
  let x-step = if n > 1 { width / (n - 1) } else { width }
  let y-range = y-max - y-min

  block(width: width, height: height + 10mm)[
    #place(top + left,
      rect(width: width, height: height,
        fill: none, stroke: 0.5pt + _t.border)
    )
    #for (si, (name, vals)) in series.enumerate() {
      let col = palette.at(calc.rem(si, palette.len()))
      for i in range(vals.len() - 1) {
        let x1 = x-step * i
        let y1 = height * (1 - (vals.at(i) - y-min) / y-range)
        let x2 = x-step * (i + 1)
        let y2 = height * (1 - (vals.at(i + 1) - y-min) / y-range)
        place(top + left, dx: x1, dy: y1,
          line(end: (x2 - x1, y2 - y1), stroke: 1.5pt + col))
      }
    }
    #if x-labels.len() > 0 {
      place(bottom + left, dy: 8mm,
        stack(dir: ltr,
          ..x-labels.enumerate().map(((i, lbl)) =>
            move(dx: x-step * i,
              align(center, text(size: label-size, fill: _t.fg-subtle, lbl)))
          )
        )
      )
    }
  ]
}
// =============================================================
// MAIN TEMPLATE FUNCTION (called by typst-show.typ)
// =============================================================
#let chanwe(
  // metadata
  title: "Untitled",
  subtitle: none,
  author: "Chanwe Studio",
  date: "",
  doc-id: "CHW · DOC · 2026 · 01",
  edition: "Edition 01 / 2026",
  volume: "Confidential",
  chapter: "Chapter",
  section: "",
  topic: "",
  rail-eyebrow: "Quarto · Style Guide",
  cover-eyebrow: none,      // overrides rail-eyebrow on the cover page only
  // assets
  hero-image: none,
  hero-img-position: none,  // 1–10 (left→right); none = fit:cover (centered)
  wordmark: none,
  stamp: ("VOL", "I", "2026"),
  hero-date: "",
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
  cover-edge-color: none,
  // page
  page-bg: rgb("#FBFBFB"),
  second-page-bg: rgb("#F7F7F7"),   // fill for the TOC/abstract page (metallic default)
  // body text
  body-size:    none,   // e.g. 10pt — overrides default 11pt
  body-leading: none,   // e.g. 0.9em — overrides default 0.85em
  body-justify: none,   // true / false — overrides default false
  body-color:   none,   // rgb color — overrides default _t.fg
  body-spacing: none,   // e.g. 1.8em — space between block elements
  // body
  body,
) = {
  // ---- store metadata in global state -----------------------
  _chanwe-doc.update((doc-id: doc-id, edition: edition, meta-rows: meta-rows))

  // ---- global text + page defaults ---------------------------
  set page(fill: page-bg)
  set text(font: _t.font-sans, size: 11pt, fill: _t.fg, lang: "en")
  set par(leading: 0.85em, justify: false, spacing: 1.0em)
  set heading(numbering: "1.1.1.")

  // ---- inline rules (apply to entire document) ---------------
  show emph: it => text(fill: _t.primary, it.body)
  show strong: it => text(weight: 700, fill: _t.ink, it.body)
  show math.equation.where(block: true): it => block(
    width: 100%,
    fill: rgb("#EDF0F1"),
    stroke: 0.5pt + _t.neutral-300,
    radius: 4pt,
    inset: (x: 10mm, y: 8mm),
  )[
    #set text(fill: _t.fg-muted, weight: 200)
    #align(center, it)
  ]
  show link: it => underline(stroke: 0.6pt + _t.primary, offset: 2pt, text(fill: _t.primary, it))
  show raw.where(block: false): it => box(
    fill: rgb("#EDF0F1"),
    stroke: 0.5pt + _t.neutral-300,
    inset: (x: 3pt, y: 2pt),
    radius: 2pt,
    text(font: _t.font-mono, size: 0.85em, fill: _t.neutral-700, it),
  )
  show raw.where(block: true): it => block(
    fill: rgb("#EDF0F1"),
    stroke: (left: 1pt + _t.primary),
    inset: (x: 4mm, y: 3mm),
    width: 100%,
  )[
    #set block(fill: none)
    #if it.lang != none {
      text(
        font: _t.font-mono, size: 7.5pt, fill: _t.fg-subtle,
        "# " + it.lang + " · " + str(it.lines.len()) + " lines",
      )
      v(2.5mm)
    }
    #text(font: _t.font-mono, size: 9pt, weight: 300, it)
  ]

  // ---- headings ----------------------------------------------
  show heading.where(level: 1): it => {
    pagebreak(weak: true)
    place(left + top, dx: -55mm, dy: -75mm,
      circle(radius: 90mm,
        fill: gradient.radial(
          _t.primary.transparentize(90%),
          white.transparentize(100%),
        ),
        stroke: none,
      )
    )
    v(6mm)
    block(below: 12mm)[
      #box(width: 50pt, height: 1.5pt, fill: _t.primary)
      #v(12mm)
      #grid(
        columns: (auto, 1fr),
        column-gutter: 8mm,
        align: (left + bottom, left + bottom),
        text(font: _t.font-serif, style: "italic", weight: 300,
             size: 60pt, fill: _t.primary,
             counter(heading).display("1")),
        block()[
          #set par(leading: 0.18em)
          #text(font: _t.font-display, size: 30pt, weight: 600,
               tracking: -0.025em, fill: _t.neutral-900, it.body)
        ],
      )
      #v(1.5mm)
      #line(length: 100%, stroke: 0.5pt + _t.neutral-900)
    ]
  }
  show heading.where(level: 2): it => block(above: 12mm, below: 6mm)[
    #set par(leading: 0.2em)
    #grid(
      columns: (auto, 1fr),
      column-gutter: 6mm,
      align: (left + bottom, left + bottom),
      text(font: _t.font-mono, weight: 100,
           size: 15pt, fill: _t.primary,
           counter(heading).display("1.1")),
      text(font: _t.font-display, size: 19pt, weight: 600,
           tracking: -0.01em, fill: _t.neutral-900, it.body),
    )
    #v(0mm)
    #line(length: 100%, stroke: 0.5pt + _t.neutral-300)
  ]
  show heading.where(level: 3): it => block(above: 32mm, below: 5.5mm)[
    #grid(
      columns: (auto, 1fr),
      column-gutter: 4mm,
      align: (left + bottom, left + bottom),
      text(font: _t.font-mono, weight: 100,
           size: 12pt, fill: _t.primary,
           counter(heading).display("1.1.1")),
      text(font: _t.font-display, size: 15pt, weight: 600,
           tracking: -0.01em, fill: _t.neutral-900, it.body),
    )
  ]
  show heading.where(level: 4): it => block(above: 32mm, below: 4mm)[
    #grid(
      columns: (auto, 1fr),
      column-gutter: 4mm,
      align: (left + bottom, left + bottom),
      text(font: _t.font-serif, style: "italic", weight: 100,
           size: 10pt, fill: _t.primary,
           counter(heading).display("1.1.1.1")),
      text(font: _t.font-display, size: 13pt, weight: 700,
           tracking: -0.01em, fill: _t.neutral-900, it.body),
    )
  ]
  show heading.where(level: 5): it => block(above: 32mm, below: 4mm)[
    #stack(dir: ttb,
      {
        box(width: 5pt, height: 5pt, radius: 2.5pt, fill: _t.primary, baseline: 0.5pt)
        h(6pt)
        text(font: _t.font-mono, size: 8pt, weight: 500,
             tracking: 0.18em, fill: _t.fg-subtle, upper(it.body))
      },
      3mm,
      line(length: 100%, stroke: 0.5pt + _t.neutral-300),
    )
  ]
  show heading.where(level: 6): it => block(above: 32mm, below: 5mm)[
    #box(width: 5pt, height: 5pt, radius: 2.5pt, fill: _t.primary, baseline: 0.5pt)
    #h(6pt)
    #text(font: _t.font-mono, size: 8pt, weight: 500,
          tracking: 0.18em, fill: _t.fg-subtle, upper(it.body))
  ]

  // ---- lists -------------------------------------------------
  set list(marker: ([•], [◦], [–]))

  // ---- quote (Pandoc/Quarto blockquotes) ---------------------
  show quote: it => block(
    above: 6mm, below: 6mm,
    inset: (left: 6mm),
    stroke: (left: 2pt + _t.primary),
  )[
    #text(font: _t.font-serif, size: 16pt, weight: 300, style: "italic", fill: _t.fg-muted, it.body)
    #if it.attribution != none {
      v(3mm)
      text(font: _t.font-serif, size: 10pt, weight: 300, style: "italic", fill: _t.fg-subtle, [— #it.attribution])
    }
  ]

  // ---- tables -----------------------------------------------
  set table(
    fill: none,
    stroke: (col, row) => (
      top:    if row == 0 { 0.5pt + _t.neutral-900 } else { none },
      bottom: if row == 0 { 0.5pt + _t.neutral-900 } else { 0.4pt + _t.border },
    ),
    inset: (x: 4mm, y: 3.5mm),
  )
  show table.cell: set text(
    size: 8pt, weight: 200, fill: _t.fg,
  )
  show table.cell.where(y: 0): set text(
    font: _t.font-display, size: 8pt, weight: 200,
    tracking: 0pt, fill: _t.ink,
  )
  show figure.where(kind: table): it => {
    v(12mm, weak: true)
    it.caption
    v(6mm)
    it.body
    v(-0.25pt)
    line(length: 100%, stroke: 0.5pt + _t.ink)
    v(12mm, weak: true)
  }
  show figure.where(kind: image): it => {
    v(14mm, weak: true)
    line(length: 100%, stroke: 0.3pt + _t.ink)
    v(4mm)
    it.body
    v(3mm)
    line(length: 100%, stroke: 0.3pt + _t.ink)
    v(2mm)
    it.caption
    v(12mm, weak: true)
  }
  show figure: set block(above: 12mm, below: 12mm)
  show figure.caption: it => align(left, text(
    font: _t.font-mono, size: 8pt, tracking: 0.14em,
    fill: _t.fg-subtle, upper(it.supplement) + " " + it.counter.display() + "  ·  " + upper(it.body),
  ))

  // ---- COVER (optional) -------------------------------------
  if cover {
    chanwe-cover-page(
      title: title,
      subtitle: subtitle,
      doc-id: doc-id,
      edition: edition,
      volume: volume,
      rail-eyebrow: if cover-eyebrow != none { cover-eyebrow } else { rail-eyebrow },
      hero-image: hero-image,
      hero-img-position: hero-img-position,
      wordmark: wordmark,
      stamp: stamp,
      hero-date: hero-date,
      meta-rows: meta-rows,
      date: date,
      cover-edge: cover-edge,
      cover-edge-color: cover-edge-color,
    )
  }

  // ---- body pages -------------------------------------------
  set page(
    paper: "a4",
    margin: (top: 12mm, bottom: 12mm, x: 18mm),
    header: chanwe-header(section, topic),
    footer: chanwe-footer(doc-id, edition),
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
    let all-meta = (
      "document": ("Document", doc-id, none),
      "edition":  ("Edition",  edition, none),
      "author":   ("Author",   author,  none),
      "status":   ("Status",   if abstract-status != none { abstract-status } else { "" }, none),
      "keywords": ("Keywords", abstract-keywords.join(" · "), none),
    )
    let fields = if abstract-show.len() > 0 { abstract-show } else { all-meta.keys() }
    let meta-items = fields
      .filter(k => all-meta.at(k, default: none) != none)
      .map(k => all-meta.at(k))
      .filter(((_, v, ..)) => v != "")
    chanwe-abstract(
      eyebrow: abstract-eyebrow,
      title: abstract-title,
      meta: meta-items,
      takeaway: abstract-takeaway,
      abstract-text,
    )
    pagebreak()
  }

  // ---- user body (paragraph overrides scoped here only) ----
  {
    set text(
      size: if body-size  != none { body-size  } else { 11pt    },
      fill: if body-color != none { body-color } else { _t.fg   },
    )
    set par(
      leading: if body-leading != none { body-leading } else { 0.85em },
      justify: if body-justify != none { body-justify } else { false  },
    )
    set block(spacing: if body-spacing != none { body-spacing } else { 1.2em })
    body
  }

  // ---- back cover (optional) --------------------------------
  if back-cover {
    chanwe-back-cover-page(
      tagline-1: back-cover-tagline-1,
      tagline-2: back-cover-tagline-2,
      back-cols: back-cover-cols,
      cover-edge: cover-edge,
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
// typst-show.typ — Quarto metadata → chanwe() template call
// =============================================================
// This is the bridge: Quarto fills Chanwe Showcase: ggplot2 + gt, Tables and plots aligned with chanwe-typst design tokens, etc. from
// the YAML front-matter of the .qmd file. Custom keys live under
// `chanwe:` and are mapped here.
// =============================================================

#show: doc => chanwe(
  title: [Chanwe Showcase: ggplot2 + gt],
  subtitle: [Tables and plots aligned with chanwe-typst design tokens],
  author: "Alejandro Abraham",
  date: "2026-05-17",
  doc-id: "CHW · DEV",
  edition: "SHOWCASE / 2026",
  volume: "MENDOZA · ARGENTINA",
  chapter: "Design System",
  section: "R Package",
  topic: "chanwer",
  rail-eyebrow: "VISUAL REFERENCE",
  hero-image: "\_extensions/chanwe/assets/bg\_mountains.jpg",
  cover: true,
  toc: true,
  toc-eyebrow: "Document map",
  toc-title: "Contents",
  toc-lede: [This document showcases all ggplot2 and gt table variants produced by the chanwer R package --- 22 figures and 8 tables --- styled with the chanwe-typst design tokens: Satoshi body, Archivo Black headings, primary orange \#FB3D0E, and the 8-color editorial chart palette.],
  abstract-eyebrow: "TLDR;",
  abstract-title: [Visual Reference],
  abstract-text: [This showcase covers every theme variant in the chanwer package --- scatter, bar, line, area, distribution, heatmap, faceted, and error-bar figures; gt tables in spacious and compact densities across both background options. All outputs use the typst design tokens directly, ensuring visual consistency between R-generated figures and the surrounding Typst document.],
  abstract-status: "Stable · Internal",
  abstract-show: ("document", "edition", "author", "status"),
  abstract-takeaway: "chanwer themes are fully aligned with chanwe-typst: same tokens, same fonts, same 8-color editorial palette.",
  meta-rows: (
    ("Package", "chanwer", "R design system"),
    ("Section", "Design Tokens", "chanwe-typst aligned"),
    ("Author", "Chanwe", "Alejandro Abraham"),
  ),
  back-cover: true,
  back-cover-tagline-1: "Estrategia Activa,",
  back-cover-tagline-2: "Codo a codo.",
  back-cover-cols: (
    ("Address", "Via Montenapoleone, 27", "Mendoza · Argentina"),
    ("Web", "chanwe.com.ar", "contacto\@chanwe.com.ar"),
    ("Document", "CHW · DEV", "Showcase / 2026"),
  ),
  page-bg: rgb("#FBFBFB"),
  doc,
)

= Complex
<complex>
===== KPI
<kpi>
#box(image("gt_files/figure-typst/unnamed-chunk-1-1.svg", width: 100.0%))

= kbl Tables
<kbl-tables>
===== Ivory background
<ivory-background>
#block(above: 2.5em, below: 2.5em)[
#block(inset: (x: 12.5pt, y: 0pt), fill: rgb("#FAF9F7"))[
#{ set text(size: 10pt, fill: _t.ink, weight: "regular", tracking: 0pt, style: "normal"); set table(inset: (x: 2.5mm, y: 10pt), stroke: none, fill: rgb("#FAF9F7"))
  [
  #table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr),
    align: (left, right, left, right, right,),
    table.header(
      table.cell(align: left, colspan: 5, inset: (top: 10pt, bottom: 5pt, x: 2.5mm), stroke: (top: 0.1pt + _t.ink))[#v(8pt, weak: false)#chanwe-eyebrow(with-rule: true, size: 5pt)[TABLE · SPACIOUS · WHITE-IVORY]#v(-10pt, weak: false)#text(font: "Archivo", size: 16pt, fill: _t.ink, weight: "regular")[bg · white-ivory]],
      table.cell(align: left, colspan: 5, inset: (top: 4pt, bottom: 10pt, x: 2.5mm))[#text(font: "Satoshi", size: 9pt, fill: _t.fg-muted, weight: "regular")[title\_size · 16pt  ·  weight · regular  ·  density · spacious]#v(8pt, weak: false)],
      table.hline(stroke: 0.7pt + _t.ink),
      table.cell(align: left, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[MODEL]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[MPG]],
      table.cell(align: left, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[CYL]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[HP]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[WT]],
    ),
    table.hline(stroke: 0.1pt + _t.ink),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.62]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4 Wag]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.88]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Datsun 710]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[22.80]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[93]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.32]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet 4 Drive]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.40]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.21]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet Sportabout]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.70]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[175]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.44]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Valiant]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.10]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[105]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.46]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Duster 360]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[14.30]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[245]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.57]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Merc 240D]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[24.40]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[62]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.19]],
    table.hline(stroke: 0.5pt + _t.ink),
    table.footer(
      table.hline(stroke: 0.3pt + _t.ink),
      table.cell(colspan: 5, align: left, inset: (top: 10pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 7pt, fill: _t.fg-muted)[#text(fill: _t.primary)[/\/]Source · Motor Trend, 1974 · mtcars dataset.]],
    )
  )
  ]
}
]
]
===== White background
<white-background>
#block(above: 2.5em, below: 2.5em)[
#block(inset: (x: 12.5pt, y: 0pt), fill: white)[
#{ set text(size: 10pt, fill: _t.ink, weight: "regular", tracking: 0pt, style: "normal"); set table(inset: (x: 2.5mm, y: 10pt), stroke: none, fill: white)
  [
  #table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr),
    align: (left, right, left, right, right,),
    table.header(
      table.cell(align: left, colspan: 5, inset: (top: 10pt, bottom: 5pt, x: 2.5mm), stroke: (top: 0.1pt + _t.ink))[#v(8pt, weak: false)#chanwe-eyebrow(with-rule: true, size: 5pt)[TABLE · SPACIOUS · WHITE]#v(-10pt, weak: false)#text(font: "Archivo", size: 16pt, fill: _t.ink, weight: "regular")[bg · white]],
      table.cell(align: left, colspan: 5, inset: (top: 4pt, bottom: 10pt, x: 2.5mm))[#text(font: "Satoshi", size: 9pt, fill: _t.fg-muted, weight: "regular")[title\_size · 16pt  ·  weight · regular  ·  density · spacious]#v(8pt, weak: false)],
      table.hline(stroke: 0.7pt + _t.ink),
      table.cell(align: left, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[MODEL]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[MPG]],
      table.cell(align: left, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[CYL]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[HP]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[WT]],
    ),
    table.hline(stroke: 0.1pt + _t.ink),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.62]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4 Wag]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.88]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Datsun 710]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[22.80]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[93]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.32]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet 4 Drive]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.40]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.21]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet Sportabout]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.70]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[175]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.44]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Valiant]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.10]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[105]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.46]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Duster 360]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[14.30]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[245]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.57]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Merc 240D]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[24.40]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[62]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.19]],
    table.hline(stroke: 0.5pt + _t.ink),
    table.footer(
      table.hline(stroke: 0.3pt + _t.ink),
      table.cell(colspan: 5, align: left, inset: (top: 10pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 7pt, fill: _t.fg-muted)[#text(fill: _t.primary)[/\/]Source · Motor Trend, 1974 · mtcars dataset.]],
    )
  )
  ]
}
]
]
===== Beige background
<beige-background>
#block(above: 2.5em, below: 2.5em)[
#block(inset: (x: 12.5pt, y: 0pt), fill: rgb("#F5F1EB"))[
#{ set text(size: 10pt, fill: _t.ink, weight: "regular", tracking: 0pt, style: "normal"); set table(inset: (x: 2.5mm, y: 10pt), stroke: none, fill: rgb("#F5F1EB"))
  [
  #table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr),
    align: (left, right, left, right, right,),
    table.header(
      table.cell(align: left, colspan: 5, inset: (top: 10pt, bottom: 5pt, x: 2.5mm))[#v(8pt, weak: false)#chanwe-eyebrow(with-rule: true, size: 5pt)[TABLE · SPACIOUS · BEIGE]#v(-10pt, weak: false)#text(font: "Archivo", size: 16pt, fill: _t.ink, weight: "regular")[bg · beige]],
      table.cell(align: left, colspan: 5, inset: (top: 4pt, bottom: 10pt, x: 2.5mm))[#text(font: "Satoshi", size: 9pt, fill: _t.fg-muted, weight: "regular")[title\_size · 16pt  ·  weight · regular  ·  density · spacious]#v(8pt, weak: false)],
      table.hline(stroke: 0.7pt + _t.ink),
      table.cell(align: left, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[MODEL]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[MPG]],
      table.cell(align: left, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[CYL]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[HP]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[WT]],
    ),
    table.hline(stroke: 0.1pt + _t.ink),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.62]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4 Wag]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.88]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Datsun 710]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[22.80]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[93]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.32]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet 4 Drive]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.40]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.21]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet Sportabout]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.70]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[175]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.44]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Valiant]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.10]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[105]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.46]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Duster 360]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[14.30]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[245]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.57]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Merc 240D]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[24.40]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[62]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.19]],
    table.hline(stroke: 0.5pt + _t.ink),
    table.footer(
      table.hline(stroke: 0.3pt + _t.ink),
      table.cell(colspan: 5, align: left, inset: (top: 10pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 7pt, fill: _t.fg-muted)[#text(fill: _t.primary)[/\/]Source · Motor Trend, 1974 · mtcars dataset.]],
    )
  )
  ]
}
]
]
===== Gray background
<gray-background>
#block(above: 2.5em, below: 2.5em)[
#{ set text(size: 10pt, fill: _t.ink, weight: "regular", tracking: 0pt, style: "normal"); set table(inset: (x: 2.5mm, y: 10pt), stroke: none, fill: rgb("#EDF0F1"))
  [
  #table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr),
    align: (left, right, left, right, right,),
    table.header(
      table.cell(align: left, colspan: 5, inset: (top: 10pt, bottom: 5pt, x: 2.5mm))[#v(8pt, weak: false)#chanwe-eyebrow(with-rule: true, size: 5pt)[TABLE · SPACIOUS · GRAY]#v(-10pt, weak: false)#text(font: "Archivo", size: 16pt, fill: _t.ink, weight: "regular")[bg · gray]],
      table.cell(align: left, colspan: 5, inset: (top: 4pt, bottom: 10pt, x: 2.5mm))[#text(font: "Satoshi", size: 9pt, fill: _t.fg-muted, weight: "regular")[title\_size · 16pt  ·  weight · regular  ·  density · spacious]#v(8pt, weak: false)],
      table.hline(stroke: 0.7pt + _t.ink),
      table.cell(align: left, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[MODEL]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[MPG]],
      table.cell(align: left, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[CYL]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[HP]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[WT]],
    ),
    table.hline(stroke: 0.1pt + _t.ink),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.62]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4 Wag]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.88]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Datsun 710]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[22.80]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[93]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.32]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet 4 Drive]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.40]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.21]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet Sportabout]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.70]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[175]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.44]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Valiant]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.10]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[105]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.46]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Duster 360]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[14.30]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[245]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.57]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Merc 240D]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[24.40]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[62]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.19]],
    table.hline(stroke: 0.5pt + _t.ink),
    table.footer(
      table.hline(stroke: 0.3pt + _t.ink),
      table.cell(colspan: 5, align: left, inset: (top: 10pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 7pt, fill: _t.fg-muted)[#text(fill: _t.primary)[/\/]Source · Motor Trend, 1974 · mtcars dataset.]],
    )
  )
  ]
}
]
===== Metallic background
<metallic-background>
#block(above: 2.5em, below: 2.5em)[
#block(inset: (x: 12.5pt, y: 0pt), fill: rgb("#F7F7F7"))[
#{ set text(size: 10pt, fill: _t.ink, weight: "regular", tracking: 0pt, style: "normal"); set table(inset: (x: 2.5mm, y: 10pt), stroke: none, fill: rgb("#F7F7F7"))
  [
  #table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr),
    align: (left, right, left, right, right,),
    table.header(
      table.cell(align: left, colspan: 5, inset: (top: 10pt, bottom: 5pt, x: 2.5mm), stroke: (top: 0.1pt + _t.ink))[#v(8pt, weak: false)#chanwe-eyebrow(with-rule: true, size: 5pt)[TABLE · SPACIOUS · METALLIC · DEFAULT]#v(-10pt, weak: false)#text(font: "Archivo", size: 16pt, fill: _t.ink, weight: "regular")[bg · metallic  ·  default]],
      table.cell(align: left, colspan: 5, inset: (top: 4pt, bottom: 10pt, x: 2.5mm))[#text(font: "Satoshi", size: 9pt, fill: _t.fg-muted, weight: "regular")[title\_size · 16pt  ·  weight · regular  ·  density · spacious]#v(8pt, weak: false)],
      table.hline(stroke: 0.7pt + _t.ink),
      table.cell(align: left, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[MODEL]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[MPG]],
      table.cell(align: left, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[CYL]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[HP]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[WT]],
    ),
    table.hline(stroke: 0.1pt + _t.ink),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.62]],
    table.hline(stroke: 0.3pt + rgb("#D4D4D4")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4 Wag]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.88]],
    table.hline(stroke: 0.3pt + rgb("#D4D4D4")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Datsun 710]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[22.80]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[93]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.32]],
    table.hline(stroke: 0.3pt + rgb("#D4D4D4")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet 4 Drive]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.40]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.21]],
    table.hline(stroke: 0.3pt + rgb("#D4D4D4")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet Sportabout]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.70]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[175]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.44]],
    table.hline(stroke: 0.3pt + rgb("#D4D4D4")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Valiant]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.10]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[105]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.46]],
    table.hline(stroke: 0.3pt + rgb("#D4D4D4")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Duster 360]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[14.30]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[245]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.57]],
    table.hline(stroke: 0.3pt + rgb("#D4D4D4")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Merc 240D]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[24.40]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[62]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.19]],
    table.hline(stroke: 0.5pt + _t.ink),
    table.footer(
      table.hline(stroke: 0.3pt + _t.ink),
      table.cell(colspan: 5, align: left, inset: (top: 10pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 7pt, fill: _t.fg-muted)[#text(fill: _t.primary)[/\/]Source · Motor Trend, 1974 · mtcars dataset.]],
    )
  )
  ]
}
]
]
= Plots
<plots>
===== Plot 1
<plot-1>
#inset-great-figure(
  eyebrow: "FY 2025",
  title: "Revenue by Segment",
  color: "beige",
  layout: "left",
  position: "right",
  source: "Data: FY 2025 — valores normalizados",
  caption: [
La categoria C presenta el valor mas alto del conjunto. Los segmentos A
y E muestran rendimiento dentro del rango esperado, mientras que F
establece el piso de referencia para el analisis diferencial.

  ],
)[
#block[
#block[
#box(image("gt_files/figure-typst/unnamed-chunk-7-1.svg", width: 100.0%))

]
]
]
===== Plot 2
<plot-2>
#box(image("gt_files/figure-typst/unnamed-chunk-8-1.svg", width: 100.0%))

===== Plot 3
<plot-3>
#box(image("gt_files/figure-typst/unnamed-chunk-9-1.svg", width: 100.0%))

===== Plot 4
<plot-4>
#box(image("gt_files/figure-typst/unnamed-chunk-10-1.svg", width: 100.0%))

===== Plot 5 · Metallic
<plot-5-metallic>
#box(image("gt_files/figure-typst/unnamed-chunk-11-1.svg", width: 100.0%))

= Highlight
<highlight>
#zone-highlight(color: "metallic", above: -2mm)[
#block[
#block[
#block[
#block[
#box(image("gt_files/figure-typst/fig-scatter-complejo-1.svg", width: 100.0%))
]
#block[
]
]
]
]
]
= No subtitle
<no-subtitle>
===== Plot · title only
<plot-title-only>
#box(image("gt_files/figure-typst/unnamed-chunk-12-1.svg", width: 100.0%))

===== Plot · title only · zone-highlight
<plot-title-only-zone-highlight>
#zone-highlight(color: "metallic", above: -2mm)[
#block[
#block[
#box(image("gt_files/figure-typst/unnamed-chunk-13-1.svg", width: 100.0%))

]
]
]
===== Plot · no title · no subtitle
<plot-no-title-no-subtitle>
#box(image("gt_files/figure-typst/unnamed-chunk-14-1.svg", width: 100.0%))

===== Plot · no title · no subtitle · zone-highlight
<plot-no-title-no-subtitle-zone-highlight>
#zone-highlight(color: "metallic", above: -2mm)[
#block[
#block[
#box(image("gt_files/figure-typst/unnamed-chunk-15-1.svg", width: 100.0%))

]
]
]
===== Table · title only
<table-title-only>
#block(above: 2.5em, below: 2.5em)[
#block(inset: (x: 12.5pt, y: 0pt), fill: rgb("#F7F7F7"))[
#{ set text(size: 10pt, fill: _t.ink, weight: "regular", tracking: 0pt, style: "normal"); set table(inset: (x: 2.5mm, y: 10pt), stroke: none, fill: rgb("#F7F7F7"))
  [
  #table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr),
    align: (left, right, left, right, right,),
    table.header(
      table.cell(align: left, colspan: 5, inset: (top: 10pt, bottom: 5pt, x: 2.5mm), stroke: (top: 0.1pt + _t.ink))[#v(8pt, weak: false)#chanwe-eyebrow(with-rule: true, size: 5pt)[TABLE · COMPACT HERO]#v(-10pt, weak: false)#text(font: "Archivo", size: 16pt, fill: _t.ink, weight: "regular")[title only · no subtitle]],
      table.hline(stroke: 0.7pt + _t.ink),
      table.cell(align: left, inset: (top: 18pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[MODEL]],
      table.cell(align: right, inset: (top: 18pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[MPG]],
      table.cell(align: left, inset: (top: 18pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[CYL]],
      table.cell(align: right, inset: (top: 18pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[HP]],
      table.cell(align: right, inset: (top: 18pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[WT]],
    ),
    table.hline(stroke: 0.1pt + _t.ink),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.62]],
    table.hline(stroke: 0.3pt + rgb("#D4D4D4")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4 Wag]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.88]],
    table.hline(stroke: 0.3pt + rgb("#D4D4D4")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Datsun 710]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[22.80]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[93]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.32]],
    table.hline(stroke: 0.3pt + rgb("#D4D4D4")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet 4 Drive]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.40]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.21]],
    table.hline(stroke: 0.3pt + rgb("#D4D4D4")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet Sportabout]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.70]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[175]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.44]],
    table.hline(stroke: 0.3pt + rgb("#D4D4D4")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Valiant]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.10]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[105]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.46]],
    table.hline(stroke: 0.3pt + rgb("#D4D4D4")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Duster 360]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[14.30]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[245]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.57]],
    table.hline(stroke: 0.3pt + rgb("#D4D4D4")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Merc 240D]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[24.40]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[62]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.19]],
    table.hline(stroke: 0.5pt + _t.ink),
    table.footer(
      table.hline(stroke: 0.3pt + _t.ink),
      table.cell(colspan: 5, align: left, inset: (top: 10pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 7pt, fill: _t.fg-muted)[#text(fill: _t.primary)[/\/]Source · Motor Trend, 1974 · mtcars dataset.]],
    )
  )
  ]
}
]
]
===== Table · title only · zone-highlight
<table-title-only-zone-highlight>
#zone-highlight(color: "metallic", above: -2mm)[
#block[
#block[
#block(above: 2.5em, below: 2.5em)[
#block(inset: (x: 12.5pt, y: 0pt), fill: none)[
#{ set text(size: 10pt, fill: _t.ink, weight: "regular", tracking: 0pt, style: "normal"); set table(inset: (x: 2.5mm, y: 10pt), stroke: none, fill: none)
  [
  #table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr),
    align: (left, right, left, right, right,),
    table.header(
      table.cell(align: left, colspan: 5, inset: (top: 10pt, bottom: 5pt, x: 2.5mm), stroke: (top: 0.1pt + _t.ink))[#v(8pt, weak: false)#chanwe-eyebrow(with-rule: true, size: 5pt)[TABLE · COMPACT HERO]#v(-10pt, weak: false)#text(font: "Archivo", size: 16pt, fill: _t.ink, weight: "regular")[title only · zone-highlight]],
      table.hline(stroke: 0.7pt + _t.ink),
      table.cell(align: left, inset: (top: 18pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[MODEL]],
      table.cell(align: right, inset: (top: 18pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[MPG]],
      table.cell(align: left, inset: (top: 18pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[CYL]],
      table.cell(align: right, inset: (top: 18pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[HP]],
      table.cell(align: right, inset: (top: 18pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[WT]],
    ),
    table.hline(stroke: 0.1pt + _t.ink),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.62]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4 Wag]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.88]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Datsun 710]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[22.80]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[93]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.32]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet 4 Drive]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.40]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.21]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet Sportabout]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.70]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[175]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.44]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Valiant]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.10]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[105]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.46]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Duster 360]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[14.30]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[245]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.57]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Merc 240D]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[24.40]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[62]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.19]],
    table.hline(stroke: 0.5pt + _t.ink),
    table.footer(
      table.hline(stroke: 0.3pt + _t.ink),
      table.cell(colspan: 5, align: left, inset: (top: 10pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 7pt, fill: _t.fg-muted)[#text(fill: _t.primary)[/\/]Source · Motor Trend, 1974 · mtcars dataset.]],
    )
  )
  ]
}
]
]
]
]
]
===== Table · no title · no subtitle
<table-no-title-no-subtitle>
#block(above: 2.5em, below: 2.5em)[
#block(inset: (x: 12.5pt, y: 0pt), fill: rgb("#F7F7F7"))[
#{ set text(size: 10pt, fill: _t.ink, weight: "regular", tracking: 0pt, style: "normal"); set table(inset: (x: 2.5mm, y: 10pt), stroke: none, fill: rgb("#F7F7F7"))
  [
  #table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr),
    align: (left, right, left, right, right,),
    table.hline(stroke: 0.1pt + _t.ink),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.62]],
    table.hline(stroke: 0.3pt + rgb("#D4D4D4")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4 Wag]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.88]],
    table.hline(stroke: 0.3pt + rgb("#D4D4D4")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Datsun 710]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[22.80]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[93]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.32]],
    table.hline(stroke: 0.3pt + rgb("#D4D4D4")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet 4 Drive]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.40]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.21]],
    table.hline(stroke: 0.3pt + rgb("#D4D4D4")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet Sportabout]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.70]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[175]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.44]],
    table.hline(stroke: 0.3pt + rgb("#D4D4D4")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Valiant]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.10]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[105]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.46]],
    table.hline(stroke: 0.3pt + rgb("#D4D4D4")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Duster 360]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[14.30]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[245]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.57]],
    table.hline(stroke: 0.3pt + rgb("#D4D4D4")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Merc 240D]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[24.40]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[62]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.19]],
    table.hline(stroke: 0.5pt + _t.ink),
    table.footer(
      table.hline(stroke: 0.3pt + _t.ink),
      table.cell(colspan: 5, align: left, inset: (top: 10pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 7pt, fill: _t.fg-muted)[#text(fill: _t.primary)[/\/]Source · Motor Trend, 1974 · mtcars dataset.]],
    )
  )
  ]
}
]
]
===== Table · no title · no subtitle · zone-highlight
<table-no-title-no-subtitle-zone-highlight>
#zone-highlight(color: "metallic", above: -2mm)[
#block[
#block[
#block(above: 2.5em, below: 2.5em)[
#block(inset: (x: 12.5pt, y: 0pt), fill: none)[
#{ set text(size: 10pt, fill: _t.ink, weight: "regular", tracking: 0pt, style: "normal"); set table(inset: (x: 2.5mm, y: 10pt), stroke: none, fill: none)
  [
  #table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr),
    align: (left, right, left, right, right,),
    table.hline(stroke: 0.1pt + _t.ink),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.62]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4 Wag]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.88]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Datsun 710]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[22.80]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[93]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.32]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet 4 Drive]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.40]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.21]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet Sportabout]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.70]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[175]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.44]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Valiant]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.10]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[105]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.46]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Duster 360]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[14.30]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[245]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.57]],
    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Merc 240D]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[24.40]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[62]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.19]],
    table.hline(stroke: 0.5pt + _t.ink),
    table.footer(
      table.hline(stroke: 0.3pt + _t.ink),
      table.cell(colspan: 5, align: left, inset: (top: 10pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 7pt, fill: _t.fg-muted)[#text(fill: _t.primary)[/\/]Source · Motor Trend, 1974 · mtcars dataset.]],
    )
  )
  ]
}
]
]
]
]
]



