# frozen_string_literal: true

require "spec_helper"
require "webmock/rspec"

RSpec.describe OpenProject::MsgraphMail::DeliveryMethod do
  let(:config) do
    OpenProject::MsgraphMail::Configuration.new.tap do |c|
      c.tenant_id = "test-tenant-id"
      c.client_id = "test-client-id"
      c.client_secret = "test-client-secret"
      c.sender_email = "test@example.com"
      c.sender_name = "Test Sender"
      c.save_to_sent_items = true
    end
  end

  let(:delivery_method) { described_class.new(config.to_h) }

  let(:mail) do
    Mail.new do
      from    "ignored@example.com" # Will be overridden by sender config
      to      "recipient@example.com"
      cc      "cc@example.com"
      subject "Test Subject"
      body    "Test body content"
    end
  end

  let(:token_response) do
    {
      "access_token" => "test-access-token",
      "token_type" => "Bearer",
      "expires_in" => 3600
    }
  end

  before do
    allow(OpenProject::MsgraphMail).to receive(:configuration).and_return(config)

    # Stub token endpoint
    stub_request(:post, "https://login.microsoftonline.com/test-tenant-id/oauth2/v2.0/token")
      .to_return(
        status: 200,
        body: token_response.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # Stub sendMail endpoint
    stub_request(:post, "https://graph.microsoft.com/v1.0/users/test%40example.com/sendMail")
      .to_return(status: 202, body: "", headers: {})
  end

  describe "#deliver!" do
    it "sends email via MS Graph API" do
      expect { delivery_method.deliver!(mail) }.not_to raise_error

      expect(WebMock).to have_requested(:post, "https://graph.microsoft.com/v1.0/users/test%40example.com/sendMail")
        .with { |req|
          body = JSON.parse(req.body)
          body.dig("message", "subject") == "Test Subject" &&
            body.dig("message", "toRecipients", 0, "emailAddress", "address") == "recipient@example.com"
        }
    end

    it "requests an access token" do
      delivery_method.deliver!(mail)

      expect(WebMock).to have_requested(:post, "https://login.microsoftonline.com/test-tenant-id/oauth2/v2.0/token")
        .with(body: hash_including(
          "client_id" => "test-client-id",
          "client_secret" => "test-client-secret",
          "grant_type" => "client_credentials"
        ))
    end

    context "when API returns error" do
      before do
        stub_request(:post, "https://graph.microsoft.com/v1.0/users/test%40example.com/sendMail")
          .to_return(
            status: 403,
            body: { error: { message: "Insufficient privileges" } }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises DeliveryError" do
        expect { delivery_method.deliver!(mail) }.to raise_error(
          OpenProject::MsgraphMail::DeliveryMethod::DeliveryError,
          /Permission denied/
        )
      end
    end

    context "with HTML content" do
      let(:mail) do
        Mail.new do
          to      "recipient@example.com"
          subject "HTML Test"

          html_part do
            content_type "text/html; charset=UTF-8"
            body "<h1>Hello</h1><p>World</p>"
          end
        end
      end

      it "sends HTML content type" do
        delivery_method.deliver!(mail)

        expect(WebMock).to have_requested(:post, "https://graph.microsoft.com/v1.0/users/test%40example.com/sendMail")
          .with { |req|
            body = JSON.parse(req.body)
            body.dig("message", "body", "contentType") == "HTML"
          }
      end
    end

    context "with attachments" do
      let(:mail) do
        Mail.new do
          to      "recipient@example.com"
          subject "Attachment Test"
          body    "See attached"

          add_file filename: "test.txt", content: "Hello World"
        end
      end

      it "includes base64-encoded attachments" do
        delivery_method.deliver!(mail)

        expect(WebMock).to have_requested(:post, "https://graph.microsoft.com/v1.0/users/test%40example.com/sendMail")
          .with { |req|
            body = JSON.parse(req.body)
            attachments = body.dig("message", "attachments")
            attachments&.first&.dig("name") == "test.txt"
          }
      end
    end
  end
end
