# The Flocking Rules — Walkthrough

A concrete, mechanical demonstration of refactoring two pieces of similar code into a shared abstraction using Sandi Metz's three rules:

1. Find things that are most alike.
2. Find the smallest difference between them.
3. Make the smallest change that removes that difference.

## The starting code

```ruby
class Verse
  def lines(n)
    case n
    when 0
      "No more bottles of beer on the wall, no more bottles of beer.\n" \
      "Go to the store and buy some more, 99 bottles of beer on the wall.\n"
    when 1
      "1 bottle of beer on the wall, 1 bottle of beer.\n" \
      "Take it down and pass it around, no more bottles of beer on the wall.\n"
    when 2
      "2 bottles of beer on the wall, 2 bottles of beer.\n" \
      "Take one down and pass it around, 1 bottle of beer on the wall.\n"
    else
      "#{n} bottles of beer on the wall, #{n} bottles of beer.\n" \
      "Take one down and pass it around, #{n-1} bottles of beer on the wall.\n"
    end
  end
end
```

Tests pass. We've reached Shameless Green. Now we want to absorb a change: support a "six-pack" verse. Before adding the feature, we listen to what the existing code wants.

## Step 1: Most alike

The four cases are all two-line couplets with the pattern:
```
{X} bottles of beer on the wall, {X} bottles of beer.
{action}, {Y} bottles of beer on the wall.
```

But the literals vary across cases. We pick the two **most alike** — `n` and `n=2`. They share structure; they differ in literal text:

```ruby
# n (else branch)
"#{n} bottles of beer on the wall, #{n} bottles of beer.\n" \
"Take one down and pass it around, #{n-1} bottles of beer on the wall.\n"

# n=2
"2 bottles of beer on the wall, 2 bottles of beer.\n" \
"Take one down and pass it around, 1 bottle of beer on the wall.\n"
```

## Step 2: Smallest difference

The smallest difference between them: **the `n=2` branch hardcodes "1 bottle" (singular) while the else branch produces "1 bottles" (plural).**

That's literally the only difference at `n=2`. Everything else is the same modulo string interpolation.

## Step 3: Smallest change to remove the difference

Move toward an abstraction that handles both. Introduce a helper that produces the right pluralization:

```ruby
def container(n)
  n == 1 ? "bottle" : "bottles"
end
```

And use it in *both* branches:

```ruby
when 2
  "2 #{container(2)} of beer on the wall, 2 #{container(2)} of beer.\n" \
  "Take one down and pass it around, 1 #{container(1)} of beer on the wall.\n"
else
  "#{n} #{container(n)} of beer on the wall, #{n} #{container(n)} of beer.\n" \
  "Take one down and pass it around, #{n-1} #{container(n-1)} of beer on the wall.\n"
```

Tests still pass.

## Repeat: most alike

Now `n=2` and `else` are even more similar. The only literal difference is `2` vs `n`. Replace `2` with `n`:

```ruby
when 2
  "#{n} #{container(n)} of beer on the wall, #{n} #{container(n)} of beer.\n" \
  "Take one down and pass it around, #{n-1} #{container(n-1)} of beer on the wall.\n"
```

But that's now identical to `else`. **Delete the `when 2` branch.**

```ruby
case n
when 0
  ...
when 1
  ...
else
  "#{n} #{container(n)} of beer on the wall, #{n} #{container(n)} of beer.\n" \
  "Take one down and pass it around, #{n-1} #{container(n-1)} of beer on the wall.\n"
end
```

Two cases reduced to one. Tests still pass. We've absorbed the structural similarity.

## Repeat: most alike (again)

Now `when 1` and `else` are most alike. The differences:
- `1` vs `n` → use `n`.
- "no more bottles" vs "0 bottles" → introduce a helper for the count.

```ruby
def quantity(n)
  n == 0 ? "no more" : n.to_s
end
```

Use it in both:

```ruby
when 1
  "#{quantity(n)} #{container(n)} of beer on the wall, #{quantity(n)} #{container(n)} of beer.\n" \
  "Take it down and pass it around, #{quantity(n-1)} #{container(n-1)} of beer on the wall.\n"
else
  "#{quantity(n)} #{container(n)} of beer on the wall, #{quantity(n)} #{container(n)} of beer.\n" \
  "Take one down and pass it around, #{quantity(n-1)} #{container(n-1)} of beer on the wall.\n"
```

