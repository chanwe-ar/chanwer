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
// and between them one of seven bodies: cover, point, quote (obsidian),
// stat, idea (orange), checklist, contact (obsidian).
//
// Geometry is measured on a 1080 px wide canvas, so every length is
// `n * _su` (one canvas pixel of the 21 cm page). The height is the
// format's: 1080 (LinkedIn, Instagram square), 1350 (Instagram post) or
// 1920 (story); the bodies stretch with `v(1fr)` instead of assuming one.
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

#let _social-arrow(color) = box(width: 40 * _su, height: 16 * _su, {
  let s = (paint: color, thickness: 1.75 * _su, cap: "square")
  place(top + left, line(start: (1 * _su, 8 * _su), end: (37 * _su, 8 * _su), stroke: s))
  place(top + left, line(start: (30 * _su, 1 * _su), end: (37 * _su, 8 * _su), stroke: s))
  place(top + left, line(start: (37 * _su, 8 * _su), end: (30 * _su, 15 * _su), stroke: s))
})

// ── chrome ──────────────────────────────────────────────────────
#let _social-masthead(th, pill, subject, index) = {
  place(top + left, dx: _social-m, dy: 50 * _su, box(width: _social-w, height: 52 * _su,
    grid(
      columns: (auto, 1fr, auto),
      align: (left + horizon, left + horizon, right + horizon),
      box(fill: th.pill-fill, stroke: th.pill-stroke, radius: 3 * _su,
        inset: (x: 16 * _su, y: 15 * _su), _social-mono(20, th.pill-fg, pill)),
      [],
      stack(dir: ltr, spacing: 28 * _su,
        if subject != none { _social-mono(20, th.subject, subject) },
        if index != none { _social-mono(20, th.index, index) },
      ),
    )))
  place(top + left, dx: _social-m, dy: _social-head * _su,
    line(length: _social-w, stroke: 1.5 * _su + th.hair))
}

#let _social-footband(th, series, cue) = {
  place(bottom + left, dx: _social-m, dy: -_social-foot-h * _su,
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
  place(bottom + left, dx: _social-m, dy: -34 * _su, box(width: _social-w, height: 52 * _su,
    grid(
      columns: (auto, 1fr, auto),
      align: (left + horizon, left + horizon, right + horizon),
      if series != none {
        box(fill: th.series-fill, radius: 3 * _su, inset: (x: 16 * _su, y: 15 * _su),
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

// The cover art: the mountains, veiled into the paper from the left and at
// both ends so the title reads over it.
#let _social-art(path) = {
  let h = 100% - (_social-head + _social-foot-h) * _su
  place(top + left, dy: _social-head * _su, box(width: 100%, height: h, clip: true, {
    // Cover the box, cropped 10% in from the left: the craggy face of
    // bg_mountains sits there (the deck's hero-img-position, 10).
    layout(size => {
      let natural = measure(image(path))
      let ratio = natural.width / natural.height
      let w = calc.max(size.width / 1pt, size.height / 1pt * ratio) * 1pt
      let hh = w / ratio
      place(top + left, dx: -(w - size.width) * 0.1, dy: -(hh - size.height) * 0.4,
        image(path, width: w, height: hh))
    })
    place(top + left, rect(width: 100%, height: 100%, stroke: none, fill: _t.paper.transparentize(45%)))
    place(top + left, rect(width: 100%, height: 100%, stroke: none, fill: gradient.linear(
      (_t.paper, 0%), (_t.paper.transparentize(8%), 38%), (_t.paper.transparentize(65%), 100%))))
    place(top + left, rect(width: 100%, height: 100%, stroke: none, fill: gradient.linear(angle: 90deg,
      (_t.paper, 0%), (_t.paper.transparentize(100%), 30%),
      (_t.paper.transparentize(100%), 70%), (_t.paper, 100%))))
  }))
}

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
  art:     none,
  dots:    none,
  content-top: 128,
  body,
) = {
  let th = _social-theme(theme)
  page(fill: th.bg, numbering: none, {
    if art != none { _social-art(art) }
    if dots == "side" {
      place(top + right, dx: 40 * _su, dy: _social-head * _su,
        _social-dots(560 * _su, 100% - 240 * _su, 55%))
    } else if dots == "full" {
      place(top + left, dy: _social-head * _su,
        _social-dots(100%, 100% - 240 * _su, 42%))
    }
    _social-masthead(th, pill, subject, index)
    _social-footband(th, series, cue)
    place(top + left, dx: _social-m, dy: content-top * _su,
      block(width: _social-w, height: 100% - (content-top + _social-foot-h + 32) * _su, {
        set text(fill: th.title)
        body
      }))
  })
}

// ── the seven bodies ────────────────────────────────────────────

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

// cover — veiled art, the title datum (orange rule, title with its orange
// run, serif-italic lede) and a ledger of up to four facts.
#let social-cover(
  title:   [Título del carrusel],
  accent:  [en dos líneas.],
  lede:    none,
  ledger:  (("Autor", "Chanwe"), ("Tema", "Estrategia")),
  index:   none,
  pill:    "Chanwe // Carrusel",
  subject: "Estrategia",
  series:  "Chanwe / Estrategia",
  cue:     "swipe",
  art:     _social-assets + "bg_mountains.jpg",
  size:    88,
) = social-page(pill: pill, subject: subject, index: index, series: series, cue: cue, art: art, {
  let th = _social-theme("paper")
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
})

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
    block(width: 100%, fill: _t.surface-sunken, radius: 4 * _su, inset: (x: 32 * _su, y: 30 * _su),
      grid(columns: (220 * _su, 1fr), column-gutter: 28 * _su, align: (left + top, left + top),
        pad(top: 8 * _su, _social-mono(18, _t.body-fg, if aside-label != none { aside-label } else { "Nota" }, tracking: 0.18em)),
        _social-body(30, _t.fg, aside, weight: _t.weight-regular)))
  }
})

