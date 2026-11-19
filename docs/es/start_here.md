# chanwer: empezar acá

**Qué es.** El paquete de R de la marca CHANWE para gráficos, tablas y KPI: el tema de ggplot2, los
constructores de gráficos de papel e interactivos, las tablas en Typst (PDF) y en HTML, el marco de figura y
los ayudantes de Quarto. Todos los valores salen de los tokens del hub (`chanwe-brandbook`), nunca de un hex
escrito en el código.

**Quién lo usa.** El equipo, en los informes de Quarto (formatos `chanwe-report-typst` y `chanwe-brand-html` de
chanwe-brand) y en los análisis en R. CHANWE Espacios lo entrega fijado en su menú de descargas.

**Dónde corre.** En la máquina de quien escribe el informe; no es un servicio. Se publica como release de GitHub
(`chanwer-vX.Y.Z.zip`).

## Instalar y probar

```r
remotes::install_local("chanwer-v3.4.0.zip")
```

Desde el repo, para desarrollar:

```r
devtools::load_all()
devtools::test()
devtools::check()
```

Para ver un cambio: `quarto render chanwer-catalogue.qmd` (el catálogo de gráficos, en PDF) y
`quarto render chanwer-showcase-html.qmd` (lo interactivo).

## Mapa de documentos

| Documento | Qué tiene |
|---|---|
| [guide.md](guide.md) | Cómo usarlo: un gráfico de papel, uno interactivo, una tabla; cómo cambiarlo y publicarlo |
| [data-tree.md](data-tree.md) | De dónde sale cada valor: tokens del hub → paquete → gráfico |
| `../../README.md` | Referencia rápida de funciones (en inglés) |
| `../../AGENTS.md` | Guía para agentes, versionado y releases |
| `../../NEWS.md` | Cambios por versión |
| `chanwer-catalogue.qmd` | Cada constructor con sus variantes, y la revisión de los gráficos de otros documentos |
