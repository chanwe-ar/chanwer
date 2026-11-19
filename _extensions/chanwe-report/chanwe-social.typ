// =================================================================
// chanwe-social.typ — the modern social slides, shared by
// chanwe-linkedin and chanwe-instagram.
//
// A shared component, like `chanwe-cards.*` and `chanwe-qr.typ`: listed
// by parent path under `template-partials` (after `../chanwe-report/
// chanwe-qr.typ`, which the contact slide calls) and included after the
// format's `_t` table. Not copied into a second extension.
//
// The design is the "Chanwe Social — Modern" canvas: the deck's and the
// research cover's language carried to a carousel. Every slide has
//   - a masthead: ink pill + orange subject run + counter, over a hairline
//   - a foot band: hairline, `// CHANWE / <series>` pill, and the wordmark,
//     a "Deslizá →" cue or a mono label
// and between them one of the bodies: cover (the photo hero), editorial-cover
// (the magazine-like headline + optional art), point, quote, stat, idea,
// checklist, contact, and the data plates kpi, table, news, event and chart.
// `social-post` draws any of them from a dictionary, which is what
// scripts/render-social.rb feeds it from a YAML file.
//
// Geometry is measured on a 1080 px wide canvas, so every length is
// `n * _su` (one canvas pixel of the 21 cm page). The height is the
// format's: 1080 (LinkedIn, Instagram square), 1350 (Instagram post) or
// 1920 (story); the bodies stretch with `v(1fr)` instead of assuming one. A
// story keeps 170 px clear above and below, where Instagram draws its own
// interface.
//
// Colours and weights are `_t` names only. The format's table must carry
// every token read below; scripts/check-typst-tokens.rb proves the values.
// =================================================================

#let _social-assets = "$chanwe-assets$".replace("\\_", "_")
#let _su = 21cm / 1080
#let _social-m = 72 * _su                // side margin
#let _social-w = 1080 * _su - 2 * _social-m
#let _social-head = 128                   // masthead hairline, canvas px
#let _social-foot-h = 112                 // foot band, from the bottom edge

// ── themes: what each surface paints ────────────────────────────
// Text on obsidian is rule-cool, never white; text on orange is white,
// large or bold; the wordmark on both is the Papel cut.
#let _social-theme(name) = if name == "ink" {
  (
    bg: _t.ink, pill-fill: none, pill-stroke: 1.5 * _su + _t.rule-ink, pill-fg: _t.rule-cool,
    subject: _t.primary, index: _t.ink-fg, hair: _t.rule-ink,
    title: _t.rule-cool, body: _t.rule-cool, label: _t.ink-fg,
    logo: "Logo_Papel.svg", series-fill: _t.ink-light, series-fg: _t.rule-cool,
  )
} else if name == "orange" {
  (
    bg: _t.primary, pill-fill: _t.ink, pill-stroke: none, pill-fg: _t.rule-cool,
    subject: _t.white, index: _t.white, hair: _t.white.transparentize(55%),
    title: _t.white, body: _t.white, label: _t.white,
    logo: "Logo_Papel.svg", series-fill: _t.ink, series-fg: _t.rule-cool,
  )
} else {
  (
    bg: _t.paper, pill-fill: _t.ink, pill-stroke: none, pill-fg: _t.rule-cool,
    subject: _t.primary, index: _t.body-fg, hair: _t.rule,
    title: _t.fg, body: _t.body-fg, label: _t.body-fg,
    logo: "Logo_Negro.svg", series-fill: _t.ink, series-fg: _t.rule-cool,
  )
}

// ── type ────────────────────────────────────────────────────────
#let _social-mono(size, fill, body, weight: _t.weight-medium, tracking: 0.16em, caps: true) = text(
  font: _t.font-mono, size: size * _su, weight: weight, tracking: tracking, fill: fill,
  top-edge: "cap-height", bottom-edge: "baseline",
  if caps { upper(body) } else { body },
)

#let _social-display(size, fill, body, weight: _t.weight-bold, tracking: -0.03em, leading: 0.3em) = {
  set par(leading: leading, spacing: 0pt, justify: false)
  set text(hyphenate: false)
  text(font: _t.font-display, size: size * _su, weight: weight, tracking: tracking, fill: fill, body)
}

#let _social-lede(size, fill, body) = {
  set par(leading: 0.42em, spacing: 0pt, justify: false)
  text(font: _t.font-serif, size: size * _su, weight: _t.weight-regular, style: "italic", fill: fill, body)
}

#let _social-body(size, fill, body, weight: _t.weight-body) = {
  set par(leading: 0.62em, spacing: 0pt, justify: false)
  text(font: _t.font-sans, size: size * _su, weight: weight, fill: fill, body)
}

// "Mendoza / Argentina": a string's slashes are the brand's orange slash.
#let _social-slashed(value, fill) = if type(value) == str and value.contains(" / ") {
  value.split(" / ").map(part => text(fill: fill, part)).join(text(fill: _t.primary, " / "))
} else {
  text(fill: fill, value)
}

// ── social-kicker — the brand eyebrow at canvas scale ───────────
#let social-kicker(label, color: _t.primary) = grid(
  columns: (44 * _su, auto),
  column-gutter: 18 * _su,
  align: (left + horizon, left + horizon),
  rect(width: 100%, height: 2 * _su, fill: color, stroke: none),
  _social-mono(22, color, label),
)

// The site's chapter label: a short rule, `/ 07` and the name in mono.
#let social-chapter(label, number: none, color: _t.primary, ink: _t.body-fg) = grid(
  columns: (44 * _su, auto),
  column-gutter: 18 * _su,
  align: (left + horizon, left + horizon),
  rect(width: 100%, height: 2 * _su, fill: color, stroke: none),
  stack(dir: ltr, spacing: 18 * _su,
    if number != none { _social-mono(22, ink, "/ " + number) },
    _social-mono(22, ink, label)),
)

// The largest size whose content stays inside the box. `sizes` runs largest
// first; if none fits, the smallest is used and the plate's check reports it.
#let _social-fit(sizes, width, max-height, make) = layout(_ => {
  let pick = sizes.find(s => measure(block(width: width, make(s))).height <= max-height)
  block(width: width, make(if pick == none { sizes.last() } else { pick }))
})

// The same for one unbroken line, such as a big figure: it must fit the width.
#let _social-fit-line(sizes, width, make) = layout(_ => {
  let pick = sizes.find(s => measure(make(s)).width <= width)
  make(if pick == none { sizes.last() } else { pick })
})

