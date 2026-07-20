#!/bin/sh
# Crew installer: links (default) or copies the pack into your Claude Code config.
#
# Zero dependencies, POSIX sh. Safe to re-run. Never touches what it does not
# own: installs are tracked in a manifest ($TARGET/.crew-manifest) together
# with a content checksum, so re-installs refresh crew's own files, prune
# files dropped from the pack, and refuse (without --force) to replace
# either files crew never installed or crew files you edited afterwards.
#
#   sh install.sh              install (symlinks, so a `git pull` here updates in place)
#   sh install.sh --copy      install by copying (independent of this checkout)
#   sh install.sh --dry-run   print every action, change nothing
#   sh install.sh --force     also replace conflicting or user-modified files
#   sh install.sh --uninstall remove what crew installed (keeps files you modified)
#   sh install.sh --target D  install into D instead of $CLAUDE_CONFIG_DIR / ~/.claude
#
# Exit codes: 0 ok · 2 usage or layout error · 3 finished, but conflicts were skipped

set -u

MODE=link DRY=0 FORCE=0 UNINSTALL=0 TARGET=""
INSTALLED=0 REFRESHED=0 CONFLICTS=0 PRUNED=0
NEW_MANIFEST=""
TAB=$(printf '\t')

usage() { sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; }
say()   { printf '%s\n' "$*"; }
die()   { printf 'install.sh: %s\n' "$*" >&2; exit 2; }

while [ $# -gt 0 ]; do
  case "$1" in
    --copy)      MODE=copy ;;
    --dry-run)   DRY=1 ;;
    --force)     FORCE=1 ;;
    --uninstall) UNINSTALL=1 ;;
    --target)    [ $# -ge 2 ] || die "--target needs a directory"; shift; TARGET=$1 ;;
    -h|--help)   usage; exit 0 ;;
    *)           die "unknown option: $1 (try --help)" ;;
  esac
  shift
done

REPO=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd) || die "cannot resolve repo dir"
[ -n "$TARGET" ] || TARGET=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
MANIFEST="$TARGET/.crew-manifest"

[ -d "$REPO/agents" ] && [ -d "$REPO/skills" ] \
  || die "no agents/ + skills/ next to install.sh (run it from a crew checkout)"

# run CMD... executes, or narrates under --dry-run
run() {
  if [ "$DRY" = 1 ]; then say "  [dry-run] $*"; else "$@"; fi
}

# manifest line format:  <installed-path> TAB <tag>
# tag = "link" for symlinks, or a cksum of the contents for copies.
manifest_tag() {  # $1 = path → prints its tag, empty if not in manifest
  [ -f "$MANIFEST" ] || return 0
  awk -F'\t' -v p="$1" '$1 == p { print $2; exit }' "$MANIFEST"
}

sum_of() {  # content checksum of a file or directory (cksum is POSIX)
  if [ -d "$1" ]; then
    (cd -- "$1" && find . -type f | LC_ALL=C sort | while IFS= read -r f; do
      printf '%s\n' "$f"; cksum < "$f"
    done) | cksum | awk '{ print $1 ":" $2 }'
  else
    cksum < "$1" | awk '{ print $1 ":" $2 }'
  fi
}

