---
name: skill-creator
description: Create or improve a skill for pi with verification proportional to the change. Use whenever the person wants a new skill, wants an existing skill edited or sharpened, or says a skill never triggers when it should.
---

# Create or improve a skill for pi

Adapted from `anthropics/skills`' `skill-creator` (Apache-2.0), cut to what pi
provides.

A skill is a directory holding `SKILL.md`. Its description helps the model
select it for a task. Optional `paths` add reminders after matching files are
read. The body holds the instructions loaded when the skill is used.

## 1. Capture what it is for

Ask until these are answered:

1. What should the skill let the model do?
2. What does the person say that should reach for it? Which adjacent request
   must not?
3. What does a finished result look like?

Mine the conversation first: when the person says "turn this into a skill", the
steps, the tools and the corrections are already there.

## 2. Write it

Read `skill(name: "tool-creator", file: "writing.md")` before writing a
description or instructions. It holds the rules for text a model reads.

Put the skill in `$PI_HOME/skills/<name>/SKILL.md`, or the nearest
`.pi/skills/<name>/` when it belongs to a checkout. A project's skill replaces
one of the same name from the home directory. pi refreshes skills before the
next request to the model. The skill's `/name` command becomes available the
next time the person types.

```markdown
---
name: rust-conventions
description: Apply Rust conventions when writing, reviewing, or refactoring Rust code.
paths:
  - "**/*.rs"
  - "**/Cargo.toml"
---

The instructions to follow once the skill is loaded.
```

- `description` is required. Without it pi reports
  `skill skipped — <path>: SKILL.md has no description` to the person and never
  offers the skill to the model.
- `name` may be omitted; pi then uses the directory name. Use a-z, 0-9, `-`
  and `_`, up to 64 characters.
- State both halves in the description: what the skill does, and the requests
  that should reach for it. Keep it under 1000 bytes; pi folds it to one line.
- Keep the body short. Move procedures and examples into files beside it, and
  say when to read each one: pi lists those files and how to fetch them with
  `skill(name: "<name>", file: "<path>")` whenever the skill loads.
- Helper scripts stay in the skill's own directory. Its subdirectories are not
  more skills.

### Choose file triggers

Add `paths` when the skill applies to a clear set of files, such as a language
or a particular configuration file. Omit it for skills selected by the task
alone. Keep `description` either way: paths supplement task-based selection.

`paths` is an optional YAML list of workspace-relative globs. Any matching
pattern can trigger a reminder. `**/*.rs` matches Rust files at any depth;
`src/*.rs` matches only files directly in `src/`. Use relative patterns, not
absolute paths or `~` paths. Files outside the workspace do not match.

After a successful `read` of a matching file, pi reminds the model to load the
skill. A path match does not load the body or block edits. Directory listings,
glob results, file access through bash, and writing a new file do not trigger
this reminder.

Reminders repeat until the full instructions load successfully. Loading only
a reference file or receiving truncated instructions does not count.
Compaction resets loaded skills; resuming restores the state recorded in the
session. For the full runtime behavior, read
`skill(name: "pi-usage", file: "references/tools.md")`.

## 3. Test it

Choose checks proportional to the change and its risk.

For a mechanical metadata edit, such as adding `paths` to existing skills,
check YAML parsing, supported fields, and glob syntax. Inspect the diff for
the requested values and unrelated changes. Stop when these checks pass.
Expand into runtime verification only when concrete evidence identifies a
runtime problem relevant to the task.

For a new skill, or other changes to selection or execution behavior, use
representative prompts:

1. Write two or three prompts a real person would type: concrete files, real
   context, and one near-miss that must not reach for the skill.
2. Run each prompt twice with `subagent`, in one message: once with the skill
   (tell it to read `<dir>/SKILL.md` first and follow it) and once without. Give
   both runs the same prompt and the same input files.
3. Show the person both results side by side, and ask which is better and why.
   Their judgement decides: you wrote the skill, so you cannot judge it blind.

## 4. Revise

Fix what the selected checks exposed. Rerun the affected checks after further
changes. Stop when the requested result is verified; report remaining uncertainty.

Do not write a skill that hides what it does: no data collection, no
destructive default, nothing the person would object to after reading it.
