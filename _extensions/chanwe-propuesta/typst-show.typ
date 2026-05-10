// =================================================================
// typst-show-propuesta.typ — Quarto metadata → chanwe-propuesta()
// =================================================================

#show: doc => chanwe-propuesta(
  doc-id:        "$if(propuesta.doc-id)$$propuesta.doc-id$$else$CHW · DOC$endif$",
  date:          "$if(propuesta.date)$$propuesta.date$$else$$date$$endif$",
  eyebrow:       "$if(propuesta.eyebrow)$$propuesta.eyebrow$$else$Propuesta Comercial$endif$",
  title:         "$if(propuesta.title)$$propuesta.title$$else$Propuesta$endif$",
  title-em:      "$if(propuesta.title-em)$$propuesta.title-em$$else$Comercial.$endif$",
$if(propuesta.edge)$
  edge:          "$propuesta.edge$",
$endif$
  to:            "$if(propuesta.to)$$propuesta.to$$endif$",
  proyecto:      "$if(propuesta.proyecto)$$propuesta.proyecto$$endif$",
  proyecto-desc: "$if(propuesta.proyecto-desc)$$propuesta.proyecto-desc$$endif$",
$if(propuesta.wordmark)$
  wordmark:      "$propuesta.wordmark$",
$endif$
$if(propuesta.page-bg)$
  page-bg:       rgb("$propuesta.page-bg$"),
$endif$
  scope: (
$for(propuesta.scope)$
    (n: "$it.n$", title: "$it.title$", desc: "$it.desc$"),
$endfor$
  ),
  fees: (
$for(propuesta.fees)$
    (kind: "$it.kind$", label: "$it.label$", currency: "$it.currency$", amount: "$it.amount$", desc: "$it.desc$"$if(it.per)$, per: "$it.per$"$endif$$if(it.highlight)$, highlight: true$endif$),
$endfor$
  ),
  terms: (
$for(propuesta.terms)$
    (label: "$it.label$", value: "$it.value$"),
$endfor$
  ),
  sigs: (
$for(propuesta.sigs)$
    (name: "$it.name$", company: "$it.company$", role: "$it.role$"),
$endfor$
  ),
  footer-client: "$if(propuesta.footer-client)$$propuesta.footer-client$$endif$",
  footer-doc:    "$if(propuesta.footer-doc)$$propuesta.footer-doc$$endif$",
  doc,
)
