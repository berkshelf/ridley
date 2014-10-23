require 'spec_helper'

describe Ridley::DataBagItemObject do
  let(:resource) { double('chef-resource') }
  let(:data_bag) { double('data-bag') }
  subject { described_class.new(resource, data_bag) }

  describe "#from_hash" do
    context "when JSON has a 'raw_data' field" do
      let(:response) do
        {
          "name" => "data_bag_item_ridley-test_appconfig",
          "raw_data" => {
            "id" => "appconfig",
            "host" => "host.local"
          },
          "json_class" => "Chef::DataBagItem",
          "data_bag" => "ridley-test",
          "chef_type" => "data_bag_item"
        }
      end

      it "returns a new object from attributes in the 'raw_data' field" do
        subject.from_hash(response).attributes.should eql(response["raw_data"])
      end
    end

    context "when JSON does not contain a 'raw_data' field" do
      let(:response) do
        {
          "id" => "appconfig",
          "host" => "host.local"
        }
      end

      it "returns a new object from the hash" do
        subject.from_hash(response).attributes.should eql(response)
      end
    end
  end

  describe "#encrypt_attributes" do

    before(:each) do
      resource.stub(encrypted_data_bag_secret: File.read(fixtures_path.join("encrypted_data_bag_secret").to_s))
      subject.instance_variable_set(:@iv, 'HzNFP+HkzSYIxpQpiAgVSA==')
    end

    it "encrypts value with version 1" do
      subject.attributes[:password] = "test"
      subject.encrypt_attributes

      subject.attributes[:password].encrypted_data.should == "1MkHPcHIC47i5jV1qzgBWIS9/MM8ZCqD5FcqmX2WqoM=\n"
      subject.attributes[:password].cipher.should == 'aes-256-cbc'
      subject.attributes[:password].version.should == 1
      subject.attributes[:password].iv.should == "SHpORlArSGt6U1lJeHBRcGlBZ1ZTQT09\n"
    end

    it "does not encrypt the id field" do
      id = "dbi_id"
      subject.attributes[:id] = id
      subject.encrypt_attributes
      subject.attributes[:id].should == id
    end
  end


  describe "#decrypt" do
    before(:each) do
      resource.stub(encrypted_data_bag_secret: File.read(fixtures_path.join("encrypted_data_bag_secret").to_s))
    end

    it "decrypts an encrypted v0 value" do
      subject.attributes[:test] = "Xk0E8lV9r4BhZzcg4wal0X4w9ZexN3azxMjZ9r1MCZc="
      subject.decrypt
      subject.attributes[:test][:database][:username].should == "test"
    end

    it "decrypts an encrypted v1 value" do
      subject.attributes[:password] = Hashie::Mash.new
      subject.attributes[:password][:version] = 1
      subject.attributes[:password][:cipher] = "aes-256-cbc"
      subject.attributes[:password][:encrypted_data] = "zG+tTjtwOWA4vEYDoUwPYreXLZ1pFyKoWDGezEejmKs="
      subject.attributes[:password][:iv] = "URVhHxv/ZrnABJBvl82qsg=="
      subject.decrypt
      subject.attributes[:password].should == "password123"
    end

    it "does not decrypt the id field" do
      id = "dbi_id"
      subject.attributes[:id] = id
      subject.decrypt
      subject.attributes[:id].should == id
    end
  end

  describe "#decrypt_value" do
    context "when no encrypted_data_bag_secret has been configured" do
      before do
        resource.stub(encrypted_data_bag_secret: nil)
      end

      it "raises an EncryptedDataBagSecretNotSet error" do
        expect {
          subject.decrypt_value("Xk0E8lV9r4BhZzcg4wal0X4w9ZexN3azxMjZ9r1MCZc=")
        }.to raise_error(Ridley::Errors::EncryptedDataBagSecretNotSet)
      end
    end
  end
end
