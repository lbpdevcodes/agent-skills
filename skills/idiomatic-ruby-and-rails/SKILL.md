---
name: idiomatic-ruby-and-rails
description: Write Ruby and Rails the way the community writes them — blocks, attr_*, modules, ActiveRecord, scopes, strong parameters, the conventions Rails encodes. Use when authoring or reviewing Ruby/Rails code, choosing between class methods and scopes, picking between callbacks and service objects, designing controllers, deciding what belongs in a model, or asking "what's the Rails way to do X?" Sourced from canonical knowledge — Ruby docs, the Ruby Style Guide, the Rails Guides, the Rails Doctrine, POODR (paired with the dedicated `sandi-metz-design` skill).
---

# Idiomatic Ruby & Rails

Two ideas underwrite the whole stack:

1. **Ruby optimizes for programmer happiness.** Many ways to do anything; pick the one that reads as English.
2. **Rails optimizes for convention.** Defaults handle the boring 95%; you only customize the part that's actually unusual.

The skill: stop fighting the conventions, learn the idioms, and write code that the next Rubyist recognizes immediately.

## Ruby idioms that pay rent

### Blocks, procs, lambdas

A block is the closure-shaped argument every Ruby method can implicitly take:

```ruby
[1, 2, 3].each { |n| puts n }
File.open("x") { |f| f.read }   # closes automatically
```

Define methods that yield:

```ruby
def with_timer
  start = Time.now
  result = yield
  puts "took #{Time.now - start}s"
  result
end

with_timer { do_thing }
```

`yield` is the cheapest API surface in any language. Use it for resource lifecycles, callbacks, and "wrap this work."

`&block` captures a block as a Proc; `&proc` passes one back:

```ruby
def collect_with(items, &block)
  items.map(&block)   # forward
end
```

Lambdas vs procs: lambdas check arity and `return` from the lambda; procs are lenient and `return` from the enclosing method. Prefer `->` (stabby lambda) for first-class callables; reserve `Proc.new` / `proc` for legacy.

### Method visibility and `attr_*`

```ruby
class User
  attr_reader :id
  attr_accessor :name
  attr_writer :password   # rare

  private :internal_helper
end
```

`attr_reader` for read-only state; `attr_accessor` when you need both. Avoid `attr_writer` alone — usually a code smell.

`private` and `protected` mark internal methods. `private` = only callable without explicit receiver; `protected` = callable only by same-class instances. Use private freely; protected almost never.

### Modules and mixins

Modules are namespaces *and* mixins:

```ruby
module Discountable
  def discounted(pct)
    self.class.new(price: price * (1 - pct))
  end
end

class Product
  include Discountable
end
```

`include` adds instance methods; `extend` adds class methods (or extends a single object). `prepend` inserts above the class in the lookup chain — used to wrap methods.

Use modules for:

- Shared behavior across unrelated classes (mixin).
- Namespacing related classes (`MyApp::Billing::Invoice`).
- Constants and helper functions (`module Math; PI = 3.14; def self.add(a,b); a+b; end; end`).

### Symbols, strings, and `frozen_string_literal`

Symbols (`:name`) are immutable, interned, fast for hash keys / method names. Strings (`"name"`) are mutable.

Add `# frozen_string_literal: true` at the top of every file. Modern Ruby. Strings become immutable by default; mutation needs explicit `+@` or `dup`.

### Hash, keyword args, double splat

```ruby
def fetch(url:, timeout: 30, **options)
  ...
end

fetch(url: "/api", timeout: 5, retry: true)
```

Use keyword args for any function with >1 argument; positional args become unreadable past 2.

`**hash` at the call site forwards a hash as keyword args. Pattern: middleware-style wrappers that forward all arguments use `*args, **kwargs, &block`.

### Pattern matching (Ruby 3+)

```ruby
case payload
in { status: 200, body: { items: [first, *rest] } }
  process(first, rest)
in { status: 4.. => code }
  raise "client error #{code}"
in { status: 500.. }
  retry
end
```

Cleaner than nested `if`/`fetch`. Use for parsing structured data: API responses, JSON payloads, config files.

### Enumerable mastery

Most Ruby code is `Enumerable` chains. The toolkit:

| Method | When |
|---|---|
| `each` | Side effects, no result |
| `map` / `collect` | Transform each element |
| `select` / `reject` | Filter |
| `reduce` / `inject` | Fold to a single value |
| `each_with_object(acc)` | Build a collection without returning the accumulator each iteration |
| `group_by` | Partition by key |
| `partition` | Split into two arrays by predicate |
| `flat_map` | Map and flatten one level |
| `tally` | Count occurrences (Ruby 2.7+) |
| `chunk_while`/`slice_when` | Break into runs |
| `lazy` | Stream large/infinite enumerables |

Prefer `each_with_object({}) { |x, h| h[x.id] = x }` over `inject({}) { |h, x| h[x.id] = x; h }` — it returns the object automatically.

### `tap` and `then` (`yield_self`)

