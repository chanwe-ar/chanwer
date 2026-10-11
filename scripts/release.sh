#!/usr/bin/env bash
# Publishes a release of chanwer: tag vX.Y.Z on main, and a GitHub release with the NEWS.md notes
# for X.Y.Z and chanwer-vX.Y.Z.zip, the package source as `R CMD build` sees it (.Rbuildignore
# applied). Install with remotes::install_local("chanwer-vX.Y.Z.zip").
#
#   scripts/release.sh 2.7.0
set -euo pipefail
version=${1:?usage: scripts/release.sh X.Y.Z}
[[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "not a X.Y.Z version: $version" >&2; exit 1; }
tag="v$version"; name=chanwer
cd "$(git rev-parse --show-toplevel)"
[ "$(git branch --show-current)" = main ] || { echo "release from main" >&2; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "the working tree has uncommitted changes" >&2; exit 1; }
git fetch -q origin main
[ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] || { echo "main is not the same as origin/main" >&2; exit 1; }
! git rev-parse -q --verify "refs/tags/$tag" >/dev/null || { echo "$tag already exists; never move a published tag" >&2; exit 1; }
grep -qx "Version: $version" DESCRIPTION || { echo "DESCRIPTION is not at Version: $version" >&2; exit 1; }
notes=$(mktemp)
awk -v h="# chanwer $version" '$0==h{f=1;next} f&&/^# /{exit} f' NEWS.md > "$notes"
grep -q '[^[:space:]]' "$notes" || { echo "NEWS.md has no section # chanwer $version" >&2; exit 1; }
zip="$(mktemp -d)/$name-$tag.zip"
# Tracked files that .Rbuildignore keeps out of the package are left out of the zip too.
python3 - > "$zip.files" <<'PY'
import re, subprocess
patterns = [re.compile(line.strip()) for line in open('.Rbuildignore') if line.strip() and not line.startswith('#')]
for path in subprocess.run(['git', 'ls-files'], capture_output=True, text=True, check=True).stdout.splitlines():
    parts = path.split('/')
    if any(p.search('/'.join(parts[:i])) for p in patterns for i in range(1, len(parts) + 1)) or path.endswith('.DS_Store'):
        continue
    print(path)
PY
git archive --format=zip --prefix="$name/" -o "$zip" HEAD -- $(cat "$zip.files")
git tag -a "$tag" -m "$name $tag"
git push -q origin "$tag"
gh release create "$tag" "$zip" --title "$name $tag" --notes-file "$notes"
echo "released $tag · $(basename "$zip") · sha256 $(shasum -a 256 "$zip" | cut -d' ' -f1)"