// quote — a statement on obsidian with the dot field at the side.
#let social-quote(
  statement: [La estrategia también aparece en los no.],
  source:  none,
  index:   none,
  pill:    "Chanwe // Lectura",
  subject: "Estrategia",
  series:  "Chanwe / Estrategia",
  cue:     "logo",
) = social-page(theme: "ink", dots: "side", pill: pill, subject: subject, index: index, series: series, cue: cue, {
  v(1fr)
  block(width: 900 * _su, {
    text(font: _t.font-serif-display, size: 260 * _su, weight: _t.weight-regular, fill: _t.primary,
      top-edge: "bounds", bottom-edge: "bounds", "“")
    v(40 * _su)
    _social-display(70, _t.rule-cool, statement, weight: _t.weight-display, leading: 0.32em)
    if source != none {
      v(36 * _su)
      grid(columns: (44 * _su, auto), column-gutter: 18 * _su, align: (left + horizon, left + horizon),
        rect(width: 100%, height: 2 * _su, fill: _t.primary, stroke: none),
        _social-mono(20, _t.ink-fg, source))
    }
  })
  v(1fr)
})

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
  block(width: 100%, fill: _t.surface-slate, radius: 4 * _su,
    inset: (x: 48 * _su, top: 44 * _su, bottom: 40 * _su), {
      set par(leading: 0pt, spacing: 0pt)
      text(font: _t.font-display, weight: _t.weight-bold, fill: _t.fg, size: 280 * _su,
        tracking: -0.05em, top-edge: "cap-height", bottom-edge: "descender", value)
      h(8 * _su)
      text(font: _t.font-display, weight: _t.weight-bold, fill: _t.primary, size: 140 * _su,
        top-edge: "cap-height", bottom-edge: "baseline", unit)
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
  _social-display(84, _t.rule-cool, [#headline#text(fill: _t.primary, ".")], tracking: -0.035em, leading: 0.26em)
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
