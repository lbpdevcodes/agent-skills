# Sandi Metz Design — Lessons

Sources: *Practical Object-Oriented Design in Ruby* (POODR, 2e), *99 Bottles of OOP* (2e, with Katrina Owen and TJ Stankus), Sandi's RailsConf / GoRuCo talks ("All the Little Things," "Nothing is Something," "Get a Whiff of This," "Polly Want a Message," "SOLID Object-Oriented Design").

## The arc of POODR

POODR is structured as a refactoring narrative. A naïve `Bicycle` class evolves under successive pressures — adding a Mountain Bike, then a Recumbent, then a Tandem — and at each step the design is rebuilt to absorb the change cheaply.

The chapters teach by example, not by lecture. You watch Sandi *not* design upfront, *not* anticipate, but follow signals from the code and end up at a clean, role-based, composed system.

### Ch. 1: Object-Oriented Design

Why design? Because requirements change, and code that's hard to change is expensive code. Design isn't about matching the world to a pre-existing structure — it's about arranging dependencies so future changes are local.

"Design is more the art of preserving changeability than it is the act of achieving perfection." Programs in production aren't done; they're momentarily quiet.

### Ch. 2: Designing Classes with a Single Responsibility

The first design move: take a class that does several things and identify its responsibilities by asking each method "what is your purpose?" Group methods that share a purpose; extract groups that don't fit.

The classic POODR example: a `Gear` class that knows about chainring/cog ratios *and* about wheel diameters. The wheel knowledge belongs to a `Wheel` class. Extracting the `Wheel` reduces Gear's reasons-to-change.

Specific tactics:
- Hide instance variables behind `attr_reader`. Inside the class, send messages to yourself instead of touching `@var`. The benefit: when the data shape changes, only the reader changes.
- Hide data structures. Don't pass arrays around with implicit positional meaning; wrap them in a class or a `Struct` with named accessors.
- Enforce single responsibility on methods, not just classes. Each method should describe what it does in a single line.

### Ch. 3: Managing Dependencies

A dependency is anything one class knows about another. Sandi enumerates them:
- Knowing the name of another class.
- Knowing a message's name.
- Knowing the arguments a message requires.
- Knowing the order of those arguments.

Each dependency is a place a future change can break you. The chapter is about removing as many as you can:

**Inject dependencies.** Don't construct collaborators inside a class; accept them. The class becomes oblivious to the concrete collaborator type — it just needs an object that responds to the right messages.

**Isolate dependencies.** When you can't avoid one, push it to a single place (often a wrapped method or a factory). The rest of the class talks to the wrapper.

**Remove argument-order dependencies.** Use keyword arguments (or a hash). The caller supplies a name; argument order doesn't matter.

**Manage dependency direction.** Volatile-depends-on-stable. If A changes more than B, A should depend on B, not the reverse. When the natural dependency goes the wrong way, invert by introducing an interface (a duck type) and depending on the interface.

### Ch. 4: Creating Flexible Interfaces

A public interface is the set of messages an object responds to. Design the public interface deliberately — it's the contract.

Sandi distinguishes:
- **Public** — methods that express the class's primary responsibility; explicit; tested; documented.
- **Private** — methods used internally; subject to change; not tested directly.

The public interface should describe "what" the object does, not "how." Implementation hides behind it.

The chapter introduces *Use cases as design tools*: write the sequence of messages a use case sends; the messages tell you what objects you need and what their public interfaces are. (Sandi calls this "trusting collaborators.")

### Ch. 5: Reducing Costs with Duck Typing

A duck type is an interface defined by behavior, not by class. Polymorphism without inheritance.

The example: a `Trip#prepare` method that calls `.prepare_trip(self)` on each preparer. Mechanic, TripCoordinator, Driver are all preparers. They share no class, only the message.

Without duck typing, the alternative is `case preparer.class when Mechanic ... when Coordinator ...` — and adding a new preparer means editing every such case statement. The duck type makes the code closed against new preparers.

Sandi's advice: when you see `kind_of?`, `instance_of?`, or a `case` on class, treat it as a smell — a missing duck type.

### Ch. 6: Acquiring Behavior Through Inheritance

Inheritance is for *specialization*. Subclasses are specialized versions of an abstract superclass.

The discipline:
1. Start concrete. Don't extract the superclass until you have at least two specializations.
2. Push behavior up to the superclass *only* when it's truly shared.
3. Use the **template method pattern**: the abstract superclass calls hook methods that subclasses fill in. Subclasses don't override main flow; they fill in variations.
4. The abstract superclass should never be instantiated directly. If you find yourself with sentinel cases or `if subclass == self.class`, reconsider.

Liskov: a subclass must be substitutable for the superclass without breaking callers. If a subclass throws "not supported" on some method, the inheritance is wrong — that subtype isn't actually a subtype.

The Bicycle/Mountain Bike example in POODR drives this home: the inheritance works initially, then breaks when Recumbent and Tandem don't fit. The fix is to abandon inheritance and **compose** instead.

