# chanwer: start here

**What it is.** The CHANWE brand's R package for charts, tables and KPIs: the ggplot2 theme, the paper and
interactive chart builders, tables in Typst (PDF) and HTML, the figure frame and the Quarto helpers. Every value
comes from the hub's tokens (`chanwe-brandbook`), never from a hex written in the code.

**Who uses it.** The team, in Quarto reports (chanwe-brand's `chanwe-report-typst` and `chanwe-brand-html`
formats) and in R analysis. CHANWE Espacios ships it pinned in its downloads menu.

**Where it runs.** On the machine of whoever writes the report; it is not a service. It is published as a
GitHub release (`chanwer-vX.Y.Z.zip`).

## Install and try it

```r
remotes::install_local("chanwer-v3.4.0.zip")
```

From the repo, to develop:

```r
devtools::load_all()
devtools::test()
devtools::check()
```

To see a change: `quarto render chanwer-catalogue.qmd` (the chart catalogue, PDF) and
`quarto render chanwer-showcase-html.qmd` (the interactive side).

## Map of the docs

| Doc | What it holds |
|---|---|
| [guide.md](guide.md) | How to use it: a paper chart, an interactive one, a table; how to change and release it |
| [data-tree.md](data-tree.md) | Where every value comes from: hub tokens → package → chart |
| `../../README.md` | Quick function reference |
| `../../AGENTS.md` | Agent guide, versioning and releases |
| `../../NEWS.md` | Changes by version |
| `chanwer-catalogue.qmd` | Every builder with its variants, and the review of other documents' charts |
