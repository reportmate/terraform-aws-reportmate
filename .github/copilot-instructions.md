````instructions
# Reminders for working with ReportMate codebase:

# 🚨🚨🚨 NEVER EVER CREATE FAKE DATA 🚨🚨🚨
# ❌❌❌ NO MOCK DATA ANYWHERE ❌❌❌
# ⛔⛔⛔ NO FALLBACK DATA GENERATION ⛔⛔⛔
# 🔥🔥🔥 PRODUCTION SYSTEMS MUST SHOW REAL DATA ONLY 🔥🔥🔥

**ABSOLUTELY FORBIDDEN:**
- ❌ createFallbackOSData() functions
- ❌ Mock macOS/Windows data generation
- ❌ Fake device data creation
- ❌ Test data in production endpoints
- ❌ Hash-based fake data distribution
- ❌ "Realistic" fake data patterns
- ❌ Any data generation that makes it "seem like something is working when it's not"

**IF THERE'S NO REAL DATA:**
- ✅ Show empty charts/tables
- ✅ Display "No data available" messages  
- ✅ Return empty arrays/objects
- ✅ Let the user know the real state

**REMEMBER:** Frontend is a READER. Heavy lifting is done on device at collection. If data is missing, fix it at the source (client collection), NOT with fake frontend compensation.

Do not use or keep API data fallbacks, what's the fucking point with that, we are working on getting a full production system here -- I can't be misguided with local fallback data that make it seem something is working when its not!

and one very important tenant of ReportMate design is the frontend web app and future native apps are 'readers' as much as possible, the heavy lifting processing is done on device at collection, if the data is off we try to fix it at the source rather than relying on the frontend to compensate.

**Commit Guidelines:**
- Bundle related changes together
- Keep commit messages short and descriptive
- No emoji in commit messages
- Don't commit testing/debug files or scripts
- Don't push commits automatically - commit only
- Commit submodules first, then main repo
- be selective with files `git add .` 
- stage only relevant files

**Code Standards:**
- No emoji in code files anywhere
- Clean professional code only
- Comments should be clear and technical

1. **Build & sign the Windows agent** (now supports MSI with scheduled tasks!)

```powershell
Set-Location clients\windows; .\build.ps1 -Sign
```

For local testing, use .nupkg, I prefer it

**Build individual package types:**
```powershell
# EXE only
.\build.ps1 -SkipNUPKG -SkipZIP -SkipMSI -Sign

# MSI only (requires WiX Toolset)
.\build.ps1 -SkipNUPKG -SkipZIP -Sign

# NUPKG only
.\build.ps1 -SkipZIP -SkipMSI -Sign
```


* **Copy an updated, signed binary by hand (temporary workaround)**

```powershell
sudo powershell -Command "Copy-Item '.\.publish\runner.exe' 'C:\Program Files\ReportMate\runner.exe' -Force"
```


If there are warnings in the build, fix them. No warnings or errors are acceptable.

2. ***DO NOT FORGET***:

**to Launch the agent with live console output (debug mode)**

```pwsh
sudo pwsh -c "& 'C:\Program Files\ReportMate\runner.exe' -vv --collect-only"
sudo pwsh -c "& 'C:\Program Files\ReportMate\runner.exe' -vv --transmit-only"
```
do not try any other option as it will spawn in another window

to run only one module collection while developing and testing you can use:

```pwsh
sudo pwsh -c "& 'C:\Program Files\ReportMate\runner.exe' -vv --run-module installs"
```

Investigate any log entries such as `[ERR] Error executing osquery` or `[WRN] osquery exited with code 1` immediately.

3. to install the .nupkg use:

```
sudo choco install com.github.reportmate.windows --source=".\clients\windows\dist\" --yes --force
```


Then inspect `https://reportmate-api.azurewebsites.net/api/device/0F33V9G25083HJ` to see if the data is as expected





#### 2. Runtime Environment

* **Web frontend (prod container)**
  `https://reportmate-container-prod.blackdune-79551938.canadacentral.azurecontainerapps.io`

* **Local file system paths**

  * Binaries: `C:\Program Files\ReportMate\`
  * Preferences / data: `C:\ProgramData\ManagedReports`

* **Signing rule**
  `runner.exe` *must* be built with `-Sign`. Unsigned binaries will not run.

* **Debug tip**
  Never test against `localhost`; it does not replicate the production environment.
  
  
You can see what `runner.exe` is collecting from device from the sample in `./raw_event_payload.json` and `./device_data.json`

I DO NOT WANT MOCK AND TEST AND FAKE DATA ANYWHERE

ReportMate's internal `deviceId` is the UUID of the device but ***all*** links are always `/device/[serialNumber]` never use UUID for links, never.


#### 3. Deployment Shortcuts

**Deploy Azure Functions API (when API code changes):**

```powershell
cd infrastructure\modules\functions\api
func azure functionapp publish reportmate-api --build remote
```

**🚨 CRITICAL: Azure Functions Python Deployment Issues 🚨**

**PROBLEM:** ZIP deploys do NOT trigger Python builds, so `requirements.txt` is ignored and imports fail at runtime.

**ROOT CAUSE:** ZIP push deploys assume "ready-to-run" packages. Build automation is OFF by default.

**CRITICAL DEPLOYMENT LESSONS LEARNED:**

🚨 **AZURE FUNCTIONS API RESTORATION SUCCESS (September 2025)** 🚨

**ROOT CAUSE OF COMPLETE API FAILURE:**
- Azure Functions remote build was **COMPLETELY IGNORING** requirements.txt
- pg8000 PostgreSQL driver not being installed despite correct requirements specification
- ALL API endpoints failing with 500 errors due to missing database connectivity

**SUCCESSFUL SOLUTION - VENDORED DEPLOYMENT:**
```powershell
# WORKING solution that MUST be used for all future deployments:
$APP = "reportmate-api"
$RG = "ReportMate" 
$SRC_DIR = "infrastructure/modules/functions/api"
$STAGE = "dist/functionapp"
$TIMESTAMP = Get-Date -Format "yyyyMMddHHmmss"
$ZIP = "dist/$APP.$TIMESTAMP.zip"

