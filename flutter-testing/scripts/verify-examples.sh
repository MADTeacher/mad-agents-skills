#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_FILE="$ROOT_DIR/SKILL.md"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

[[ -f "$SKILL_FILE" ]] || fail "Missing SKILL.md"

ruby -ryaml -e '
path = ARGV.fetch(0)
text = File.read(path)
unless text.start_with?("---\n")
  abort "ERROR: SKILL.md must start with YAML frontmatter"
end
parts = text.split(/^---\s*$/, 3)
abort "ERROR: SKILL.md frontmatter is not closed" unless parts.length == 3
frontmatter = YAML.safe_load(parts[1], permitted_classes: [], aliases: false)
abort "ERROR: frontmatter must be a map" unless frontmatter.is_a?(Hash)
name = frontmatter["name"]
description = frontmatter["description"]
abort "ERROR: missing frontmatter name" if name.to_s.empty?
abort "ERROR: missing frontmatter description" if description.to_s.empty?
expected = File.basename(File.dirname(path))
abort "ERROR: frontmatter name #{name.inspect} does not match #{expected.inspect}" unless name == expected
required_terms = %w[unit widget integration mock plugin]
missing = required_terms.reject { |term| description.downcase.include?(term) }
abort "ERROR: description missing trigger terms: #{missing.join(", ")}" unless missing.empty?
' "$SKILL_FILE"

ruby -e '
root = ARGV.fetch(0)
failed = false
Dir[File.join(root, "**/*.md")].sort.each do |file|
  File.readlines(file).each_with_index do |line, index|
    line.scan(/\[[^\]]+\]\(([^)]+)\)/).flatten.each do |target|
      next if target.match?(/\A(?:https?:|mailto:|#)/)
      path = target.split("#", 2).first
      next if path.empty?
      full_path = File.expand_path(path, File.dirname(file))
      unless File.exist?(full_path)
        warn "ERROR: missing local link #{file}:#{index + 1} -> #{target}"
        failed = true
      end
    end
  end
end
exit(failed ? 1 : 0)
' "$ROOT_DIR"

while IFS= read -r -d '' file; do
  count="$(grep -c '^```' "$file" || true)"
  if (( count % 2 != 0 )); then
    fail "Unbalanced fenced code blocks in $file"
  fi
done < <(find "$ROOT_DIR" -name '*.md' -print0)

[[ -z "$(find "$ROOT_DIR" -name '.DS_Store' -print)" ]] || fail "Remove .DS_Store files from flutter-testing"

grep -q 'scripts/verify-examples.sh' "$SKILL_FILE" || fail "SKILL.md must route to scripts/verify-examples.sh"

for pattern in \
  'tester\.trace\(' \
  'tester\.takeScreenshot\(' \
  'flutter test --platform' \
  '--no-sound-null-safety' \
  'captureNamed' \
  'flutter pub run build_runner build' \
  'setSurfaceSize\(Size\.zero\)'
do
  if rg -n --glob '*.md' -- "$pattern" "$ROOT_DIR/references"; then
    fail "Forbidden stale pattern found: $pattern"
  fi
done

echo "flutter-testing skill checks passed"
