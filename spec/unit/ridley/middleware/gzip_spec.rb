require 'spec_helper'

describe Ridley::Middleware::Gzip do
  let(:env) do
    Hashie::Mash.new(
      'response_headers' => {
        'content-encoding' => nil
      },
      'body' => nil
    )
  end

  subject { described_class.new }

  describe "#on_complete" do
    let(:run) { subject.on_complete(env) }

    context "when content-encoding is set to 'gzip'" do
      let(:secret) { "this is a secret zipped message" }

      before do
        env['response_headers']['content-encoding'] = 'gzip'
        io = StringIO.new
        writer = Zlib::GzipWriter.new(io)
        writer.write(secret)
        writer.close
        env['body'] = io.string
      end

      it "unzips the commpressed body" do
        run
        expect(env['body']).to eq(secret)
      end
    end

    context "when content-encoding is set to 'deflate'" do
      let(:secret) { "this is a secret deflated message" }

      before do
        env['response_headers']['content-encoding'] = 'deflate'
        env['body'] = Zlib::Deflate.deflate(secret)
      end

      it "inflates the compressed body" do
        run
        expect(env['body']).to eq(secret)
      end
    end

    context "when content-encoding is set to nothing" do
      before { env['body'] = 'not changed' }

      it "does not manipulate the body of the request" do
        run
        expect(env['body']).to eq('not changed')
      end
    end
  end
end
