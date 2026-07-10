# Idiomatic Ruby & Rails — Lessons

Sources: the Ruby docs, the Ruby Style Guide, the Rails Guides, *The Rails Doctrine* (DHH), *POODR* and *99 Bottles of OOP* (Sandi Metz — see the dedicated `sandi-metz-design` skill for the design philosophy itself), the various *Practicing Rails* / *Rebuilding Rails* / *The Rails 7 Way* / Confident Ruby tradition, and the cumulative wisdom of fifteen years of Rails community blog posts.

The Ruby/Rails ecosystem is opinionated. Most disagreements have been litigated; following the convention is almost always cheaper than diverging.

## The Rails Doctrine (paraphrased)

DHH wrote *The Rails Doctrine* in 2016 to enumerate the values Rails encodes. The relevant ones for daily work:

1. **Optimize for programmer happiness.** Ruby is the language; Rails is the framework. The whole stack is biased toward "code that's nice to write and read" over "code that's optimal to execute."
2. **Convention over configuration.** Pick a convention; document it; default everyone to it. Customize only when you have a reason.
3. **The menu is omakase.** Rails picks your defaults. The point isn't that they're the best in isolation; it's that they're chosen, integrated, and maintained.
4. **No one paradigm.** Rails is OO with functional flavors, MVC with patterns layered on. Don't try to make it "pure" anything.
5. **Beautiful code matters.** Rails reads as English partly because Ruby allows it and partly because the framework names things carefully.
6. **Provide sharp knives.** Rails doesn't paternalize. Metaprogramming, monkey patching, dangerous gems — they're available; you're trusted.
7. **Value integrated systems.** Rails is intentionally a full-stack framework. A monolith with a clear codebase usually beats an over-distributed one.
8. **Progress over stability.** Rails moves fast. Major versions break things. The trade-off is that Rails stays current.
9. **Push up a big tent.** Many disagreements get embraced as configuration: ERB vs HAML, Minitest vs RSpec, Sidekiq vs SolidQueue. All ride along.

These values explain why "the Rails way" exists and why fighting it costs more than it saves.

## Ruby's quirks worth understanding

### Everything is an object — and a method call

`1 + 2` is `1.+(2)`. Operators are methods you can override. Even keywords like `if` and `while` are *almost* method calls — they're statements, but Ruby's design pulls strongly in this direction.

`nil.to_s` is `""`. `nil.to_a` is `[]`. The "everything responds to something" property makes Ruby code fluent.

### Open classes

You can reopen any class and add methods, even on standard library types:
```ruby
class String
  def shout
    upcase + "!"
  end
end
"hello".shout   # "HELLO!"
```

Used judiciously, it's elegant. Used carelessly, it's chaos. Modern style: use `Refinements` for scoped extensions, or extract a helper method:
```ruby
module StringExtensions
  refine String do
    def shout; upcase + "!"; end
  end
end

using StringExtensions
"hi".shout
```

Refinements are scoped to the file/module that opens them. Far safer than monkey-patching.

### Object identity and equality

- `equal?` — object identity (same memory).
- `==` — value equality (override per class).
- `eql?` — equality with strict type matching (used by `Hash`).
- `===` — case-equality (used by `case`).

Override `==` on your value types; override `hash` whenever you override `==`. Use `Comparable` mixin for ordering — define `<=>` once and get `<`, `<=`, `==`, `>=`, `>`, `between?` for free.

### Method missing & friends

```ruby
class DynamicAttrs
  def initialize(hash)
    @h = hash
  end

  def method_missing(name, *args, &block)
    if @h.key?(name)
      @h[name]
    else
      super
    end
  end

  def respond_to_missing?(name, _include_private = false)
    @h.key?(name) || super
  end
end
```

Always pair `method_missing` with `respond_to_missing?` — without it, things like `.respond_to?` and tab completion lie.

In modern Ruby, prefer `define_method` (less magical, faster, debuggable) when you can enumerate the methods up front. Reach for `method_missing` only when methods are truly dynamic.

### Singletons / `self.class` / metaclasses

Every object has a singleton class (sometimes called metaclass) that holds methods only that object answers to:
```ruby
str = "hi"
def str.shout; upcase + "!"; end
str.shout                # ok
"another".shout          # NoMethodError
```

