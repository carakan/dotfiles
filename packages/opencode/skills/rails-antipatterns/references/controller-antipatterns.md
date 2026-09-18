# Controller Anti-Patterns

## Fat Controller

Business logic in controller actions makes code hard to test, reuse, and maintain.

**Bad:**

```ruby
class OrdersController < ApplicationController
  def create
    @order = current_user.orders.build(order_params)
    @order.total = @order.line_items.sum { |li| li.product.price * li.quantity }
    @order.tax = @order.total * TaxRate.for(@order.shipping_address)
    @order.shipping = ShippingCalculator.cost(@order)

    if @order.total > 1000
      @order.discount = @order.total * 0.1
      @order.total -= @order.discount
    end

    if @order.save
      OrderMailer.confirmation(@order).deliver_later
      InventoryService.reserve(@order.line_items)
      Analytics.track('order_placed', amount: @order.total)
      redirect_to @order, notice: 'Order placed!'
    else
      render :new, status: :unprocessable_entity
    end
  end
end
```

**Good** — extract to a service object (see `service-patterns` skill):

```ruby
class OrdersController < ApplicationController
  def create
    result = PlaceOrder.call(params: order_params, user: current_user)

    if result.success?
      redirect_to result.order, notice: 'Order placed!'
    else
      @order = result.order
      render :new, status: :unprocessable_entity
    end
  end
end
```

## Non-RESTful Custom Actions

Proliferating custom actions instead of extracting new resources.

**Bad:**

```ruby
# config/routes.rb
resources :posts do
  member do
    post :publish
    post :unpublish
    post :archive
    post :unarchive
    post :feature
    post :unfeature
  end
end
```

**Good** — model state changes as RESTful resources:

```ruby
# config/routes.rb
resources :posts do
  resource :publication, only: [:create, :destroy]
  resource :archive, only: [:create, :destroy]
  resource :feature, only: [:create, :destroy]
end
```

```ruby
class Posts::PublicationsController < ApplicationController
  def create
    @post = Post.find(params[:post_id])
    @post.publish!
    redirect_to @post, notice: 'Post published.'
  end

  def destroy
    @post = Post.find(params[:post_id])
    @post.unpublish!
    redirect_to @post, notice: 'Post unpublished.'
  end
end
```

## Blocking External Calls in Request Cycle

Calling external APIs synchronously makes requests slow and fragile.

**Bad:**

```ruby
class UsersController < ApplicationController
  def create
    @user = User.new(user_params)
    if @user.save
      StripeService.create_customer(@user)       # Blocks request
      MailchimpService.subscribe(@user.email)     # Blocks request
      SlackNotifier.notify("New user: #{@user.name}")  # Blocks request
      redirect_to @user
    else
      render :new, status: :unprocessable_entity
    end
  end
end
```

**Good** — move external calls to background jobs:

```ruby
class UsersController < ApplicationController
  def create
    @user = User.new(user_params)
    if @user.save
      SetupNewUserJob.perform_later(@user.id)
      redirect_to @user
    else
      render :new, status: :unprocessable_entity
    end
  end
end
```