Remove-Item -Recurse -Force dist -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path "$STAGE/.python_packages/lib/site-packages"
Copy-Item -Recurse "$SRC_DIR/*" "$STAGE/"
python -m pip install --upgrade pip
python -m pip install -r "$STAGE/requirements.txt" --target "$STAGE/.python_packages/lib/site-packages"
Compress-Archive -Path "$STAGE/*" -DestinationPath $ZIP -Force

# CRITICAL: Disable remote build
az functionapp config appsettings set --name $APP --resource-group $RG --settings SCM_DO_BUILD_DURING_DEPLOYMENT=false ENABLE_ORYX_BUILD=false

# Deploy the vendored package
az functionapp deployment source config-zip --name $APP --resource-group $RG --src $ZIP
```

**DEPLOYMENT REQUIREMENTS:**
1. **Database Driver Requirements**: Azure Functions with Python runtime REQUIRES `pg8000>=1.31.2` ONLY
   - ❌ NEVER add `psycopg2-binary` - causes deployment failures
   - ❌ NEVER add `asyncpg` without proper async setup
   - ✅ Use ONLY `pg8000>=1.31.2` in requirements.txt
   - ✅ Update database manager to try `pg8000` FIRST before other drivers

2. **NEVER USE REMOTE BUILD FOR CRITICAL DEPLOYMENTS:**
   - ❌ NEVER use `func azure functionapp publish reportmate-api --build remote` - unreliable
   - ❌ NEVER use plain `az functionapp deployment source config-zip` without vendored deps
   - ✅ ALWAYS use vendored `.python_packages` deployment for production
   - ✅ ALWAYS disable remote build settings before deployment

3. **Azure Functions 500 Error Debugging**:
   - ✅ Health endpoint working = Python runtime OK
   - ❌ Device/Events endpoints 500 = Database connection or import issues
   - ✅ Check Azure portal Function logs for detailed error messages
   - ✅ Test database connection separately from API endpoints
   - ✅ Create diagnostic functions (dbtest) to verify module availability

**VERIFIED WORKING ENDPOINTS (September 10, 2025):**
- ✅ `/api/health` - Returns healthy status
- ✅ `/api/devices` - Returns 80+ real device records
- ✅ `/api/events` - Returns real event data
- ✅ `/api/device/{serial}` - Returns complete device information
- ✅ `/api/negotiate` - SignalR negotiation endpoint

**CRITICAL SUCCESS VERIFICATION:**
```powershell
# These must ALL return real data (not 500 errors):
curl "https://reportmate-api.azurewebsites.net/api/health"
curl "https://reportmate-api.azurewebsites.net/api/devices"
curl "https://reportmate-api.azurewebsites.net/api/events"
curl "https://reportmate-api.azurewebsites.net/api/device/0F33V9G25083HJ"
```

**SOLUTION A (Recommended - Deterministic):** Vendor dependencies into `.python_packages` and ZIP deploy

```powershell
# Use minimal requirements.txt (avoid pinning platform libs)
# infrastructure/modules/functions/api/requirements.txt should contain ONLY:
pg8000>=1.31.2

# One-shot build+deploy (run from repo root)
$APP = "reportmate-api"
$RG = "ReportMate" 
$SRC_DIR = "infrastructure/modules/functions/api"
$STAGE = "dist/functionapp"
$TIMESTAMP = Get-Date -Format "yyyyMMddHHmmss"
$ZIP = "dist/$APP.$TIMESTAMP.zip"

Remove-Item -Recurse -Force dist -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path "$STAGE/.python_packages/lib/site-packages"
Copy-Item -Recurse "$SRC_DIR/*" "$STAGE/"
python -m pip install --upgrade pip
python -m pip install -r "$STAGE/requirements.txt" --target "$STAGE/.python_packages/lib/site-packages"
Compress-Archive -Path "$STAGE/*" -DestinationPath $ZIP -Force

# Disable remote build (critical!)
az functionapp config appsettings set --name $APP --resource-group $RG --settings SCM_DO_BUILD_DURING_DEPLOYMENT=false ENABLE_ORYX_BUILD=false

