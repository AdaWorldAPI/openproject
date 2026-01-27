#!/bin/bash

set -e
set -o pipefail

# Use jemalloc at runtime
if [ "$USE_JEMALLOC" = "true" ]; then
	export LD_PRELOAD=libjemalloc.so.2
fi

# Ensure PGBIN is set according to PGVERSION env var
if [ -n "$PGVERSION" ]; then
	export PGBIN="/usr/lib/postgresql/$PGVERSION/bin"
	export PATH="$PGBIN:$PATH"
fi

# ONE-TIME: Reset admin password if RESET_ADMIN_PASSWORD is set
if [ -n "$RESET_ADMIN_PASSWORD" ]; then
	echo "==> Resetting admin password..."
	bundle exec rails runner "
		admin = User.find_by(login: 'admin')
		if admin
			admin.password = ENV['RESET_ADMIN_PASSWORD']
			admin.password_confirmation = ENV['RESET_ADMIN_PASSWORD']
			admin.failed_login_count = 0
			admin.save!(validate: false)
			puts 'Admin password reset and lockout cleared!'
		else
			puts 'Admin user not found!'
		end
	" || echo "Password reset failed, continuing..."
fi

exec "$@"
