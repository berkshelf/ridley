require 'spec_helper'

describe Ridley::UserResource, type: 'wip' do
  subject { described_class.new(double('registry')) }
  let(:user_id) { "rspec-user" }
  let(:user_password) { "swordfish" }

  describe "#regenerate_key" do
    before { subject.stub(find: nil) }

    context "when a user with the given ID exists" do
      let(:user) { double('chef-user') }
      before { subject.should_receive(:find).with(user_id).and_return(user) }

      it "sets the private key to true and updates the user" do
        user.should_receive(:private_key=).with(true)
        subject.should_receive(:update).with(user)

        subject.regenerate_key(user_id)
      end
    end

    context "when a user with the given ID does not exist" do
      before { subject.should_receive(:find).with(user_id).and_return(nil) }

      it "raises a ResourceNotFound error" do
        expect {
          subject.regenerate_key(user_id)
        }.to raise_error(Ridley::Errors::ResourceNotFound)
      end
    end
  end
end