# Deploy the vendored package
az functionapp deployment source config-zip --name $APP --resource-group $RG --src $ZIP
```

**SOLUTION B (Alternative):** Use proper remote build (NOT plain config-zip)

```powershell
cd infrastructure\modules\functions\api
func azure functionapp publish reportmate-api --python --build remote
```

**WHY THIS HAPPENS:**
- ❌ ZIP push assumes ready-to-run code (no build steps)
- ❌ `requirements.txt` gets ignored completely
- ❌ Nothing ends up in `/home/site/wwwroot/.python_packages`
- ❌ All imports fail: `ModuleNotFoundError`

**CRITICAL RULES:**
- ✅ Use `func azure functionapp publish --build remote` for remote builds
- ✅ Use vendored `.python_packages` + ZIP for deterministic deploys  
- ✅ Keep `requirements.txt` minimal (no `azure.functions` - platform provides it)
- ❌ NEVER use plain `az functionapp deployment source config-zip` without vendored deps
- ❌ NEVER rely on ZIP deploy to trigger builds (it won't)

**Verification Commands:**
```powershell
# Check function status
az functionapp show --name reportmate-api --resource-group ReportMate --query "state"

# ❌ NOTE: az webapp log tail DOES NOT WORK for Function Apps - do not use
# ❌ NOTE: az functionapp logs tail DOES NOT EXIST - this was incorrect
# ✅ Use Azure portal Function logs or infrastructure\scripts\status.ps1 instead for debugging

# Test API endpoint
curl "https://reportmate-api.azurewebsites.net/api/device/0F33V9G25083HJ"

# Use status script for comprehensive health check
cd infrastructure\scripts
.\status.ps1
```

**Deploy Web Container (when frontend changes):**

```powershell
cd infrastructure
.\scripts\deploy-containers.ps1
```

**Deploy Web Container (without rebuilding - use existing image):**

```powershell
cd infrastructure
.\scripts\deploy-containers.ps1 -SkipBuild
```

**Deploy Web Container (with custom tag):**

```powershell
cd infrastructure
.\scripts\deploy-containers.ps1 -Tag "20250901141109-81bb6f2"
```

**Infrastructure Changes (Terraform - only for resource changes, NOT code updates):**

```powershell
cd infrastructure
terraform apply -auto-approve
```

#### 3.2 Container Deployment for Next.js Development

**Perfect workflow for iterative Next.js development:**

```powershell
# Quick deployment with latest code changes (recommended for development)
cd infrastructure\scripts
.\deploy-containers.ps1 -ForceBuild

# Deploy to development environment
.\deploy-containers.ps1 -Environment dev -ForceBuild

# Deploy existing image without rebuilding (faster, for testing deployment process)
.\deploy-containers.ps1 -SkipBuild -Tag "20250902152337-e8e4c2d"

# Deploy with custom tag
.\deploy-containers.ps1 -Tag "my-feature-v1"
```

**What the container deployment script handles automatically:**
- ✅ Smart tagging: `YYYYMMDDHHMMSS-githash` format
- ✅ Docker layer caching: Faster rebuilds using latest image as cache
- ✅ Image pushing: To Azure Container Registry (reportmateacr.azurecr.io)
- ✅ Container update: Updates running production/dev container app
- ✅ Health checks: Verifies deployment success
- ✅ Version tracking: Includes container image tag in settings page
- ✅ Build arguments: Passes IMAGE_TAG, BUILD_TIME, BUILD_ID to container

**Container deployment assumes:**
- ✅ Terraform infrastructure exists (Container Apps, ACR, etc.)
- ✅ Validates prerequisites (Docker, Azure CLI, authentication)
- ✅ Fails gracefully if infrastructure missing
- ✅ No risk of breaking existing infrastructure

**Container deployment is self-contained for updates** - perfect for daily development cycle:
1. Make changes to Next.js app (components, pages, APIs, etc.)
2. Run `.\deploy-containers.ps1 -ForceBuild`
3. Test on production: https://reportmate.ecuad.ca

**New feature: Image tag tracking in settings**
- Container info now shows actual deployed image tag
- Visible in settings page tooltip and copy-to-clipboard
- Format: `reportmateacr.azurecr.io/reportmate:20250902152337-e8e4c2d`

**CRITICAL DEPLOYMENT NOTES:**
- ✅ Use `func azure functionapp publish reportmate-api --build remote` for API code updates (NOT terraform)
- ✅ Use `.\deploy-containers.ps1 -Environment prod -ForceBuild` for frontend updates  
- ✅ Use `terraform apply -auto-approve` ONLY for infrastructure resource changes (new resources, networking, etc.)
- ✅ Azure Functions code is in `infrastructure\modules\functions\api` directory
- ❌ **NEVER use terraform for code deployments** - it doesn't update the running function code
- ❌ **NEVER use `func azure functionapp publish` from wrong directory** - must be in `modules\functions\api`
- ⚠️ Terraform only manages infrastructure resources, NOT application code
- 🔄 After API fixes, always test with: `curl -s "https://reportmate-api.azurewebsites.net/api/device/0F33V9G25083HJ"`

## 🚨 CRITICAL CONTAINER ARCHITECTURE (September 29, 2025) 🚨

**CORRECT ARCHITECTURE - NEVER VIOLATE AGAIN:**

✅ **ONLY ONE CONTAINER EXISTS:**
- `reportmate-functions-api` = The ONLY FastAPI container (production API for all platforms)
- URL: `https://reportmate-functions-api.blackdune-79551938.canadacentral.azurecontainerapps.io`

❌ **CONTAINERS THAT MUST NEVER EXIST:**
- `reportmate-web-app-prod` = ❌ DELETED - Should never be recreated
- `reportmate-web-app` = ❌ Should never exist
- `reportmate-container-prod` = ❌ Should never exist

