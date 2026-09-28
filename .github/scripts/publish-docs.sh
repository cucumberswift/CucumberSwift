#!/usr/bin/env bash
# Builds this repository's GitHub Pages site from the docs attached to its
# releases. The Docs workflow runs it, then deploys the directory it writes.
#
#   .github/scripts/publish-docs.sh <output directory>
#
# Each release carries its DocC docs as two assets, built for fixed paths:
# docs-major.zip for /<DOCS_PATH>/X.x/ and docs-root.zip for /<DOCS_PATH>/.
# The Pages site is served at /<DOCS_PATH>/, and publishes:
#
#   /<DOCS_PATH>/X.x/  the highest stable release of each major X
#   /<DOCS_PATH>/      the highest stable release overall
#
# Nothing is rebuilt, and no project code runs. Releases are immutable, so docs
# built for a former path (FORMER_PATHS) are moved when they are unpacked: DocC
# writes the path only into each page's index.html shell, which is rewritten. A
# zip built for any other path is skipped, and the next lower release is used.
# Releases without both assets are skipped.
#
# It also writes redirect pages for /<DOCS_PATH>/ and /<DOCS_PATH>/X.x/ to the
# documentation page, 404.html, versions.json and sitemap.xml.
#
# Environment:
#   DOCS_PATH     path of the site, e.g. CucumberSwift
#   MODULE        DocC module name, lower case, e.g. cucumberswift
#   FORMER_PATHS  paths earlier releases were built for, space separated, e.g. "help docs"
#   GH_REPO       the repository, e.g. cucumberswift/CucumberSwift
#   GH_TOKEN      a token that can read its releases and its Pages settings
#   SITE_URL      optional, e.g. https://cucumberswift.org. Read from the Pages settings if unset.
#
# Needs gh, jq, unzip and perl. A failed API call or download stops the script,
# so a site with docs missing is never deployed.
set -euo pipefail
# Also inside $(...), so a failed download in publish_first stops the script.
shopt -s inherit_errexit

out=${1:?usage: publish-docs.sh <output directory>}
path_re='^[A-Za-z0-9_-][A-Za-z0-9._-]*(/[A-Za-z0-9_-][A-Za-z0-9._-]*)*$'
if ! [[ "${DOCS_PATH:-}" =~ $path_re ]]; then
  echo "::error::DOCS_PATH must be a path like CucumberSwift."
  exit 1
fi
if ! [[ "${MODULE:-}" =~ ^[a-z0-9_-]+$ ]]; then
  echo "::error::MODULE must be a lower-case DocC module name."
  exit 1
