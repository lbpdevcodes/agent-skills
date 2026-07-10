---
name: prove-it-works
description: Prove a feature, fix, or behavior actually works end-to-end — failure first, then success — by constructing a realistic scenario, watching the code catch the bad case, then watching it pass the good case. Use when verifying work is truly done, validating a fix, proving a feature behaves as claimed, or when about to declare a task complete. Adapted from searlsco/prove_it's prove-feature methodology, generalized to any project.
---

# Prove it works (or doesn't)

The most common failure mode of AI-assisted coding is prematurely declaring
success: announcing a task complete without running the tests, without adding
tests, without running the code. This skill is the antidote. The output of a
proof is evidence a human can read — a transcript, test output, a demo — not
an assertion that things "should work."

## What "prove" means — read this first

**Proving something works means watching it do its actual job, not watching
the plumbing around it succeed.**

- If it's validation logic: feed it **actually invalid input** → see it
  **reject with a specific reason** → fix the input → see it **accept**.
- If it's a bug fix: reproduce the **original failure first** (on the old
  code path or with a regression test that fails without the fix) → apply
  the fix → see the same scenario pass.
- If it's a feature: construct the **real-world situation the feature exists
  to handle** → see the feature handle it → construct the situation it should
  refuse or ignore → see it refuse or ignore.
- If it's error handling: make the dependency **actually fail** (service down,
  bad state, wrong type) → see the error path produce the intended behavior.

The pattern is always the same: **construct a realistic situation where the
logic is exercised, then observe it both fail and succeed.**

### The critical question

Before proving anything, answer: **"What real-world situation does this code
exist to handle, and how will I simulate that situation?"** If you can't
answer that, you don't understand the change well enough to prove it yet.
Stop and think harder.

### Anti-patterns — do NOT do these

- **Success-only proof.** If you only show the happy path passing, you may
  have proved the code does nothing. A validator that always approves is
  broken. **Always prove it can fail/reject/deny before proving it can pass.**
  Failure-first is how you know the code has teeth.
- **Plumbing-only proof.** Showing that the route responds 200, the script
  exits 0, or the test file runs is testing the framework, not the change.
  The proof must exercise the specific logic that changed.
- **Trivial stand-ins.** Stub inputs like `exit 0`/`exit 1` or `{}` prove
  the harness handles codes and shapes — nothing about the behavior. Inputs
  must be realistic enough to exercise the real logic.
- **Config/setup-exists proof.** Showing that a file was created, a config
  parses, or a class loads is not proof of what happens when it's *used*.
- **Tests that pass either way.** A test that passes with and without the
  change proves nothing. Check by reverting (or stashing) the change and
  confirming the test fails.

## Method

### Step 1: Design the scenario before touching anything

Write down (as a short plan or comments):

1. **What does the change actually do?** Not which file it touched — what
   real-world thing does it detect, enforce, transform, or fix?
2. **What does a realistic failing input look like?** Actual bad code, actual
   invalid payload, actual down service — be specific.
3. **What does the passing version of the same scenario look like?** Same
   structure, problem fixed.
4. **What side effects should be observable?** Specific error messages, log
   entries, DB rows, rendered output — these prove the code understood the
   input rather than guessed.

### Step 2: Build the proof

Prefer the cheapest medium that genuinely exercises the logic, in this order:

1. **The project's own test suite** — a new test (or existing tests) run for
   real. For bug fixes this is the regression test: confirm it fails without
   the fix, passes with it.
2. **A real run of the app or script** — run the actual entry point against
   the failing scenario, then the passing one — launch the app for real and
   observe the behavior.
3. **A throwaway scenario** — when the suite can't reach the behavior, build
   a disposable project/fixture in a temp directory (never in the
   user's project, never touching real config or data), wire in realistic
   inputs, and drive the code through it.

### Step 3: Run it — failure first, then success

1. Run against the **bad input**. Assert not just that it fails, but that the
   **reason references the specific problem** (the field name, the function,
   the threshold). "Exited 1" is not proof; "rejected: `email` is missing"
   is.
2. **Fix the input** (or apply the fix under test), re-run, and see it pass.
   This confirms the code is sensitive to the input, not failing randomly.
3. **Check side effects** — logs, messages, written files — contain the right
   content.

### Step 4: Present the evidence

Show the actual output — test runs, terminal transcript, before/after — in
the final report. The transcript IS the proof. Summarize what was proven in
one line per scenario: what failed, why, and what now passes.

If the proof cannot be completed — the scenario can't be simulated, the
failure can't be reproduced, a dependency is unavailable — **say so plainly**.
"Proven except X, because Y" is a valid, honest outcome. "Done" without
evidence is not.

## Anti-loop discipline

Proving must not become thrashing. If the same check is still failing after
~3 genuinely different attempts (different hypothesis each time, not the same
edit re-tried), STOP. Report what was tried, what failed and why, and the
honest current state. An accurate "stuck" report is a successful outcome of
this skill; a fourth blind attempt is not.
