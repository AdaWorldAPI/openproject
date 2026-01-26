# frozen_string_literal: true

#-- copyright
# OpenProject MS Graph Mail Module
# Copyright (C) 2025 Jan Hübener / DATAGROUP SE
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#++

require "open_project/plugins"

module OpenProject
  module MsgraphMail
    class Engine < ::Rails::Engine
      engine_name :openproject_msgraph_mail

      include OpenProject::Plugins::ActsAsOpEngine

      register "openproject-msgraph_mail",
               bundled: true,
               author_url: "https://github.com/AdaWorldAPI/openproject" do
        # Settings accessible via Setting model
        settings default: {
          "msgraph_tenant_id" => nil,
          "msgraph_client_id" => nil,
          "msgraph_client_secret" => nil,
          "msgraph_sender_email" => nil,
          "msgraph_sender_name" => "OpenProject",
          "msgraph_save_to_sent_items" => true
        },
                 partial: "settings/msgraph_mail"
      end

      initializer "msgraph_mail.register_delivery_method" do
        ActiveSupport.on_load(:action_mailer) do
          # Register :msgraph as a valid delivery method
          ActionMailer::Base.add_delivery_method(:msgraph, OpenProject::MsgraphMail::DeliveryMethod)
        end
      end

      initializer "msgraph_mail.configure", after: "openproject.configuration" do
        # Sync settings from OpenProject's Setting model to our configuration
        OpenProject::MsgraphMail.configure do |config|
          config.tenant_id = Setting.plugin_openproject_msgraph_mail["msgraph_tenant_id"].presence ||
                             ENV.fetch("MSGRAPH_TENANT_ID", nil)
          config.client_id = Setting.plugin_openproject_msgraph_mail["msgraph_client_id"].presence ||
                             ENV.fetch("MSGRAPH_CLIENT_ID", nil)
          config.client_secret = Setting.plugin_openproject_msgraph_mail["msgraph_client_secret"].presence ||
                                 ENV.fetch("MSGRAPH_CLIENT_SECRET", nil)
          config.sender_email = Setting.plugin_openproject_msgraph_mail["msgraph_sender_email"].presence ||
                                ENV.fetch("MSGRAPH_SENDER_EMAIL", nil)
          config.sender_name = Setting.plugin_openproject_msgraph_mail["msgraph_sender_name"].presence ||
                               ENV.fetch("MSGRAPH_SENDER_NAME", "OpenProject")
          config.save_to_sent_items = Setting.plugin_openproject_msgraph_mail["msgraph_save_to_sent_items"] != false
        end
      rescue StandardError => e
        Rails.logger.warn "MS Graph Mail: Could not load settings: #{e.message}"
      end

      config.to_prepare do
        # Extend Setting class to handle msgraph delivery method
        # MailSettings is extended as class methods on Setting
        Setting.singleton_class.prepend(OpenProject::MsgraphMail::MailSettingsExtension)
      end
    end

    # Extension to handle msgraph delivery method in Setting::MailSettings
    # This extends Setting's class methods since MailSettings is `extend`ed
    module MailSettingsExtension
      def reload_mailer_settings!
        super

        return unless Setting.email_delivery_method == :msgraph

        Rails.logger.info "MS Graph Mail: Configuring msgraph delivery method"

        ActionMailer::Base.delivery_method = :msgraph
        ActionMailer::Base.msgraph_settings = OpenProject::MsgraphMail.configuration.to_h
      end
    end
  end
end