❌ **DEPRECATED APIS THAT MUST BE ELIMINATED:**
- `reportmate-api.azurewebsites.net` = ❌ OLD deprecated Azure Functions (eliminate from all code)

**NAMING CONVENTION:**
- API containers are shared across ALL platforms (web, Mac, Windows apps)
- NEVER name containers with platform-specific names like "web-app"
- FastAPI container serves ALL client applications

**ENVIRONMENT VARIABLE RULES:**
- `API_BASE_URL` = Must always point to `reportmate-functions-api` container
- `NEXT_PUBLIC_API_BASE_URL` = Must always point to `reportmate-functions-api` container
- ❌ NEVER reference deprecated `reportmate-api.azurewebsites.net` in any environment files

**DEPLOYMENT RULES:**
- ✅ Deploy FastAPI container: `.\deploy-containers.ps1 -Environment prod -ForceBuild`
- ❌ NEVER create additional containers without explicit architecture review
- ✅ Frontend calls FastAPI container directly (no internal API calls)

This architecture was established September 29, 2025 - NEVER CREATE DUPLICATE CONTAINERS AGAIN!

#### 3.1 Common Deployment Issues

**Error: "Unable to find project root. Expecting to find one of host.json"**
- ❌ You're in wrong directory
- ✅ Must be in `infrastructure\modules\functions\` directory
- ✅ Verify `host.json` exists: `ls host.json`

**Error: API changes not reflected after terraform apply**
- ❌ Terraform doesn't deploy function code
- ✅ Use `func azure functionapp publish reportmate-api --python` instead

**Error: Dashboard shows no data after API updates**
- ✅ Check API response structure: `curl "https://reportmate-api.azurewebsites.net/api/device/0F33V9G25083HJ"`
- ✅ Verify clientVersion is dynamic (not hardcoded)
- ✅ Ensure API returns clean device structure matching frontend expectations

**Memory Leak & Performance Issues (FIXED):**
- ✅ **Browser Memory Leak Fix**: Implemented memory management utilities in dashboard hooks
- ✅ **SignalR Connection Improvements**: Added proper cleanup and memory management
- ✅ **Polling vs SignalR**: Polling is WORKING as primary mechanism, SignalR infrastructure deployed but client-side connection issues
- 🔧 **Environment Variables**: Use `NEXT_PUBLIC_` prefix for client-side access in Next.js
- � **SignalR Status**: See `docs/SIGNALR_STATUS.md` for complete implementation status

**SignalR Infrastructure Status (INFRASTRUCTURE WORKING, CLIENT BROKEN):**
- ✅ Azure WebPubSub service: `reportmate-signalr` deployed and functional
- ✅ Negotiate endpoint: `https://reportmate-api.azurewebsites.net/api/negotiate` working
- ✅ JWT token generation: Proper authentication with Azure WebPubSub
- ✅ Environment variables: `EVENTS_CONNECTION` configured in Function App
- ❌ Client-side connection: useEffect not executing due to compilation issues
- ✅ **WORKING FALLBACK**: 30-second polling provides real-time updates

**CRITICAL API RESTORATION SUCCESS (September 2025):**
- ✅ **FIXED**: All API endpoints restored and functional with real data
- ✅ **SOLUTION**: Vendored deployment with .python_packages approach
- ✅ **VERIFIED**: Dashboard now displays real device data (80+ devices)
- ⚠️ **NEVER BREAK AGAIN**: Use only vendored deployment method documented above

**CRITICAL AUTHENTICATION ISSUE:**
- ❌ **Frontend using REPORTMATE_PASSPHRASE for internal communication** - This is WRONG!
- ✅ **REPORTMATE_PASSPHRASE is for Windows clients only** - NOT for web app
- ✅ **Web app should use Azure Managed Identity** - For Azure-to-Azure communication
- 🔧 **Fix**: Remove `X-API-PASSPHRASE` headers from all frontend API calls
- 🔧 **Fix**: Configure Azure Functions to allow internal Azure traffic without passphrase

**Error: "Invalid revalidate value" in Next.js**
- ❌ Cannot use `export const revalidate` in client components ("use client")
- ✅ Only use `revalidate` in server components (pages without "use client")
- ✅ Use `export const dynamic = 'force-dynamic'` for dynamic client components

## 🚨 Current System Status & Troubleshooting

**FastAPI Container Status (September 29, 2025):**
- ✅ **Container Running**: FastAPI container successfully deployed and operational
- ✅ **Health endpoint**: Working (`curl https://reportmate-functions-api.blackdune-79551938.canadacentral.azurecontainerapps.io/api/health`)
- ✅ **Individual device endpoint**: Working with complete data (`/api/device/0F33V9G25083HJ`)
- ⚠️ **Bulk devices endpoint**: Working but missing inventory data in bulk response (`/api/devices`)
- ✅ **Database connectivity**: 217 devices, all module tables populated
- ✅ **Architecture compliance**: Single FastAPI container, no deprecated APIs

**CRITICAL DEVICE IDENTIFICATION PATTERN (September 29, 2025):**
- ✅ **Database Schema**: `devices` table has `id` (primary key), `device_id` (UUID), `serial_number` (actual serial)
- ✅ **Module Tables**: All module tables (`inventory`, `system`, etc.) use `device_id` column containing SERIAL NUMBERS (not UUIDs)
- ✅ **API Standard**: Both bulk and individual endpoints must use `serial_number` for module queries
- ❌ **NEVER**: Query module tables with primary key ID or UUID - always use serial number
- ✅ **Device Links**: All frontend links use `/device/[serialNumber]` format (never UUID)

