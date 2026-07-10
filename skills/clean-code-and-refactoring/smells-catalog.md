# Code Smells Catalog

A reach-for-it list of smells, grouped by severity, with a recommended refactoring move.

## Severity scale

- **🔴 Critical** — likely cause of bugs or perf issues; address before merging.
- **🟡 Worth fixing** — increases maintenance cost; address in next refactor pass.
- **🟢 Nuisance** — cosmetic / stylistic; fix when you're nearby.

## Scope smells

| Smell | Severity | Why it hurts | Move |
|---|---|---|---|
| God class (>200 LOC, >10 methods) | 🔴 | Multiple reasons to change; impossible to test in isolation | Extract classes by responsibility |
| Long method (>20 LOC; Sandi rule: >5 LOC) | 🟡 | Doing many things; hard to name | Extract method per concept |
| Long parameter list (>4 args) | 🟡 | Hard to call correctly; missing object | Introduce parameter object |
| Primitive obsession (string for email everywhere) | 🟡 | Validation scattered; no place for behavior | Wrap in a value object |
| Data clump (3+ params travel together) | 🟡 | Same set of fields appears across signatures | Extract a class |
| Feature envy (method uses another object's data more than its own) | 🟡 | Logic in the wrong place | Move method to the data's owner |
| Inappropriate intimacy (two classes touching each other's internals) | 🟡 | Tight coupling; one change breaks both | Push boundary; expose proper messages |
| Cyclic dependency between modules | 🔴 | Can't test or change either independently | Introduce a third role; invert one direction |

## Duplication smells

| Smell | Severity | Why it hurts | Move |
|---|---|---|---|
| Identical duplication | 🟡 | Bug fixes need N edits | Extract function |
| Similar-but-not-identical duplication | 🟢 then 🟡 | Wait for 3rd use; then Flock to abstraction | Apply Flocking Rules; introduce parameter or polymorphism |
| Parallel inheritance hierarchies | 🟡 | Adding a class requires adding two | Compose instead; extract role |
| Duplicate test setup | 🟢 | Tests fragile to setup changes | Extract helper or `setup` block; consider FactoryBot |

## Conditional smells

| Smell | Severity | Why it hurts | Move |
|---|---|---|---|
| `case` on type / `is_a?` / `kind_of?` | 🔴 | Open/Closed violation; new types require editing | Replace with polymorphism (one class per branch) |
| Switch statement returning different "kind" of result | 🟡 | Doing too many things | Extract per-case method or class |
| Long if/elsif chain on the same variable | 🟡 | Same as case on type | Hash dispatch or polymorphism |
| Flag argument (`fetch(force: true)`) | 🟡 | Function is two functions hiding | Split into two functions |
| Negative conditional that reads worse than positive | 🟢 | Cognitive load | Invert; rename predicate |
| Nested conditionals (>2 levels) | 🟡 | Hard to read; prone to bugs | Extract method; guard clauses |
| Conditional that replicates type check | 🔴 | Missing duck type | Introduce role / interface |

## Dependency smells

| Smell | Severity | Why it hurts | Move |
|---|---|---|---|
| Class instantiates its collaborators | 🟡 | Hard to test; rigid | Inject dependencies via initializer |
| Hardcoded class name in business logic | 🟡 | Future renames break unrelated code | Hide behind a method |
| Argument-order dependence | 🟡 | Caller has to remember positions | Use keyword arguments |
| Volatile-stable inversion (stable depends on volatile) | 🔴 | Stable code breaks on volatile change | Invert: introduce role; depend on role |
| Long message chain (`a.b.c.d`) | 🟡 | Demeter violation; many neighbors | Delegate or restructure |

## Naming smells

| Smell | Severity | Why it hurts | Move |
|---|---|---|---|
| Magic numbers | 🟡 | Intent unclear | Named constants |
| Vague names (`data`, `info`, `manager`, `helper`) | 🟡 | Class doesn't have a real responsibility | Rename to its actual job; if you can't, the class is wrong |
| Misleading name (returns more than it says) | 🔴 | Bugs compound | Rename or split |
| Name doesn't match role (`Calculator` that also persists) | 🟡 | Single Responsibility violation | Split or rename |
| Pluralization mismatch | 🟢 | Reads wrong | Match singular/plural to cardinality |
| Inconsistent vocabulary (fetch/get/retrieve mixed) | 🟢 | Cognitive load | Pick one verb per concept |

## Comment smells

| Smell | Severity | Why it hurts | Move |
|---|---|---|---|
| Comment explains *what* the code does | 🟡 | Better name would suffice | Extract method; better name |
| Comment is out of date | 🔴 | Misleads future readers | Delete or update |
| Commented-out code | 🟡 | Noise; git remembers | Delete |
| Section dividers in long file (`# ----- USERS -----`) | 🟡 | The file should be split | Extract files/classes |
| Mandatory javadoc-style on every method | 🟢 | Boilerplate; obscures intent | Document only public APIs |

## Test smells

| Smell | Severity | Why it hurts | Move |
|---|---|---|---|
| Test calls private methods directly | 🟡 | Brittle; test breaks on refactor | Test through public interface |
| Test setup is 30+ lines | 🔴 | SUT has too many dependencies | Refactor the SUT to take fewer collaborators |
| One test asserts on 5 things | 🟡 | When it fails, which one? | Split into multiple tests |
| Mocks of mocks of mocks | 🔴 | Testing mocks, not behavior | Use real objects or fewer collaborators |
| Tests share state | 🔴 | Order-dependent failures | Isolate; use `setup`/`teardown` |
| Slow tests (>1ms unit, >1s system) | 🟡 | Feedback loop suffers | Mock IO; profile setup |
| Eyeballing fixtures | 🟢 | Readability | Use FactoryBot / data builders |

## Performance smells (Rails-specific)

| Smell | Severity | Why it hurts | Move |
|---|---|---|---|
| N+1 query | 🔴 | Linear DB hits per record | `includes` / `preload` / `eager_load` |
| `.each` over a 100k row table | 🔴 | Memory blowup | `find_each(batch_size: 1000)` |
| `.count` on a relation that's already loaded | 🟡 | Extra `SELECT COUNT(*)` | Use `.size` or `.length` |
| Querying inside views | 🟡 | Logic in view; hard to optimize | Pull data in controller / presenter |
| Missing index on queried column | 🔴 | Sequential scan at scale | `add_index` migration |
| Fetching all columns via AR when 2 will do | 🟢 | Memory + bandwidth | `pluck` / `select` |
| Synchronous external API call in request path | 🔴 | User-blocking; can hang | Move to background job |

## Refactoring moves cheat sheet

For each smell, the typical mechanical refactor:

| Move | When |
|---|---|
| Extract Method | Long method; chunk has a name |
| Inline Method | Method body as clear as its name |
| Rename | Better name found |
| Move Method | Feature envy detected |
| Extract Class | Cohesive cluster of methods |
| Inline Class | Class no longer pulls weight |
| Hide Delegate | Demeter violation: caller traversing too deep |
| Remove Middle Man | Class is just forwarding; expose real one |
| Introduce Parameter Object | Long parameter list; parameters travel together |
| Replace Magic Number with Named Constant | Magic number in code |
| Replace Conditional with Polymorphism | Case on type / kind |
| Replace Type Code with Subclass | Type tag + behavior diverges by tag |
| Replace Inheritance with Delegation | Subclass uses only some superclass |
| Replace Delegation with Inheritance | Class is just forwarding all messages |
| Pull Up Method | Identical method in siblings |
| Push Down Method | Method only used by one subclass |
| Introduce Null Object | Many `if x.nil?` checks |
| Replace Error Code with Exception | Error returned via flag |
| Replace Exception with Test | Exception used for control flow |

## When NOT to refactor

- No tests cover the area. Add characterization tests first.
- Tight deadline + code is already shipped and working. Note debt; come back.
- Refactoring would cross a boundary you don't yet understand. Read first.
- You're designing for a feature that doesn't exist. Wait.
- The smell is a 🟢 nuisance and you're touching unrelated code.

## When to absolutely refactor

- A 🔴 smell will be touched as part of the change.
- The change is hard. ("Make the change easy, then make the easy change.")
- A bug pattern keeps recurring in the same area.
- You're onboarding a new developer and the code is the obstacle.
