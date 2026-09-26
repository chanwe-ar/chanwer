// =================================================================
// typst-template-propuesta.typ
// Chanwe one-page commercial proposal
// =================================================================

#let _p-assets = "$chanwe-assets$".replace("\\_", "_")

// ── Tokens ────────────────────────────────────────────────────────────
// Espejo de _extensions/chanwe-brand/brand.yml, nombre por nombre, el mismo
// contrato que el reporte y el memo: Typst no lee YAML, brand.yml manda y
// estos valores se mantienen alineados a mano (scripts/check-typst-tokens.rb
// lo verifica). Ningún trazo escribe un color, `white`, `black` ni un peso
// numérico: todo lee `_t.<token>`, `_t.weight-<rol>` y `_t.font-*`.
#let _t = (
  primary:     rgb("#FD3810"),
  ink:         rgb("#111319"),
  body-fg:     rgb("#475569"),
  fg-muted:    rgb("#475569"),
  fg-subtle:   rgb("#8A94A6"),
  paper:       rgb("#F8FAFC"),
  // El panel de asunto es el panel `light` del reporte y del memo.
  surface-slate:  rgb("#EBF0F6"),
  white:       rgb("#FFFFFF"),
  rule:        rgb("#E2E8F0"),
  rule-cool:   rgb("#C6CDD6"),
  border-cool: rgb("#CFD6DF"),
  border:      rgb("#1113191A"),
  weight-thin:      200,
  weight-body:      300,
  weight-regular:   400,
  weight-medium:    500,
  weight-display:   600,
  weight-bold:      700,
  font-display: ("Schibsted Grotesk", "Helvetica Neue", "Arial"),
  font-sans:    ("Inter", "Helvetica Neue", "Arial"),
  font-mono:    ("JetBrains Mono", "Menlo", "Courier New"),
  font-serif:   ("Cormorant Garamond", "Georgia", "Times New Roman"),
)

// El writer typst de Pandoc escapa caracteres de markup dentro de los valores
// YAML (@ → \@, _ → \_, # → \#, / → \/) y escribe `--` / `---` para las rayas.
// Todo lo que este formato recibe llega como string y va a parar a un argumento
// de `text()`, donde el markup ya no liga: hay que limpiarlo a mano.
// Mismo helper que `_m-clean()` en chanwe-memo.
#let _p-clean(s) = if s == none { none } else if type(s) == str {
  s.replace("\\@", "@").replace("\\_", "_").replace("\\-", "-").replace("\\#", "#").replace("\\/", "/")
   .replace("---", "—").replace("--", "–")
} else { s }

// El QR de contacto enmarcado, compartido con el reporte y el memo.
$chanwe-qr.typ()$

