# Ruby/Rails Cheatsheet

A reach-for-it reference. Pair with `SKILL.md` for the rules and `lessons.md` for the why.

## Rails CLI essentials

```bash
# new app, opinionated
rails new myapp --database=postgresql --css=tailwind --javascript=esbuild

# generate
bin/rails generate migration AddArchivedAtToOrders archived_at:datetime
bin/rails generate model User email:string:uniq name:string
bin/rails generate scaffold Post title:string body:text
bin/rails generate controller Pages home about

# DB
bin/rails db:create db:migrate db:seed
bin/rails db:rollback STEP=1
bin/rails db:reset                      # drops, recreates, runs migrations + seeds
bin/rails db:setup                      # for new clones (no migration history)

# console
bin/rails c                              # production-safe by default
bin/rails c --sandbox                    # auto-rollback at exit

# routes
bin/rails routes -g orders               # grep
bin/rails routes -c OrdersController     # filter

# server
bin/rails server                         # dev
bin/rails server -e production -p 8080

# tests
bin/rails test                           # minitest
bin/rails test test/models/user_test.rb
bin/rails test test/models/user_test.rb:42
bundle exec rspec                        # rspec
bundle exec rspec spec/models/user_spec.rb:42

# tasks
bin/rails -T                             # list
bin/rails my:task                        # run
```

## ActiveRecord query patterns

```ruby
User.where(active: true).where("created_at > ?", 1.week.ago)
User.where.not(role: "admin")
User.where(role: %w[admin moderator])           # IN
User.where(created_at: 1.week.ago..Time.current)

User.includes(:posts).where(active: true)        # eager load (Rails picks)
User.preload(:posts)                             # 2 queries, no JOIN
User.eager_load(:posts).where(posts: { ... })    # JOIN, single query

User.find_each(batch_size: 1000) { |u| ... }     # batched scan
User.in_batches(of: 1000) { |b| b.update_all(...) }

User.pluck(:email)                                # array of strings
User.pluck(:id, :email)                           # array of arrays
User.group(:role).count                           # {role => count}
User.distinct.pluck(:role)

User.joins(:orders).where(orders: { paid: true })
User.left_outer_joins(:orders).where(orders: { id: nil })   # users with no orders

User.order(created_at: :desc, id: :desc)
User.limit(20).offset(40)

User.count                                        # SELECT COUNT(*)
User.size                                         # cached count if loaded
User.exists?(email: "x@y")                        # SELECT 1
User.find_by(email: "x@y")                        # nil if not found
User.find_or_create_by!(email: "x@y") { |u| u.name = "X" }

User.transaction do
  user.save!
  Audit.create!(...)
end
```

## ActiveRecord associations

```ruby
class Order < ApplicationRecord
  belongs_to :user
  belongs_to :coupon, optional: true
  has_many :line_items, dependent: :destroy, inverse_of: :order
  has_many :products, through: :line_items
  has_one :shipping_address, dependent: :destroy
  has_and_belongs_to_many :tags                   # rare; usually use through:

  accepts_nested_attributes_for :line_items, allow_destroy: true

  enum :status, { pending: 0, paid: 1, shipped: 2 }, prefix: true
  # generates: pending?, paid?, shipped?, status_pending!, etc.

  validates :total, presence: true, numericality: { greater_than: 0 }
  validates :reference, uniqueness: { scope: :user_id }

  scope :recent, -> { where("created_at > ?", 1.week.ago) }
  scope :for_user, ->(u) { where(user: u) }

  delegate :name, :email, to: :user, prefix: true
end
```

## Migrations

```ruby
class AddArchivedAtToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :archived_at, :datetime
    add_index :orders, :archived_at
    # FK with cascade
    add_reference :orders, :user, foreign_key: { on_delete: :cascade }, null: false, index: true
  end
end

# data backfill — separate task, never in migration body
class BackfillOrdersArchivedAt < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!     # for long-running, online migrations
  def up
    Order.in_batches do |batch|
      batch.update_all(archived_at: Time.current)
    end
  end
end

# safe column rename
def change
  safety_assured { rename_column :users, :name, :full_name }   # if using strong_migrations
end
```

## Controllers & strong params

