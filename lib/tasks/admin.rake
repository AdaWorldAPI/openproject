# frozen_string_literal: true

namespace :admin do
  desc "Reset admin password from OPENPROJECT_SEED_ADMIN_USER_PASSWORD environment variable"
  task reset_password: :environment do
    admin = User.not_builtin.admin.find_by(login: "admin")

    unless admin
      warn "Admin user with login 'admin' not found. Skipping password reset."
      next
    end

    password = Setting.seed_admin_user_password

    if password.blank? || password == "admin"
      warn "No custom admin password configured. Set OPENPROJECT_SEED_ADMIN_USER_PASSWORD to reset."
      next
    end

    admin.password = password
    admin.force_password_change = Setting.seed_admin_user_password_reset?

    # Unlock the account if it was locked due to failed login attempts
    if admin.failed_login_count.to_i > 0
      admin.failed_login_count = 0
      admin.last_failed_login_on = nil
    end

    admin.activate
    admin.save!(validate: false)
    puts "Admin password reset successfully. force_password_change=#{admin.force_password_change}"
  end
end
