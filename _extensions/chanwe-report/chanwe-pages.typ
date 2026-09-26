// =============================================================
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
// es el ultimo de su capitulo. Por eso el ultimo de todos lo pone
// `chanwe-agenda` a mano, despues del `outline`.
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
// nadie lo escribe en el YAML. Va sobre obsidiana: el rótulo en `ink-subtle`
// (#646464, el gris hundido sobre tinta) y el número en `rule-cool`, que es
// la regla para texto sobre tinta.
#let _chanwe-agenda-counts() = context {
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
           fill: _t.ink-subtle, upper(label)),
      text(font: _t.font-mono, size: 8.05pt, weight: _t.weight-body, tracking: 0.18em,
           fill: _t.rule-cool, _pad2(n)),
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
  stroke: (left: 1pt + _t.primary),
  inset: (left: 7mm, top: 3mm, bottom: 3mm),
)[
  #set par(spacing: 0pt, leading: 0pt)
  #grid(
    columns: (12mm, auto, 1fr, auto),
    column-gutter: 3mm,
    align: (left + horizon, left + horizon, center + horizon, right + horizon),
    text(font: _t.font-mono, size: 7.5pt, tracking: 0.1em, weight: _t.weight-regular, fill: _t.primary, num),
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
        font: _t.font-serif, style: "italic", weight: _t.weight-body,
        size: 28pt, tracking: -0.025em, fill: _t.primary,
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

#let chanwe-agenda(
  eyebrow: "Document map",
  title: "Agenda",
  lede: none,
  groups: none,
  parts: none,
) = {
  // El encabezado del índice repite la losa del H1: obsidiana de orilla a
  // orilla, pegada al filete del encabezado y con la misma trama de puntos.
  v(-4.5mm)
  context move(dx: -18mm, block(
    width: page.width,
    fill: _t.ink,
    inset: (left: 18mm, right: 18mm, top: 14mm, bottom: 16mm),
    clip: true,
  )[
    #place(top + left, dx: -18mm, dy: -14mm,
      _chanwe-dot-field(width: page.width, height: 140mm, ramp: (88%, 58%)))
    #chanwe-section-eyebrow(eyebrow)
    #v(7.5mm)
    // El titular a la izquierda y el recuento del documento a la derecha,
    // alineados por la base: la losa cuenta de qué está hecho el documento
    // sin que haya que escribirlo a mano.
    #grid(
      columns: (1fr, auto),
      align: (left + bottom, right + bottom),
      block(spacing: 0pt)[
        #text(
          font: _t.font-display, size: 72.8pt, weight: _t.weight-display,
          tracking: -0.05em, fill: _t.rule-cool, title,
        )
        #box(width: 13pt, height: 13pt, baseline: 0pt,
          circle(fill: _t.primary, stroke: none))
      ],
      block(spacing: 0pt, _chanwe-agenda-counts()),
    )
  ])
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
        text(font: _t.font-serif-display, style: "italic", weight: _t.weight-body, size: 24pt, fill: _t.primary, num),
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
                text(font: _t.font-serif-display, style: "italic", weight: _t.weight-body,
                     size: 42pt, fill: _t.primary, cur-part.number),
                {
                  // Misma familia y tracking que el H1 del índice, un paso más
                  // liviano (700 -> 600) y con más cuerpo: la sección pesa por
                  // tamaño, no por trazo. El numeral sigue en la serif
                  // itálica, que es lo que separa sección de capítulo.
                  text(font: _t.font-display, weight: _t.weight-display,
                       size: _toc-section-size, tracking: -0.05em,
                       fill: _t.fg, cur-part.title)
                  text(font: _t.font-display, weight: _t.weight-display,
                       size: _toc-section-size, tracking: -0.05em,
                       fill: _t.primary, ".")
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
                text(font: _t.font-serif-display, style: "italic", weight: _t.weight-body,
                     size: 22pt, fill: _t.primary, _pad2(n))
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
          // Sin filete por renglón: el riel naranja del subrenglón ya agrupa.
          // El aire va solo antes del primero, para que el riel salga entero.
          if n == 1 and numbered { v(3mm) }
          if n == 0 { v(3mm) }
          chanwe-toc-subrow(
            num: if numbered { str(h1n) + "." + str(n) }
                 else { box(width: 7mm, height: 0.75pt, fill: _t.primary, baseline: -2pt) },
            label: it.element.body,
            page: _pad2(pg),
          )
        }
      }
    }
    outline(title: none, depth: 2)
    // El cierre del ultimo capitulo. Adentro del `outline` no hay forma de
    // saber cual es, asi que se emite aca, ya fuera de el. Misma regla que
    // adentro: solo si el capitulo no tuvo subniveles.
    context {
      let h1s = query(heading.where(level: 1))
      if h1s.len() > 0 {
        let last-loc = h1s.last().location()
        let had-sub = query(heading.where(level: 2).after(last-loc, inclusive: false)).len() > 0
        if not had-sub {
          v(7mm)
          _toc-chapter-rule
        }
      }
    }
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
//       p.lead   (Cormorant Garamond 12pt body, ::first-letter 56pt drop-cap)
//       p · p · ... (Cormorant Garamond 12pt body)
// =============================================================
// El rotulo va un paso mas claro que el valor (`fg-subtle`, el tono de toda
// la metadata) y el valor entra en el mismo chip contorneado que la portada
// usa para el taggy: filete de 0.5pt, radio 2pt, mono en versalitas. Es un
// `block` y no un `box` a proposito: asi un valor largo parte de linea dentro
// del chip en vez de desbordar el riel de 60mm.
#let chanwe-side-row(label: "", value: "", dark: false, accent: _t.primary) = {
  // Sobre la hoja: rótulo y texto del chip en el mismo fg-subtle, el marco
  // del chip en border-cool.
  let lc = if dark { _t.white.transparentize(62%) } else { _t.fg-subtle }
  let vc = if dark { _t.white                     } else { _t.fg-subtle }
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
  let pill(t) = block(width: 100%, stroke: 0.5pt + pc, radius: 2pt,
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
    // El tercer campo de la tupla es un subtitulo opcional. Solo se concatena
    // si el valor es texto: los keywords llegan como lista y pasan enteros.
    meta.map(((lbl, val, ..rest)) => (
      label: lbl,
      value: if type(val) == str and rest.len() > 0 and rest.at(0) != none {
        val + "\n" + rest.at(0)
      } else { val },
    ))
  } else { side-rows }

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
  chanwe-eyebrow(resolved-eyebrow, with-rule: true, color: accent)
  v(7.5mm)
  block[
    #text(
      font: _t.font-display, size: 56pt, weight: _t.weight-display,
      tracking: -0.05em, fill: title-color, resolved-title,
    )
    #box(width: 10pt, height: 10pt, baseline: 0pt,
      circle(fill: accent, stroke: none))
  ]
  v(13mm)
  // Mismo truco de sangrado que el encabezado: el margen lateral es 18mm, asi
  // que el filete se corre -18mm y mide 100% + 36mm para llegar a los bordes.
  block(spacing: 0pt,
    pad(x: -18mm, line(length: 100% + 36mm, stroke: 0.5pt + under-rule)))
  v(14mm)

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
          ..resolved-rows.map(r => chanwe-side-row(..r, dark: dark, accent: accent))
        )
      ],
      // body block
      block[
        #set par(leading: 0.65em, justify: true)
        #set text(font: _t.font-sans, size: 10pt, weight: _t.weight-regular, fill: body-color)
        #show emph: it => if dark { text(font: _t.font-serif, style: "italic", weight: _t.weight-body, size: 1.414em, fill: body-color, it.body) } else { it }
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
        #text(font: _t.font-display, size: 28pt, weight: _t.weight-display,
              tracking: -0.05em, fill: _t.fg, abstract-heading)
      ]

      // Lead paragraph with manual drop-cap
      #if lead != none {
        let first = lead.at(0)
        let rest  = lead.slice(1)
        block(below: 4mm)[
          #place(top + left, dx: 0pt, dy: 8pt)[
            #text(
              font: _t.font-serif, size: 56pt, weight: _t.weight-body,
              fill: _t.fg, first,
            )
          ]
          #pad(left: 24mm)[
            #set par(leading: 0.62em, justify: true, first-line-indent: 0pt)
            #set text(font: _t.font-serif, size: 12pt, weight: _t.weight-body, fill: _t.fg)
            #text(weight: _t.weight-body, fill: _t.fg,
                  rest.slice(0, calc.min(rest.len(), 60)))
            #rest.slice(calc.min(rest.len(), 60))
          ]
        ]
      }

      // remaining paragraphs (no drop cap)
      #set par(leading: 0.62em, justify: true)
      #set text(font: _t.font-serif, size: 12pt, weight: _t.weight-body, fill: _t.fg)
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
  // Sin color, la página va sobre surface-slate, como la del abstract, que
  // es la misma página con otro nombre.
  let bg = if color == "light" or color == "slate" or color == "beige" { _t.surface-slate }
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
  let bg = if color == "light" or color == "slate" or color == "beige" { _t.surface-slate }
      else if color == "dark"   { _t.ink         }
      else if color == "primary" { _t.primary    }
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
  let lc          = if dark { _t.white.transparentize(45%) } else { _t.fg-subtle }
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
    radius: 1pt,
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
    #chanwe-eyebrow(eyebrow, with-rule: true, color: accent)
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
        #show emph: it => if dark { text(font: _t.font-serif, style: "italic", weight: _t.weight-body, size: 1.414em, fill: body-color, it.body) } else { it }
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

  // Mismo papel que una pagina de cuerpo (`page-bg`, que es `callout-surface`):
  // la portadilla se separa por su composicion, no por un tono distinto. El
  // halo radial cierra contra ese mismo color, asi que se mueven juntos.
  set page(
    paper: _chanwe-paper, margin: 0pt, fill: _t.callout-surface,
    header: none, footer: none,
    background: place(top + left, dx: -50mm, dy: -50mm,
      circle(radius: 145mm,
        fill: gradient.radial(
          _t.ink-fg.transparentize(90%),
          _t.callout-surface.transparentize(100%),
        ),
        stroke: none,
      )
    ),
  )
  set text(fill: _t.fg)

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
    // ---- TOP: la marca a la izquierda ----
    #block(width: 100%)[
      // Mismo tono que el encabezado y el pie del cuerpo.
      #set text(font: _t.font-mono, size: 7pt, tracking: 0.22em,
                fill: _t.fg-subtle)
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
                 fill: _t.fg-subtle, upper(_chanwe-clean-str(_right)))))))
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
      text(
        font: _t.font-serif, style: "italic", weight: _t.weight-body,
        size: 220pt, tracking: -0.05em,
        fill: _t.primary,
        number,
      ),
      stack(
        dir: ttb, spacing: 9mm,
        // Misma familia y prosa que el H1: display, peso 700 y su tracking.
        // El numeral gigante se queda en la serif itálica.
        text(
          font: _t.font-display, weight: _t.weight-display,
          size: 51.75pt, tracking: -0.05em, fill: _t.fg,
          title,
        ),
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
                 fill: _t.fg-subtle)
        upper(_chanwe-clean-str(doc.doc-id))
        if doc.edition != "" {
          h(14mm)
          upper(_chanwe-clean-str(doc.edition))
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
}
