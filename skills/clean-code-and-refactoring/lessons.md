# Clean Code & Refactoring — Lessons

Sources: *Clean Code* (Robert C. Martin), *99 Bottles of OOP* 2e (Sandi Metz, Katrina Owen, TJ Stankus — Ruby and JS editions), *Code Complete 2e* (Steve McConnell).

The three books rhyme. Martin gives rules. Metz gives a process. McConnell gives a 900-page reference grounded in research. Read together, the message is: code is read more than written, and most "good design" is the local discipline of removing duplication, naming things well, and taking small testable steps.

## From *Clean Code* (Martin)

**Meaningful names.** Choose names that reveal intent. `int d; // elapsed time in days` should be `int elapsedTimeInDays`. Avoid disinformation (`accountList` for a non-list). Make meaningful distinctions (`Customer`, `CustomerInfo`, `CustomerData` is noise). Use pronounceable, searchable names; avoid encodings (Hungarian notation, member prefixes). Class names are nouns; method names are verbs. Pick one word per concept (`fetch`/`retrieve`/`get` — pick one).

**Functions.** Small. Smaller than that. Do one thing, at one level of abstraction. Read top-down — every function should be followed by functions at the next level of abstraction (the *Stepdown Rule*). Switch statements that dispatch on type are usually polymorphism waiting to happen. Use descriptive names — long names beat short obscure ones. Few arguments. No side effects. Command-Query Separation: a function either changes state or returns information, not both.

**Comments.** "Comments are, at best, a necessary evil." Most are compensation for our failure to express ourselves in code. Good comments: legal headers, intent ("why this magic constant"), warnings, TODOs (sparingly), public API javadoc. Bad comments: redundant, mandatory, journal/changelog (use VCS), commented-out code, "noise" ("// default constructor"). Rename rather than explain when you can.

**Formatting.** Vertical openness separates concepts. Related things stay close. Variables declared near use. Short lines (≤120). Team agrees on a style and follows it; consistency beats individual preference.

**Objects vs. data structures.** Objects hide data and expose behavior; data structures expose data and have no meaningful behavior. Don't try to be both. The Law of Demeter is about objects, not data. `obj.getX().getY().doZ()` is a smell.

**Error handling.** Use exceptions, not return codes. Write `try` first (TDD-style for error paths). Provide context with each exception. Don't return `null`; don't pass `null`. Define exception classes by how the caller catches them, not by source.

**Boundaries.** Wrap third-party APIs at the boundary so changes don't ripple. Write *learning tests* against external libraries to lock in assumptions.

**Unit tests.** F.I.R.S.T.: Fast, Independent, Repeatable, Self-validating, Timely. One assert per test (loose rule — really: one *concept*). Tests deserve the same quality as production code. Tests enable change; without them, every change is risk.

**Classes.** Small. Single Responsibility. SRP measured by reasons to change. Cohesion: when methods share fields, the class is cohesive; when they don't, you have two classes hiding in one. Open/Closed: extend by adding code, not editing existing code. Depend on abstractions.

**Smells (Appendix).** Comments (redundant, misleading), environment (long build, long tests), functions (too many args, output args, flag args, dead code), general (multiple languages in one source, obvious behavior unimplemented, incorrect behavior at boundaries, overridden safeties, duplication, code at wrong level of abstraction, base classes depending on derivatives, too much information, dead code, vertical separation, inconsistency, clutter, artificial coupling, feature envy, selector arguments, obscured intent, misplaced responsibility, inappropriate static, prefer non-static, use explanatory variables, function names should say what they do, understand the algorithm, prefer polymorphism to if/else, follow standard conventions, replace magic numbers with named constants, be precise, structure over convention, encapsulate conditionals, avoid negative conditionals, functions do one thing, hidden temporal couplings, don't be arbitrary, encapsulate boundary conditions, functions should descend only one level of abstraction, keep configurable data at high levels, avoid transitive navigation), Java (long imports, constants vs. enums), names (descriptive, appropriate level of abstraction, standard nomenclature where possible, unambiguous, long scope = long names, avoid encodings, names describe side effects), tests (insufficient, use coverage, don't skip trivial tests, ignored test = ambiguity, test boundaries, exhaust bugs near other bugs, patterns of failure are revealing, coverage patterns are revealing, tests should be fast).

## From *99 Bottles of OOP* (Metz/Owen/Stankus)

The book takes the trivial "99 Bottles of Beer" song and uses it to teach an entire object-design discipline. The lessons:

**Rediscovering simplicity (Ch. 1).** Compares four solutions to the same problem: *Incomprehensibly Concise* (clever one-liner), *Speculatively General* (premature abstraction), *Concretely Abstract* (over-named primitives), and *Shameless Green* (the dumbest code that works). Shameless Green wins. It is honest about what it knows and refuses to predict what it doesn't. Use objective metrics — Source Lines of Code, Cyclomatic Complexity, ABC (Assignments/Branches/Conditions) — not feelings.

**Test-driving Shameless Green (Ch. 2).** Make it red, make it green, make it clean — but be patient on the "clean." Tolerate duplication during green. Don't refactor before you have evidence; tests first.

**Listening to change (Ch. 3).** When a new requirement arrives, *don't add it*. First study the change. The shape of the change tells you which abstraction is missing. Then refactor the code into that shape — and only then add the feature. **Make the change easy, then make the easy change.**

**The Flocking Rules (Ch. 3–4).** A mechanical refactoring procedure for finding abstractions:

1. Select things that are most alike.
2. Find the smallest difference between them.
3. Make the smallest change that removes that difference.
Repeat. The abstractions emerge from the code; you don't impose them.

