---
name: ladder-of-inference
description: "Apply the Ladder of Inference to trace a conclusion, judgment, or decision back to its raw data — exposing the assumptions and interpretations that may have been skipped. Use when the user wants to check whether a conclusion is well-grounded, examine a snap judgment, avoid acting on incomplete reasoning, or understand why two people reach different conclusions from the same situation. Triggers: 'ladder of inference', '推理阶梯', 'check my reasoning', '检查推理', 'why did I conclude', 'am I jumping to conclusions', 'is this assumption valid'."
---

# Ladder of Inference

## The seven rungs (bottom to top)

1. **Observable data** — what actually happened; what anyone watching would have seen or heard
2. **Selected data** — which part of the data we noticed (filtered by prior beliefs)
3. **Interpretation** — what meaning we assigned to that data
4. **Assumptions** — what we took for granted in making that interpretation
5. **Conclusions** — what we decided based on the assumptions
6. **Beliefs** — what this conclusion reinforces or builds into our worldview
7. **Actions** — what we did or plan to do

We typically climb from rung 1 to rung 7 in seconds, skipping steps invisibly.

## Workflow

Given a conclusion, judgment, or planned action:

1. **Name the action/conclusion** — what is the top-of-ladder position being examined?

2. **Climb down** — work backwards rung by rung:
   - What belief supports this action?
   - What conclusion produced that belief?
   - What assumption underlies that conclusion?
   - What interpretation produced that assumption?
   - What data did I actually select to interpret?
   - What was the full set of observable data I could have selected from?

3. **Identify the jump** — where in the chain did reasoning skip a step or make an unverified leap?

4. **Test the weak rung** — what would change if that assumption or interpretation were wrong? What additional data would verify or falsify it?

5. **Rebuild if needed** — if the jump is material, re-climb with the corrected rung and state the revised conclusion.

## Output format

- Present as a top-down trace: action → belief → conclusion → assumption → interpretation → selected data → observable data.
- Mark the weakest or most questionable rung explicitly.
- End with: "The jump is at [rung]. If [assumption] is wrong, the conclusion changes to [X]." If the reasoning holds, say so clearly.
