---
name: sandi-metz-design
description: "MANDATORY for all Ruby code and all object-oriented code in any language — writing, refactoring, or reviewing. Design objects the Sandi Metz way — small, dependency-aware, message-passing, refactored mechanically toward abstractions you couldn't have predicted. Also use when choosing between inheritance / composition / duck typing, smelling a god class, deciding what to test, or applying the Metz Rules. Sources: Practical Object-Oriented Design in Ruby (POODR), 99 Bottles of OOP, and Sandi's conference talks."
---

# Sandi Metz Design

The thesis: **the cost of code is the cost of changing it, and the way to make change cheap is to manage dependencies between small, well-named objects that communicate by sending messages.** Everything in Metz's work serves that thesis.

This skill is OO-design-specific. Pair with:
- `clean-code-and-refactoring` for general craft principles.
- `idiomatic-ruby-and-rails` for the language and framework conventions.

## The Metz Rules

Sandi proposed these as discipline-tools, not laws. They prevent the most expensive mistakes by forcing you to refactor early:

1. **Classes can be no longer than 100 lines of code.**
2. **Methods can be no longer than 5 lines of code.**
3. **Methods can take no more than 4 parameters** (a hash counts as one — but if the hash has more than 4 keys, you're cheating).
4. **Controllers can instantiate only one object** to do whatever needs to be done. Views can only know about one instance variable, and views should send messages only to that instance variable.

You may break the rules with permission from a pair / reviewer. The point is: when you find yourself wanting to break them, ask first whether the underlying smell can be cured.

## Single Responsibility

A class has a single responsibility when **you can describe it in one sentence using the word "and" zero times.** If you need "and," you have two classes hiding in one.

Test: ask each method "what is this method's responsibility?" If the answers cluster into two or three groups, extract.

The unit of "responsibility" is *reason to change* — Single Responsibility means having only one reason to change. If a class changes for both UI reasons and business-logic reasons, those are two responsibilities.

## Dependencies are the cost

A dependency is anything one object knows about another:
- The class name.
- The name of a method on it.
- The arguments a message takes.
- The order of those arguments.

Each is a tether. Each tether you can avoid is one less thing to change later.

**Reduce dependencies by:**
1. **Hiding instance variables behind `attr_reader`.** Even inside the class, send a message instead of touching the variable. The first place you hide a dependency is from yourself.
2. **Hiding data structures behind methods.** Don't `wheels[0].diameter` everywhere; expose `front_wheel_diameter` or wrap the data in a class.
3. **Isolating creation knowledge.** `Gear.new(chainring: 52, cog: 11)` should appear once. After that, the rest of the system shouldn't know how to construct a Gear.
4. **Removing argument order dependencies.** Use keyword arguments (or a hash). The caller doesn't need to remember positions.
5. **Depending on stable interfaces, not unstable implementations.** A method name on an injected collaborator changes less often than the class of the collaborator.

## The direction of dependencies

Dependencies should point from things that change frequently to things that change infrequently. The volatile depends on the stable.

If `Order` (which changes weekly) depends on `Currency` (which changes rarely), great. If `Currency` depends on `Order`, bad — every time you change Order, you risk breaking Currency.

When the natural dependency is wrong-way, **invert it**:
- Inject the dependency rather than constructing it.
- Define an interface (in Ruby, just a duck type — a method name) and make the dependent thing depend on the interface.
- The dependent class no longer mentions the concrete other class.

This is the heart of dependency injection. In Ruby:
```ruby
class Order
  def initialize(line_items:, payment_processor: PaymentProcessor.new)
    @line_items = line_items
    @payment_processor = payment_processor
  end

  def complete!
    @payment_processor.charge!(total)
  end
end
```

Tests can pass a fake processor; production passes the real one; the Order doesn't care which.

## Duck typing

A duck type is "any object that responds to these messages." Type by behavior, not class.

The classic example: `Trip#prepare` accepts a list of `preparers`. Each preparer responds to `prepare_trip(trip)`. They don't share a class; they share an interface. Cleaning crew, mechanic, and trip leader can all be preparers without inheritance.

When to reach for duck types:
- You have a `case` statement on class.
- Adding a new "kind of thing" requires editing existing code.
- You're tempted to make something inherit from another only to share one method.

The presence of `kind_of?`, `instance_of?`, or `class ==` in your code usually points at a missing duck type.

## Inheritance — only when you must

The rule: **inheritance is for specialization, not for code reuse.** If `B inherits from A` then "every B is an A" must be unambiguously true.

When to use inheritance:
- The subclasses are unambiguously specializations of the superclass.
- The superclass is abstract — never instantiated directly.
- Subclasses extend, not contradict, the superclass's behavior.
- Liskov holds: a subclass can be substituted for the superclass without breaking callers.

Refactoring toward inheritance:
1. Start with concrete classes that look similar.
2. Push common methods up to a superclass — but only after you've named the abstraction.
3. Use the **template method pattern**: the superclass calls hooks the subclass implements.
4. Subclasses override only the hooks; they never call `super` for shared logic. (If you need to extend rather than override, you're modeling something else.)

When inheritance breaks down: **use composition.** Composition is "X has a Y," inheritance is "X is a Y." When in doubt, compose. Sandi's Bicycle/Mountain Bike → Bicycle/Parts evolution in POODR is the canonical example: parts are *composed* into a bicycle rather than inherited.

## Modules and roles

A role is "what an object can do." Multiple objects may share a role without sharing a class.

In Ruby, modules express shared behavior across the role:
```ruby
module Schedulable
  def schedule(date)
    raise NotImplementedError
  end

  def lead_days
    raise NotImplementedError
  end

  def schedulable?(date)
    !scheduled?(date - lead_days)
  end
end
```

Vehicles, employees, mechanics — anything Schedulable — includes the module and provides the abstract methods. The module gives the role a name and a place to grow.

This is "interface inheritance" without the cliché Java baggage. Sandi treats roles as essentially identical to duck types — modules are a Ruby-specific way to make the role concrete.

## Message-passing as design

A program is a set of objects sending messages. Designing it well means:
1. **Naming the messages well** — the message says intent.
2. **Letting senders depend on the message, not the receiver** — duck typing.
3. **Pushing the right responsibility to the right object** — the receiver should be the one that "knows" how to do the work.
4. **Having only one reason to send a message** — if a message both queries and commands, split it (Command-Query Separation).

Sandi: "Tell, don't ask." Don't ask an object for its data and operate on it externally; tell the object to do the work itself. (Tempered by: don't tell when the receiver shouldn't know — sometimes querying is right. The judgment is whether the *behavior* belongs to the asker or the askee.)

The Law of Demeter operationalizes this: talk only to your immediate neighbors. `customer.order.shipping_address.zip` is two too many neighbors. Either expose `customer.shipping_zip` (delegation) or restructure so the asker doesn't need to know.

## The refactoring discipline

From 99 Bottles, the steady-state work is mostly mechanical:

### Shameless Green

Write the simplest code that passes the tests, even if it's ugly. Don't try to be clever. Don't preempt structure. Don't predict what the abstraction will be.

This is harder than it sounds. Engineers love to abstract early; Sandi argues the early abstraction is almost always wrong because you don't yet know what the right one is.

### Wait for the Third Use

Two pieces of similar code might be coincidence. Three is a pattern worth abstracting. Following this rule prevents most premature abstractions.

### The Flocking Rules

When you finally do refactor:
1. **Find the things that are most alike.**
2. **Find the smallest difference between them.**
3. **Make the smallest change that removes that difference.**

Repeat. The abstraction emerges; you don't impose it. You're not "designing" — you're following a procedure that produces the design.

### Make the change easy, then make the easy change

Kent Beck's phrase, internalized by Sandi: when a feature is hard to add, **don't add it.** First refactor the surrounding code into a shape that makes the feature trivial. Commit the refactor. Then add the feature in a clean, separate commit.

Two consequences:
- A single PR has one refactor commit and one feature commit, never both at once.
- Tests must already pass before the refactor; they must still pass after; the feature commit then adds tests for new behavior.

## Identifying when to refactor

Code smells worth chasing (in priority order):

1. **Comments explaining what the code does.** Replace with a method whose name is the comment.
2. **Long methods** (Metz Rule: ≤5 lines).
3. **Long parameter lists** (≤4 args; if you need more, you have a missing object).
4. **Duplicate code** (the prime smell — it points at a missing abstraction).
5. **Conditionals on type** (`case obj.class when X when Y`) — almost always polymorphism in disguise.
6. **Feature envy** (one method using another object's data more than its own).
7. **Data clumps** (3+ params traveling together — wrap them in a class).
8. **Primitive obsession** (a string for an email everywhere; wrap it in `Email`).
9. **God class** (Metz Rule: ≤100 lines; if it's longer, what is its responsibility really?).
10. **Liskov violations** (a subclass that overrides a method to throw / no-op).

Each smell has a refactoring step that addresses it directly.

## Testing

Sandi's testing rules emerge from her dependency rules:

1. **Test the public interface, not private methods.** Private methods change as you refactor; tests on them brittle the refactor.
2. **Test outgoing command messages with mocks** (the test asserts a message was sent).
3. **Test incoming query messages by asserting on the return value.**
4. **Don't test outgoing query messages.** They're tested by whoever calls them.
5. **Don't test framework code** — Rails has tests; trust them.

For collaborators you don't own (a payment processor, an email service): inject a fake. Ruby's loose typing makes this trivial; in Java you'd need an interface.

For roles played by multiple objects: write a *shared test* (or a `Test::SharedExamples`) that any role-player can run against itself. Liskov made executable.

## When tests hurt — they're telling you something

If a test is hard to write:
- The class has too many dependencies.
- It's hard to construct the SUT (system under test) without setting up the world.
- The thing being tested is doing more than one thing.

Listen. Don't add helpers to make the painful test pass — refactor the design until the test is easy.

If you find yourself stubbing many collaborators, the SUT has too many. If you find yourself testing implementation rather than behavior, you've testied at the wrong level.

## Reaping the benefits

Once you have small, dependency-aware, well-named objects:
- Adding a new feature is local — one new class, no edits to existing.
- Bugs are local — one place is wrong; fix and ship.
- Onboarding is fast — each class is readable.
- Testing is fast — small classes, fast tests, no setup.

Sandi calls this "reaping the benefits of design." It's the payoff for the discipline.

## Triggers (when to load this skill)

- Designing or refactoring OO code (especially Ruby/Rails).
- A class is getting too long; deciding how to split it.
- Considering inheritance vs. composition.
- A `case` on type appears.
- Tests are getting hard to write.
- You see a feature that's hard to add — the design needs work.
- Onboarding to a Ruby codebase that feels tangled.

## Anti-heuristics

- Pre-designing class hierarchies before writing concrete code. The hierarchy will be wrong.
- Big up-front "domain modeling." Start concrete, refactor toward abstractions.
- Inheriting to share three lines of code. Extract a module or compose instead.
- Reaching for design patterns by name ("we need a Visitor here"). Patterns are post-hoc names; if you need one you'll arrive at it via the smell, not by checking GoF.
- Adding tests after the design is set. Tests inform design — they're the first user of your interface.
- Treating the Metz Rules as religion. They're discipline. Break them when the discipline is paying for itself; respect them when it's not.
- Testing private methods because you "want coverage." Coverage of private methods is a metric, not a goal.
- Mocking everything. If your test mocks 5 collaborators, the SUT has 5 dependencies — fix the design.

See `lessons.md` for the deeper distillation of POODR and 99 Bottles, including the canonical examples (Bicycle, Schedule, Trip, Beer Verse).
