# spec/services/create_post_spec.rb
RSpec.describe CreatePost do
  let(:user) { create(:user) }
  let(:valid_params) { { title: "Test", body: "Content" } }

  describe ".call" do
    context "with valid params" do
      it "returns success" do
        result = described_class.call(valid_params, user)
        expect(result).to be_success
      end

      it "creates a post" do
        expect {
          described_class.call(valid_params, user)
        }.to change(Post, :count).by(1)
      end

      it "returns the post" do
        result = described_class.call(valid_params, user)
        expect(result.post).to be_a(Post)
        expect(result.post.title).to eq("Test")
      end
    end

    context "with invalid params" do
      it "returns failure" do
        result = described_class.call({}, user)
        expect(result).to be_failure
      end

      it "includes error messages" do
        result = described_class.call({}, user)
        expect(result.errors).to include("Title can't be blank")
      end
    end
  end
end