fi
if ! [[ "${GH_REPO:-}" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
  echo "::error::GH_REPO must be owner/repository."
  exit 1
fi
read -r -a former_paths <<< "${FORMER_PATHS:-}"
for former in "${former_paths[@]}"; do
  if ! [[ "$former" =~ $path_re ]]; then
    echo "::error::FORMER_PATHS must be paths like help, separated by spaces."
    exit 1
  fi
done
if [ -e "$out" ] && [ -n "$(ls -A "$out")" ]; then
  echo "::error::$out is not empty."
  exit 1
fi

site_url=${SITE_URL:-}
if [ -z "$site_url" ]; then
  # e.g. https://cucumberswift.org/CucumberSwift/ -> https://cucumberswift.org
  html_url=$(gh api "repos/$GH_REPO/pages" --jq .html_url)
  if ! [[ "$html_url" =~ ^(https://[^/]+) ]]; then
    echo "::error::Unexpected Pages URL: $html_url"
    exit 1
  fi
  site_url=${BASH_REMATCH[1]}
fi
site_url=${site_url%/}

name=${GH_REPO#*/}
base="/$DOCS_PATH/"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$out"
sitemap="$work/sitemap.txt"
: > "$sitemap"

# The baseUrl DocC baked into a zip, e.g. /CucumberSwift/5.x/.
base_url() {
  unzip -p "$1" index.html | sed -n 's/.*baseUrl = "\([^"]*\)".*/\1/p' | head -n 1
}

# Downloads <asset> of the first of <tags> (highest first) that was built for
# $base<sub>, or for a former path plus <sub> (then moved), unpacks it into <dir>
# and prints its tag. Prints nothing if none fits.
publish_first() {
  local asset=$1 sub=$2 dir=$3
  shift 3
  local target="$base$sub" tag zip built accepted former
  for tag in "$@"; do
    zip="$work/$tag-$asset"
    gh release download "$tag" --repo "$GH_REPO" --pattern "$asset" --output "$zip" --clobber < /dev/null
    built=$(base_url "$zip")
    accepted=
    if [ "$built" = "$target" ]; then accepted=yes; fi
    for former in "${former_paths[@]}"; do
      if [ "$built" = "/$former/$sub" ]; then accepted=yes; fi
    done
    if [ -n "$accepted" ]; then
      mkdir -p "$dir"
      unzip -q -o "$zip" -d "$dir"
      if [ "$built" != "$target" ]; then
        # Only the page shells carry the path, as "<path>... in attributes and baseUrl.
        # shellcheck disable=SC2016 # $ENV{...} is expanded by perl, not the shell
        find "$dir" -name index.html -print0 | FROM="\"$built" TO="\"$target" xargs -0 perl -pi -e 's/\Q$ENV{FROM}\E/$ENV{TO}/g'
        echo "$tag: $asset built for $built, moved to $target." >&2
      fi
      echo "$tag"
      return
    fi
    echo "::warning::$tag: $asset is built for $built, not $target. Skipped." >&2
  done
}

redirect_page() {
  local file=$1 target=$2
  mkdir -p "$(dirname "$file")"
  cat > "$file" <<EOF
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Moved</title>
<link rel="canonical" href="$site_url$target">
<meta http-equiv="refresh" content="0; url=$target">
</head>
<body>
<p>This page has moved to <a href="$target">$site_url$target</a>.</p>
<script>location.replace("$target" + location.search + location.hash)</script>
</body>
</html>
EOF
}

# Pages of a DocC site, as paths relative to it, e.g. documentation/cucumberswift/hooks/.
pages() {
  local dirs=() d
  for d in documentation tutorials; do
    if [ -d "$1/$d" ]; then dirs+=("$d"); fi
  done
  if [ ${#dirs[@]} -gt 0 ]; then
    (cd "$1" && find "${dirs[@]}" -name index.html | sed 's|index.html$||' | sort)
  fi
}

# Stable releases that carry both assets, lowest version first. Fetched on its
# own, so a failed API call stops the script.
releases=$(gh api --paginate "repos/$GH_REPO/releases?per_page=100" \
  --jq '.[] | select((.draft or .prerelease) | not)
            | select([.assets[].name] | index("docs-major.zip") and index("docs-root.zip"))
            | .tag_name')
tags=$(grep -E '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' <<< "$releases" | sort -V || true)
if [ -z "$tags" ]; then
  echo "::error::$GH_REPO has no stable release with docs. Nothing to publish."
  exit 1
fi

# /<DOCS_PATH>/: the highest stable release overall.
# shellcheck disable=SC2046 # one tag per word
root=$(publish_first docs-root.zip "" "$out" $(sort -rV <<< "$tags"))
if [ -z "$root" ]; then
  echo "::error::$GH_REPO has no docs built for $base. Nothing to publish."
  exit 1
fi
echo "$base: $root"
redirect_page "$out/index.html" "${base}documentation/$MODULE/"
pages "$out" | sed "s|^|$site_url$base|" >> "$sitemap"

# /<DOCS_PATH>/X.x/: the highest stable release of each major.
majors='[]'
fallback=()
while read -r major; do
  # shellcheck disable=SC2046
  tag=$(publish_first docs-major.zip "$major.x/" "$out/$major.x" $(grep "^$major\." <<< "$tags" | sort -rV))
  if [ -z "$tag" ]; then continue; fi
  echo "$base$major.x/: $tag"
  redirect_page "$out/$major.x/index.html" "$base$major.x/documentation/$MODULE/"
  majors=$(jq -c --arg m "$major.x" --arg v "$tag" --arg p "$base$major.x/" '. + [{major: $m, version: $v, path: $p}]' <<< "$majors")
  fallback+=("[\"$base$major.x/\", \"$base$major.x/documentation/$MODULE/\"]")

  if [ "$tag" = "$root" ]; then
    # Same release as /<DOCS_PATH>/: point search engines there.
    pages "$out/$major.x" | while read -r page; do
      CANONICAL="$site_url$base$page" perl -0pi -e 's|<head>|<head><link rel="canonical" href="$ENV{CANONICAL}">|' \
        "$out/$major.x/${page}index.html"
    done
  else
    pages "$out/$major.x" | sed "s|^|$site_url$base$major.x/|" >> "$sitemap"
  fi
done < <(cut -d. -f1 <<< "$tags" | sort -un)

# Pages that do not exist go to the documentation of their major, or of the latest release.
fallback+=("[\"$base\", \"${base}documentation/$MODULE/\"]")
map=$(IFS=,; echo "${fallback[*]}")
cat > "$out/404.html" <<EOF
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="robots" content="noindex">
<title>Page not found</title>
</head>
<body>
<p>This page does not exist. See the <a href="${base}documentation/$MODULE/">$name documentation</a>.</p>
<script>(function(){var m=[$map];for(var i=0;i<m.length;i++){if(location.pathname.indexOf(m[i][0])===0){location.replace(m[i][1]);return;}}})();</script>
</body>
</html>
EOF

versions=$(jq -n --arg n "$name" --arg v "$root" --arg p "$base" --argjson m "$majors" \
  '{name: $n, version: $v, path: $p, majors: $m}')
echo "$versions" > "$out/versions.json"

{
  echo '<?xml version="1.0" encoding="UTF-8"?>'
  echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
  # DocC names operator pages after the operator, e.g. <(_:_:). Percent-encode
  # what a URL path may not contain (RFC 3986), then escape & for XML.
  perl -pe 's{([^A-Za-z0-9._~/:@!\$&\x27()*+,;=\n-])}{sprintf("%%%02X", ord($1))}ge; s/&/&amp;/g; s|.*|  <url><loc>$&</loc></url>|' "$sitemap"
  echo '</urlset>'
} > "$out/sitemap.xml"

echo "Published: $(jq -c '{version, majors: [.majors[].version]}' <<< "$versions")"
