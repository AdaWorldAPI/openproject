# Deploying OpenProject with MS Graph Mail on Railway

This guide covers deploying your OpenProject fork to Railway with MS Graph mail integration.

## Prerequisites

1. Railway account (https://railway.app)
2. Azure AD app registration with `Mail.Send` permission
3. This forked OpenProject repository

## Quick Deploy

### Option 1: Deploy from GitHub

1. Go to [Railway Dashboard](https://railway.app/dashboard)
2. Click **New Project** → **Deploy from GitHub repo**
3. Select `AdaWorldAPI/openproject`
4. Railway will detect the `railway.toml` and build automatically

### Option 2: Railway CLI

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Create project
railway init

# Link to your repo
railway link

# Deploy
railway up
```

## Add PostgreSQL Database

1. In your Railway project, click **New** → **Database** → **PostgreSQL**
2. Railway automatically sets `DATABASE_URL` for your service

## Environment Variables

Set these in Railway's **Variables** tab:

### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `SECRET_KEY_BASE` | Rails secret (64 hex chars) | `openssl rand -hex 64` |
| `OPENPROJECT_HOST__NAME` | Your Railway domain | `openproject-production.up.railway.app` |
| `OPENPROJECT_HTTPS` | Always `true` on Railway | `true` |

### MS Graph Mail

| Variable | Description | Example |
|----------|-------------|---------|
| `OPENPROJECT_EMAIL_DELIVERY_METHOD` | Set to `msgraph` | `msgraph` |
| `MSGRAPH_TENANT_ID` | Azure AD Tenant ID | `xxxxxxxx-xxxx-...` |
| `MSGRAPH_CLIENT_ID` | App Registration Client ID | `xxxxxxxx-xxxx-...` |
| `MSGRAPH_CLIENT_SECRET` | Client Secret value | `your-secret` |
| `MSGRAPH_SENDER_EMAIL` | Sending mailbox | `noreply@yourdomain.com` |
| `MSGRAPH_SENDER_NAME` | Display name | `OpenProject` |
| `MAIL_FROM` | From header | `noreply@yourdomain.com` |

### Optional

| Variable | Default | Description |
|----------|---------|-------------|
| `MSGRAPH_SAVE_TO_SENT_ITEMS` | `true` | Save to Sent folder |
| `OPENPROJECT_EDITION` | `standard` | Or `bim` for BIM features |
| `RAILS_MAX_THREADS` | `4` | Puma threads |

## Railway Template (One-Click)

You can also create a Railway template button. Add this to your README:

```markdown
[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/template/your-template-id)
```

## Resource Recommendations

| Setting | Minimum | Recommended |
|---------|---------|-------------|
| RAM | 1 GB | 2 GB |
| vCPU | 1 | 2 |
| Disk | 1 GB | 5 GB |

The MS Graph mail module adds minimal overhead (~50MB RAM for token caching).

## Verify Deployment

1. Check deployment logs in Railway dashboard
2. Visit your domain's `/health_checks/default` endpoint
3. Log into OpenProject as admin
4. Go to **Administration** → **Emails and notifications** → **Send a test email**

## Troubleshooting

### Build fails

Check if all modules are included:
```bash
railway logs --build
```

### MS Graph authentication errors

1. Verify Azure AD app has `Mail.Send` **Application** permission (not Delegated)
2. Ensure admin consent was granted
3. Check client secret hasn't expired

### Database connection issues

Railway sets `DATABASE_URL` automatically when you link PostgreSQL. Check:
```bash
railway variables
```

### Viewing Rails logs

```bash
railway logs
```

Or in the Railway dashboard under **Deployments** → **View Logs**

## Local Testing Before Deploy

```bash
# Copy env file
cp .env.prod.example .env

# Edit with your values
nano .env

# Build and run
docker compose -f docker-compose.prod.yml build
docker compose -f docker-compose.prod.yml up
```

Access at http://localhost:8080

## Worker Process (Optional)

For production, you may want a separate worker for background jobs:

1. Create a new service in Railway
2. Point it to the same repo
3. Set start command: `./docker/prod/worker`
4. Share the same `DATABASE_URL`