### Ch. 7: Sharing Role Behavior with Modules

Some shared behavior isn't "is-a" but "behaves-as-a." A `Schedulable` role can be played by employees, vehicles, mechanics — they're not all instances of any common class.

Modules express roles. Include a module to take on the role:
```ruby
module Schedulable
  def lead_days
    raise NotImplementedError
  end

  def schedulable?(start_date)
    !scheduled?(start_date - lead_days)
  end
end
```

The module defines abstract methods (the role's requirements) and concrete methods (the shared behavior). Implementers fill in the abstract methods.

Modules in Ruby give role-based polymorphism without inheritance pyramids. They're also how Ruby achieves "multiple inheritance" without the complications of full multiple inheritance.

### Ch. 8: Combining Objects with Composition

The big shift: instead of "Bicycle inherits from MountainBike," **Bicycle has Parts.** Parts is an object that knows about the parts. Different bicycle styles get different `Parts` configurations.

Composition has-a relationships:
- A bicycle has parts.
- A trip has bicycles.
- An order has line items.

Composition is the default unless inheritance genuinely fits. Sandi argues this loud and often: when in doubt, compose. The reasons:
- Composition is more flexible — you can swap the composed object at runtime.
- Composition has shallower hierarchies — easier to understand.
- Composition avoids the fragile-base-class problem.

The chapter walks the Bicycle redesign: from inheritance hierarchy → small specialized classes → roles → composition. The end result is a small set of classes, each with a clear responsibility, none deeply inherited.

### Ch. 9: Designing Cost-Effective Tests

Testing chapter — but really a testing-philosophy chapter, since the tests express the design.

The taxonomy of messages:
1. **Incoming query messages** — assert on the return value (state-based testing).
2. **Incoming command messages** — assert on the side effect.
3. **Outgoing command messages** — assert that the message was sent (mock/expectation).
4. **Outgoing query messages** — *don't test*. Whoever owns them tests them.
5. **Self-sent messages** — *don't test*. They're implementation detail.

The implication: tests should pin down the *interface*, not the *implementation*. Refactor freely as long as tests still pass.

Tests of duck types: write a *shared example* that any role-player must satisfy. Run the same example against each implementer.

Tests of inheritance hierarchies: same — shared examples for the role; a few specific tests for what each subclass adds.

When you find a test that requires elaborate setup, listen — the SUT has too many dependencies. Refactor the design until the test is easy.

## The arc of 99 Bottles of OOP

POODR teaches design retrospectively (clean code as the destination). 99 Bottles teaches *the process of getting there*.

### Solutions compared (Ch. 1)

Four solutions to the song:
1. **Incomprehensibly Concise** — clever one-liner; impossible to read.
2. **Speculatively General** — anticipates extensions that never happen; over-architected.
3. **Concretely Abstract** — wraps every primitive in a poorly-named "abstraction."
4. **Shameless Green** — the dumbest code that works; honest about what it knows.

Shameless Green wins. It's not pretty, but it's clear, and it doesn't lie.

### Test-driving Shameless Green (Ch. 2)

Get to green as fast as possible. Tolerate duplication. Don't refactor before you have evidence (i.e., a third example).

Tests come first. Each test is a single, specific behavior. The test name should describe the behavior — "verse 99 of the song" not "test_verse_99."

Once green, you can pause. The next chapter brings a real change request, and now the design pressure is appropriate.

### Listening to change (Ch. 3)

A change request arrives: "6 bottles" should say "1 six-pack of bottles." Don't add the feature directly. *Listen.* The change tells you what abstraction is missing — the song is treating bottle counts as primitives.

The procedure:
1. Don't write the new code yet.
2. Refactor the existing code toward a shape where the change is trivial.
3. Apply the Flocking Rules.
4. When the design absorbs the change cheaply, add the change as a small commit.

This is where "make the change easy, then make the easy change" lives.

### The Flocking Rules (Ch. 3-4)

The mechanical refactoring procedure:
1. Find things that are most alike.
2. Find the smallest difference between them.
3. Make the smallest change that removes that difference.

Repeat. Abstractions emerge. You don't choose the abstraction; the code reveals it.

The reason it works: each step is small enough that you can verify (by running tests) without thinking. Big jumps are where bugs live; small jumps are mechanical.

### Open/Closed (Ch. 3, 6)

Open/Closed Principle: a class should be open to extension, closed to modification *with respect to a particular axis of change.*

The OCP is local. You make code open along the axis you currently need to extend. You don't try to make code "open to anything."

Adding a new bottle behavior (six-pack) is closed under the OCP if you can do it by adding a class, not by editing an existing one.

### Replace Conditionals with Polymorphism (Ch. 6)

A `case` on type is a class hierarchy in disguise. The mechanical conversion:
1. Each branch becomes a class.
2. Each class implements a common method (the message the case branches were dispatching).
3. A small factory chooses which class.
4. Callers send the message; the right class responds.

Result: adding a case = adding a class. No editing the dispatcher. The OCP is preserved.

The 99 Bottles example: bottle counts at boundaries (`0`, `1`, `2`, `6`, regular). Each gets its own `BottleNumber` subclass / case. Polymorphism replaces the if/else cascade.

### Liskov violations (Ch. 4-5)

Sandi explicitly walks Liskov violations and how to detect them:
- A subclass that returns `nil` from a method the superclass returns a value from.
- A subclass that throws "not supported."
- A subclass that strengthens preconditions or weakens postconditions.

The cure: either fix the subclass, or rethink whether the inheritance is appropriate (often: it isn't — extract a role / use composition).

### Manufacturing Intelligence (Ch. 7)

Factories: a small class whose only job is to create the right object. Sandi argues for "self-registering candidates" — each subclass tells the factory it can handle a case, rather than the factory hardcoding the catalog.

This is more advanced and not always necessary. The simpler factory (a `case` returning `Class.new`) is fine for many cases. The key is *isolating creation knowledge* in one place.

### Programming Aesthetic (Ch. 8)

Sandi's named procedure for writing methods:
1. **Pseudocode first.** Write what the method does in plain English.
2. **Refine the pseudocode** until it's clear and minimal.
3. **Translate** the pseudocode into code. Each pseudocode line becomes a small named method.
4. **Push object creation to the edge.** The center of the system shouldn't construct things; let creation happen at the boundary.

Combined with **Dependency Inversion** (the center depends on roles, not concrete types) and the **Law of Demeter** (talk to neighbors only), this produces small composable code.

### Reaping the Benefits (Ch. 9)

The final chapter is about tests. By the time the design is good, the tests should be easy to write, fast to run, and stable to refactor. Tests that aren't are signals — go back and fix the design.

Specifically:
- Test public roles. Don't test private internals.
- Use fakes / doubles for collaborators you don't own.
- Test behavior, not implementation.
- Delete tests that no longer carry information (because the behavior is exercised elsewhere or because the abstraction has moved).

## Sandi's catchphrases (worth memorizing)

- **"You can't predict the future, so don't try."** Don't anticipate; don't pre-architect; refactor when evidence accumulates.
- **"Make the change easy, then make the easy change."** The most-cited rule in OO refactoring; Beck's phrase, Sandi's tradition.
- **"Programs are read more than they are written, by the same author who wrote them."** Future-you is the user.
- **"Tests are alarms that go off when something breaks."** Not specifications, not documentation — alarms.
- **"Every class needs a reason to exist."** If you can't articulate the reason, the class is wrong.
- **"Methods should do one thing."** And classes should do one thing. The "thing" is a single responsibility, not a single line.
- **"Trust your collaborators."** Don't check what you've been given; if it's the wrong type, that's a bug.
- **"Don't test private methods."** They are implementation; they will change.
- **"Send a message, don't ask for state."** Tell, don't ask.
- **"Inherit only when you must."** The default is composition.
- **"There are no rules, only trade-offs."** The Metz Rules included.

## The cumulative discipline

Reading POODR and 99 Bottles together produces a discipline:

1. **Start concrete. Stay concrete.** Until you have evidence (a third use case or a failing change), don't abstract.
2. **Listen to change pressure.** When a feature is hard, the design is asking for a refactor first.
3. **Refactor mechanically.** Small steps, tests passing each time. Flocking Rules.
4. **Compose by default.** Use inheritance only for genuine specialization.
5. **Inject dependencies.** Make collaborators visible; let tests substitute fakes.
6. **Use duck types and modules** for shared behavior where inheritance is wrong.
7. **Push complexity to the edges.** The middle of the system depends on roles; the edges deal with concrete objects.
8. **Test behavior, not implementation.** Test the public interface; trust private methods to follow.
9. **Listen to your tests.** Hard tests = bad design.
10. **Aim for code that's cheap to change.** Not perfect; cheap.

Once internalized, you stop asking "what's the right design?" and start asking "what does the next small step ask of me?" The right design emerges as the answer.

## Exercises that build the muscle

Sandi often gives exercises in workshops:

- Take a 200-line god class. Identify its responsibilities. Extract one class per responsibility, one at a time, with tests passing throughout.
- Take a class that uses inheritance and convert it to composition.
- Take a `case` on type and replace with polymorphism.
- Take a method with 6 parameters and reduce to 2 by introducing parameter objects.
- Take a method that asks 3 layers deep (`a.b.c.d`) and refactor by introducing delegation or relocating the message.
- Take a brittle test (mocks 5 collaborators) and refactor the SUT until the test is simple.

If you can do these mechanically, you have the discipline. If you find yourself thinking "what should I do next?" — go back to the Flocking Rules; they tell you.

## Final aphorism

The Sandi Metz way is not a style; it's a *practice.* It's a habit of small refactors, dependency-awareness, and trusting collaborators. Like any practice, it gets faster with repetition. The first time you apply the Flocking Rules, you'll feel slow. The hundredth time, you'll write better code without thinking — and that's the point.
