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
// https://chanwe.com.ar (v3, nivel H, máscara 4). Lo genera
// `scripts/make-qr-svg.mjs`; no se edita a mano.
// =================================================================

#let chanwe-qr-frame(
  path,
  size:         11.4mm,   // lado del código, sin contar marco ni tarjeta
  edge:         none,     // color del filete exterior — lo pasa el formato
  card:         none,     // color de la tarjeta interior — idem
  pad-outer:    2mm,      // aire entre el filete y la tarjeta
  pad-inner:    0.8mm,    // zona tranquila de la tarjeta alrededor del código
  radius-outer: 1.4mm,
  radius-inner: 0.8mm,
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
)
