# app/services/create_post.rb
class CreatePost
  include Callable

  def initialize(params, user)
    @params = params
    @user = user
  end

  def call
    post = @user.posts.build(@params)

    if post.save
      notify_followers(post)
      Result.success(post: post)
    else
      Result.failure(errors: post.errors.full_messages)
    end
  end

  private

  def notify_followers(post)
    NotifyFollowersJob.perform_later(post.id)
  end
end
