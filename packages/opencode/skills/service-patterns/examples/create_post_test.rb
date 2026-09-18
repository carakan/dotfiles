# test/services/create_post_test.rb
class CreatePostTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @valid_params = { title: "Test", body: "Content" }
  end

  test "returns success with valid params" do
    result = CreatePost.call(@valid_params, @user)
    assert result.success?
  end

  test "creates a post" do
    assert_difference "Post.count", 1 do
      CreatePost.call(@valid_params, @user)
    end
  end

  test "returns the post" do
    result = CreatePost.call(@valid_params, @user)
    assert_kind_of Post, result.post
    assert_equal "Test", result.post.title
  end

  test "returns failure with invalid params" do
    result = CreatePost.call({}, @user)
    assert result.failure?
  end

  test "includes error messages on failure" do
    result = CreatePost.call({}, @user)
    assert_includes result.errors, "Title can't be blank"
  end
end
