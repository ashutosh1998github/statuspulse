cat > /opt/statuspulse/SECURITY.md << 'EOF'
# Security Documentation

## Container Image Scanning

### Tool Used
Trivy by Aqua Security

### Before Fix
- Total: 123 vulnerabilities (HIGH: 7, MEDIUM: 46, LOW: 63, CRITICAL: 0)
- HIGH vulnerabilities in: gunicorn 21.2.0, starlette 0.27.0, wheel 0.45.1

### Fixes Applied
- `gunicorn` upgraded from `21.2.0` → `22.0.0` (fixes CVE-2024-1135, CVE-2024-6827)
- `starlette` upgraded from `0.27.0` → `0.40.0` (fixes CVE-2024-47874)
- `wheel` upgraded from `0.45.1` → `0.46.2` (fixes CVE-2026-24049)

### After Fix
- All HIGH Python package vulnerabilities resolved
- Remaining issues are OS-level (Debian base image) with no available fixes

## Secret Management

- Zero secrets committed to Git
- `.env` file listed in `.gitignore`
- All secrets stored in GitHub Actions Secrets
- Passwords passed via environment variables only
- `.env.example` provided with placeholders only

## Reverse Proxy Security Headers

Configured in Caddy reverse proxy:

| Header | Value |
|--------|-------|
| X-Content-Type-Options | nosniff |
| X-Frame-Options | DENY |
| Strict-Transport-Security | max-age=31536000; includeSubDomains |
| X-XSS-Protection | 1; mode=block |
| Referrer-Policy | strict-origin-when-cross-origin |

## Rate Limiting

- UFW connection limiting enabled on ports 80 and 443
- Limits repeated connections from same IP
- Configured via: `sudo ufw limit 443/tcp`

## SSH Hardening

- Root login disabled
- Password authentication disabled
- Key-based authentication only
EOF
