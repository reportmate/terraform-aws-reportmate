# Running Windows Client Against Local Development Environment

## Prerequisites
1. Local development server is running and mirroring production
2. You have administrator privileges on your Windows machine
3. osquery is installed and functional

## Step-by-Step Instructions

### 1. Start Local Development Server (if not already running)
```powershell
cd c:\Users\rchristiansen\DevOps\ReportMate\apps\www
npm run dev
```
Verify it's running on http://localhost:3000

### 2. Open PowerShell as Administrator
- Press `Win + X`
- Select "Windows PowerShell (Admin)" or "Terminal (Admin)"
- Navigate to the Windows client directory:
```powershell
cd c:\Users\rchristiansen\DevOps\ReportMate\clients\windows
```

### 3. Configure Client for Local Development
```powershell
.\Setup-LocalDev.ps1
```

This will:
- Check admin privileges (required for registry edits)
- Test connection to local server
- Configure registry to point to `http://localhost:3000`
- Remove authentication requirements for local dev

### 4. Run the Data Collector
```powershell
.\ReportMate-Collector.ps1 -Verbose
```

This will:
- Query osquery for system information
- Send real device data to your local development server
- Show detailed logging of the process

### 5. Verify Data in Local Dashboard
1. Open http://localhost:3000 in your browser
2. Navigate to the dashboard
3. You should see:
   - Your current machine listed as a device
   - Real osquery data (not mock data)
   - The same crash that occurs in production

### 6. Monitor Data Flow
In the PowerShell window running the collector, you should see:
```
[INFO] Executing osquery...
[INFO] Found X processes, Y network connections, Z installed software
[INFO] Sending payload to http://localhost:3000/api/ingest
[SUCCESS] Data sent successfully
```

### 7. Reset to Production (when done)
```powershell
.\Setup-LocalDev.ps1 -Reset
```

## Troubleshooting

### If "Access Denied" Registry Errors
- Ensure PowerShell is running as Administrator
- Check UAC settings are not blocking registry modifications

### If Local Server Connection Fails
- Verify the dev server is running: http://localhost:3000/api/ingest
- Check Windows Firewall isn't blocking connections
- Ensure no other service is using port 3000

### If No Data Appears in Dashboard
- Check the collector output for errors
- Verify osquery is installed and working: `osqueryi "SELECT * FROM system_info;"`
- Check the local dev server logs for incoming requests

### If Still Getting Mock Data
- Verify you're using the production-mirror environment (`.env.production-mirror`)
- Check database connection strings point to production
- Restart the local dev server after environment changes

## Expected Behavior
1. **Device Registration**: Your machine should appear in the local dashboard within 1-2 minutes
2. **Real Data**: Dashboard should show actual system information, not mock data
3. **Crash Reproduction**: The same error that occurs in production should now occur locally
4. **Debugging Ready**: You can now debug the crash with real data in your local environment

## Important Notes
- **Admin Rights Required**: Registry modifications require administrator privileges
- **Production Database**: Local dev connects to production database for real data
- **No Authentication**: Local development disables authentication for easier testing
- **Real osquery Data**: Collector sends actual system information, not test data
