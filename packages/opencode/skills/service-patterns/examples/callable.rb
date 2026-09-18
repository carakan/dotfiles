# app/services/concerns/callable.rb
#
# DRY up the .call class method pattern across service objects.
# Include in any service to get a `.call` class method that delegates
# to `new(...).call`.
#
# Usage:
#   class CreatePost
#     include Callable
#
#     def initialize(params, user)
#       @params = params
#       @user = user
#     end
#
#     def call
#       # ...
#     end
#   end
#
#   CreatePost.call(params, user)

module Callable
  extend ActiveSupport::Concern

  class_methods do
    def call(...)
      new(...).call
    end
  end
end
