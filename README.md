# StatusPulse 🟢

A lightweight status page and health monitoring API built with FastAPI, PostgreSQL, and Redis — fully containerized and deployed with CI/CD, HTTPS, and monitoring.

**Live URL:** https://statuspulse.duckdns.org  
**Status Page:** http://13.206.199.147:3001  
**API Docs:** https://statuspulse.duckdns.org/docs  

---

## Architecture

                   ┌─────────────────────────────────────┐
                     │           AWS EC2 (t2.micro)        │
                     │                                     │
Internet ──HTTPS──▶ Caddy (443/80) ──▶ FastAPI App (8000)  │
│                    │                │
│            ┌───────┴────────┐       │
│            ▼                ▼       │
│       PostgreSQL          Redis     │
│            │                        │
│       Uptime Kuma (3001)            │
└─────────────────────────────────────┘
▲
GitHub Actions CI/CD
(build → push → deploy)
**Components:**
- **FastAPI** — REST API with health checks, services, incidents endpoints
- **PostgreSQL** — persistent storage for services and incidents
- **Redis** — pub/sub for incident notifications
- **Caddy** — reverse proxy with automatic HTTPS via Let's Encrypt
- **Uptime Kuma** — self-hosted monitoring with Discord + Ntfy alerts
- **GitHub Actions** — CI/CD pipeline for automated testing and deployment
- **Terraform** — Infrastructure as Code for AWS provisioning

---

## Prerequisites

- Docker and Docker Compose
- Git
- Make
- A domain name (DuckDNS free)
- AWS account (free tier)

---

## Running Locally with Docker Compose

### Step 1 — Clone the repo
```bash
git clone https://github.com/ashutosh1998github/statuspulse.git
cd statuspulse
```

### Step 2 — Create .env file
```bash
cp .env.example .env
# Edit .env and fill in your values
nano .env
```

### Step 3 — Start all services
```bash
make up
```

### Step 4 — Verify everything is running
```bash
make test
```

### Available Make commands
| Command | Description |
|---------|-------------|
| `make build` | Build Docker image |
| `make up` | Start all services |
| `make down` | Stop all services |
| `make logs` | Tail logs |
| `make test` | Health check via curl |
| `make clean` | Remove containers, images, volumes |
| `make shell` | Open bash in app container |

---

## Deploying to Production

### Prerequisites
- AWS EC2 instance (t2.micro, Ubuntu 22.04)
- Domain pointed to server IP (DuckDNS)
- GitHub repository with secrets configured

### GitHub Actions Secrets Required
GHCR_TOKEN        - GitHub Personal Access Token
EC2_HOST          - Your server IP
EC2_USER          - ubuntu
EC2_SSH_KEY       - Private SSH key content
DB_PASSWORD       - PostgreSQL password
REDIS_PASSWORD    - Redis password
### Deploy Steps
```bash
# SSH into server
ssh ubuntu@your-server-ip

# Clone repo
git clone https://github.com/ashutosh1998github/statuspulse.git
cd statuspulse

# Create .env file
cp .env.example .env
nano .env

# Run deploy script
bash scripts/deploy.sh
```

---

## CI/CD Pipeline

### CI Workflow (ci.yml)
Triggers on every push and PR to main:

1. Lint Python code with `ruff`
2. Scan Dockerfile with `hadolint`
3. Build Docker image
4. Start full stack via Docker Compose
5. Run integration tests against all endpoints
6. Tear down stack
7. Upload test results as artifact

### Deploy Workflow (deploy.yml)
Triggers on push to main after CI passes:

1. Build and tag image with commit SHA + latest
2. Push to GitHub Container Registry (ghcr.io)
3. SSH into EC2 server
4. Pull new image and deploy
5. Run post-deployment health check
6. Auto-rollback if health check fails
7. Send notification to Discord

---

## Monitoring and Alerting

### Uptime Kuma
- Running at http://13.206.199.147:3001
- Monitors:
  - StatusPulse `/health` endpoint (every 60s)
  - PostgreSQL TCP port check
  - Redis TCP port check
  - TLS certificate expiry

### Notification Channels
- **Discord** — webhook alerts for down/recovery events
- **Ntfy** — push notifications to mobile

### Health Monitor Script
Runs every 5 minutes via cron:
```bash
crontab -l  # view cron jobs
cat /var/log/statuspulse-monitor.log  # view logs
```

Checks:
- `/health` endpoint returns HTTP 200
- Disk usage < 80%
- Memory usage < 90%
- All Docker containers running
- TLS certificate expiry > 14 days

---

## Backup and Restore

### Manual Backup
```bash
bash scripts/backup.sh
```

### Backup Location
/opt/statuspulse/backups/statuspulse_db_YYYY-MM-DD_HHMMSS.sql.gz
### Restore from Backup
```bash
# Decompress
gunzip statuspulse_db_2026-05-06_120000.sql.gz

# Restore
docker exec -i statuspulse-postgres psql -U postgres statuspulse < statuspulse_db_2026-05-06_120000.sql
```

### Automated Backups
Daily backups scheduled via cron:
```bash
crontab -l  # shows daily backup schedule
```

Keeps last 7 backups automatically.

---

## Infrastructure as Code (Terraform)

### What it provisions
- AWS EC2 t2.micro instance (Ubuntu 22.04)
- Security group with ports 22, 80, 443, 3001
- Elastic IP address
- 20GB gp2 EBS volume

### Usage
```bash
cd terraform

# Configure AWS credentials
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_DEFAULT_REGION="ap-south-1"

# Initialize
terraform init

# Preview changes
terraform plan

# Apply
terraform apply
```

---

## Security

See [SECURITY.md](SECURITY.md) for full details.

- Container images scanned with Trivy
- No secrets in Git — all via GitHub Actions Secrets
- Security headers on all responses
- UFW firewall — only ports 22, 80, 443, 3001 allowed
- Rate limiting on ports 80 and 443
- Non-root user inside Docker containers
- Automatic security updates via unattended-upgrades

---

## Troubleshooting

### App not starting
```bash
docker logs statuspulse-app --tail 50
```

### Database connection issues
```bash
docker exec -it statuspulse-postgres psql -U postgres -c "SELECT 1"
```

### Caddy/HTTPS issues
```bash
docker logs statuspulse-caddy --tail 50
```

### Check all container health
```bash
docker ps
curl https://statuspulse.duckdns.org/health
```

### Restart everything
```bash
cd /opt/statuspulse
docker compose down && docker compose up -d
```
