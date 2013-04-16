require 'spec_helper'

describe Ridley::ClientResource do
  subject { described_class.new(double('registry')) }

  describe "#regenerate_key" do
    let(:client_id) { "rspec-client" }
    before { subject.stub(find: nil) }

    context "when a client with the given ID exists" do
      let(:client) { double('chef-client') }
      before { subject.should_receive(:find).with(client_id).and_return(client) }

      it "sets the private key to true and updates the client" do
        client.should_receive(:private_key=).with(true)
        subject.should_receive(:update).with(client)

        subject.regenerate_key(client_id)
      end
    end

    context "when a client with the given ID does not exist" do
      before { subject.should_receive(:find).with(client_id).and_return(nil) }

      it "raises a ResourceNotFound error" do
        expect {
          subject.regenerate_key(client_id)
        }.to raise_error(Ridley::Errors::ResourceNotFound)
      end
    end
  end
end