**Open/Closed Principle (Ch. 3, 6).** Code is "open to extension, closed to modification" *with respect to a particular change*. The OCP is local, not global. You make code open in the dimensions you currently need to extend.

**Replace Conditionals with Polymorphism (Ch. 6).** A `case` on type is a class hierarchy in disguise. Convert by: extract a class per branch; give each the same interface; let a small factory choose. Result: adding a new case adds a class instead of editing the conditional.

**Liskov Substitution (Ch. 4–5).** Subtypes must be substitutable for their supertypes. Practically: don't override a method to throw "not supported"; don't strengthen preconditions or weaken postconditions. If you can't substitute, the inheritance is wrong.

**Data clumps & primitive obsession (Ch. 5).** Three primitives that travel together want to be a class. Wrapping them gives the abstraction a place to grow.

**Inversion of dependencies (Ch. 8).** Push knowledge of concrete classes to the edges of the system. The center should know about roles (interfaces), not implementations. *Push object creation to the edge.*

**Law of Demeter (Ch. 8).** Talk only to your immediate neighbors. `a.b.c.d` is a sign that you know too much about other people's structure.

**Programming aesthetic (Ch. 8).** Pseudocode → wishful thinking → real code. Imagine the code you wish you had, then make it exist. The gap between pseudocode and code is where good names live.

**Tests as the safety net (Ch. 9).** Test public roles, not private internals. Use fakes for collaborators you don't own. Test behavior, not implementation. Delete tests that no longer carry information.

The cumulative lesson: small, mechanical, evidence-driven steps produce better designs than upfront cleverness.

## From *Code Complete 2e* (McConnell)

Code Complete is the encyclopedic reference; the highest-leverage chapters are listed.

**Software construction is design (Ch. 5).** Design is "wicked": you don't fully understand a problem until you've solved it. Design heuristics: find real-world objects, find consistent abstractions, encapsulate, inherit only when it simplifies, hide secrets (information hiding), identify areas likely to change, keep coupling loose, look for common design patterns. Iterate. Design is non-linear and never "done"; you stop when it's good enough.

**Information hiding (Ch. 5, 6).** The single most powerful design tool. *Identify what is likely to change and hide it behind an interface.* Likely-to-change: business rules, hardware dependencies, I/O, non-standard language features, difficult-design areas, status variables, data-size constraints.

**High-quality routines (Ch. 7).** Why create a routine: reduce complexity, introduce an intermediate abstraction, avoid duplicate code, hide sequences, hide pointer ops, improve portability, simplify boolean tests, improve performance. *A routine should do one thing well.* Cohesion ranking: functional > sequential > communicational > temporal > procedural > logical > coincidental — aim for functional.

**Defensive programming (Ch. 8).** Validate inputs at module boundaries; trust internal callers. Assertions document assumptions and catch impossible conditions. Distinguish assertions (programmer errors) from error handling (expected runtime conditions). Choose between robustness (do something useful) and correctness (refuse to compute on bad input) — pick per context.

**Pseudocode programming process (Ch. 9).** Write pseudocode first, at the right level (intent, not syntax). Iterate the pseudocode until it's clear, then translate line by line into code. Pseudocode becomes the comments. Saves time over diving straight into code.

**Variables (Ch. 10–13).** Initialize close to first use. Each variable should have one purpose. Minimize scope (the *span* and *live time*). Group related variables. Use the most specific type. Magic numbers → named constants.

**Naming (Ch. 11).** Length: 8–20 characters is a sweet spot. Use the *problem domain*, not the solution domain (use `customerOrder`, not `linkedList`). Loop indexes can be short (`i`, `j`, `k`) only if scope is small. Make booleans read as predicates. Use opposites consistently. Don't abbreviate by removing vowels — you'll forget the rule. Common conventions matter more than any specific convention.

**Layout & style (Ch. 31).** Layout reflects logical structure. Use whitespace to group, not decorate. Fundamental theorem of formatting: good layout reveals the logical structure of code. Pure-block, begin-end-block, endline, and emulating-pure-block are the four common indent styles — pick one and apply consistently.

**Self-documenting code (Ch. 32).** Comments compensate for unclear code. Levels of comments: repeat-of-code (bad), explain-the-code (bad — fix the code), marker (TODO: ok), summary (good — saves reading), describe-intent (best). The Kernighan rule: "Don't comment bad code — rewrite it."

**Personal character (Ch. 33).** Discipline and humility do more than raw intelligence. Curiosity, honesty about limits, communication. Habits compound. The pros write code that other pros can read.

**Themes of integration & construction practices (Ch. 28–29).** Integration strategy matters: incremental beats big-bang. Daily build with smoke test. Continuous integration is a hygiene practice, not a heroic effort.

**Debugging (Ch. 23).** Debugging is a problem-solving process: stabilize the error, locate it, fix it, test it, look for similar errors. Most bugs are simple in retrospect; the hard part is reproducing reliably. *Don't change code at random.* Form a hypothesis; predict what changing X will do; verify. Keep a log. When stuck, take a break.

## Distilled into a checklist

Before merging:

1. Every name reads as intent without reading the body.
2. Every function does one thing at one level of abstraction.
3. No flag arguments, no >3 args without a reason.
4. No commented-out code, no noisy "what" comments — only "why".
5. No duplication that exists for the *same reason*.
6. Tests cover behavior; one fails per real defect; they run fast.
7. The change consists of separate refactor commits and one behavior commit.
8. Things likely to change are hidden behind an interface.
9. Public boundaries validate inputs; internals trust their callers.
10. The code reads top-down at decreasing abstraction.
