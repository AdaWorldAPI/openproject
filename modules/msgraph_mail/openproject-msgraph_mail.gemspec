# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = "openproject-msgraph_mail"
  s.version     = "1.0.0"
  s.authors     = ["Jan Hübener"]
  s.summary     = "Microsoft Graph Mail Delivery for OpenProject"
  s.description = "Provides Microsoft Graph API mail delivery method for OpenProject, " \
                  "enabling email sending via Microsoft 365 / Azure AD OAuth2"
  s.license     = "GPLv3"

  s.files = Dir["{app,config,db,doc,lib}/**/*"] + %w[README.md]
  s.metadata["rubygems_mfa_required"] = "true"

  # Dependencies
  s.add_dependency "oauth2", "~> 2.0"
end