Class methods are just instance methods on the class's singleton class:
```ruby
class Foo
  def self.bar; "hi"; end
end
# equivalent:
class Foo
  class << self
    def bar; "hi"; end
  end
end
```

The `class << self ... end` block is where you put many class-level definitions when there are several.

### Comparable, Enumerable

`Enumerable` is the source of `map`, `select`, `reduce`, etc. Mix it in by including the module and defining `each`:
```ruby
class Inventory
  include Enumerable
  def initialize(items); @items = items; end
  def each(&block); @items.each(&block); end
end

inv.map(&:name)
inv.select { |i| i.in_stock? }
```

`Comparable` similarly: include + define `<=>`.

### Blocks: `&` is the punctuation

`&:to_s` converts a symbol to a block: `[1,2,3].map(&:to_s)` is `[1,2,3].map { |x| x.to_s }`. Idiomatic when the block has one argument and one method call.

`yield` invokes the implicit block. `block_given?` checks if one was passed.

`&block` captures the implicit block as a Proc parameter — necessary if you need to forward it.

### Pattern matching

Ruby 3 added real pattern matching. It deconstructs hashes and arrays, binds variables, and is generally cleaner than `case ... when`.

```ruby
case response
in { status: 200, body: }
  process(body)
in { status: 4.. => code, body: { error: msg } }
  handle_client_error(code, msg)
in { status: 5.. }
  retry_later
end
```

Use it for parsing structured data: API responses, JSON, config. Combine with hash shorthand `body:` (binds the local variable `body` to the value) for terse code.

## The Rails request lifecycle

When a request comes in:
1. **Rack** receives it. Middleware chain runs (`Rack::Runtime`, `Rack::Cache`, `ActionDispatch::*`, custom middleware).
2. **Routes** (`config/routes.rb`) match path → controller#action.
3. **Controller** runs `before_action`s, the action method, then `after_action`s.
4. **Action** typically: pull params, call model/service, render view or redirect.
5. **View** renders ERB → HTML (or JSON via `respond_to`/`render json:`).
6. **After-action** middleware finishes; response goes back through the chain.

Knowing this:
- Middleware is the right place for cross-cutting concerns (logging, auth, locale, rate limiting).
- Routes are the right place for path conventions (RESTful resources).
- `before_action` is the right place for action-scoped setup that involves the request.

## ActiveRecord deep cuts

### Associations and the dependent option

```ruby
has_many :orders, dependent: :destroy
has_many :comments, dependent: :nullify
has_many :photos, dependent: :delete_all
```

- `:destroy` runs each child's destroy callbacks (slow, runs callbacks).
- `:delete_all` issues a single `DELETE` (fast, no callbacks).
- `:nullify` sets the FK to null (orphans the children).
- Don't omit it — silent orphaning is a bug factory.

Add DB-level cascades too (`on_delete: :cascade` in the migration) for defense in depth.

### Scopes and chaining

```ruby
scope :active, -> { where(active: true) }
scope :for_period, ->(start, finish) { where(created_at: start..finish) }
```

Scopes return `ActiveRecord::Relation`, so they chain: `User.active.for_period(...).order(:name)`.

Class methods on the model that return relations work too — they're equivalent to scopes:
```ruby
def self.active; where(active: true); end
```

The lambda style is preferred for one-liners; class methods are clearer for multi-line logic.

### Query methods that don't load records

- `pluck(:column)` — returns an array of values, no model instantiation.
- `count`, `exists?`, `any?`, `none?` — DB-side aggregates.
- `find_each(batch_size: 1000) { |record| ... }` — iterate huge tables in batches.
- `in_batches { |batch| ... }` — operate on relation batches without loading per-record.

### Eager loading: `includes`, `preload`, `eager_load`

- `includes` — Rails decides between `preload` (separate query) and `eager_load` (LEFT OUTER JOIN).
- `preload` — explicit separate query.
- `eager_load` — explicit JOIN (use when filtering on the association).

```ruby
# loads users + their orders in 2 queries, no JOIN
User.preload(:orders)

# JOINs so we can filter
User.eager_load(:orders).where(orders: { paid: true })

# Rails auto-selects: most often picks preload
User.includes(:orders)
```

Bullet gem catches missing eager loads; check it in CI.

### Concerns