```ruby
User.new(name: "x").tap { |u| u.save }       # side effect, return self
fetch_data.then { |d| transform(d) }         # transform in a pipeline
```

`tap` for side effects; `then` for pipeline transformations. Together they enable readable method chains.

### Errors

```ruby
class InsufficientFunds < StandardError; end

def charge(amount)
  raise InsufficientFunds, "needed $#{amount}" if balance < amount
  ...
rescue InsufficientFunds => e
  notify_user(e.message)
  raise
end
```

Inherit from `StandardError`, not `Exception`. Define domain-specific exceptions. Use `raise` (single argument) when re-raising in a `rescue`.

### Style cheatsheet

- Two-space indent, no tabs.
- `snake_case` methods/variables, `CamelCase` classes/modules, `SCREAMING_SNAKE` constants.
- Predicate methods end in `?`; bang methods (mutate or raise) end in `!`.
- Use parentheses on method calls with arguments except for DSL-shaped contexts (`raise`, `puts`, `attr_reader`, Rails finders).
- Prefer `&&` / `||` to `and` / `or` (different precedence; `and`/`or` are control-flow keywords, rarely the right choice).
- Use `unless` for single-line negative conditions; avoid `unless` with `else`.
- Use string interpolation `"#{x}"` over concatenation.
- Use `%w(words)`, `%i(symbols)`, `%w[a b c]` for literal arrays of strings/symbols.
- Use `require` for third-party gems; `require_relative` for your own files.
- Write `def initialize(name:, email:)` — keyword args make call sites readable.

## Rails idioms

### Convention over configuration

Rails has strong opinions about file layout. Don't fight them:

```
app/
  models/      # ActiveRecord classes
  controllers/ # request handlers
  views/       # ERB / HAML templates
  helpers/     # view helpers (use sparingly)
  jobs/        # ActiveJob background workers
  mailers/     # ActionMailer classes
  channels/    # ActionCable for WebSockets
  services/    # plain-Ruby service objects (you add this)
  policies/    # auth policies (Pundit / your own)
config/
  routes.rb
  database.yml
  application.rb
db/
  migrate/
  schema.rb
```

The `app/` files autoload by class name (Zeitwerk in modern Rails). Naming things correctly *is* the configuration.

### ActiveRecord: schemas, associations, scopes

```ruby
class Order < ApplicationRecord
  belongs_to :user
  has_many :line_items, dependent: :destroy
  has_one :shipping_address

  enum :status, { pending: 0, paid: 1, shipped: 2 }

  validates :total, presence: true, numericality: { greater_than: 0 }

  scope :recent, -> { where("created_at > ?", 1.week.ago) }
  scope :for_user, ->(u) { where(user: u) }

  def total_with_tax
    total * 1.0875
  end
end
```

Conventions:

- One model per table; table name is the pluralized snake_case class name.
- Foreign keys are `model_name_id`.
- Timestamps (`created_at`, `updated_at`) are automatic if columns exist.
- Use `enum` for fixed-value columns (auto-generates scopes and predicates).
- Validations on the model (Rails-side) plus DB constraints (defense in depth).
- Scopes for reusable query fragments; prefer `-> { ... }` over class methods.

### Avoid callback abuse

Callbacks (`before_save`, `after_create`, `around_destroy`) are seductive and dangerous. They:

- Fire across all paths to the model (tests, console, jobs).
- Hide intent from the caller.
- Make tests slow and brittle.

Use them for genuinely cross-cutting concerns (timestamps, slug generation, normalization). For business logic — sending an email, charging a card, creating related records — use **service objects**:

```ruby
class CompleteOrder
  def initialize(order, payment_processor: PaymentProcessor.new)
    @order = order
    @payment_processor = payment_processor
  end

  def call
    Order.transaction do
      @payment_processor.charge!(@order)
      @order.update!(status: :paid)
      OrderMailer.with(order: @order).confirmation.deliver_later
    end
  end
end

# in controller:
CompleteOrder.new(@order).call
```

This pattern is the single biggest improvement you can make to a Rails codebase past 10k lines.

### Controllers: thin

```ruby
class OrdersController < ApplicationController
  before_action :require_login
  before_action :set_order, only: %i[show update destroy]

  def index
    @orders = current_user.orders.recent.includes(:line_items)
  end

  def create
    @order = current_user.orders.new(order_params)
    if @order.save
      redirect_to @order, notice: "Order placed"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_order
    @order = current_user.orders.find(params[:id])
  end

  def order_params
    params.require(:order).permit(:total, line_items_attributes: [:product_id, :quantity])
  end
end
```

Patterns:

- `before_action` to factor out auth and lookup.
- Strong parameters (`require`/`permit`) to whitelist incoming attributes.
- Find through associations (`current_user.orders.find`) to scope authorization automatically.
- Eager-load with `includes` to avoid N+1.
- Render with `status:` on validation failure (modern Rails uses 422).

If a controller has more than ~10 lines per action, business logic is leaking — extract a service object.