#let _social-arrow(color) = box(width: 40 * _su, height: 16 * _su, {
  let s = (paint: color, thickness: 1.75 * _su, cap: "square")
  place(top + left, line(start: (1 * _su, 8 * _su), end: (37 * _su, 8 * _su), stroke: s))
  place(top + left, line(start: (30 * _su, 1 * _su), end: (37 * _su, 8 * _su), stroke: s))
  place(top + left, line(start: (37 * _su, 8 * _su), end: (30 * _su, 15 * _su), stroke: s))
})

// ── chrome ──────────────────────────────────────────────────────
#let _social-masthead(th, pill, subject, index, safe: 0) = {
  place(top + left, dx: _social-m, dy: (50 + safe) * _su, box(width: _social-w, height: 52 * _su,
    grid(
      columns: (auto, 1fr, auto),
      align: (left + horizon, left + horizon, right + horizon),
      box(fill: th.pill-fill, stroke: th.pill-stroke, radius: _t.radius-pill,
        inset: (x: 16 * _su, y: 15 * _su), _social-mono(20, th.pill-fg, pill)),
      [],
      stack(dir: ltr, spacing: 28 * _su,
        if subject != none { _social-mono(20, th.subject, subject) },
        if index != none { _social-mono(20, th.index, index) },
      ),
    )))
  place(top + left, dx: _social-m, dy: (_social-head + safe) * _su,
    line(length: _social-w, stroke: 1.5 * _su + th.hair))
}

#let _social-footband(th, series, cue, safe: 0) = {
  place(bottom + left, dx: _social-m, dy: -(_social-foot-h + safe) * _su,
    line(length: _social-w, stroke: 1.5 * _su + th.hair))
  let mark = if cue == "logo" {
    image(_social-assets + th.logo, height: 34 * _su, fit: "contain")
  } else if cue == "swipe" {
    stack(dir: ltr, spacing: 16 * _su,
      _social-mono(20, th.title, "Deslizá"),
      _social-arrow(th.title))
  } else if cue != none {
    _social-mono(20, th.title, cue)
  }
  place(bottom + left, dx: _social-m, dy: -(34 + safe) * _su, box(width: _social-w, height: 52 * _su,
    grid(
      columns: (auto, 1fr, auto),
      align: (left + horizon, left + horizon, right + horizon),
      if series != none {
        box(fill: th.series-fill, radius: _t.radius-pill, inset: (x: 16 * _su, y: 15 * _su),
          stack(dir: ltr, spacing: 12 * _su,
            _social-mono(19, _t.primary, "//", tracking: 0.18em),
            _social-mono(19, th.series-fg, series, tracking: 0.18em)))
      },
      [],
      mark,
    )))
}

// The dot field drawn on obsidian (`ink-fg`), at a given strength.
#let _social-dots(width, height, strength) = rect(width: width, height: height, stroke: none,
  fill: tiling(size: (26 * _su, 26 * _su),
    place(center + horizon, circle(radius: 2.4 * _su, stroke: none,
      fill: _t.ink-fg.transparentize(100% - strength)))))

// The photo band: the site's hero. A rounded block of the mountains, well
// darkened with obsidian (the photograph is a texture, not the subject), with
// the dot field over it, so white display type reads.
#let _social-photo-band(path, width, height, inset: 44, body) = block(
  width: width, height: height, radius: 32 * _su, clip: true, fill: _t.ink, {
    place(top + left, layout(size => {
      let natural = measure(image(path))
      let ratio = natural.width / natural.height
      let w = calc.max(size.width / 1pt, size.height / 1pt * ratio) * 1pt
      let hh = w / ratio
      place(top + left, dx: -(w - size.width) * 0.62, dy: -(hh - size.height) * 0.4,
        image(path, width: w, height: hh))
    }))
    place(top + left, rect(width: 100%, height: 100%, stroke: none, fill: gradient.linear(angle: 90deg,
      (_t.ink.transparentize(14%), 0%), (_t.ink.transparentize(24%), 45%), (_t.ink.transparentize(3%), 100%))))
    // The dot field of every dark surface, subtle over the photograph.
    place(top + left, _social-dots(100%, 100%, 30%))
    place(top + left, block(width: 100%, height: 100%, inset: inset * _su, {
      set text(fill: _t.white)
      body
    }))
  })

// Artwork as artwork: no veil, dots or text over it. Editorial covers use this
// band for a supplied illustration or photograph while the title remains on
// the page surface. Keeping the art separate makes one layout work for a
// collage, a diagram exported as an image or a licensed photograph.
#let _social-image-band(path, width, height, fit: "cover") = block(
  width: width, height: height, radius: _t.radius-band, clip: true,
  fill: _t.tint, stroke: 1.5 * _su + _t.rule,
  image(path, width: 100%, height: 100%, fit: fit),
)

// ── social-page — one slide: surface, chrome, body ──────────────
// theme:  "paper" | "ink" | "orange"
// pill / subject / index:  the masthead (index: "02 / 07"; none hides it)
// series: the foot pill after `//`; none hides it
// cue:    "logo" | "swipe" | any label | none
// art:    an image path for the veiled cover art, or none
// dots:   none | "side" | "full" — the dot field, on ink only
// content-top: where the body starts, in canvas px (default under the masthead)
// The body is a fixed-height block between masthead and foot: use v(1fr)
// to centre or push.
#let social-page(
  theme:   "paper",
  pill:    "Chanwe // Carrusel",
  subject: "Estrategia",
  index:   none,
  series:  "Chanwe / Estrategia",
  cue:     "logo",
  dots:    none,
  content-top: 128,
  check:   false,
  body,
) = {
  let th = _social-theme(theme)
  page(fill: th.bg, numbering: none, context {
    // A story: Instagram's own interface covers the top and bottom 170 px.
    let safe = if page.height > 30cm { 170 } else { 0 }
    if dots == "side" {
      place(top + right, dx: 40 * _su, dy: (_social-head + safe) * _su,
        _social-dots(560 * _su, 100% - (240 + 2 * safe) * _su, 55%))
    } else if dots == "full" {
      place(top + left, dy: (_social-head + safe) * _su,
        _social-dots(100%, 100% - (240 + 2 * safe) * _su, 42%))
    }
    _social-masthead(th, pill, subject, index, safe: safe)
    _social-footband(th, series, cue, safe: safe)
    place(top + left, dx: _social-m, dy: (content-top + safe) * _su,
      block(width: _social-w, height: 100% - (content-top + _social-foot-h + 32 + 2 * safe) * _su, {
        set text(fill: th.title)
        // Generated posts must not lose text silently: a plate whose content
        // does not fit stops the render and says so.
        if check {
          layout(size => {
            let m = measure(block(width: size.width, body))
            if m.height > size.height + 1pt {
              panic("El contenido no entra en la placa: mide " + str(calc.round(m.height / _su)) + " px y hay " + str(calc.round(size.height / _su)) + " px. Acortá el texto o sacá filas.")
            }
          })
        }
        body
      }))
  })
}

