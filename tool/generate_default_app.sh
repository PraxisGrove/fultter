#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_dir="${1:-$repo_root/build/generated_app}"

if [[ -e "$output_dir" ]] && [[ -n "$(find "$output_dir" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
  echo "Generation output must be absent or empty: $output_dir" >&2
  exit 2
fi

mkdir -p "$output_dir"
cd "$repo_root"

if command -v mason >/dev/null 2>&1; then
  mason_command=(mason)
else
  mason_command=(dart pub global run mason_cli:mason)
fi

"${mason_command[@]}" get
"${mason_command[@]}" make fultter_app \
  --config-path "$repo_root/tool/default_app.json" \
  --output-dir "$output_dir" \
  --on-conflict overwrite

test -d "$output_dir/android"
test -d "$output_dir/ios"
test -f "$output_dir/.github/workflows/flutter_ci.yml"
test -f "$output_dir/.github/workflows/ios_build.yml"
test -f "$output_dir/.github/workflows/deploy_android.yml"

for removed_path in \
  .github/workflows/android_release.yml \
  .github/workflows/deploy_ios.yml \
  .github/workflows/integration_tests.yml \
  docs/localization.md \
  lib/src/features/README.md \
  lib/src/features/reference/data/README.md; do
  if [[ -e "$output_dir/$removed_path" ]]; then
    echo "Generated output contains retired template file: $removed_path" >&2
    exit 1
  fi
done

if grep -REn 'sentry_flutter|SentryObservability|\{\{[^}]' \
  "$output_dir/pubspec.yaml" "$output_dir/lib"; then
  echo "Default output contains an optional integration or template marker." >&2
  exit 1
fi

echo "Generated default app at $output_dir"