#let chanwe-propuesta(
  // Renglón del encabezado: la voz de la práctica, no un código.
  doc-id:        "Estrategia, codo a codo",
  date:          "",
  eyebrow:       "Propuesta Comercial",
  title:         "Propuesta",
  title-em:      "Comercial.",
  edge:          none,
  to:            "",
  proyecto:      "",
  proyecto-desc: "",
  lede:          none,
  scope:         (),
  fees:          (),
  terms:         (),
  sigs:          (),
  // Pie: sede y fecha — "MENDOZA // ARGENTINA - 01 JUL 2026".
  location:      "Mendoza // Argentina",
  // QR de contacto, al lado de las firmas. `qr` cambia el asset; el default
  // es el `contact-qr.svg` de assets/, que lleva a https://chanwe.com.ar.
  qr:            none,
  show-qr:       true,
  page-bg:       _t.paper,
  wordmark:      none,
  lang:          "es",
  ..rest,
) = {

  let panel-lede = lede

  let wm = if wordmark != none { _p-clean(wordmark) } else { _p-assets + "Logo_Negro.svg" }
  let qr-src = if qr != none { _p-clean(qr) } else { _p-assets + "contact-qr.svg" }

  // ─── Page ─────────────────────────────────────────────────────
  set page(
    paper:  "a4",
    margin: (x: 18mm, top: 14mm, bottom: 14mm),
    fill:   page-bg,
    header: block(height: 100%, width: 100%)[
      #grid(
        rows: (1fr, auto),
        align(horizon, grid(
          columns: (1fr, auto),
          align: (left + horizon, right + horizon),
          {
            set text(font: _t.font-mono, size: 6pt, tracking: 0.14em)
            text(weight: _t.weight-bold, fill: _t.primary, "//")
            h(5pt)
            text(fill: _t.fg-subtle, upper(_p-clean(doc-id)))
          },
          image(wm, height: 3.5mm, fit: "contain"),
        )),
        pad(x: -18mm, line(length: 100% + 36mm, stroke: 0.5pt + _t.border)),
      )
    ],
    // El pie es el del reporte, punto por punto: filete arriba a sangre, el
    // renglón de servicio en mono al mismo tono que el encabezado, y el folio
    // real a la derecha. A la izquierda la sede y la fecha, como el doc-id y
    // la edición en el reporte. El ícono de la práctica se fue.
    footer: context block(height: 100%, width: 100%)[
      #grid(
        rows: (auto, 1fr),
        pad(x: -18mm, line(length: 100% + 36mm, stroke: 0.5pt + _t.border)),
        align(horizon, {
          set text(font: _t.font-mono, size: 6pt, tracking: 0.14em, fill: _t.fg-subtle)
          grid(
            columns: (1fr, auto),
            align: (left + horizon, right + horizon),
            // El separador va como string: en markup un renglón que arranca con
            // "- " es una lista y la fecha saltaba a una viñeta.
            [#upper[#_p-clean(location)#if date != "" [#" - "#_p-clean(date)]]],
            [#text(size: 6.9pt, upper(str(counter(page).get().first()) + " / " + str(counter(page).final().first())))],
          )
        }),
      )
    ],
  )
  set text(font: _t.font-sans, size: 10.5pt, weight: _t.weight-body, fill: _t.body-fg, lang: lang)
  set par(leading: 0.5em, spacing: 0pt)

  place(center + bottom, dy: -7mm,
    image(_p-assets + "Logo_Papel.svg", width: 100%, fit: "contain")
  )

  // ─── Edge label ───────────────────────────────────────────────
  if edge != none {
    place(right + top, dx: 13mm, dy: 36mm,
      rotate(-90deg, origin: right + horizon,
        text(font: _t.font-mono, size: 7.5pt, weight: _t.weight-medium, tracking: 0.4em, fill: _t.fg-subtle, upper(_p-clean(edge)))
      )
    )
  }

  v(8mm)

  // ─── HERO ─────────────────────────────────────────────────────
  // El titular a la izquierda y el QR enmarcado arriba a la derecha,
  // apoyados en la misma línea de base: la relación de la contratapa del
  // reporte, subida al hero. Antes vivía junto a las firmas.
  grid(
    columns: (1fr,) + if show-qr { (auto,) } else { () },
    column-gutter: 8mm,
    align: (left + bottom, right + bottom),
    {
      // Eyebrow with orange rule prefix
      grid(
        columns: (8mm, auto),
        column-gutter: 4mm,
        align: (center + horizon, left + horizon),
        rect(width: 100%, height: 0.75pt, fill: _t.primary, stroke: none),
        text(font: _t.font-mono, size: 8.5pt, weight: _t.weight-medium, tracking: 0.28em, fill: _t.primary, upper(_p-clean(eyebrow))),
      )
      v(5.5mm)

      // H1 — display + italic serif
      {
        set par(leading: 0.72em, spacing: 0pt)
        [#text(font: _t.font-display, size: 51.2pt, weight: _t.weight-display, tracking: -0.05em, fill: _t.ink, _p-clean(title))#linebreak()#text(font: _t.font-display, size: 51.2pt, weight: _t.weight-display, tracking: -0.05em, fill: _t.ink, _p-clean(title-em).slice(0, -1))#box(width: 12pt, height: 12pt, baseline: 2pt, circle(fill: _t.primary, stroke: none))]
      }
    },
    ..if show-qr {
      (chanwe-qr-frame(qr-src, size: 20.5mm, edge: _t.ink.transparentize(84%),
                       card: _t.white, pad-outer: 2.6mm, pad-inner: 1mm),)
    } else { () },
  )
  v(11mm)

  // Subject grid + optional lede — wrapped in compact callout
  line(length: 100%, stroke: 0.5pt + _t.border-cool)
  v(5mm)
  block(
    width: 100%,
    fill: _t.surface-slate,
    inset: (x: 5mm, y: 5mm),
  )[
    #grid(
      columns: (20mm, 1fr),
      row-gutter: 3.5mm,
      column-gutter: 7mm,
      align: (left + top, left + top),
      pad(top: 5pt,
        text(font: _t.font-mono, size: 7.4pt, weight: _t.weight-medium, tracking: 0.26em, fill: _t.fg-subtle, upper("Para"))
      ),
      text(font: _t.font-display, size: 16.8pt, weight: _t.weight-display, tracking: -0.05em, fill: _t.ink, _p-clean(to)),
      pad(top: 3pt,
        text(font: _t.font-mono, size: 7.4pt, weight: _t.weight-medium, tracking: 0.26em, fill: _t.fg-subtle, upper("Proyecto"))
      ),
      {
        set par(leading: 0.5em, spacing: 0pt)
        text(font: _t.font-serif, size: 18.6pt, weight: _t.weight-body, style: "italic", tracking: -0.025em, fill: _t.primary, _p-clean(proyecto))
        v(2.8mm)
        text(font: _t.font-sans, size: 8.7pt, weight: _t.weight-regular, fill: _t.fg-muted, _p-clean(proyecto-desc))
        v(2mm)
      },
    )
    #if panel-lede != [] and panel-lede != none {
      v(4mm)
      line(length: 100%, stroke: 0.5pt + _t.rule)
      v(3mm)
      set text(font: _t.font-sans, size: 9pt, weight: _t.weight-regular, fill: _t.fg-muted)
      set par(leading: 0.34em, spacing: 0.6em)
      panel-lede
    }
    #if terms.len() > 0 {
      v(4mm)
      line(length: 100%, stroke: 0.5pt + _t.rule)
      v(3mm)
      set text(font: _t.font-mono, size: 6.2pt, weight: _t.weight-thin, tracking: 0.1em)
      stack(dir: ltr, spacing: 8mm,
        ..terms.map(t =>
          [#text(fill: _t.ink, upper(_p-clean(t.label)))#h(3pt)·#h(3pt)#text(fill: _t.fg-muted, _p-clean(t.value))]
        )
      )
    }
  ]

  v(8mm)

  // ─── SCOPE ────────────────────────────────────────────────────
  if scope.len() > 0 {
    grid(
      columns: (22mm, 1fr),
      align: (left + top, left + top),
      pad(top: 15pt,
        text(font: _t.font-mono, size: 6.8pt, weight: _t.weight-medium, tracking: 0.28em, fill: _t.fg-subtle, upper("Alcance"))
      ),
      {
        line(length: 100%, stroke: 0.5pt + _t.rule)
        for item in scope {
          let is-optional = item.at("optional", default: false)
          let number-fill = if is-optional { _t.fg-subtle } else { _t.primary }
          grid(
            columns: (10mm, 1fr),
            column-gutter: 6mm,
            align: (right + horizon, left + top),
            pad(top: 8pt, bottom: 8pt,
              stack(dir: ttb, spacing: 0.8mm,
                text(font: _t.font-serif, size: 15pt, weight: _t.weight-body, style: "italic", fill: number-fill, _p-clean(item.n)),
                ..if is-optional { (
                  text(font: _t.font-serif, size: 5.4pt, weight: _t.weight-body, style: "italic", fill: number-fill, "(next)"),
                ) } else { () },
              )
            ),
            pad(top: 15pt, bottom: 15pt,
              {
                set par(spacing: 1.5mm, leading: 0.5em)
                text(font: _t.font-display, size: 8.8pt, weight: _t.weight-display, tracking: -0.05em, fill: _t.ink, _p-clean(item.title))
                linebreak()
                text(font: _t.font-sans, size: 7.6pt, weight: _t.weight-regular, fill: _t.fg-muted, _p-clean(item.desc))
              }
            ),
          )
          line(length: 100%, stroke: 0.5pt + _t.rule)
        }
      }
    )
  }

  v(8mm)

  // ─── FEES ─────────────────────────────────────────────────────
  if fees.len() > 0 {
    grid(
      columns: fees.map(_ => 1fr),
      column-gutter: 12mm,
      ..fees.map(fee => {
        let hl  = fee.at("highlight", default: false)
        let per = fee.at("per", default: none)
        let cur = fee.at("currency", default: "USD")
        let desc = fee.at("desc", default: none)
        // Marco y filetes en slate (`border-cool`) también en la fase destacada:
        // el chip naranja ya la señala; una caja negra pesaba de más.
        block(above: 0pt, width: 100%, fill: none, stroke: 0.5pt + _t.border-cool, inset: (x: 5mm, y: 2.1mm))[
          #grid(
            columns: (auto, 1fr),
            column-gutter: 3mm,
            align: (left + horizon, left + bottom),
            box(inset: (x: 2.5mm, y: 1.3mm),
              fill: if hl { _t.primary } else { _t.rule-cool },
              text(font: _t.font-mono, size: 5.2pt, weight: _t.weight-medium, tracking: 0.18em,
                fill: if hl { _t.white } else { _t.ink },
                upper(_p-clean(fee.kind)))
            ),
            stack(dir: ttb, spacing: 3.25pt,
              text(font: _t.font-mono, size: 5.2pt, weight: _t.weight-medium, tracking: 0.28em, fill: _t.fg-subtle, upper(_p-clean(fee.label))),
              line(length: 100%, stroke: 0.5pt + _t.border-cool),
            ),
          )
          #v(1.7mm)
          // La glosa va en una segunda fila de la misma grilla, a partir de la
          // columna del importe: queda alineada con el número, no con "USD".
          // Misma voz que el rótulo a la derecha del chip: slate claro.
          #let ncols = 2 + if per != none { 1 } else { 0 }
          #grid(
            columns: (auto, auto) + if per != none { (auto,) } else { () },
            column-gutter: 2.5mm,
            row-gutter: 1.5mm,
            align: (top, top) + if per != none { (top,) } else { () },
            text(font: _t.font-mono, size: 4.9pt, weight: _t.weight-medium, tracking: 0.18em, fill: _t.fg-subtle, _p-clean(cur)),
            // A 600 como toda la Schibsted: el 300 que pedía antes no existe en la
            // familia y salía en 400.
            pad(top: 0.9mm, text(font: _t.font-display, size: 20.8pt, weight: _t.weight-display, tracking: -0.05em, fill: _t.ink, _p-clean(fee.amount))),
            ..if per != none { (
              pad(top: 0.9mm, text(font: _t.font-serif, size: 6.8pt, weight: _t.weight-body, style: "italic", fill: _t.fg-muted, _p-clean(per))),
            ) } else { () },
            ..if desc != none and desc != "" { (
              [],
              grid.cell(colspan: ncols - 1,
                text(font: _t.font-sans, size: 6.3pt, weight: _t.weight-regular, fill: _t.fg-subtle, _p-clean(desc))),
            ) } else { () },
          )
        ]
      })
    )
  }


  v(1fr)

  // ─── SIGNATURES ───────────────────────────────────────────────
  // A todo el ancho: el QR se mudó al hero.
  if sigs.len() > 0 {
    block(width: 100%)[
      #grid(
        columns: sigs.map(_ => 1fr),
        column-gutter: 12mm,
        ..sigs.map(sig => block(above: 0pt)[
          #line(length: 100%, stroke: 0.5pt + _t.border-cool)
          #v(3.5mm)
          #text(font: _t.font-display, size: 12pt, weight: _t.weight-display, tracking: -0.05em, fill: _t.ink, _p-clean(sig.name))
          #linebreak()
          #v(2mm)
          #text(font: _t.font-serif, size: 11.5pt, weight: _t.weight-body, style: "italic", fill: _t.primary, _p-clean(sig.company))
          #v(2.5mm)
          #text(font: _t.font-mono, size: 6pt, weight: _t.weight-body, tracking: 0.18em, fill: _t.fg-subtle, upper(_p-clean(sig.role)))
        ])
      )
    ]
  }

  v(8mm)

}
