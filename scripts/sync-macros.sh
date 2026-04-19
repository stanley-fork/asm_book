#!/usr/bin/env bash
#
# sync-macros.sh
#
# Propagate canonical macro files from macros/ into the per-chapter
# copies scattered throughout the repository.
#
# Source of truth:
#     Any file in macros/*.S at the repository root.
#
# Targets:
#     Every file elsewhere in the repository whose basename matches a
#     file in macros/. The chapter copies exist so that each chapter
#     directory remains self-contained (a reader can download a single
#     chapter from GitHub and have the macros it needs sitting right
#     next to the source files). That self-containment is valuable;
#     manual synchronization of ~12 copies is not. This script lets us
#     have both.
#
# Operation:
#     For each canonical file, find every copy with the same basename
#     outside macros/ and overwrite it if (and only if) it differs.
#     Prints one line per file actually modified; prints nothing beyond
#     a final summary if everything was already in sync.
#
# Intended use:
#     Run after editing any file in macros/, then commit the changes
#     (the canonical file plus all updated copies). CI verifies this
#     was done by re-running the script and requiring `git diff
#     --exit-code` to be clean.
#
# Perry Kivolowitz
# A Gentle Introduction to Assembly Language

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

if [ ! -d macros ]; then
    echo "error: macros/ directory not found at repo root" >&2
    exit 1
fi

changed=0
checked=0

for canonical in macros/*.S; do
    [ -f "$canonical" ] || continue
    name="$(basename "$canonical")"

    # Find every file in the repo with this basename, excluding the
    # canonical location itself and anything under .git/. The -type f
    # filter skips any stray symlinks a prior experiment may have left.
    while IFS= read -r copy; do
        checked=$((checked + 1))
        if ! cmp -s "$canonical" "$copy"; then
            cp "$canonical" "$copy"
            echo "synced: $copy  <-  $canonical"
            changed=$((changed + 1))
        fi
    done < <(find . -name "$name" -not -path './macros/*' -not -path './.git/*' -type f)
done

if [ "$changed" -eq 0 ]; then
    echo "macros already in sync ($checked chapter copies checked)"
else
    echo "synced $changed of $checked chapter copies"
fi