// ── the bodies ────────────────────────────────────────────

#let _social-ledger(th, rows) = {
  line(length: 100%, stroke: 1.5 * _su + th.hair)
  v(28 * _su)
  grid(
    columns: (1fr,) * calc.max(rows.len(), 1),
    column-gutter: 32 * _su,
    ..rows.map(((k, v)) => stack(spacing: 14 * _su,
      _social-mono(18, th.label, k, tracking: 0.18em),
      _social-body(28, th.title, _social-slashed(v, th.title), weight: _t.weight-regular))),
  )
}

// cover — the site's hero: the photo band with a dot pill, the title in white
// with its orange run, and the serif lede; a ledger of facts under it. With
// `art: none` the title sits on plain paper.
#let social-cover(
  title:   [Título del carrusel],
  accent:  [en dos líneas.],
  lede:    none,
  ledger:  (("Autor", "Chanwe"), ("Tema", "Estrategia")),
  kicker:  "Estrategia activa",
  index:   none,
  pill:    "Chanwe // Carrusel",
  subject: "Estrategia",
  series:  "Chanwe / Estrategia",
  cue:     "swipe",
  art:     _social-assets + "bg_mountains.jpg",
  size:    88,
) = social-page(pill: pill, subject: subject, index: index, series: series, cue: cue, content-top: 152, {
  let th = _social-theme("paper")
  if art == none {
    v(1fr)
    block(width: 860 * _su, stroke: (left: 6 * _su + _t.primary), inset: (left: 36 * _su), {
      _social-display(size, th.title, [#title #text(fill: _t.primary, accent)], tracking: -0.035em, leading: 0.26em)
      if lede != none {
        v(28 * _su)
        _social-lede(42, th.body, lede)
      }
    })
    v(1fr)
    if ledger.len() > 0 { _social-ledger(th, ledger) }
  } else {
    layout(room => {
      let foot = if ledger.len() > 0 { measure(block(width: room.width, _social-ledger(th, ledger))).height + 30 * _su } else { 0pt }
      _social-photo-band(art, room.width, room.height - foot, {
        box(stroke: 1.5 * _su + _t.white.transparentize(55%), radius: _t.radius-pill, inset: (x: 18 * _su, y: 14 * _su),
          stack(dir: ltr, spacing: 12 * _su,
            circle(radius: 5 * _su, fill: _t.primary, stroke: none),
            _social-mono(18, _t.white, kicker)))
        v(1fr)
        _social-display(size, _t.white, [#title #text(fill: _t.primary, accent)], tracking: -0.04em, leading: 0.24em)
        if lede != none {
          v(28 * _su)
          _social-lede(40, _t.white, lede)
        }
      })
      if ledger.len() > 0 {
        v(30 * _su)
        _social-ledger(th, ledger)
      }
    })
  }
})

// editorial-cover — the publication system's clean cover: category eyebrow,
// direct headline, optional italic deck and an illustration/photo band. It
// translates the editorial mockups into the current Chanwe tokens and type.
// `art: none` gives the typography-only version. A relative art path in a YAML
// post is resolved beside that YAML by scripts/render-social.rb.
#let social-editorial-cover(
  title:       [Título de la publicación],
  accent:      none,
  lede:        none,
  kicker:      "Empresas / Estrategia",
  art:         none,
  art-fit:     "cover",
  art-height:  none,
  art-caption: none,
  theme:       "paper",
  index:       none,
  pill:        "Chanwe // Perspectiva",
  subject:     "Perspectiva",
  series:      "Chanwe / Perspectiva",
  cue:         "swipe",
) = {
  let th = _social-theme(theme)
  let accent-color = if theme == "orange" { th.title } else { _t.primary }
  let kicker-color = if theme == "orange" { th.title } else { _t.primary }
  social-page(theme: theme, pill: pill, subject: subject, index: index,
    series: series, cue: cue, content-top: 164, {
    context {
      let band-height = if art-height != none { art-height }
        else if page.height > 30cm { 760 }
        else if page.height > 24cm { 500 }
        else { 350 }
      v(1fr)
      social-kicker(kicker, color: kicker-color)
      v(32 * _su)
      _social-fit((92, 82, 72, 64, 56, 50), _social-w, if art == none { 560 * _su } else { 360 * _su }, s =>
        _social-display(s, th.title,
          if accent == none { title } else { [#title #text(fill: accent-color, accent)] },
          weight: _t.weight-display, tracking: -0.04em, leading: 0.26em))
      if lede != none {
        v(24 * _su)
        block(width: 880 * _su, _social-lede(36, th.body, lede))
      }
      if art != none {
        v(36 * _su)
        _social-image-band(art, _social-w, band-height * _su, fit: art-fit)
        if art-caption != none {
          v(16 * _su)
          _social-mono(17, th.label, art-caption, tracking: 0.12em)
        }
      }
      v(1fr)
    }
  })
}

// point — a numbered idea: serif numeral, eyebrow, headline, body, and an
// optional sunken aside ("Qué mirar: …") at the foot.
#let social-point(
  number:      "01",
  label:       "Idea",
  headline:    [Una idea por placa, dicha en una oración.],
  body:        none,
  aside-label: none,
  aside:       none,
  index:       none,
  pill:        "Chanwe // Carrusel",
  subject:     "Estrategia",
  series:      "Chanwe / Estrategia",
  cue:         "logo",
) = social-page(pill: pill, subject: subject, index: index, series: series, cue: cue, content-top: 176, {
  text(font: _t.font-serif-display, size: 300 * _su, weight: _t.weight-regular, fill: _t.primary,
    top-edge: "cap-height", bottom-edge: "baseline", tracking: -0.02em, number)
  v(48 * _su)
  social-kicker(label)
  v(32 * _su)
  _social-display(66, _t.fg, headline)
  if body != none {
    v(32 * _su)
    block(width: 860 * _su, _social-body(34, _t.body-fg, body))
  }
  v(1fr)
  if aside != none {
    block(width: 100%, fill: _t.tint, radius: 16 * _su, inset: (x: 32 * _su, y: 30 * _su),
      grid(columns: (220 * _su, 1fr), column-gutter: 28 * _su, align: (left + top, left + top),
        pad(top: 8 * _su, _social-mono(18, _t.body-fg, if aside-label != none { aside-label } else { "Nota" }, tracking: 0.18em)),
        _social-body(30, _t.fg, aside, weight: _t.weight-regular)))
  }
})

// quote — a statement on obsidian (or `theme: "orange"`) with the dot field at
// the side. The type takes the largest size that fits; `author` and `role`
// sign it, `source` is the older one-line signature.
#let social-quote(
  statement: [La estrategia también aparece en los no.],
  source:  none,
  author:  none,
  role:    none,
  theme:   "ink",
  index:   none,
  pill:    "Chanwe // Lectura",
  subject: "Estrategia",
  series:  "Chanwe / Estrategia",
  cue:     "logo",
) = {
  let on-orange = theme == "orange"
  let ink = if on-orange { _t.white } else { _t.rule-cool }
  let mark = if on-orange { _t.white } else { _t.primary }
  let sign = if on-orange { _t.white } else { _t.fg-subtle }
  social-page(theme: theme, dots: if on-orange { none } else { "full" }, pill: pill, subject: subject, index: index, series: series, cue: cue, check: true, {
    v(1fr)
    text(font: _t.font-serif-display, size: 260 * _su, weight: _t.weight-regular, fill: mark,
      top-edge: "bounds", bottom-edge: "bounds", "“")
    v(40 * _su)
    _social-fit((104, 92, 80, 70, 60, 52), 900 * _su, 620 * _su, s =>
      _social-display(s, ink, statement, weight: _t.weight-display, tracking: -0.035em, leading: 0.3em))
    let signed = author != none or source != none
    if signed {
      v(44 * _su)
      grid(columns: (44 * _su, auto), column-gutter: 18 * _su, align: (left + horizon, left + horizon),
        rect(width: 100%, height: 2 * _su, fill: mark, stroke: none),
        _social-mono(22, ink, if author != none { author } else { source }))
      if role != none {
        v(16 * _su)
        pad(left: 62 * _su, _social-body(28, sign, role, weight: _t.weight-regular))
      }
    }
    v(1fr)
  })
}

// stat — one figure on a slate band. Pass real numbers only; a starter
// leaves `[XX]` and `[FUENTE · AÑO]` for the author to fill.
#let social-stat(
  label:   "El dato",
  caption: [de las iniciativas no tiene un responsable claro.],
  value:   "[XX]",
  unit:    "%",
  source:  "Fuente: [FUENTE · AÑO]",
  index:   none,
  pill:    "Chanwe // Dato",
  subject: "Estrategia",
  series:  "Chanwe / Estrategia",
  cue:     "logo",
) = social-page(pill: pill, subject: subject, index: index, series: series, cue: cue, {
  v(1fr)
  social-kicker(label)
  v(40 * _su)
  block(width: 880 * _su, _social-display(58, _t.fg, caption, leading: 0.32em))
  v(40 * _su)
  block(width: 100%, fill: _t.tint, radius: 16 * _su,
    inset: (x: 48 * _su, top: 44 * _su, bottom: 40 * _su), {
      set par(leading: 0pt, spacing: 0pt)
      _social-fit-line((280, 240, 210, 180, 160, 140), 820 * _su, s => {
        text(font: _t.font-display, weight: _t.weight-bold, fill: _t.fg, size: s * _su,
          tracking: -0.05em, top-edge: "cap-height", bottom-edge: "descender", value)
        if unit != "" {
          h(8 * _su)
          text(font: _t.font-display, weight: _t.weight-bold, fill: _t.primary, size: s * 0.5 * _su,
            top-edge: "cap-height", bottom-edge: "baseline", unit)
        }
      })
      v(28 * _su)
      if source != none { _social-mono(20, _t.body-fg, source, tracking: 0.18em) }
    })
  v(1fr)
})

// idea — the protagonist piece: one line, white and bold, on orange.
#let social-idea(
  statement: [Foco es decidir qué no hacer.],
  label:   "La idea",
  size:    112,
  index:   none,
  pill:    "Chanwe // Idea",
  subject: "Estrategia",
  series:  "Chanwe / Estrategia",
  cue:     "logo",
) = social-page(theme: "orange", pill: pill, subject: subject, index: index, series: series, cue: cue, {
  v(1fr)
  social-kicker(label, color: _t.white)
  v(44 * _su)
  block(width: 900 * _su, _social-display(size, _t.white, statement, tracking: -0.04em, leading: 0.24em))
  v(1fr)
})

// checklist — numbered rows with an empty box to tick.
#let social-checklist(
  label:   "Checklist",
  title:   [Antes de la próxima reunión:],
  items:   (),
  index:   none,
  pill:    "Chanwe // Checklist",
  subject: "Estrategia",
  series:  "Chanwe / Estrategia",
  cue:     "logo",
) = social-page(pill: pill, subject: subject, index: index, series: series, cue: cue, {
  v(1fr)
  social-kicker(label)
  v(40 * _su)
  _social-display(64, _t.fg, title)
  v(40 * _su)
  for (i, item) in items.enumerate() {
    line(length: 100%, stroke: 1.5 * _su + _t.rule)
    block(width: 100%, inset: (y: 26 * _su),
      grid(columns: (72 * _su, 1fr, 28 * _su), column-gutter: 20 * _su,
        align: (left + horizon, left + horizon, right + horizon),
        _social-mono(22, _t.primary, if i < 9 { "0" + str(i + 1) } else { str(i + 1) }, tracking: 0.08em),
        _social-body(32, _t.fg, item, weight: _t.weight-regular),
        box(width: 28 * _su, height: 28 * _su, radius: 3 * _su, stroke: 1.75 * _su + _t.border-cool)))
  }
  line(length: 100%, stroke: 1.5 * _su + _t.rule)
  v(1fr)
})