A `Concern` is a module with a small DSL for declaring class methods, included blocks, and inheritance:
```ruby
module Trashable
  extend ActiveSupport::Concern

  included do
    scope :alive, -> { where(deleted_at: nil) }
  end

  def trash!
    update!(deleted_at: Time.current)
  end

  class_methods do
    def restore_all
      where.not(deleted_at: nil).update_all(deleted_at: nil)
    end
  end
end
```

Useful for genuine cross-cutting behavior (soft delete, slugging, auditing). Misused as a "place to dump methods that don't fit." If a concern is included in only one class, it's not a concern — inline it.

## ActiveSupport: the Ruby Rails wishes Ruby had

Rails extends Ruby's stdlib heavily. Highlights:

- `1.day.ago`, `5.minutes.from_now`, `Date.tomorrow.beginning_of_month` — date arithmetic.
- `"hello world".titleize`, `.parameterize`, `.pluralize`, `.singularize`.
- `Array.wrap(x)` — `nil → []`, scalar → `[scalar]`, array → array.
- `Hash.except`, `.slice`, `.deep_merge`, `.transform_values`.
- `Object#presence` (returns self if not blank, else nil).
- `Object#blank?` (nil, "", " ", [], {}).
- `Numeric#minutes`, `#hours`, `#days`.
- `String#squish`, `#truncate`, `#first`, `#last`.
- `Time.zone.now` (always use this in Rails — `Time.now` is local time).

These are core to Rails idiom. Learn them.

## Service objects (one of many names)

A service object is a plain Ruby class that does one thing. Common naming:
```
app/services/
  complete_order.rb
  cancel_subscription.rb
  process_signup.rb
```

Common interface: a class method or a `call`. Use a single command-shaped name:
```ruby
class CompleteOrder
  def self.call(order)
    new(order).call
  end

  def initialize(order, payment: PaymentProcessor.new, mailer: OrderMailer)
    @order = order
    @payment = payment
    @mailer = mailer
  end

  def call
    Order.transaction do
      @payment.charge!(@order)
      @order.update!(status: :paid)
      @mailer.confirmation(@order).deliver_later
    end
    Result.success(order: @order)
  rescue PaymentError => e
    Result.failure(error: e)
  end
end
```

Why service objects beat fat models / fat controllers:
- One reason to change.
- Easy to test (inject collaborators, no DB hits if you stub).
- Easy to compose: a higher-level service calls smaller ones.
- The name encodes intent: `CompleteOrder` is clearer than `Order#complete!`.

The `dry-rb` family (`dry-monads`, `dry-validation`, `dry-struct`) formalizes this with result types and validators. Worth adopting if your team is into it.

### Form objects

When a form doesn't map to a single model:
```ruby
class SignupForm
  include ActiveModel::Model
  attr_accessor :email, :password, :company_name

  validates :email, presence: true, format: URI::MailTo::EMAIL_REGEXP
  validates :password, length: { minimum: 12 }
  validates :company_name, presence: true

  def save
    return false unless valid?
    User.transaction do
      company = Company.create!(name: company_name)
      User.create!(email: email, password: password, company: company)
    end
    true
  end
end
```

Carries the changeset shape from Phoenix (Ecto) into Rails: validations + persistence on a non-AR object.

### Query objects

When a query is complex enough to be its own concern:
```ruby
class OrdersByCohort
  def initialize(relation = Order.all)
    @relation = relation
  end

  def call(cohort_start:, cohort_end:)
    @relation
      .joins(:user)
      .where(users: { signed_up_at: cohort_start..cohort_end })
      .group("DATE_TRUNC('week', orders.created_at)")
      .count
  end
end
```

Beats stuffing all queries into the model class.

## Testing patterns

### Minitest

```ruby
require "test_helper"

class OrderTest < ActiveSupport::TestCase
  def setup
    @user = users(:alice)
    @order = @user.orders.create!(total: 100)
  end

  def test_completes_successfully
    assert CompleteOrder.call(@order).success?
    assert @order.reload.paid?
  end
end
```

Use fixtures (`test/fixtures/users.yml`) for stable reference data; FactoryBot for ad-hoc objects.

### RSpec