points_into_repo() {  # a symlink into this checkout is crew's
  [ -L "$1" ] || return 1
  command -v readlink >/dev/null 2>&1 || return 0  # no readlink → trust the manifest
  case "$(readlink -- "$1")" in "$REPO"/*) return 0 ;; *) return 1 ;; esac
}

unmodified() {  # $1 = installed path, $2 = recorded tag: still as crew left it?
  if [ -L "$1" ]; then
    # The manifest recording "link" is what makes this symlink ours: it is
    # still a symlink, so it is untouched. Requiring it to point into THIS
    # checkout would call every link foreign after the repo is moved or
    # re-cloned, which orphaned files on uninstall. Fall back to the target
    # check only for links installed before manifests existed.
    if [ "$2" = link ]; then return 0; fi
    points_into_repo "$1"
  else
    [ "$2" != link ] && [ "$(sum_of "$1")" = "$2" ]
  fi
}

# ---------- uninstall ----------
if [ "$UNINSTALL" = 1 ]; then
  [ -f "$MANIFEST" ] || { say "nothing to do: no manifest at $MANIFEST"; exit 0; }
  KEPT_MANIFEST=""
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    path=${line%%"$TAB"*} tag=${line#*"$TAB"}
    [ -e "$path" ] || [ -L "$path" ] || continue
    if unmodified "$path" "$tag" || [ "$FORCE" = 1 ]; then
      say "remove  $path"
      run rm -rf -- "$path"
    else
      say "keep    $path (you modified it; remove by hand or use --force)"
      KEPT_MANIFEST="${KEPT_MANIFEST}${path}${TAB}${tag}
"
    fi
  done < "$MANIFEST"
  # Dropping the manifest while files are still installed would orphan them:
  # a later uninstall finds no manifest and reports nothing to do, leaving the
  # user to clean up by hand. Keep tracking whatever we kept.
  if [ -n "$KEPT_MANIFEST" ]; then
    say "keep    $MANIFEST (still tracking the files above; --force removes them)"
    [ "$DRY" = 1 ] || printf '%s' "$KEPT_MANIFEST" > "$MANIFEST"
  else
    say "remove  $MANIFEST"
    run rm -f -- "$MANIFEST"
  fi
  [ "$DRY" = 1 ] && say "dry run: nothing was removed." || say "uninstalled."
  exit 0
fi

# ---------- install ----------
install_one() {  # $1 = source (file or dir), $2 = destination
  src=$1 dst=$2 existed=0
  tag=$(manifest_tag "$dst")
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if { [ -n "$tag" ] && unmodified "$dst" "$tag"; } || { [ -z "$tag" ] && points_into_repo "$dst"; }; then
      existed=1                       # ours, untouched (or a pre-manifest crew link)
      run rm -rf -- "$dst"
    elif [ "$FORCE" = 1 ]; then
      say "force   $dst (replacing a file crew does not own as-is)"
      run rm -rf -- "$dst"
    elif [ -n "$tag" ]; then
      say "CONFLICT $dst was modified after crew installed it; skipped (--force overwrites your edits)"
      CONFLICTS=$((CONFLICTS + 1))
      NEW_MANIFEST="${NEW_MANIFEST}${dst}${TAB}${tag}
"                                     # keep tracking it under its old tag
      return 0
    else
      say "CONFLICT $dst exists and crew does not own it; skipped (--force to replace)"
      CONFLICTS=$((CONFLICTS + 1)); return 0
    fi
  fi
  if [ "$MODE" = link ]; then run ln -s -- "$src" "$dst"; else run cp -R -- "$src" "$dst"; fi
  if [ "$MODE" = link ]; then newtag=link
  elif [ "$DRY" = 1 ];   then newtag=dry-run
  else                        newtag=$(sum_of "$dst")
  fi
  NEW_MANIFEST="${NEW_MANIFEST}${dst}${TAB}${newtag}
"
  if [ "$existed" = 1 ]; then
    REFRESHED=$((REFRESHED + 1)); say "refresh $dst"
  else
    INSTALLED=$((INSTALLED + 1)); say "install $dst"
  fi
}

say "crew installer: $MODE mode, target $TARGET$( [ "$DRY" = 1 ] && printf ' (dry run)' )"
run mkdir -p -- "$TARGET/agents" "$TARGET/skills"

for f in "$REPO"/agents/*.md; do
  [ -e "$f" ] || continue
  install_one "$f" "$TARGET/agents/$(basename -- "$f")"
done

for d in "$REPO"/skills/*/; do
  [ -f "${d}SKILL.md" ] || continue        # a skill without SKILL.md is not a skill
  install_one "${d%/}" "$TARGET/skills/$(basename -- "$d")"
done

# prune: paths crew installed previously that this version no longer ships
if [ -f "$MANIFEST" ]; then
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    old=${line%%"$TAB"*} oldtag=${line#*"$TAB"}
    case "$NEW_MANIFEST" in *"$old$TAB"*) continue ;; esac
    [ -e "$old" ] || [ -L "$old" ] || continue
    if unmodified "$old" "$oldtag" || [ "$FORCE" = 1 ]; then
      say "prune   $old (no longer in the pack)"
      run rm -rf -- "$old"
      PRUNED=$((PRUNED + 1))
    else
      say "keep    $old (left the pack, but you modified it; remove by hand)"
    fi
  done < "$MANIFEST"
fi

if [ "$DRY" = 1 ]; then
  say "  [dry-run] write manifest $MANIFEST"
else
  printf '%s' "$NEW_MANIFEST" > "$MANIFEST"
fi

say "done: $INSTALLED installed, $REFRESHED refreshed, $PRUNED pruned, $CONFLICTS conflicts."
[ "$MODE" = link ] && [ "$DRY" = 0 ] && say "symlink mode: keep this checkout; \`git pull\` here updates the install."
[ "$CONFLICTS" -gt 0 ] && exit 3
exit 0
