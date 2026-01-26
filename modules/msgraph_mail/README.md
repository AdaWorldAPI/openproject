# OpenProject MS Graph Mail Module

Provides Microsoft Graph API email delivery for OpenProject, replacing SMTP with OAuth2-based mail sending via Microsoft 365.

## Why Use This?

- **Modern Authentication**: Uses OAuth2 client credentials flow instead of username/password
- **Better Security**: No SMTP passwords stored, uses short-lived tokens
- **Microsoft 365 Integration**: Native support for M365/Exchange Online
- **Firewall Friendly**: Uses HTTPS (port 443) instead of SMTP ports

## Requirements

- OpenProject 13.0+
- Azure AD tenant with admin access
- Microsoft 365 mailbox for sending

## Installation

1. Add to `Gemfile.modules`:

```ruby
gem 'openproject-msgraph_mail', path: 'modules/msgraph_mail'
```

2. Run bundle install:

```bash
bundle install
```

3. Set the delivery method:

```bash
export OPENPROJECT_EMAIL_DELIVERY_METHOD=msgraph
```

## Azure AD Configuration

### 1. Register an Application

1. Go to [Azure Portal](https://portal.azure.com) > Azure Active Directory > App registrations
2. Click **New registration**
3. Name: "OpenProject Mail" (or your preference)
4. Supported account types: "Accounts in this organizational directory only"
5. Click **Register**

### 2. Note Your IDs

From the app's Overview page, copy:
- **Application (client) ID** → `MSGRAPH_CLIENT_ID`
- **Directory (tenant) ID** → `MSGRAPH_TENANT_ID`

### 3. Create a Client Secret

1. Go to **Certificates & secrets**
2. Click **New client secret**
3. Set description and expiry
4. Copy the **Value** (shown only once) → `MSGRAPH_CLIENT_SECRET`

### 4. Add API Permissions

1. Go to **API permissions**
2. Click **Add a permission**
3. Select **Microsoft Graph**
4. Select **Application permissions** (not Delegated)
5. Search for and add: `Mail.Send`
6. Click **Grant admin consent for [Your Organization]**

### 5. Verify Permissions

Your API permissions should show:
- `Mail.Send` - Application - Granted for [Your Organization]

## Configuration

### Option A: Environment Variables (Recommended for Docker)

```bash
# Required
OPENPROJECT_EMAIL_DELIVERY_METHOD=msgraph
MSGRAPH_TENANT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
MSGRAPH_CLIENT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
MSGRAPH_CLIENT_SECRET=your-client-secret-value
MSGRAPH_SENDER_EMAIL=noreply@yourdomain.com

# Optional
MSGRAPH_SENDER_NAME=OpenProject
MSGRAPH_SAVE_TO_SENT_ITEMS=true
```

### Option B: Admin UI

1. Go to **Administration** > **Plugins**
2. Find **OpenProject MS Graph Mail** and click **Configure**
3. Fill in the settings
4. Ensure `OPENPROJECT_EMAIL_DELIVERY_METHOD=msgraph` is set

### Docker Compose Example

```yaml
version: '3.8'
services:
  openproject:
    image: openproject/openproject:14
    environment:
      OPENPROJECT_EMAIL_DELIVERY_METHOD: msgraph
      MSGRAPH_TENANT_ID: ${MSGRAPH_TENANT_ID}
      MSGRAPH_CLIENT_ID: ${MSGRAPH_CLIENT_ID}
      MSGRAPH_CLIENT_SECRET: ${MSGRAPH_CLIENT_SECRET}
      MSGRAPH_SENDER_EMAIL: openproject@yourdomain.com
      MSGRAPH_SENDER_NAME: OpenProject Notifications
```

## Testing

### Rails Console Test

```ruby
# In OpenProject Rails console
ActionMailer::Base.mail(
  to: 'test@example.com',
  subject: 'Test from OpenProject',
  body: 'This is a test email via MS Graph'
).deliver_now
```

### Check Configuration

```ruby
# Verify configuration is loaded
OpenProject::MsgraphMail.configuration.valid?
# => true

OpenProject::MsgraphMail.configuration.to_h
# => { tenant_id: "...", client_id: "...", ... }
```

## Troubleshooting

### "Authentication failed"

- Verify tenant ID, client ID, and client secret are correct
- Ensure the client secret hasn't expired
- Check Azure AD > App registrations > Your app > Overview

### "Permission denied"

- Verify `Mail.Send` permission is added as **Application permission** (not Delegated)
- Ensure admin consent has been granted
- Check Azure AD > App registrations > Your app > API permissions

### "Invalid sender"

- The sender email must be a valid mailbox in your M365 tenant
- Shared mailboxes work, but verify the address is correct

### Token Caching

Tokens are cached in memory for their lifetime (typically 1 hour). To clear:

```ruby
OpenProject::MsgraphMail::TokenManager.clear_cache!
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ OpenProject                                                  │
│  ┌─────────────────┐    ┌─────────────────────────────────┐ │
│  │ ActionMailer    │───>│ DeliveryMethod                  │ │
│  │ deliver_now/    │    │ - Converts Mail::Message to     │ │
│  │ deliver_later   │    │   MS Graph sendMail payload     │ │
│  └─────────────────┘    └───────────────┬─────────────────┘ │
│                                         │                    │
│                         ┌───────────────▼─────────────────┐ │
│                         │ TokenManager                    │ │
│                         │ - OAuth2 client credentials     │ │
│                         │ - Thread-safe token caching     │ │
│                         └───────────────┬─────────────────┘ │
└─────────────────────────────────────────┼───────────────────┘
                                          │
                          ┌───────────────▼───────────────┐
                          │ Azure AD Token Endpoint       │
                          │ login.microsoftonline.com     │
                          └───────────────┬───────────────┘
                                          │ Access Token
                          ┌───────────────▼───────────────┐
                          │ Microsoft Graph API           │
                          │ POST /users/{id}/sendMail     │
                          └───────────────────────────────┘
```

## Security Considerations

- Client secrets should be rotated regularly (Azure allows up to 2 year expiry)
- Use environment variables or secrets management for credentials
- The `Mail.Send` permission allows sending as any user in the tenant - restrict the sender email in configuration
- Consider using [certificate-based authentication](https://learn.microsoft.com/en-us/azure/active-directory/develop/certificate-credentials) for production

## License

GPLv3 - See LICENSE file

## Author

Jan Hübener / DATAGROUP SE
