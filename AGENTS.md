# Coding standards

- **Ruby and OOP work:** Whenever writing, refactoring, or reviewing Ruby code — or object-oriented code in any language — ALWAYS use the `sandi-metz-design` skill first and follow its rules (the Metz Rules, dependency management, message-based design). This applies to all work in Ruby codebases, not just when design questions come up. Pair with the `idiomatic-ruby-and-rails` skill for Ruby/Rails conventions, and the `clean-code-and-refactoring` skill for changeability heuristics.

## Test-driven development

- **Default to test-first for all behavior changes.** Drive new behavior with the `tdd` skill (red-green-refactor with an observed failing test). If you can't write the test first, you don't understand the requirement well enough yet — stop and clarify before coding.
- **Bug fixes start with a regression test** that reproduces the original failure before you write the fix.
- **Exempt from test-first:** trivial mechanical edits — renames, comments, docs, formatting, config tweaks, lockfiles. Still run the existing suite afterward.
- **Anti-loop escape hatch:** if the same test or verification step is still failing after ~3 genuinely different attempts, STOP. Do not thrash or loop. Report exactly what was tried, what failed and why, and the honest current state — an accurate "stuck" report beats a fourth blind attempt.

## Testing rules

- One behavior per test — a failure should tell you what broke without reading the implementation.
- Test behavior, not implementation. Tests should survive a refactor; if renaming a private method breaks a test, the test is coupled to the wrong thing.
- Tests must be fast, isolated, and deterministic. Delete tests that don't earn their keep.
- Don't mock what you don't own — wrap third-party dependencies behind your own interface and mock that.
- Difficulty testing is a design signal. Restructure for testability before reaching for heavy mocking; when something genuinely can't be tested, say what isn't covered and why.

## Definition of done — "prove it"

Work is done when it has been proven to work, not when it plausibly works.

- **Verified, not assumed.** Never claim completion without evidence: a test that fails without the change and passes with it, a real run, a demo output. If you can't show it working, it isn't done.
- **Prove failure first.** A check that only ever passes proves nothing — show the test/guard/validation catching the bad case before showing the good case pass. For end-to-end proof of a feature or fix, use the `prove-it-works` skill.
- **Verify the reason, not just the outcome.** An error or rejection should reference the actual problem, not just exit non-zero.
- **Error paths are exercised.** Happy-path-only verification is incomplete.
- **Clean working tree.** No debug code, TODO hacks, or commented-out blocks left behind.
- **Docs match reality.** Comments, README sections, and docs referencing changed behavior get updated.
- **Report faithfully.** Failing tests, skipped steps, and unverified claims are stated plainly — never rounded up to "done."