// cycle — four short stages around a native circular cue. The diagram stays
// as text and vectors so its labels remain editable, searchable and sharp in
// every social ratio; artwork generation is deliberately not used for it.
#let social-cycle(
  label:   "Cómo trabajamos",
  title:   [Una estrategia que aprende.],
  items:   ("Brújula", "Hipótesis", "Evidencia", "Redefinición"),
  pill:    "Chanwe // Método",
  ..chrome,
) = {
  if items.len() != 4 { panic("social-cycle needs exactly four items") }
  let node(body) = box(
    width: 340 * _su,
    radius: _t.radius-pill,
    stroke: 1.5 * _su + _t.rule-ink,
    fill: _t.ink.transparentize(18%),
    inset: (x: 28 * _su, y: 22 * _su),
    align(center, _social-body(28, _t.rule-cool, body, weight: _t.weight-regular)),
  )
  social-page(theme: "ink", dots: "full", pill: pill, check: true, ..chrome, {
    v(1fr)
    social-chapter(label, color: _t.primary, ink: _t.fg-subtle)
    v(34 * _su)
    _social-fit((86, 76, 68, 60), _social-w, 260 * _su, s =>
      _social-display(s, _t.rule-cool, title, tracking: -0.04em, leading: 0.26em))
    v(64 * _su)
    align(center, node(items.at(0)))
    v(22 * _su)
    grid(
      columns: (1fr, 210 * _su, 1fr),
      column-gutter: 18 * _su,
      align: (left + horizon, center + horizon, right + horizon),
      node(items.at(3)),
      text(font: _t.font-display, size: 176 * _su, weight: _t.weight-regular,
        fill: _t.primary, top-edge: "bounds", bottom-edge: "bounds", "↻"),
      node(items.at(1)),
    )
    v(22 * _su)
    align(center, node(items.at(2)))
    v(1fr)
  })
}

