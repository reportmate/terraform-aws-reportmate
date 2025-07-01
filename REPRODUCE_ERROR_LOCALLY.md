# REPRODUCE PRODUCTION ERROR LOCALLY

This guide helps you reproduce the production web app crash caused by large Windows client payloads.

## 🎯 The Problem

- **Production**: Crashes due to large osquery payloads (100KB+ JSON) accumulated in Azure PostgreSQL
- **Local Dev**: Uses fresh/demo data, so crashes don't occur
- **Solution**: Mirror production data locally or inject realistic large payloads

## 🚀 Option 1: Connect Local Dev to Production Database (FASTEST)

> ⚠️ **CAUTION**: This connects to live production data

1. **Set production database connection**:
   ```bash
   # File already created: apps/www/.env.local
   # Contains: DATABASE_URL=postgresql://reportmate:${DB_PASSWORD}@reportmate-database.postgres.database.azure.com:5432/reportmate?sslmode=require
   ```

2. **Get production database password**:
   ```bash
   # In project root
   source .env.production
   echo $DB_PASSWORD
   ```

3. **Start development server**:
   ```bash
   cd apps/www
   pnpm dev
   ```

4. **Test the crash**:
   - Navigate to http://localhost:3000/dashboard
   - Navigate to http://localhost:3000/events
   - Look for browser console errors or page crashes

## 🔧 Option 2: Import Production Data to Local Database

### For Git Bash/Linux:
```bash
cd apps/www/scripts
chmod +x import-production-data.sh
./import-production-data.sh
```

### For PowerShell:
```powershell
cd apps\www\scripts
.\import-production-data.ps1
```

## 🧪 Option 3: Generate Realistic Test Data (RECOMMENDED)

1. **Generate large test payloads**:
   ```bash
   cd apps/www/scripts
   node generate-large-payloads.js
   ```

2. **Start local database**:
   ```bash
   # In project root
   docker-compose up -d postgres
   ```

3. **Inject test data**:
   ```bash
   psql postgresql://reportmate:reportmate123@localhost:5432/reportmate -f scripts/inject-large-payloads.sql
   ```

4. **Start development server**:
   ```bash
   cd apps/www
   pnpm dev
   ```

5. **Reproduce the crash**:
   - Visit http://localhost:3000/dashboard
   - Visit http://localhost:3000/events
   - Check browser console for errors

## 🔍 What to Look For

### Browser Console Errors:
- Memory exhaustion errors
- "Maximum call stack size exceeded"
- Browser tab crashes or freezes
- Network request timeouts

### Symptoms:
- Dashboard page doesn't load
- Events page shows blank or crashes
- Browser becomes unresponsive
- Large payload display issues

## ✅ Verify the Fix

After reproducing the error:

1. **Check ErrorBoundary**: Should catch and display error UI instead of crashing
2. **Check API responses**: Large payloads should be summarized
3. **Check dashboard**: Should show safe summaries instead of full payloads
4. **Monitor memory**: Browser memory usage should remain stable

## 📊 Understanding the Data

### Large Payloads Come From:
- **osquery**: Windows system monitoring data
- **File events**: File system monitoring
- **Process lists**: Running processes with full command lines
- **Registry entries**: Windows registry data
- **Service information**: Windows services with descriptions

### Typical Sizes:
- Small payload: 1-10 KB
- Medium payload: 10-100 KB
- **PROBLEM** Large payload: 100KB - 1MB+
- **CRITICAL** payload: 1MB+

## 🛠️ Debugging Tips

1. **Check payload sizes**:
   ```sql
   SELECT id, device_id, event_type, 
          length(payload::text) as size_bytes,
          (length(payload::text) / 1024) as size_kb
   FROM events 
   ORDER BY length(payload::text) DESC 
   LIMIT 10;
   ```

2. **Monitor browser memory**:
   - Open Chrome DevTools > Performance
   - Record while loading dashboard
   - Look for memory spikes

3. **Check network requests**:
   - DevTools > Network tab
   - Look for large response sizes
   - Check for failed/timeout requests

## 📝 Expected Results

### Before Fix:
- ❌ Browser crashes or freezes
- ❌ Dashboard doesn't load
- ❌ Large payloads cause memory issues

### After Fix:
- ✅ ErrorBoundary catches errors gracefully
- ✅ Large payloads are summarized safely
- ✅ Dashboard loads and remains responsive
- ✅ Memory usage stays reasonable