```ruby
require "rails_helper"

RSpec.describe CompleteOrder do
  let(:order) { create(:order) }
  let(:payment) { instance_double(PaymentProcessor, charge!: true) }

  subject { described_class.new(order, payment: payment).call }

  it "marks the order paid" do
    subject
    expect(order.reload).to be_paid
  end

  context "when payment fails" do
    before { allow(payment).to receive(:charge!).and_raise(PaymentError) }
    it "returns a failure result" do
      expect(subject).to be_failure
    end
  end
end
```

Both work. Pick what your team uses; don't switch mid-project.

### System tests

Capybara + a real browser (Chrome via Selenium / Cuprite). Tests the full stack — slow, occasionally flaky, valuable for end-to-end confidence.

```ruby
def test_user_can_place_an_order
  visit new_order_path
  fill_in "Total", with: 50
  click_button "Place order"
  assert_text "Order placed"
end
```

Don't test every controller action this way; reserve for critical user paths.

## Performance patterns

1. **N+1 queries** are the most common slow query. Bullet gem catches them.
2. **Counter caches** (`belongs_to :post, counter_cache: true`) avoid `count` queries.
3. **Russian-doll caching** for nested view fragments.
4. **`pluck` over `.map(&:column)`** — DB returns just the column, no AR cost.
5. **`find_each` over `each`** for batched iteration on large tables.
6. **Database indexes** on every queried column. Migration: `add_index :table, :column`.
7. **Background jobs** for anything > 200ms in a request path.
8. **HTTP caching** (`fresh_when`, `stale?`) for endpoints with idempotent reads.
9. **`select(:column1, :column2)`** when you don't need all columns.
10. **`includes` strategically** — not on every query; only where you'll use the association.

## Security defaults

- **Strong parameters** for all controller input.
- **CSRF protection** (`protect_from_forgery`) for browser-served apps.
- **`rails credentials:edit`** for secrets, not env vars (decryptable; key in `RAILS_MASTER_KEY`).
- **`bcrypt` / `has_secure_password`** for password hashing.
- **`devise` or hand-rolled** for auth. Hand-rolled is more work but you understand it; devise is fast but a black box.
- **`pundit` or `cancancan`** for authorization. Per-action, per-record checks.
- **SQL injection prevention**: never `where("name = #{params[:name]}")`. Always parameterize: `where("name = ?", params[:name])` or `where(name: params[:name])`.
- **Mass assignment prevention**: strong params handle this.
- **`brakeman`** for static security analysis; runs in CI.
- **`bundler-audit`** for known-vulnerable gems.

## Deployment

- Heroku-style buildpacks → easy, opinionated, gets expensive.
- Render / Fly / Railway → modern PaaS alternatives.
- Self-hosted: Kamal (DHH's deployer) → opinionated, simple, single command from `git push` to live.
- Docker → standard for portability; the official Ruby image works as base.
- Capistrano → older but solid; fewer teams use it now.

Modern Rails defaults to PostgreSQL; SQLite is now production-viable for small apps (Rails 8 gives it serious attention).

## Common patterns and pitfalls

1. **God models.** When `Order` has 50 methods, extract: presenters, services, query objects, value objects.
2. **Concern-pile.** When you have `app/models/concerns/` with 30 modules each used once, you've recreated the god model with extra steps.
3. **Callback chains.** `before_save`, `after_create`, `after_commit` — easy to write, hard to test, surprising in jobs/console. Move business logic to services.
4. **Fat helpers.** `app/helpers/` shouldn't have business logic. Helpers format; presenters compute.
5. **Skinny controller, fat model** is half-true. Skinny controllers, **services for actions**, models for queries + persistence.
6. **`current_user.x.y.z` in views.** Views shouldn't dig through associations — push the work to a presenter or query.
7. **`if Rails.env.production?`** in business logic. Push environment differences to configuration.
8. **Rolling your own auth in 2025.** `devise` for password auth, `omniauth` for OAuth, `JWT` for tokens. Hand-rolled if you have time and the audit budget.

## Final aphorism

Rails optimizes for the team size you have, not the team size you imagine you'll have. Most "we need microservices / event sourcing / hexagonal architecture / DDD with three bounded contexts" energy is better spent writing service objects, query objects, and tests inside the monolith. Rails has carried massive companies (Shopify, GitHub, Basecamp, Airbnb at various stages) on the same stack. Trust the conventions; reach for sophistication when you've earned it.