// contact — the closing slide on obsidian: wordmark, headline, lede, a
// contact ledger and the framed QR.
#let social-contact(
  headline: [¿Ordenamos tu estrategia],
  lede:     [Escribinos y armamos el primer mapa juntos.],
  rows:     (("Web", "chanwe.com.ar"), ("Base", "Mendoza / Argentina")),
  qr:       _social-assets + "contact-qr.svg",
  index:    none,
  pill:     "Chanwe // Contacto",
  subject:  "Estrategia",
  series:   "Chanwe / Estrategia",
  cue:      "Guardalo · Compartilo",
) = social-page(theme: "ink", dots: "full", pill: pill, subject: subject, index: index, series: series, cue: cue, {
  v(1fr)
  image(_social-assets + "Logo_Papel.svg", height: 64 * _su, fit: "contain")
  v(44 * _su)
  _social-display(84, _t.rule-cool, [#headline#h(0.08em)#box(circle(radius: 0.11em, fill: _t.primary, stroke: none))], tracking: -0.035em, leading: 0.26em)
  if lede != none {
    v(24 * _su)
    _social-lede(40, _t.rule-cool, lede)
  }
  v(1fr)
  line(length: 100%, stroke: 1.5 * _su + _t.rule-ink)
  v(32 * _su)
  grid(
    columns: (1fr, auto), column-gutter: 48 * _su, align: (left + bottom, right + bottom),
    grid(columns: (140 * _su, 1fr), row-gutter: 22 * _su, column-gutter: 24 * _su,
      align: (left + horizon, left + horizon),
      ..rows.map(((k, v)) => (
        _social-mono(18, _t.ink-fg, k, tracking: 0.18em),
        _social-mono(26, _t.rule-cool, _social-slashed(v, _t.rule-cool), weight: _t.weight-regular, tracking: 0em, caps: false),
      )).flatten()),
    if qr != none {
      chanwe-qr-frame(qr, size: 132 * _su, edge: _t.white.transparentize(84%), card: _t.white,
        pad-outer: 6 * _su, pad-inner: 6 * _su, radius-outer: 6 * _su, radius-inner: 4 * _su)
    },
  )
})

// ── the data plates: each takes plain text and numbers ───────────

// kpi — one huge figure on obsidian, its change as a pill, and up to four
// secondary figures in hairline cells. `delta-dir`: "up" | "down" | "flat".
#let social-kpi(
  value:     "[XX]",
  unit:      none,
  label:     "Indicador",
  kicker:    "Dato",
  number:    none,
  delta:     none,
  delta-dir: "up",
  delta-label: none,
  context-note: none,
  items:     (),
  source:    none,
  pill:      "Chanwe // Dato",
  ..chrome,
) = social-page(theme: "ink", dots: "full", pill: pill, check: true, ..chrome, {
  v(1fr)
  social-chapter(kicker, number: number, ink: _t.fg-subtle)
  v(44 * _su)
  block(width: 900 * _su, _social-display(54, _t.rule-cool, label, weight: _t.weight-display, leading: 0.3em))
  v(30 * _su)
  _social-fit-line((360, 320, 280, 240, 200, 170, 140, 120), 930 * _su, s => {
    text(font: _t.font-display, weight: _t.weight-bold, fill: _t.white, size: s * _su,
      tracking: -0.05em, top-edge: "cap-height", bottom-edge: "baseline", str(value))
    if unit != none {
      h(14 * _su)
      text(font: _t.font-display, weight: _t.weight-bold, fill: _t.primary, size: s * 0.45 * _su,
        top-edge: "cap-height", bottom-edge: "baseline", str(unit))
    }
  })
  if delta != none {
    v(44 * _su)
    let tone = if delta-dir == "down" { _t.chart-red } else if delta-dir == "flat" { _t.fg-subtle } else { _t.chart-green }
    let arrow = if delta-dir == "down" { "▼" } else if delta-dir == "flat" { "–" } else { "▲" }
    stack(dir: ltr, spacing: 20 * _su,
      box(stroke: 1.5 * _su + _t.rule-ink, radius: _t.radius-pill, inset: (x: 22 * _su, y: 16 * _su),
        stack(dir: ltr, spacing: 12 * _su,
          _social-mono(24, tone, arrow, tracking: 0em),
          _social-mono(24, _t.rule-cool, str(delta), tracking: 0.04em, caps: false))),
      if delta-label != none { box(inset: (y: 16 * _su), _social-mono(20, _t.fg-subtle, delta-label)) },
    )
  }
  if context-note != none {
    v(36 * _su)
    block(width: 880 * _su, _social-body(34, _t.rule-cool, context-note))
  }
  if items.len() > 0 {
    v(52 * _su)
    grid(columns: (1fr,) * calc.min(items.len(), 2), column-gutter: 32 * _su, row-gutter: 32 * _su,
      ..items.map(it => block(width: 100%, stroke: (top: 1.5 * _su + _t.rule-ink), inset: (top: 24 * _su), {
        _social-mono(18, _t.fg-subtle, it.label, tracking: 0.18em)
        v(16 * _su)
        _social-display(64, _t.rule-cool, str(it.value), weight: _t.weight-display, tracking: -0.04em)
      })))
  }
  v(1fr)
  if source != none { _social-mono(18, _t.fg-subtle, source, tracking: 0.14em) }
})

// table — a title and a white pane with a tinted header. The first column is
// text, the others align right; `highlight` names the row to mark in orange.
#let social-table(
  title:     [Título de la tabla],
  columns:   ("Nombre", "Valor"),
  rows:      (),
  highlight: none,
  kicker:    "Ranking",
  number:    none,
  source:    none,
  pill:      "Chanwe // Tabla",
  ..chrome,
) = social-page(theme: "paper", pill: pill, check: true, ..chrome, {
  v(1fr)
  social-chapter(kicker, number: number)
  v(32 * _su)
  _social-fit((84, 72, 62, 54), _social-w, 280 * _su, s =>
    _social-display(s, _t.fg, title, tracking: -0.04em, leading: 0.26em))
  v(40 * _su)
  block(width: 100%, radius: 24 * _su, clip: true, fill: _t.pane, stroke: 1.5 * _su + _t.rule, {
    let n = columns.len()
    let cell(c, r, body, fill-col, weight) = {
      let aligned = if c == 0 { left + horizon } else { right + horizon }
      align(aligned, _social-body(if r == 0 { 19 } else { 31 }, fill-col, body, weight: weight))
    }
    grid(
      columns: (1fr,) + (auto,) * (n - 1),
      inset: (x: 26 * _su, y: 25 * _su),
      fill: (c, r) => if r == 0 { _t.tint } else { none },
      stroke: (c, r) => (bottom: if r <= rows.len() - 1 { 1.5 * _su + _t.rule } else { none }),
      ..columns.enumerate().map(((c, h)) => align(if c == 0 { left + horizon } else { right + horizon },
        _social-mono(19, _t.fg-muted, h, tracking: 0.12em))),
      ..rows.map(row => {
        let marked = highlight != none and str(row.at(0)) == str(highlight)
        row.enumerate().map(((c, v)) => {
          let body = if c == 0 and marked {
            box(circle(radius: 7 * _su, fill: _t.primary, stroke: none), baseline: -3 * _su) + h(12 * _su) + str(v)
          } else { str(v) }
          cell(c, 1, body, if marked { _t.fg } else { _t.body-fg }, if marked { _t.weight-display } else { _t.weight-regular })
        })
      }).flatten(),
    )
  })
  v(30 * _su)
  if source != none { _social-mono(18, _t.fg-muted, source, tracking: 0.14em) }
  v(1fr)
})

