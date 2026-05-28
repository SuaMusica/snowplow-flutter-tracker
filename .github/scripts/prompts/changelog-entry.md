You are preparing the CHANGELOG entry for a new release of the Snowplow Flutter tracker.

Inputs you will be given:
- `VERSION`: the new version string, e.g. `0.10.0`.
- `COMMITS`: a list of merge / squash commits going into this release, one per line, formatted as `<short-sha> <subject>`. Subjects usually end with ` (#NNN)`.
- `PREVIOUS_ENTRY`: the most recent existing CHANGELOG entry (header + bullets), provided verbatim as a style example.

Produce exactly the new CHANGELOG entry in markdown — nothing else. No preamble, no code fences around the whole output, no trailing commentary.

Format (match `PREVIOUS_ENTRY` exactly — Flutter's CHANGELOG.md style):

```
# <VERSION>
* <one short line per change> (#NNN)
* <one short line per change> (#NNN)
```

Rules:
- Header is `# X.Y.Z` (no date, no parentheses).
- One bullet per change, prefixed with `* ` (asterisk + space).
- Preserve the PR/issue reference at the end of the line in parentheses, e.g. `(#71)`. If a commit subject contains one, keep it; do not invent one if it is missing.
- For external contributors, you may append ` thanks to @<github-login>` after the PR reference — only if the commit explicitly came from an external author. (The PR-body prompt classifies this more rigorously; for CHANGELOG, when unsure, omit the attribution.)
- Skip commits that are pure chores: dependency bumps with no behaviour change, CI-only changes, docs-only changes, and any commit whose subject begins with "Prepare for". When in doubt, include.
- Rewrite subjects only when they are ungrammatical or unclear; otherwise keep them close to the original wording.
- End the entry with a single trailing blank line so it can be prepended to the existing CHANGELOG.