Differences left: `n=1` says "Take it down and pass it around"; `else` says "Take one down and pass it around." Introduce a helper:

```ruby
def action(n)
  n == 1 ? "Take it down and pass it around" : "Take one down and pass it around"
end
```

Both branches now identical. Delete `when 1`.

## Repeat: most alike (again)

Now `when 0` and `else` are most alike. Differences:
- `0` vs `n` → use `n`.
- The action: "Go to the store and buy some more" vs "Take one down and pass it around".
- The "next" count: `99` vs `n-1`.

Update `action` to handle 0:

```ruby
def action(n)
  if n == 0
    "Go to the store and buy some more"
  elsif n == 1
    "Take it down and pass it around"
  else
    "Take one down and pass it around"
  end
end
```

Update `quantity` so `n-1` at `n=0` produces 99:

```ruby
def quantity(n)
  case n
  when 0  then "no more"
  when -1 then "99"
  else        n.to_s
  end
end
```

Hmm — but `n-1` at `n=0` is `-1`. Awkward but works.

Now `when 0` and `else` are identical. Delete the case.

```ruby
def lines(n)
  "#{quantity(n)} #{container(n)} of beer on the wall, #{quantity(n)} #{container(n)} of beer.\n" \
  "#{action(n)}, #{quantity(n-1)} #{container(n-1)} of beer on the wall.\n"
end
```

One method, three helpers. Tests still pass.

## What we actually built

Look at what just happened. The case statement vanished. In its place: three pure functions of `n` (`quantity`, `container`, `action`). Each handles its slice of variability. The `lines` method is now a template with three substitutions.

That's the abstraction. We didn't choose it; we **discovered** it by mechanically removing differences.

## Now add the feature

The original change was: support six-packs at `n=6`. With the current shape, that's localized:

```ruby
def quantity(n)
  case n
  when 0  then "no more"
  when -1 then "99"
  when 6  then "1 six-pack"      # add
  else        n.to_s
  end
end

def container(n)
  case n
  when 1 then "bottle"
  when 6 then "of"               # "1 six-pack of beer" — adjust
  else        "bottles"
  end
end
```

Two small changes, each in the helper that owns that variability. **The change was easy because we made it easy first.**

If we'd added the six-pack case to the original case-statement code, we'd have added a fifth `when 6` branch with all four lines duplicated. By refactoring first, we made it a one-line addition.

## What this teaches

1. **Abstractions come from the code, not from your head.** You don't decide the right shape; you let the code reveal it via the smallest difference.
2. **Each step is mechanical.** No leaps. Tests pass after every step. If they don't, you've moved too fast — back up.
3. **You earn changes.** Adding a feature gets cheap once you've paid down the structural debt.
4. **Resist polymorphism early.** A `BottleNumber` class hierarchy with `Default`, `Single`, `Empty`, `SixPack` subclasses is a *next* step — only after you've used helpers and seen them grow. Premature class extraction is one of the most expensive premature abstractions.

## When the helpers want to be a class

Eventually you may notice: `quantity(n)`, `container(n)`, `action(n)` all take the same `n`. Three functions taking the same argument is a class with `n` as state:

```ruby
class BottleNumber
  attr_reader :number

  def initialize(number)
    @number = number
  end

  def container; @number == 1 ? "bottle" : "bottles"; end
  def quantity;  @number == 0 ? "no more" : @number.to_s; end
  def action;    @number == 0 ? "Go to the store and buy some more" : "Take one down and pass it around"; end
end

def lines(n)
  current = BottleNumber.new(n)
  next_one = BottleNumber.new(n - 1)
  "#{current.quantity.capitalize} #{current.container}..., #{current.action}, #{next_one.quantity}..."
end
```

Now the conditionals are inside `BottleNumber`. To get a six-pack, subclass:

```ruby
class BottleNumber6 < BottleNumber
  def quantity; "1 six-pack"; end
  def container; "of"; end
end

def factory(n)
  case n
  when 6 then BottleNumber6.new(n)
  else        BottleNumber.new(n)
  end
end
```

That's the polymorphism step. Only after you've earned it.

## A discipline

Run this exercise on real code. Pick a class with two similar methods. Apply Flocking Rules. Watch how the abstraction emerges.

If you've done it three times, you'll never again "design" the abstraction up front — you'll wait, refactor, and find what was always there.
