# 🚨 CRITICAL: PASSWORDS EXPOSED IN PUBLIC REPOSITORIES

## ⚠️ IMMEDIATE THREAT - Action Required NOW

**Date**: October 18, 2025  
**Severity**: CRITICAL - PUBLIC EXPOSURE  
**Status**: 🔴 ACTIVE THREAT

---

## 💀 What Was Exposed

### Repository 1: `terraform-azurerm-reportmate` (Public)
**URL**: https://github.com/reportmate/terraform-azurerm-reportmate

**Exposed File**: `schemas/run-migrations.ps1`
**Exposed Password**: `2sSWbVxyqjXp9WUpeMmzRaC`
**Commit**: `e15b262` - "Consolidated any db related prisma file into `.\infrastructure\schemas`"
**Currently on**: `origin/main` (PUBLIC)

### Repository 2: `reportmate-app-web` (Public)
**URL**: https://github.com/reportmate/reportmate-app-web

**Exposed File**: `.env.example`
**Exposed Password**: `reportmate123`
**Commits**: 
- `8113e98` - "Update authentication terminology and flow improvements"
- `03a5b6b` - "Implement NextAuth.js authentication with automatic SSO redirect"
- `f0e21a1` - "Moving pnpm workspace configuration..."
**Currently on**: `origin/main` (PUBLIC)

---

## 🔥 IMMEDIATE ACTIONS (DO NOW - In Order)

### 1. Rotate ALL Database Passwords (5 minutes)

```powershell
# Generate new secure password
$newPassword = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 48 | ForEach-Object {[char]$_})
Write-Host "New password: $newPassword" -ForegroundColor Green

# Rotate Azure PostgreSQL password
az postgres flexible-server update `
  --resource-group ReportMate `
  --name reportmate-database `
  --admin-password $newPassword

# Store in Azure Key Vault
az keyvault secret set `
  --vault-name reportmate-keyvault `
  --name db-password `
  --value $newPassword `
  --expires (Get-Date).AddYears(1).ToString("yyyy-MM-ddTHH:mm:ssZ")
```

**Passwords to rotate**:
- [ ] Production: `2sSWbVxyqjXp9WUpeMmzRaC` (PUBLICLY EXPOSED)
- [ ] Dev/Docker: `reportmate123` (PUBLICLY EXPOSED)
- [ ] Current local: `RmDb7K9mL3qP2wX8vN4zF6H` (was in 11 files)

### 2. Update Production Systems (10 minutes)

```powershell
# Update Container App environment variable
az containerapp update `
  --name reportmate-www `
  --resource-group ReportMate `
  --set-env-vars "DATABASE_URL=secretref:database-url"

# Update Container App secret
az containerapp secret set `
  --name reportmate-www `
  --resource-group ReportMate `
  --secrets "database-url=postgresql://reportmate:${newPassword}@reportmate-database.postgres.database.azure.com:5432/reportmate?sslmode=require"
```

### 3. Fix Git History - Remove Secrets (30 minutes)

**Infrastructure Repo**:
```bash
cd C:\Users\rchristiansen\DevOps\ReportMate\infrastructure

# Install BFG Repo Cleaner (if not installed)
# Download from: https://rtyley.github.io/bfg-repo-cleaner/

# Remove password from history
java -jar bfg.jar --replace-text passwords.txt

# passwords.txt contains:
# 2sSWbVxyqjXp9WUpeMmzRaC==>REDACTED
# reportmate123==>REDACTED
# RmDb7K9mL3qP2wX8vN4zF6H==>REDACTED

# Clean up
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Force push (CAREFUL - coordinate with team!)
git push --force
```

**Web App Repo**:
```bash
cd C:\Users\rchristiansen\DevOps\ReportMate\apps\www

# Same process
java -jar bfg.jar --replace-text passwords.txt
git reflog expire --expire=now --all
git gc --prune=now --aggressive
git push --force
```

### 4. Commit Fixed Files (5 minutes)

```bash
cd C:\Users\rchristiansen\DevOps\ReportMate\infrastructure
git add schemas/run-migrations.ps1
git commit -m "SECURITY: Remove hardcoded password from migration script"
git push

cd C:\Users\rchristiansen\DevOps\ReportMate\apps\www
git add .env.example
git commit -m "SECURITY: Remove example password from .env.example"
git push
```

### 5. Monitor for Unauthorized Access (Ongoing)

```bash
# Check Azure Activity Logs
az monitor activity-log list `
  --resource-group ReportMate `
  --start-time (Get-Date).AddDays(-7).ToString("yyyy-MM-ddTHH:mm:ssZ") `
  --query "[?contains(operationName.value, 'Microsoft.DBforPostgreSQL')]" `
  --output table

# Check database connections
az postgres flexible-server show `
  --resource-group ReportMate `
  --name reportmate-database `
  --query "network.publicNetworkAccess"
```

---

## 📊 Exposure Timeline

| Date | Event | Severity |
|------|-------|----------|
| Unknown | Password `2sSWbVxyqjXp9WUpeMmzRaC` committed to infrastructure repo | 🔴 CRITICAL |
| Unknown | Password `reportmate123` committed to web app repo | 🔴 CRITICAL |
| Oct 18, 2025 | Password `RmDb7K9mL3qP2wX8vN4zF6H` found in 11 local files | 🟡 HIGH |
| Oct 18, 2025 | **DISCOVERY** - User identified security issue | ✅ |
| Oct 18, 2025 | All local files remediated | ✅ |
| Oct 18, 2025 | **PUBLIC EXPOSURE CONFIRMED** | 🔴 CRITICAL |

