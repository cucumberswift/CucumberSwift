#!/usr/bin/env bash
# Selects one of the runner image's Xcode versions for the rest of the job, and
# fails if the image doesn't have it. CI's jobs that test an older Xcode run it.
#
#   .github/scripts/select-xcode.sh <version>
#
# The version is as the image's README lists it, such as 16.0 or 26.2: GitHub's
# macOS images install each Xcode as /Applications/Xcode_<version>.app, or link
# that name to it.
set -euo pipefail

version=${1:?usage: select-xcode.sh <version>}
app="/Applications/Xcode_${version}.app"
if [[ ! -d "$app" ]]; then
  echo "::error::Xcode $version is not installed on this image. It has:"
  find /Applications -maxdepth 1 -name 'Xcode*.app' | sort
  exit 1
fi
sudo xcode-select -s "$app/Contents/Developer"
xcodebuild -version
