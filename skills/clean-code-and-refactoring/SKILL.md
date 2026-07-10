---
name: clean-code-and-refactoring
description: Write code that other people (and future-you) can change cheaply. Use when authoring new code, reviewing a PR, smelling duplication or long methods, picking names, or deciding whether to refactor before adding a feature. Distills Clean Code (Martin), 99 Bottles of OOP (Metz), and Code Complete 2e (McConnell).
---

# Clean Code & Refactoring

The single thesis: **the cost of code is the cost of changing it.** Clarity beats cleverness; small reversible steps beat big rewrites; tests are how you make refactors safe.

## Decision-time heuristics

**Naming**

- A good name encodes intent so the body of the function isn't required to understand it. If you have to read the body to remember what it does, rename.
- Replace magic numbers and booleans with named constants/enums. `paint(true)` is unreadable; `paint(forceRefresh: true)` or `paint.force()` is.
- Pair-of-opposites should be lexically opposite: `add/remove`, `open/close`, never `add/destroy`.
- Class names: nouns for things, not verbs. Method names: verbs. Booleans read as predicates: `is*`, `has*`, `can*`.

**Functions**

- Do one thing, at one level of abstraction. If you can extract a meaningful name for a block, extract it.
- Arguments: 0 ideal, 1–2 fine, 3 suspect, 4+ almost always wrong. Long arg lists are unextracted objects.
- No flag arguments; split into two functions.
- Prefer return values to side effects; prefer pure functions to mutation when the choice is free.

**Comments**

- A comment is a failure to express intent in code. Most "what" comments should become better names. Keep "why" comments — context the code can't carry (regulatory reason, performance trick, surprising bug).
- Never check in commented-out code. `git` remembers.

**Refactoring discipline**

- **Make the change easy, then make the easy change.** If a feature is hard to add, refactor toward shape that makes it trivial first; commit the refactor; then add the feature.
- **Shameless Green** (Metz): start with the dumbest code that passes the tests. Don't preempt structure. Refactor when a *second* concrete case reveals the abstraction. Three is even safer.
- **Flocking Rules** (Metz):
  1. Find things that are most alike.
  2. Find the smallest difference between them.
  3. Make the smallest change that removes that difference.
- One refactor per commit; one behavior change per commit; never both at once.

**Smells worth chasing**

- Duplication (the prime smell — almost always points at a missing abstraction).
- Long method, long parameter list, long class.
- Feature envy (method that uses another object's data more than its own).
- Data clumps (same 3+ params travel together — make them a class).
- Primitive obsession (passing a `String email`/`int dollars` everywhere — wrap it).
- Shotgun surgery (one change → many files). Suggests a missing module boundary.
- Divergent change (one file changes for many reasons). Same diagnosis from the other side.

**When NOT to refactor**

- You don't have tests. Write characterization tests first.
- You're under deadline and the code is already shipped-and-works. Note the debt; come back.
- You'd be designing for a third use case that doesn't exist yet. Wait for it.

## Triggers (when to load this skill)

- "Review this code" / "what could be cleaner here?"
- About to add a feature to a messy file.
- About to name something (variable, function, class, file).
- See duplication, a 200-line function, or a method with 5+ args.
- Choosing between "fix it now" vs. "refactor first."

## Anti-heuristics (common mistakes)

- DRYing up code that *coincidentally* looks similar. The shape matters less than the reason for change. Two pieces of code are duplicates only if they will change for the same reason.
- "Clean = lots of small classes." Smallness is a side effect, not a goal. Small classes that hide nothing are noise.
- Over-applying SOLID. SRP, OCP, LSP, ISP, DIP are guides, not laws. Apply when you feel the corresponding pain.
- Treating tests as an afterthought to clean up later. Tests *enable* refactoring; without them you're frozen.

See `lessons.md` for the long-form lessons and chapter-by-chapter highlights from the four sources.
