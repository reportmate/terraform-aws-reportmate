# 🎯 TRUE LOCAL REPLICA SETUP GUIDE

## The Problem (Why Local ≠ Production)

**Production**: Your Windows machine with `runner.exe` sends real osquery data to Azure Functions
**Local Dev**: Only has demo/fake data, so no real crash occurs

## ✅ Solution: Make Your Windows Client Report to Local Dev

### Step 1: Start Your Local Development Server

```bash
cd c:\Users\rchristiansen\DevOps\ReportMate\apps\www
npm run dev
# Server should be running at http://localhost:3000
```

### Step 2: Configure Windows Client for Local Dev

**Run as Administrator** in PowerShell:

```powershell
cd c:\Users\rchristiansen\DevOps\ReportMate
.\Configure-Local-Dev.ps1
```

This script will:
- ✅ Test your local dev server
- ✅ Configure Windows registry to point to `http://localhost:3000`
- ✅ Show you next steps

### Step 3: Send Real Data to Local Dev

Run your Windows client:

```powershell
cd c:\Users\rchristiansen\DevOps\ReportMate\clients\windows
.\ReportMate-Collector.ps1 -Verbose
```

**Expected Result:**
- ✅ Your computer (`$env:COMPUTERNAME`) appears in local dashboard
- ✅ Real osquery data populates the local database
- ✅ Large payloads trigger the same crash locally
- ✅ You can debug the exact production issue

### Step 4: Check Local Dashboard

Visit: http://localhost:3000/dashboard

You should now see:
- **Real device**: Your computer name in the device list
- **Real events**: Actual osquery data from your Windows machine
- **Real crash**: The same large payload crash as production

### Step 5: Restore Production Config (When Done)

```powershell
.\Configure-Local-Dev.ps1 -RestoreProduction
```

## 🔍 What This Achieves

1. **True Replica**: Local environment receives same data as production
2. **Real Device**: Your computer appears in local dashboard
3. **Real Payloads**: Actual osquery data with realistic sizes
4. **Accurate Testing**: Can reproduce and debug the exact production crash
5. **Safe Development**: Changes tested against real data before deployment

## 🚀 New API Routes Created

- **`/api/ingest`**: Receives client data (matches Azure Functions endpoint)
- **Device Registration**: Automatically registers your device when it sends data
- **Dynamic Updates**: Device info updated from real osquery data

## 🧪 Testing the Setup

1. **Health Check**: `curl http://localhost:3000/api/ingest`
2. **Device List**: `curl http://localhost:3000/api/device`
3. **Dashboard**: Open http://localhost:3000/dashboard

## 📊 What You'll See

- **Before**: Only demo devices (MAC-001, WS-ACC-001, etc.)
- **After**: Your real computer + demo devices
- **Events**: Mix of real osquery data + demo events
- **Crash**: Real browser crash from large osquery payloads

---

**🎯 This creates a TRUE local replica where you can accurately debug and test the production crash scenario.**
