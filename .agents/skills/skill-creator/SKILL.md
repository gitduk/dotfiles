---
name: skill-creator
description: Create or improve a skill for pi — draft it, test it on real prompts with subagents, and revise until it works. Use whenever the person wants a new skill, wants an existing skill edited or sharpened, or says a skill never triggers when it should.
---

# Create or improve a skill for pi

Adapted from `anthropics/skills`' `skill-creator` (Apache-2.0), cut to what pi
provides.

A skill is a directory holding `SKILL.md`. The model loads its body only when
the description matches, so the description does the triggering and the body
does the work.

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
one of the same name from the home directory. pi reads the directory on its
next turn, and the person gets the skill's `/name` command the next time they
type.

```markdown
---
name: a-z, 0-9, - and _, up to 64 characters; may be left out, and then the directory name is used
description: What it does and when to use it. Only this line rides every request.
---

The instructions to follow once the skill is loaded.
```

- `description` is required. Without it pi reports
  `skill skipped — <path>: SKILL.md has no description` to the person and never
  offers the skill to the model.
- State both halves in the description: what the skill does, and the requests
  that should reach for it. Keep it under 1000 bytes; pi folds it to one line.
- Keep the body short. Move procedures and examples into files beside it, and
  say when to read each one: pi lists those files and how to fetch them with
  `skill(name: "<name>", file: "<path>")` whenever the skill loads.
- Helper scripts stay in the skill's own directory. Its subdirectories are not
  more skills.

## 3. Test it

1. Write two or three prompts a real person would type: concrete files, real
   context, and one near-miss that must not reach for the skill.
2. Run each prompt twice with `subagent`, in one message: once with the skill
   (tell it to read `<dir>/SKILL.md` first and follow it) and once without. Give
   both runs the same prompt and the same input files.
3. Show the person both results side by side, and ask which is better and why.
   Their judgement decides: you wrote the skill, so you cannot judge it blind.

## 4. Revise

Fix what the comparison exposed, rerun the same prompts, and keep any case that
got worse. Stop when the person is satisfied, or when a round changes nothing.

Do not write a skill that hides what it does: no data collection, no
destructive default, nothing the person would object to after reading it.
