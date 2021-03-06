require "spec_helper"

describe ShippingEasy::Http::Request do

  let(:http_method) { "post" }
  let(:params) { { :page => 1 } }
  let(:base_url) { "https://www.test.com" }
  let(:relative_path) { "/orders" }
  let(:body) { { order_number: "1234" } }
  let(:api_key) { "12345678ASGHSGHJ" }
  let(:api_secret) { "12345678ASGHSGHJ123213321312" }
  let(:signed_body) { body && body.to_json }
  let(:signature) { ShippingEasy::Signature.new(api_secret: api_secret, method: http_method, path: "/api#{relative_path}", params: params.dup, body: signed_body) }

  before do
    ShippingEasy.configure do |config|
      config.api_key = api_key
      config.api_secret = api_secret
    end
  end

  subject { ShippingEasy::Http::Request.new(http_method: http_method, params: params, relative_path: relative_path, payload: body) }

  [:http_method, :params, :relative_path].each do |m|
    it "parses and sets the option named #{m}" do
      subject.send(m).should == send(m)
    end
  end

  describe "#api_secret" do
    it "delegates the api_secret to the config" do
      subject.api_secret.should == ShippingEasy.api_secret
    end
  end

  describe "#api_key" do
    it "delegates the api_key to the config" do
      subject.api_key.should == ShippingEasy.api_key
    end
  end

  describe "#adpater" do
    it "instantiates a new adapter" do
      subject.adapter.should be_a(ShippingEasy::Http::FaradayAdapter)
    end
  end

  describe "#signature" do
    it "returns a calculated sigature object" do
      subject.signature.to_s.should == signature.to_s
    end
  end

  describe 'body is nil for GET requests with nil body' do
    let(:http_method) { "get" }
    let(:body) { nil }
    specify do
      subject.body.should == nil
      subject.signature.to_s.should == signature.to_s
    end
  end

  describe 'body is nil for GET requests with omitted payload key' do
    let(:http_method) { "get" }
    let(:body) { nil }
    subject { ShippingEasy::Http::Request.new(http_method: http_method, params: params, relative_path: relative_path) }
    specify do
      subject.body.should == nil
      subject.signature.to_s.should == signature.to_s
    end
  end

  describe "#sign_request!" do
    before { subject.sign_request! }

    it "adds the api signature parameter to the params hash" do
      subject.params[:api_signature].should_not be_nil
    end

    it "adds the api timestamp parameter to the params hash" do
      subject.params[:api_timestamp].should_not be_nil
    end
  end

  describe "#connect" do
    before do
      subject.stub(:sign_request!)
      subject.stub_chain(:adapter, :connect!).and_return("connected!")
    end

    it "signs the request" do
      subject.should_receive(:sign_request!).once
      subject.connect!
    end

    it "connects via the adapter" do
      subject.connect!.should == "connected!"
    end
  end

end
