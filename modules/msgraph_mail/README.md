# OpenProject MS Graph Mail Module

Send emails via Microsoft Graph API instead of SMTP. This is useful for Microsoft 365 / Azure AD environments where SMTP relay is restricted.

## Features

- 📧 Send emails via Microsoft Graph API
- 🔐 Azure AD App Registration authentication (Client Credentials flow)
- 🎛️ Admin UI for configuration and testing
- ✅ Test connection and send test emails from admin panel
- 🌐 Supports all OpenProject email notifications

## Installation

This module is bundled with the custom OpenProject distribution. No additional installation required.

## Configuration

### 1. Azure AD Setup

1. Go to [Azure Portal → App registrations](https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationsListBlade)
2. Create a new registration (or select an existing one)
3. Note the **Application (client) ID** and **Directory (tenant) ID**
4. Under **Certificates & secrets**, create a new client secret
5. Under **API permissions**, add:
   - Microsoft Graph → Application permissions → **Mail.Send**
6. Grant admin consent for the permissions

### 2. Environment Variables

Set the following environment variables in your OpenProject deployment:

```bash
MSGRAPH_TENANT_ID=your-azure-tenant-id
MSGRAPH_CLIENT_ID=your-app-client-id
MSGRAPH_CLIENT_SECRET=your-app-client-secret
MSGRAPH_SENDER_EMAIL=noreply@yourdomain.com

# Optional
MSGRAPH_SENDER_NAME=OpenProject
MSGRAPH_SAVE_TO_SENT_ITEMS=true

# To auto-activate on startup
EMAIL_DELIVERY_METHOD=msgraph
```

### 3. Admin UI

1. Go to **Administration → Emails and notifications → MS Graph Mail**
2. Verify all configuration values show ✓
3. Click **Test Connection** to validate Azure credentials
4. Click **Send Test Email** to verify email delivery
5. Click **Activate MS Graph Mail** to enable

## Admin Menu Location

```
Administration
└── Emails and notifications
    ├── Aggregation
    ├── Email notifications
    ├── MS Graph Mail          ← This module
    └── Incoming emails
```

## Troubleshooting

### "Connection failed" error
- Verify Tenant ID, Client ID, and Client Secret are correct
- Check that the Azure AD app has the Mail.Send permission
- Ensure admin consent was granted

### "Failed to send test email"
- Verify the sender email exists as a mailbox or shared mailbox in Microsoft 365
- The Azure AD app needs Mail.Send permission for that mailbox
- Check that the mailbox is licensed and active

### Module not showing in admin menu
- Restart OpenProject after configuration changes
- Check Rails logs for any startup errors

## License

GNU General Public License v3.0

## Author

Jan Hübener / DATAGROUP SE

## Links

- [Microsoft Graph Mail.Send API](https://learn.microsoft.com/en-us/graph/api/user-sendmail)
- [Azure AD App Registration](https://learn.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app)