// news — the headline on the photo band, its source and date, and why it
// matters in up to three short rows on the paper under it.
#let social-news(
  headline: [Titular de la noticia],
  kicker:   "Noticias",
  source:   none,
  date:     none,
  why-label: "Por qué importa",
  why:      (),
  art:      _social-assets + "bg_mountains.jpg",
  pill:     "Chanwe // Noticias",
  ..chrome,
) = social-page(theme: "paper", pill: pill, content-top: 152, ..chrome, {
  layout(size => {
    let why-block = block(width: size.width, {
      social-chapter(why-label)
      v(22 * _su)
      for (i, item) in why.enumerate() {
        if i > 0 { line(length: 100%, stroke: 1.5 * _su + _t.rule) }
        block(width: 100%, inset: (y: 22 * _su),
          grid(columns: (64 * _su, 1fr), align: (left + top, left + top),
            pad(top: 7 * _su, _social-mono(22, _t.fg-muted, "0" + str(i + 1), tracking: 0.06em)),
            _social-body(34, _t.fg, item, weight: _t.weight-regular)))
      }
    })
    let need = measure(why-block).height
    let band = size.height - need - 34 * _su
    if band < 420 * _su {
      panic("La noticia no entra en la placa: acortá «why» o el titular.")
    }
    _social-photo-band(art, size.width, band, {
      box(stroke: 1.5 * _su + _t.white.transparentize(55%), radius: _t.radius-pill, inset: (x: 18 * _su, y: 14 * _su),
        stack(dir: ltr, spacing: 12 * _su,
          circle(radius: 5 * _su, fill: _t.primary, stroke: none),
          _social-mono(18, _t.white, kicker)))
      v(1fr)
      _social-fit((88, 76, 66, 58, 50), size.width - 88 * _su, band - 260 * _su, s =>
        _social-display(s, _t.white, headline, tracking: -0.04em, leading: 0.26em))
      if source != none or date != none {
        v(26 * _su)
        _social-mono(20, _t.white, (source, date).filter(x => x != none).join("  ·  "))
      }
    })
    v(34 * _su)
    why-block
  })
})

// event — the date as the protagonist on obsidian, the title, a ledger, the
// call to action as the one orange pill and the framed QR.
#let social-event(
  title:   [Nombre del evento],
  day:     "00",
  month:   "Mes",
  kicker:  "Eventos",
  lede:    none,
  rows:    (),
  cta:     none,
  qr:      none,
  pill:    "Chanwe // Evento",
  ..chrome,
) = social-page(theme: "ink", dots: "full", pill: pill, check: true, ..chrome, {
  v(1fr)
  social-chapter(kicker, ink: _t.fg-subtle)
  v(36 * _su)
  grid(columns: (auto, 1fr), column-gutter: 30 * _su, align: (left + bottom, left + bottom),
    text(font: _t.font-display, weight: _t.weight-bold, fill: _t.white, size: 280 * _su, tracking: -0.05em,
      top-edge: "cap-height", bottom-edge: "baseline", str(day)),
    _social-mono(40, _t.primary, month, tracking: 0.08em),
  )
  v(48 * _su)
  _social-fit((84, 72, 62, 54), _social-w, 300 * _su, s =>
    _social-display(s, _t.rule-cool, title, weight: _t.weight-display, tracking: -0.04em, leading: 0.26em))
  if lede != none {
    v(24 * _su)
    _social-lede(40, _t.rule-cool, lede)
  }
  v(1fr)
  line(length: 100%, stroke: 1.5 * _su + _t.rule-ink)
  v(30 * _su)
  grid(columns: (1fr, auto), column-gutter: 40 * _su, align: (left + bottom, right + bottom),
    {
      grid(columns: (160 * _su, 1fr), row-gutter: 22 * _su, align: (left + horizon, left + horizon),
        ..rows.map(((k, v)) => (
          _social-mono(18, _t.fg-subtle, k, tracking: 0.18em),
          _social-body(30, _t.rule-cool, str(v), weight: _t.weight-regular),
        )).flatten())
      if cta != none {
        v(30 * _su)
        box(fill: _t.primary, radius: _t.radius-pill, inset: (x: 34 * _su, y: 22 * _su),
          text(font: _t.font-sans, size: 30 * _su, weight: _t.weight-medium, fill: _t.white, str(cta)))
      }
    },
    if qr != none {
      let path = if qr == "contact" { _social-assets + "contact-qr.svg" } else { qr }
      chanwe-qr-frame(path, size: 132 * _su, edge: _t.white.transparentize(84%), card: _t.white,
        pad-outer: 6 * _su, pad-inner: 6 * _su, radius-outer: 6 * _su, radius-inner: 4 * _su)
    },
  )
})

