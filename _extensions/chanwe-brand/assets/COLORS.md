# Portable color catalog

`colors.json` uses `chanwe-colors/v2` and is generated from
`../brand.yml` (`color.palette`). It covers the entire active named palette —
the report's token set plus what the HTML rules read — including the
eight-digit hex colors with alpha.

- `primary` identifies the primary token and its resolved hex value.
- Each `colors` entry has `internal_name`, `code`, and `aliases`.
- Only explicit YAML references become aliases. Distinct semantic roles that
  happen to share a hex value remain separate entries.
- Every active palette name appears exactly once, as an `internal_name` or
  an alias. Names and values are case-sensitive; hex codes are uppercase.
- `code` uses sRGB `#RRGGBB` or `#RRGGBBAA`; the final byte is alpha, not a
  fourth color channel.

Regenerate or validate from the repository root:

```sh
ruby scripts/export-brand-colors.rb --write
ruby scripts/export-brand-colors.rb --check
```

The brand check runs the same validation to prevent the catalog drifting from
the YAML source.

## Migration from v1

The old hand-maintained selection contained stale and standalone colors.
The v2 catalog exports current roles: brand black is `#111319`, paper is
`#F8FAFC`, and primary remains `#FD3810`. Look up a name in both
`internal_name` and `aliases`; the only alias today is `primary-text` →
`primary`. Old v1 names map by value: `brand-red` / `brand-orange` →
`primary`, `brand-black` → `ink`, `brand-paper` / `brand-white` → `paper`,
`brand-gray` → `chart-gray`, `brand-silver` → `neutral-300`.

`brand-charcoal-green`, `brand-gray-light`, and `brand-orange-deep` were not
in the active YAML palette and are no longer exported. The old page-13 names
(`p13-orange-*`, `p13-gray-*`) live in `legacy/p13-palette.json` as a
historical reference. On 2026-09-24 the palette was cut to what a format
actually reads: the `cw-color-*` twins, the `brand-*` names (`brand-red`,
`brand-orange`, `brand-black`, `brand-gray`…), the `orange-*` / `dark-*` /
`beige-*` ramps and the `p14-*` chart names are gone. The accent is
`primary`; HTML statuses are `status-*`; chart accents are `chart-*`.

The cleanup also removes 33 CSS variables with no consumers in this repo,
including the four `--chanwe-primary/ink/paper/muted` aliases and the unused
`--cw-logo-negro-image` placeholder. Existing `--cw-color-*` variables used
by the HTML styles retain their resolved colors. Palette aliases for
`cw-color-neutral-0`, `cw-color-text-secondary`, and `cw-color-text-inverse`
now reflect the values that the HTML CSS was already rendering, rather than
their previously bypassed literals.
