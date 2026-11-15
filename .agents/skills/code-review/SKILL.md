---
name: code-review
description: Review code changes in parallel passes over security, performance, correctness, and maintainability, then merge the findings into one prioritized report. Trigger with a PR URL or diff, "review this before I merge", "is this code safe?", or when checking a change for N+1 queries, injection risks, missing edge cases, or error handling gaps.
argument-hint: "<PR URL, branch/range, diff, or file path>"
---

# /code-review

Review the change the user names. Split the review across parallel subagent passes, then
merge what they return into one report. The reviewers find; you verify and rank.

## 1 Fix the scope

Decide what counts as the change before reviewing anything:

- **PR URL or number** — `<repo>` is that PR's checkout. With `gh`, write `gh pr diff <arg>
  --patch` to the diff path below. Without `gh`, fetch the `.diff` URL into it. Skip the
  range commands.
- **Branch or range** — `<repo>` is the current checkout and `<range>` is that range, such
  as `main...HEAD` or `HEAD~3`.
- **File or directory** — `<repo>` is the current checkout and `<range>` is `<base>...HEAD
  -- <path>`, with `<base>` from `git merge-base HEAD @{upstream}`, falling back to `main`
  or `master`.
- **Nothing named** — ask what to review, and stop.

Write the diff where the reviewers can read it. Replace `<range>` with the range decided
above, and pass the same `-- <path>` to `git ls-files`:

```bash
d="$(git -C <repo> rev-parse --absolute-git-dir)/pi-code-review.diff"
git -C <repo> diff --no-color --stat <range> > "$d"
git -C <repo> diff --no-color <range> >> "$d"
git -C <repo> diff HEAD >> "$d"
git -C <repo> ls-files --others --exclude-standard | while read -r f; do
  git -C <repo> diff --no-color --no-index --src-prefix=a/ --dst-prefix=b/ -- /dev/null "$f" || true
done >> "$d"
```

The last two commands add uncommitted work and untracked files, which a range diff leaves
out. Drop them when the tree is clean. Say in the report when the review covers the
working tree.

Record the absolute `<repo>`, the diff path, and `git -C <repo> diff --stat <range>`.

Pick the split by diff size:

- **Up to ~1500 changed lines** — four reviewers, one per lens.
- **Larger** — four reviewers, one per file group, each running all four lenses. Keep the
  file sets disjoint and the changed-line counts balanced, and never split a function.

## 2 Dispatch the reviewers

Send every reviewer call in one message so they run in parallel, and set `background:
false`: the merge needs their conclusions in this turn. Give each reviewer only the read
tools (`read`, `grep`, `glob`).

Each prompt must stand on its own, because a subagent cannot see this conversation. Fill
the template for that lens from `references/lenses.md` with:

- the absolute `<repo>` and the diff path, and that reading the diff comes first;
- which files or lens it owns, when running in file-group mode;
- the finding format below, and that it must report no findings when there are none.

```
<Critical|Major|Minor> | <file>:<line> | <issue in one sentence> | <evidence: the code or call path that shows it> | <smallest fix>
```

Require the evidence field to start with `unverified` when the reviewer could not confirm
the claim from the diff or the code it read. Reviewers sometimes add a header or a closing
line; keep only lines with five `|`-separated fields.

## 3 Verify and merge

1. Open every Critical and Major finding at its `file:line` and confirm it. Drop the ones
   that do not hold.
2. Merge findings on the same location and cause into one line. Keep every lens that raised
   it, and take the highest severity any reviewer gave.
3. Downgrade a finding the diff, a nearby comment, or a deliberate caller already
   justifies, and give the reason in one line.
4. Rank by severity, then by blast radius: a reachable path before an unreachable one.

Reviewers invent plausible problems, so a finding you did not open is a finding you cannot
report. Two lenses hitting one line is normal, and reviewers disagree on severity: re-grade
every survivor against the definitions below.

## 4 Report

~~~markdown
## Code review: <PR title, branch, or files>

**Scope:** `<range>` — <n> files, <n> changed lines. Four parallel passes: <lens per reviewer, or file groups>.
**Summary:** <two sentences: what the change does, and how it holds up>.

### Critical
| # | Location | Lens | Issue | Fix |
|---|----------|------|-------|-----|

### Major
| # | Location | Lens | Issue | Fix |
|---|----------|------|-------|-----|

### Minor
| # | Location | Lens | Issue | Fix |
|---|----------|------|-------|-----|

### Dropped or downgraded
- `src/x.ts:10` — <what a reviewer claimed> — <why it does not hold>

### What looks good
- <two to four specific things the change does well>

### Verdict
**Request changes** — <one line why>
~~~

Severity, and the verdict it drives:

- **Critical** — a bug, security hole, or data loss on a reachable path. Any Critical means
  *Request changes*.
- **Major** — works, but with a real cost: wrong behavior under load, an unhandled failure,
  an untested branch. Major alone means *Approve with comments*.
- **Minor** — naming, structure, duplication, polish. Minor alone means *Approve*.

Leave out a section with no findings, and leave out "Dropped or downgraded" when every
finding survived. "What looks good" stays: it is what the author is told to keep.

## Tips

1. **Name the base** — "against `main`" or "just the last commit" avoids reviewing
   unrelated changes.
2. **Name the concern** — "this handles PII" or "this is a hot path" reweights the passes.
3. **Paste the diff** when there is no git checkout: save the pasted text to a file,
   review that file, and say in the report that the diff came from a paste.