// chart — horizontal bars with rounded ends. `mode: "focus"` paints `focus`
// orange and the rest slate; `mode: "discrete"` gives each bar its series
// colour, in the order of the brand's categorical palette.
// A bar is { label, value }; `text` prints the value another way ("7,4").
#let social-chart(
  title:   [Título del gráfico],
  subtitle: none,
  bars:    (),
  focus:   none,
  mode:    "focus",
  unit:    "",
  kicker:  "Gráfico",
  number:  none,
  source:  none,
  pill:    "Chanwe // Gráfico",
  ..chrome,
) = social-page(theme: "paper", pill: pill, check: true, ..chrome, {
  let palette = (_t.primary, _t.chart-blue, _t.chart-teal, _t.chart-indigo, _t.chart-purple, _t.chart-green, _t.chart-orange, _t.chart-red)
  let peak = calc.max(..bars.map(b => float(b.value)))
  v(1fr)
  social-chapter(kicker, number: number)
  v(32 * _su)
  _social-fit((80, 70, 60, 52), _social-w, 260 * _su, s =>
    _social-display(s, _t.fg, title, tracking: -0.04em, leading: 0.26em))
  if subtitle != none {
    v(20 * _su)
    _social-body(32, _t.body-fg, subtitle)
  }
  v(52 * _su)
  for (i, b) in bars.enumerate() {
    let tone = if mode == "discrete" { palette.at(calc.rem(i, palette.len())) }
      else if focus != none and str(b.label) == str(focus) { _t.primary } else { _t.fg-subtle }
    let strong = focus != none and str(b.label) == str(focus)
    block(width: 100%, below: 30 * _su, {
      grid(columns: (1fr, auto), align: (left + horizon, right + horizon),
        _social-body(30, if strong { _t.fg } else { _t.body-fg }, str(b.label), weight: if strong { _t.weight-display } else { _t.weight-regular }),
        _social-mono(28, if strong { _t.fg } else { _t.body-fg }, str(b.at("text", default: b.value)) + str(unit), tracking: 0.02em, caps: false, weight: _t.weight-medium))
      v(14 * _su)
      block(width: 100%, height: 40 * _su, fill: _t.tint, radius: 12 * _su,
        place(top + left, rect(width: calc.max(float(b.value) / peak, 0.015) * 100%, height: 100%, fill: tone, stroke: none, radius: 12 * _su)))
    })
  }
  v(14 * _su)
  if source != none { _social-mono(18, _t.fg-muted, source, tracking: 0.14em) }
  v(1fr)
})

// ── v2 pieces (2026-11-17): theme covers, series art, contact QR ──
// Full-bleed plates with no masthead or foot band: the Fundido pattern icons
// carry them. Every element is an argument, so a YAML post sets all of it.
// The files under assets/v2/ are copies of the brand hub (chanwe-brandbook
// `brand/assets/patrones`, `brand/applications/documentos`, `brand/media/fotografia`).
#let _social-v2 = _social-assets + "v2/"
#let _social-icons = ("Aspa", "Nudo", "Paso", "Mas", "Codo", "Reloj", "Onda", "Traslado", "Damero", "Escala", "Rombo", "Cruz")
#let _social-icon(name, tone) = {
  if name not in _social-icons { panic("Unknown icon «" + name + "». Use: " + _social-icons.join(", ") + ".") }
  _social-v2 + "iconos/Icono_" + name + "_" + tone + ".svg"
}
#let _social-photos = (alps: "v2/alps-blue-hour.jpg", ridge: "cover-snow-ridge.jpg")
#let _social-photo(photo) = if photo in _social-photos { _social-assets + _social-photos.at(photo) } else { photo }
// The dot field fading out towards the lower right, on any surface.
#let _social-dots-fade(bg, strength) = {
  place(top + left, _social-dots(100%, 100%, strength))
  place(top + left, rect(width: 100%, height: 100%, stroke: none,
    fill: gradient.linear(angle: 55deg, (bg.transparentize(100%), 0%), (bg, 62%), (bg, 100%))))
}
#let _social-v2-surface(style, tone) = if style == "orange" {
  (bg: _t.primary, fg: _t.white, label: _t.white, icon: "Blanco", logo: "Logo_Papel.svg")
} else if style == "photo" {
  (bg: _t.ink, fg: _t.white, label: _t.white, icon: "Papel", logo: "Logo_Papel.svg")
} else if tone == "paper" {
  (bg: _t.paper, fg: _t.fg, label: _t.fg-muted, icon: "Obsidiana", logo: "Logo_Negro.svg")
} else {
  (bg: _t.ink, fg: _t.rule-cool, label: _t.ink-fg, icon: "Papel", logo: "Logo_Papel.svg")
}