**Current Working Components:**
- ✅ FastAPI container infrastructure
- ✅ Azure PostgreSQL database with 217 devices
- ✅ Individual device endpoints with complete module data
- ✅ Container logs showing successful data processing
- ✅ Windows client data collection and transmission
- ✅ Next.js frontend calling FastAPI directly

**NEXT STEPS:**
- 🔧 **Debug bulk endpoint**: Fix LEFT JOIN query to include inventory data for all devices
- ✅ **Architecture verified**: Single container approach working correctly

#### 4. Source-Control Constraints

**Do not** embed hard-coded URLs or environment-specific values anywhere in `apps\www` or `clients\windows` (both are open-source submodules).
Example of a bad commit: adding `device/route.ts` with a hard-coded URL.



#### 5. Privileged Operations

Use **`sudo` for Windows** to perform elevated tasks (copying to `Program Files`, service installation, etc.). This bypasses UAC prompts in automated scripts and pipelines.



#### 6. Data Integrity & Schema Alignment

* The dashboard schema ↔︎ `osquery` pack ↔︎ `runner.exe` payload must remain **identical**. Any field added or renamed in one layer must be mirrored in the other two.
* Collect data exclusively with `osqueryi`; do **not** use WMI.
* Whenever new data points are added, update the Azure Functions API and validate schema alignment.



#### 7. Non-Negotiables

* **Signed binaries only.**
* **No hard-coded constants inside submodules.**
* **Runner-based ingestion is the single source of truth** (manual API calls don’t count).
* **Infrastructure changes are made only through Terraform.** Use the `az` CLI strictly for read-only inspection of status, settings, or configuration—never for mutations.



System is simple, we are:

1. collecting - local binary
2. transmitting - local binary
3. receiving - functions api
4. storing - database
5. reading - web app



## Core Repositories

- `\apps\www` is a submodule for **reportmate-web-app** – A React + Next.js web dashboard for visualizing device telemetry and module data  
- `\apps\swift` will a submodule for **reportmate-swift-app** – A native macOS/iOS app for visualizing reports and managing configuration  
- `\apps\csharp` will a submodule for **reportmate-csharp-app** – A native Windows app for viewing device state and local configuration

- `\clients\mac` will be a submodule for  **reportmate-mac-client** – macOS client for executing reporting queries  
- `\clients\win` is a submodule for **reportmate-windows-client** – Windows client for executing reporting queries  

- `\infrastructure` is a submodule for - **terraform-azurerm-reportmate** – Terraform and serverless telemetry ingestion for Azure  
- we won't use but will be a template offered: **terraform-aws-reportmate** – Terraform and serverless telemetry ingestion for AWS  

**terraform-azurerm-reportmate** is meant to be the repo for the entire infra: cloud resources, REST API, storage, database, etc




----


Well we have made it. The base modules data collections are virtually done. 
I have 99% of what I want. And its working really really well. 

It's time to move on to build the robust REST API layer of ReportMate.

We pretty much will have to most likely disregard most of, if not all, of the past cloud function code. But maybe not, you tell me. 

The cloud function(s) are only conduits, they don't process / change the data. That is done on device and each app can do some minor adaptations.

The goal is to get right now everything working while building it in a way that we will be able to say: "ReportMate offers a Powerful REST API - Our simple and intuitive developer JSON REST API allows you to develop custom automations based on your own individual needs."

I think this needs to happen at the cloud function API layer creation time which is now, but I am not expecting to have it built right now. Laying the groundwork yes.

The next objective is get the local collections we now have really deep data about the device send to the database so that the web app can get it.

# ReportMate Simplified Architecture Plan

## Simplified Architecture Goal:

```
Client (Enhanced) → Direct Database Upload → Frontend Display
    ↓                        ↓                    ↓
1. Single osquery pass   2. Store processed    3. Display actual
2. Process all data         data directly        collected data
3. Send structured JSON
```


System is simple, we are:

1. collecting - local binary
2. transmitting - local binary
3. receiving - functions api
4. storing - database
5. reading - web app

## Installs Module Debug Commands

When troubleshooting the installs module issue:

1. **Collection Test:**
```powershell
sudo pwsh -c "& 'C:\Program Files\ReportMate\runner.exe' -vv --run-module installs"
```

2. **Transmission Test:**
```powershell
sudo pwsh -c "& 'C:\Program Files\ReportMate\runner.exe' -vv --transmit-only"
```

3. **API Test:**
```powershell
Invoke-RestMethod -Uri "https://reportmate-api.azurewebsites.net/api/device/0F33V9G25083HJ"
```

4. **Full Collection & Transmission:**
```powershell
sudo pwsh -c "& 'C:\Program Files\ReportMate\runner.exe' -vv --collect-only"
sudo pwsh -c "& 'C:\Program Files\ReportMate\runner.exe' -vv --transmit-only"
```

The installs module should be collecting Cimian data and showing packages with proper status mapping in the frontend.



## Core Repositories