```ruby
class OrdersController < ApplicationController
  before_action :require_login
  before_action :set_order, only: %i[show update destroy]

  def index
    @orders = current_user.orders.recent.includes(:line_items).page(params[:page])
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
    params.require(:order).permit(:total, line_items_attributes: %i[product_id quantity _destroy])
  end
end
```

## Routes

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
      resources :orders, only: %i[index show]
    end
  end

  # health check
  get "up", to: "rails/health#show", as: :rails_health_check
end
```

## ActiveSupport gems for daily use

```ruby
# time
1.day.ago
5.minutes.from_now
Date.tomorrow.beginning_of_month
Time.zone.now                            # always use this in Rails

# strings
"hello".titleize                         # "Hello"
"Some Title".parameterize                # "some-title"
"users".singularize                      # "user"
"order".pluralize                        # "orders"
"hello world!".truncate(8)               # "hello..."
"  spaced  string  ".squish              # "spaced string"

# hash/array
Array.wrap(nil)                          # []
Array.wrap("x")                          # ["x"]
{a: 1, b: 2}.except(:a)                  # {b: 2}
{a: 1, b: 2}.slice(:a)                   # {a: 1}
{a: {b: 1}}.deep_merge({a: {c: 2}})      # {a: {b: 1, c: 2}}
[1, 2, nil, ""].compact_blank             # [1, 2]
"".presence                              # nil
"x".presence                             # "x"
nil.blank?                               # true; "" .blank? true; " ".blank? true
```

## Background jobs

```ruby
class ProcessUploadJob < ApplicationJob
  queue_as :default
  retry_on Net::ReadTimeout, attempts: 3, wait: :exponentially_longer
  discard_on ActiveJob::DeserializationError

  def perform(upload_id)
    upload = Upload.find(upload_id)        # pass id, fetch fresh
    UploadProcessor.new(upload).call
  end
end

ProcessUploadJob.perform_later(@upload.id)
ProcessUploadJob.set(wait: 10.minutes).perform_later(@upload.id)
ProcessUploadJob.set(queue: :critical).perform_later(@upload.id)
```

## Service object skeleton

```ruby
class CompleteOrder
  Result = Struct.new(:success?, :order, :error, keyword_init: true)

  def self.call(order, **deps)
    new(order, **deps).call
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
      @mailer.with(order: @order).confirmation.deliver_later
    end
    Result.new(success?: true, order: @order)
  rescue PaymentError => e
    Result.new(success?: false, error: e)
  end
end
```

## Test scaffolds

```ruby
# minitest — note: project convention is `def test_*` form, not the `test "..."` macro
class OrderTest < ActiveSupport::TestCase
  def setup
    @user = users(:alice)
    @order = @user.orders.create!(total: 100)
  end

  def test_completes_successfully
    result = CompleteOrder.call(@order)
    assert result.success?
    assert @order.reload.status_paid?
  end

  def test_returns_failure_on_payment_error
    payment = Minitest::Mock.new
    payment.expect(:charge!, nil) { raise PaymentError }
    refute CompleteOrder.call(@order, payment: payment).success?
  end
end

# rspec
RSpec.describe CompleteOrder do
  let(:order) { create(:order) }
  let(:payment) { instance_double(PaymentProcessor, charge!: true) }

  subject(:result) { described_class.call(order, payment: payment) }

  it { is_expected.to be_success }

  it "marks the order paid" do
    result
    expect(order.reload).to be_status_paid
  end

  context "when payment fails" do
    before { allow(payment).to receive(:charge!).and_raise(PaymentError) }
    it { is_expected.not_to be_success }
  end
end
```

## Useful gem cocktail (Gemfile)

```ruby
gem "rails", "~> 7.1"
gem "pg"
gem "puma"

# core helpers
gem "bcrypt"                 # has_secure_password
gem "image_processing"        # Active Storage variants

# observability
gem "rails-i18n"

group :development, :test do
  gem "debug", platforms: %i[mri windows]
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
  gem "rubocop-performance", require: false
  gem "brakeman", require: false
  gem "bundler-audit", require: false
  gem "strong_migrations"
  gem "bullet"                       # N+1 detector
end

group :development do
  gem "web-console"
  gem "letter_opener"
  gem "annotate"                      # adds schema annotations to models
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "webmock"
  gem "vcr"
  gem "shoulda-matchers"
  gem "simplecov", require: false
end
```