// theme — one pattern icon and one word. Three styles:
//   style: "icon"    the icon on obsidian or paper (`tone: ink | paper`), dot field
//          "photo"   the photograph behind, a smaller icon
//          "orange"  full orange, the icon oversized and cropped, the title in the centre
// title / show-title, icon (a pattern icon name), label (mono, top left; none hides it),
// logo (the wordmark at the foot), dots, photo ("alps" | "ridge" | a path, or `art:`),
// icon-size / title-size (canvas px; none follows the canvas height), icon-shift (orange: x offset, % of width),
// veil (photo: how much obsidian covers it at the top, 0 to 100).
// On a story the icon sits in the centred disc Instagram shows for a highlight.
#let social-theme(
  title: "Tema", show-title: true, icon: "Aspa", style: "icon", tone: "ink",
  label: none, logo: true, dots: true, photo: "alps", art: none,
  icon-size: none, title-size: none, icon-shift: 16, veil: 55, ..rest,
) = {
  if style not in ("icon", "photo", "orange") { panic("theme: style is icon, photo or orange.") }
  let s = _social-v2-surface(style, tone)
  page(fill: s.bg, numbering: none, context {
    let hp = page.height / _su
    let safe = if page.height > 30cm { 170 } else { 0 }
    let k = calc.min(1, hp / 1500)
    let isz = if icon-size != none { icon-size } else if style == "orange" { calc.max(hp, 1080) * 0.8 } else if style == "photo" { 300 * k } else { 400 * k }
    let tsz = if title-size != none { title-size } else if style == "orange" { 118 * k } else { 104 * k }
    if style == "photo" {
      place(top + left, image(_social-photo(if art != none { art } else { photo }), width: 100%, height: 100%, fit: "cover"))
      place(top + left, rect(width: 100%, height: 100%, stroke: none, fill: gradient.linear(angle: 90deg,
        (_t.ink.transparentize(100% - veil * 1%), 0%), (_t.ink.transparentize(100% - veil * 0.7%), 40%), (_t.ink.transparentize(8%), 100%))))
    }
    if dots and style == "icon" { _social-dots-fade(s.bg, if tone == "paper" { 34% } else { 46% }) }
    let word = if show-title { _social-display(tsz, s.fg, title, weight: _t.weight-medium) }
    if style == "orange" {
      place(center + horizon, dx: icon-shift * 1%, dy: -3%, image(_social-icon(icon, "Velo"), width: isz * _su))
      place(center + horizon, block(width: _social-w, align(center, word)))
    } else {
      place(center + horizon, image(_social-icon(icon, s.icon), width: isz * _su))
      place(center + horizon, dy: (isz / 2 + 70 * k) * _su + tsz * _su / 2, block(width: _social-w, align(center, word)))
    }
    if label != none {
      place(top + left, dx: 84 * _su, dy: (96 * k + safe) * _su, _social-mono(22 * calc.max(k, 0.8), s.label, label))
    }
    if logo {
      place(bottom + center, dy: -(110 * k + safe) * _su, image(_social-assets + s.logo, width: 230 * calc.max(k, 0.7) * _su))
    }
  })
}

// series — the art of a publication series: one oversized icon bleeding off
// the edge. icon, tone (ink | paper), dots, scale (1 = the brand's cut),
// shift-x / shift-y (% of the canvas), label and title (optional, lower left).
#let social-series(
  icon: "Onda", tone: "ink", dots: true, scale: 1.0, shift-x: 0, shift-y: 0,
  label: none, title: none, ..rest,
) = {
  let s = _social-v2-surface("icon", tone)
  page(fill: s.bg, numbering: none, context {
    let hp = page.height / _su
    if dots { _social-dots-fade(s.bg, if tone == "paper" { 34% } else { 46% }) }
    // The brand's cut on the 27:20 art canvas; on taller canvases the width rules.
    let side = calc.min(page.height * 1.1, page.width * 0.82) * scale
    place(top + right, dx: side * 0.24 + shift-x * 1%, dy: -side * 0.16 + shift-y * 1%,
      image(_social-icon(icon, s.icon), width: side))
    if label != none or title != none {
      place(bottom + left, dx: _social-m, dy: -64 * _su, stack(spacing: 18 * _su,
        if label != none { _social-mono(20, s.label, label) },
        if title != none { _social-display(calc.min(72, hp * 0.07), s.fg, title, weight: _t.weight-medium) }))
    }
  })
}

// qr — the contact code as a piece. variant: "paper" | "ink" | "orange";
// title (above), label (mono, above the title), caption (mono, under the code),
// logo, dots, size (canvas px), qr (a path replaces the brand's code).
#let social-qr(
  variant: "paper", title: none, label: none, caption: "chanwe.ar",
  logo: true, dots: true, size: 520, qr: none, ..rest,
) = {
  let files = (paper: "contact-qr-papel.svg", ink: "contact-qr-obsidiana.svg", orange: "contact-qr-naranja.svg")
  if variant not in files { panic("qr: variant is paper, ink or orange.") }
  let s = if variant == "orange" { _social-v2-surface("orange", none) } else { _social-v2-surface("icon", variant) }
  page(fill: s.bg, numbering: none, context {
    let hp = page.height / _su
    let safe = if page.height > 30cm { 170 } else { 0 }
    let k = calc.min(1, hp / 1500)
    if dots and variant != "orange" { _social-dots-fade(s.bg, if variant == "paper" { 34% } else { 46% }) }
    place(center + horizon, stack(spacing: 44 * k * _su,
      if label != none { align(center, _social-mono(22, s.label, label)) },
      if title != none { block(width: _social-w, align(center, _social-display(84 * k, s.fg, title, weight: _t.weight-medium))) },
      align(center, image(if qr != none and qr != "contact" { qr } else { _social-v2 + files.at(variant) }, width: size * k * _su)),
      if caption != none { align(center, _social-mono(24, s.label, caption)) }))
    if logo {
      place(bottom + center, dy: -(110 * k + safe) * _su, image(_social-assets + s.logo, width: 230 * calc.max(k, 0.7) * _su))
    }
  })
}

// ── social-post — a post from data ───────────────────────────────
// `data` is a dictionary: one plate (`plate: kpi`, plus its fields), or a
// carousel (`plates:` a list of them, with fields shared at the top). Keys
// match each plate's arguments. scripts/render-social.rb passes a YAML file.
#let _social-plates = (
  cover: social-cover, editorial-cover: social-editorial-cover,
  point: social-point, quote: social-quote, stat: social-stat,
  idea: social-idea, checklist: social-checklist, cycle: social-cycle, contact: social-contact,
  kpi: social-kpi, table: social-table, news: social-news, event: social-event, chart: social-chart,
  theme: social-theme, series: social-series, qr: social-qr,
)
#let social-post(data) = {
  let shared = data
  let plates = if "plates" in data { shared.remove("plates") } else { (data,) }
  if "plates" in data { } else { shared = (:) }
  for (i, entry) in plates.enumerate() {
    let args = shared + entry
    if "plate" not in args { panic("A plate needs `plate:` (" + _social-plates.keys().join(", ") + ").") }
    let kind = args.remove("plate")
    if kind not in _social-plates { panic("Unknown plate «" + kind + "». Use: " + _social-plates.keys().join(", ") + ".") }
    if plates.len() > 1 and "index" not in args {
      let two(n) = if n < 10 { "0" + str(n) } else { str(n) }
      args.insert("index", two(i + 1) + " / " + two(plates.len()))
    }
    (_social-plates.at(kind))(..args)
  }
}