---

## 🎯 Risk Assessment

### Current Exposure
- ✅ Local files: **FIXED** (using environment variables)
- 🔴 Infrastructure repo (public): **EXPOSED** - `2sSWbVxyqjXp9WUpeMmzRaC`
- 🔴 Web app repo (public): **EXPOSED** - `reportmate123`
- 🔴 Git history: **EXPOSED** - All passwords in commit history

### Attack Vectors
1. **Direct Database Access**: Anyone with exposed passwords can connect to:
   - `reportmate-database.postgres.database.azure.com:5432`
   - Database: `reportmate`
   - Username: `reportmate`

2. **Data Exfiltration**: Full access to:
   - 215+ device records
   - Serial numbers, hardware info
   - Software inventory (98+ applications)
   - Usage analytics
   - User data

3. **Data Destruction**: Attacker could:
   - Drop tables
   - Delete records
   - Corrupt data
   - Create backdoors

4. **Lateral Movement**: Database credentials might enable:
   - Access to other Azure resources
   - Service principal enumeration
   - Resource group exploration

---

## 🛡️ Mitigation Checklist

### Immediate (Within 1 Hour)
- [ ] Rotate all database passwords
- [ ] Update Azure Container Apps with new credentials
- [ ] Update Azure Key Vault secrets
- [ ] Update local `.env.local` files
- [ ] Update CI/CD pipeline secrets
- [ ] Notify team (use template below)
- [ ] Check Azure Activity Logs for suspicious access
- [ ] Review database audit logs

### Short Term (Within 24 Hours)
- [ ] BFG Repo Cleaner on both public repos
- [ ] Force push cleaned history
- [ ] Commit sanitized versions of files
- [ ] Enable GitHub secret scanning
- [ ] Enable Azure Security Center alerts
- [ ] Configure database firewall rules (IP whitelist)
- [ ] Enable PostgreSQL audit logging
- [ ] Review all other repos for similar issues

### Medium Term (Within 1 Week)
- [ ] Implement Azure Key Vault integration everywhere
- [ ] Add pre-commit hooks (git-secrets)
- [ ] Enable GitHub Advanced Security
- [ ] Conduct full security audit
- [ ] Implement secret rotation policy (quarterly)
- [ ] Add monitoring alerts for failed auth attempts
- [ ] Document secure development practices
- [ ] Team security training

---

## 📧 Team Notification Template

```
Subject: CRITICAL SECURITY INCIDENT - Immediate Action Required

Team,

We have discovered database credentials exposed in our PUBLIC GitHub repositories:

REPOSITORIES AFFECTED:
- terraform-azurerm-reportmate (public)
- reportmate-app-web (public)

EXPOSURE:
- Production database password
- Development database password
- Exposed in commit history (publicly accessible)

ACTIONS TAKEN:
1. All database passwords have been rotated
2. Local files remediated (environment variables)
3. Git history cleanup in progress

REQUIRED ACTIONS (ALL TEAM MEMBERS):
1. Pull latest changes from both repos (after force push notification)
2. Update your local .env.local files with new credentials:
   - Get from: az keyvault secret show --vault-name reportmate-keyvault --name db-password
3. Delete any cached database credentials
4. Do NOT use old passwords

TIMING:
- Password rotation: COMPLETED [timestamp]
- Force push: SCHEDULED [timestamp]
- Team access restored: [timestamp]

GOING FORWARD:
- Pre-commit hooks will be mandatory
- All secrets must use Azure Key Vault
- Code review will check for hardcoded secrets

Questions? Contact: [Security Lead]

This is a P0 security incident. Please acknowledge receipt.
```

---

## 🔍 Forensics

### Check Who Has Accessed
```powershell
# GitHub API - Check repo clones
$infraRepo = "reportmate/terraform-azurerm-reportmate"
$webRepo = "reportmate/reportmate-app-web"

gh api "repos/$infraRepo/traffic/clones" | ConvertFrom-Json
gh api "repos/$webRepo/traffic/clones" | ConvertFrom-Json

# Check unique visitors
gh api "repos/$infraRepo/traffic/popular/referrers" | ConvertFrom-Json
gh api "repos/$webRepo/traffic/popular/referrers" | ConvertFrom-Json
```

### Check Database Connections
```sql
-- Connect to database (after password rotation)
-- Check for suspicious connections
SELECT 
    datname,
    usename,
    application_name,
    client_addr,
    backend_start,
    state
FROM pg_stat_activity
WHERE usename = 'reportmate'
ORDER BY backend_start DESC;

-- Check recent login attempts (if audit logging enabled)
-- This requires pgAudit extension
```

---

## 📚 References

- [BFG Repo Cleaner](https://rtyley.github.io/bfg-repo-cleaner/)
- [GitHub Secret Scanning](https://docs.github.com/en/code-security/secret-scanning)
- [Azure Key Vault Best Practices](https://learn.microsoft.com/en-us/azure/key-vault/general/best-practices)
- [OWASP Secrets Management](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [Git History Rewrite](https://git-scm.com/book/en/v2/Git-Tools-Rewriting-History)

---

## 📞 Incident Response Contacts

- **Security Lead**: [Contact]
- **DevOps Lead**: [Contact]
- **Database Admin**: [Contact]
- **Emily Carr IT Security**: [Contact]

---

**STATUS**: 🔴 ACTIVE INCIDENT - PASSWORDS PUBLICLY EXPOSED  
**PRIORITY**: P0 - CRITICAL  
**NEXT UPDATE**: After password rotation (within 30 minutes)  

**DO NOT DELAY - START WITH STEP 1 NOW**