### Routes

```ruby
Rails.application.routes.draw do
  root "pages#home"
  resources :orders, only: %i[index show create] do
    member { post :pay }
    collection { get :recent }
  end
  namespace :admin do
    resources :users
  end
  scope module: :api, defaults: { format: :json } do
    namespace :v1 do
      resources :orders
    end
  end
end
```

- `resources` generates the seven RESTful routes; restrict with `only:`/`except:`.
- `member` / `collection` for non-CRUD actions.
- `namespace` for path + module nesting; `scope module:` for module without path.
- Avoid `match` and shallow nesting unless you really mean it.

### Views and helpers

Default to ERB. HAML/Slim if your team prefers, but don't introduce them mid-project.

Keep views dumb: render data, don't compute it. Push logic to:

- Decorators / presenters (Draper or hand-rolled) for view-specific formatting.
- Helpers for trivial cross-cutting (date formatting, URL building).
- Partials for reusable view fragments (`render partial: "form", locals: { order: @order }`).

Avoid deeply nested partials and `instance_variable`-leaking partials. Pass everything as locals.

### Background jobs

```ruby
class ProcessUploadJob < ApplicationJob
  queue_as :default
  retry_on StandardError, attempts: 5, wait: :exponentially_longer

  def perform(upload_id)
    upload = Upload.find(upload_id)
    UploadProcessor.new(upload).call
  end
end

ProcessUploadJob.perform_later(@upload.id)
```

Pass IDs (or globally-unique identifiers), not records — records may have changed by the time the job runs. Set retry policies. Use `perform_later` (queued) over `perform_now` (synchronous) by default.

Adapter: Sidekiq for production-grade Redis-backed queue; SolidQueue (Rails 8+) for DB-backed; Active Job's default test adapter for tests.

### Testing

The default is Minitest. Many teams use RSpec. Either is fine; use what your team uses.

Pyramid:

1. **Unit tests** for models / service objects / POROs — fast, no DB.
2. **Integration / system tests** for end-to-end flows.
3. **Request specs** (RSpec) or **integration tests** (Minitest) for controllers.

Tools: `factory_bot` for test data, `webmock` for HTTP stubs, `vcr` for recorded fixtures, `capybara` for browser-driven system tests.

`fixtures` are still excellent for reference data; use `factories` for ad-hoc objects per test.

### Migrations

```ruby
class AddArchivedAtToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :archived_at, :datetime
    add_index :orders, :archived_at
  end
end
```

Rules:

- Reversible. Use `change` when possible; fall back to `up`/`down`.
- Don't use models in migrations (they drift). Use raw SQL or `Order.reset_column_information` if you must.
- Heavy operations (backfills, data fixes) belong in a separate task, not a migration.
- Add indexes whenever you add a column you'll query on.
- `null: false`, defaults, and FKs at the DB level — not just Rails-level validations.

### Performance defaults

- Eager-load with `includes` / `preload` / `eager_load` — N+1 is the most common slow query.
- `bullet` gem in dev to flag missing eager loads.
- `find_each` for batched iteration over large tables.
- `pluck` for column-only queries (no AR instantiation).
- `counter_cache: true` on `belongs_to` to avoid `count` queries.
- Cache fragments / actions / Russian-doll-cache for slow views.
- Database indexes for every column in a `where`, `order`, `join`, or unique constraint.

### Configuration

- `config/credentials.yml.enc` for secrets (encrypted; key in `RAILS_MASTER_KEY` env var).
- `Rails.configuration` for environment knobs.
- `dotenv-rails` or env vars for truly per-environment values.
- Avoid `if Rails.env.production?` branching inside business code — push environment differences to configuration.

## Triggers (when to load this skill)

- Writing or reviewing Ruby / Rails.
- Designing a new model / controller / job / mailer.
- Choosing between callback, service object, concern, or job.
- Asking "what's the Rails way?" / "how do Rubyists usually solve this?"
- Onboarding to an existing Rails codebase.

## Anti-heuristics

- "Skinny controllers, fat models" → unbounded models. Skinny controllers, **service objects** when the model gets fat.
- Callbacks doing business logic. Use them only for normalization / housekeeping.
- Long-running work in controllers. Extract to a job.
- `before_action` chains 5 deep. Inline or extract.
- Concerns as a dumping ground. A concern that's used in one model is just a partial extraction without a name; pick a real name and a real abstraction.
- Reaching for metaprogramming. Almost always a class method, a module, or a refactor would do.
- Treating Rails like Java. Rails rewards trusting the conventions; rewards punish premature abstraction.
- Using `where(...)` in a controller. Put it in a model scope or a query object.
- `User.find_by(email: params[:email])` from anywhere outside an authentication path. Scope queries to a current user / tenant.
- Treating tests as optional. Rails is opinionated about testing too; the default scaffolding generates tests for a reason.

See `lessons.md` for deeper Ruby / Rails lessons, the Rails Doctrine, and pattern catalogs.