- `\apps\www` is a submodule for **reportmate-web-app** – A React + Next.js web dashboard for visualizing device telemetry and module data  
- `\apps\swift` will a submodule for **reportmate-swift-app** – A native macOS/iOS app for visualizing reports and managing configuration  
- `\apps\csharp` will a submodule for **reportmate-csharp-app** – A native Windows app for viewing device state and local configuration

- `\clients\mac` will be a submodule for  **reportmate-mac-client** – macOS client for executing reporting queries  
- `\clients\win` is a submodule for **reportmate-windows-client** – Windows client for executing reporting queries  

- `\infrastructure` is a submodule for - **terraform-azurerm-reportmate** – Terraform and serverless telemetry ingestion for Azure  
- we won't use but will be a template offered: **terraform-aws-reportmate** – Terraform and serverless telemetry ingestion for AWS  

**terraform-azurerm-reportmate** is meant to be the repo for the entire infra: cloud resources, REST API, storage, database, etc


## ReportMate Modular Architecture - Complete Data Flow

✅ Collection: osquery → module.json files
✅ Transmission: event.json → Azure Functions  
✅ Ingestion: Functions → individual DB tables
✅ Storage: PostgreSQL → JSONB per module
✅ API: Functions → exact data return
✅ Frontend: extractXxx() → modular processing
✅ Display: Components → module-specific UI

ReportMate is built with a strict modularization model where each module follows the exact same pattern from collection to display:

### Module Data Flow Pipeline:

**1. Collection (Windows Client - C#)**
- Location: `clients\windows\src\modules\[ModuleName]Module.cs`
- Uses: `osquery` SQL queries only (NO WMI)
- Output: Individual JSON files in `C:\ProgramData\ManagedReports\cache\[module].json`
- Examples: `applications.json`, `hardware.json`, `installs.json`, etc.

**2. Transmission (Windows Client - C#)**
- Location: `clients\windows\src\core\EventProcessor.cs`
- Combines: All module JSONs into single `event.json` payload
- Structure: Maintains module separation within single payload
- Endpoint: `POST /api/events` to Azure Functions

**3. Ingestion (Azure Functions - TypeScript)**
- Location: `infrastructure\functions\src\events.ts`
- Process: Routes each module to its own database table
- Validation: Enforces schema per module type
- No Processing: Data stored as-received (processing done on device)

**4. Storage (PostgreSQL Database)**
- Schema: One table per module (mirrors JSON structure)
- Tables: `applications`, `hardware`, `installs`, `network`, etc.
- Format: JSONB storage for flexibility
- Location: Azure PostgreSQL database

**5. API Functions (Azure Functions - TypeScript)**
- Location: `infrastructure\functions\src\device.ts`
- Endpoints: `/api/device/[serialNumber]` returns all module data
- Structure: Returns data exactly as stored (no transformation)
- Module Access: Individual module endpoints available

**6. Frontend Processing (React/Next.js - TypeScript)**
- Location: `apps\www\src\lib\data-processing\modules\[module].ts`
- Functions: `extractXxx()` functions (extract only, no heavy processing)
- Pattern: One module file per data type
- Exports: Centralized through `apps\www\src\lib\data-processing\modules\index.ts`

**7. Frontend Display (React Components)**
- Tabs: `apps\www\src\components\tabs\[Module]Tab.tsx`
- Cards: `apps\www\src\components\cards\[Module]Card.tsx`
- Tables: `apps\www\src\components\tables\[Module]Table.tsx`
- Widgets: `apps\www\src\components\widgets\[Module].tsx`

### ⚠️ **CRITICAL: No Monolithic Code Allowed**

**ELIMINATED MONOLITHIC FILES:**
- ❌ `component-data.ts` - DELETED ✅
- ❌ `component-data-fixed.ts` - DELETED ✅  
- ❌ `device-mapper.ts` - DELETED ✅
- ❌ `modules-index.ts` - DELETED ✅ (obsolete file with broken references)
- ❌ `temp-network-function.ts` - DELETED ✅

**ONLY MODULAR FILES ALLOWED:**
- ✅ `modules/[module].ts` - Individual module files only
- ✅ `modules/index.ts` - Centralized exports only
- ✅ `device-mapper-modular.ts` - Clean modular mapper only
- ✅ `index.ts` - Main entry point only

**MONOLITHIC PATTERNS TO AVOID:**
- ❌ `processXxxData()` functions - Use `extractXxx()` instead
- ❌ Large files with multiple module logic - Split into individual modules
- ❌ Cross-module dependencies - Each module must be self-contained
- ❌ Hardcoded fallback data - Frontend reads real data only

### Module Architecture Rules:

✅ **Frontend = Reader Only**: Heavy processing happens on device at collection
✅ **One File Per Module**: Each module is completely self-contained
✅ **No Cross-Dependencies**: Modules don't reference each other
✅ **Consistent Naming**: extractXxx(), XxxInfo interface, XxxTab component
✅ **No Monolithic Files**: Eliminated all "monster" files (component-data.ts, device-mapper.ts)

### Adding a New Module:

1. **Collection**: Create `[Module]Module.cs` with osquery collection
2. **Storage**: Add module table to database schema
3. **Processing**: Create `apps\www\src\lib\data-processing\modules\[module].ts`
4. **Display**: Create React components following naming pattern
5. **Export**: Add to `modules\index.ts` centralized exports

ReportMate is built with a modularization model and what I mean by that is in the source collection we will be matching the modules as well from source.


Set-Location C:\Users\rchristiansen\DevOps\ReportMate\clients\windows
.\build.ps1 -Sign -SkipNUPKG -SkipZIP
sudo powershell -Command "Copy-Item '.\.publish\runner.exe' 'C:\Program Files\ReportMate\runner.exe' -Force"
sudo pwsh -c "& 'C:\Program Files\ReportMate\runner.exe' -vv --collect-only --run-module installs"
sudo pwsh -c "& 'C:\Program Files\ReportMate\runner.exe' -vv --transmit-only"


## Cimian:
Reminder that we can not run unsigned binaries so use `.\build.ps1 -Sign -Binary managedsoftwareupdate` (never ever skip signing, we can not run unsigned binaries in this system) to build a new one and you can test it with using `sudo managedsoftwareupdate.exe` with the relevant flags so its in line in the console here, such as when you are testing the runs use: `sudo .\release\arm64\managedsoftwareupdate.exe -v --checkonly` so it doesn't run installs and take forever



Managed Packages versions and statusese
curl -s "https://reportmate-api.azurewebsites.net/api/device/0F33V9G25083HJ" | ConvertFrom-Json | Select-Object -ExpandProperty installs | Select-Object -ExpandProperty cimian | Select-Object -ExpandProperty items | Select-Object itemName, latestVersion, currentStatus | Format-Table




## Complete Tech Stack Integration when adding new data
Now that the Windows client is updated and working, let's proceed up the tech stack as you requested:

Awesome, let's run through one more time through the whole stack now that we've made these changes to the statuses, confirm everything is in alignment:

- Windows Client - COMPLETED and tested
- Azure Functions API - Update to handle new field structure
- Database Schema - Update table structure for new fields
- Prisma Schema - Update ORM mappings
- Frontend Device Mapper - Update UI to display new field data
- Frontend React UI elements 



And let's go back all the way to the client on device collection level to make sure these are fields we create in the collection step, so we don't need to run data processing on the cloud backend, happens on device at collection time.


Awesome we have the collection working, now we need to go up the tech stack and make sure every step knowns and understands this new data format and fields: the api functions, the db storage table, the prisma schema, the device-mapper frontend code




### Client Local on Device Collection and Data Transmission

The C# code in the runner is separated by module. We have what is needed for `osquery` logic for all and anything that is shared and collection code files separated by module: 

Applications - collection of all applications data
Hardware - collection of all hardware details
Inventory - name, serial, UUID, asset tag, 
Installs - collection of Cimian config and run logs
Management - collection of all MDM info: enrollment status, enrollment date, server url, last checked in, etc
Network - collection of all network info
Profiles - collection of all MDM Profiles and CSP / GPO applied settings on device
Security - collection of security data TPM, EDR, AV, etc
System - collection of operating system data

Allows future modules to be added easily without interfering with core modules

Save each dataset as their own structured JSON locally in `C:\ProgramData\ManagedReports\cache`: applications.json, hardware.json, inventory.json, installs.json, management.json, network.json, profiles.json, security.json, system.json

Collect all the data from the modular jsons into a single structured `event.json` payload that inside the json still has the sections (the idea here is to make it super easy in the future to add/remove modules)

We now have this fully built and the latest run sample is in `"C:\ProgramData\ManagedReports\cache\2025-07-15-195231"` for us to use and understand what is coming in from the device.

Functions should also have modularity (in however way it makes sense to have it) so its easy to add/remove modules.


 

Can you see how that is different from:

```
{
  "success": true,
  "device": {
    "id": "0F33V9G25083HJ",
    "serial_number": "0F33V9G25083HJ", 
    "status": "online",
    "last_seen": "2025-07-23T00:54:45.514604+00:00",
    "modules": {
      "source": "runner.exe --transmit-only (module: system)",
      "collectionType": "transmit-only-system",
      "clientVersion": "2025.7.22.0",
      "collectionTimestamp": "2025-07-22T21:09:25.8118614Z",
      "osQuery": {
        "system": [
          {
            "uptime": "4.22:47:11",
            "updates": [...],
            "services": [...],
            "environment": [...],
            "operatingSystem": {...}
          }
        ]
      }
    }
  }
}
```

This is one of the core core issues we are having, this discrepancy between the collection and there's bad data processing happening in the transmission or in the api ingest or in the database storage stepsThe payload is perfectly nested exactly. There's a few metadata keys:

```
{
  "deviceId": "79349310-287D-8166-52FC-0644E27378F7",
  "collectedAt": "2025-07-22T21:09:25.8118614Z",
  "clientVersion": "2025.7.22.0",
  "platform": "Windows",
```

and everything else is perfectly nested per module

# Database structure

Core Tables (Mirror Windows Client Payload):

devices - Core device information
events - Event metadata (from event.json metadata array)

One table per module JSON file:
applications ← applications.json
displays ← displays.json
hardware ← hardware.json
installs ← installs.json
inventory ← inventory.json
management ← management.json
network ← network.json
printers ← printers.json
profiles ← profiles.json
security ← security.json
system ← system.json

ReportMate Business Logic Tables (Optional):
business_units
machine_groups
business_unit_users
business_unit_groups

This is exactly what the Windows client sends and makes perfect sense! Each JSON file from the client cache becomes one database table. Simple, modular, and clean.



      "inventory": {
        "deviceName": "Rod Christiansen",
        "usage": "Assigned",
        "catalog": "Staff",
        "department": "IT",
        "location": "B1115",
        "assetTag": "A004733",
        "serialNumber": "0F33V9G25083HJ"
        "uuid": "79349310-287D-8166-52FC-0644E27378F7",
      },

The one change we should do in how `event.json` is structure is have this in a metadata struct at the top, there is an empty one right now *at the bottom* -- let's start with this actually and it should have the device serialNumber as well.

What we have to tackle next to fix is the transmission, ingestion, storage of this perfect data we have locally right now so we can get the pages routers rendering it them as is -- the structure should be ready to go for them?

🚀 Now let's focus on the Web App!
The infrastructure is rock-solid. Let's enhance the web application! Here are some key areas we can improve:

1. Dashboard Enhancements
Better real-time updates
More detailed device information
Enhanced filtering and search

2. Device Detail Views
Individual device pages with full module data
Historical tracking
Performance metrics

3. Event Management
Advanced event filtering
Event alerting/notifications
Export capabilities

4. UI/UX Improvements
Mobile responsiveness
Dark/light theme refinements
Performance optimizations

5. Additional Features
User authentication
Role-based access
Reporting capabilities




Complete Modular Architecture Implemented:
✅ 11 modular tables - One per JSON module from Windows client
✅ All tables have data - 11 records total (1 per module)
✅ No complex sub-tables - Simple, clean structure
✅ JSONB storage - Flexible data storage per module

3. Data Integrity Enforced:
✅ No duplicate serial numbers
✅ No duplicate device IDs
✅ Serial number + Device ID uniqueness enforced

4. Event Type Validation Working:
✅ Only info events (8 events) - within allowed types
✅ No invalid event types - Strict validation working

5. Clean Database Architecture
📊 CURRENT STATE:
📱 Total devices: 1
📅 Total events: 8  
📦 Total module records: 11
🏗️ Module tables: 11

✅ applications: 1 records
✅ displays: 1 records  
✅ hardware: 1 records
✅ installs: 1 records
✅ inventory: 1 records
✅ management: 1 records
✅ network: 1 records
✅ printers: 1 records
✅ profiles: 1 records
✅ security: 1 records
✅ system: 1 records

🏗️ Architecture Summary:
You now have exactly what you requested:

✅ One Azure PostgreSQL database
✅ One table per module (matching the JSON files from runner.exe)
✅ Serial number uniqueness enforced
✅ Device ID (UUID) constraints working
✅ Event type restrictions (success, warning, error, info, system only)
✅ Clean data transmission from runner.exe → Azure Functions → PostgreSQL

---

Let's do two very important things: 

1. create a single canonical review `infrastructure\scripts\check.ps1` script that tests and checks over every single component of the infrastructure -- what is received from transmission, what function is doing, how the data is stored in database tables -- we need a single place not these dozens and dozens of scripts we have to review where we are at... collapse everything into this single script and delete every other one -- there's way too much going on.

2. make sure that we have a full 'bootstrap' setup for migration and for when someone clones the project and runs an infrastructure terraform, they get the schemas created and migrated -- essentially everything is ready out of the box for a new infra provisoning without all this boold sweat and tears we are going through right now



API DATA:
https://reportmate-api.azurewebsites.net/api/device/0F33V9G25083HJ

https://reportmate-api.azurewebsites.net/api/events/46/payload


Still not displaying -- must be the `apps\www\src\lib\data-processing\device-mapper.ts` again??


Fantastic -- let's now make sure transmission is working, api is good to receive this data, the db schema and the table are good and the data-mapper for frontend is also ready


Backend API Modularization: 
Module-specific endpoints?

### Display front

Web app, or native Mac Swift/Swift UI/Swift Data apps, or native Windows C# apps. We are only working on the web app right now.

The `/device` page is the main page where all the details show up and the biggest focus of the modularity. We are already way on our way there:

`\APPS\WWW\SRC\COMPONENTS`:

```
ª   DeviceEvents.tsx
ª   DeviceEventsSimple.tsx
ª   ErrorBoundary.tsx
ª   ModuleManager.tsx
ª   theme-provider.tsx
ª   
+---cards
ª       ApplicationsCard.tsx
ª       EventsCard.tsx
ª       HardwareCard.tsx
ª       index.ts
ª       InstallsCard.tsx
ª       NetworkCard.tsx
ª       ProfilesCard.tsx
ª       SecurityCard.tsx
ª       SystemCard.tsx
ª       
+---tables
ª       ApplicationsTable.tsx
ª       index.ts
ª       ManagedInstallsTable.tsx
ª       NetworkTable.tsx
ª       ProfilesTable.tsx
ª       SecurityCard.tsx
ª       
+---tabs
ª       ApplicationsTab.tsx
ª       EventsTab.tsx
ª       HardwareTab.tsx
ª       index.ts
ª       InfoTab.tsx
ª       InstallsTab.tsx
ª       NetworkTab.tsx
ª       ProfilesTab.tsx
ª       SecurityTab.tsx
ª       SystemTab.tsx
ª       
+---widgets
        Hardware.tsx
        Information.tsx
        Management.tsx
        Network.tsx
        Security.tsx
        shared.tsx
        System.tsx
``` 

Save information as we go in /docs so you can refer to it as we go
Update your progress in docs\MODULAR_IMPLEMENTATION_STATUS.md

````