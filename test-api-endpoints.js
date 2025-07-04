const https = require('https');
const http = require('http');

const API_BASE_URL = process.env.REPORTMATE_API_URL || process.env.NEXT_PUBLIC_API_BASE_URL || 'https://your-reportmate-api.com';

function testEndpoint(url, method = 'GET', data = null) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const options = {
      hostname: urlObj.hostname,
      port: urlObj.port || (urlObj.protocol === 'https:' ? 443 : 80),
      path: urlObj.pathname + urlObj.search,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'ReportMate-Test/1.0'
      }
    };

    if (data) {
      const jsonData = JSON.stringify(data);
      options.headers['Content-Length'] = Buffer.byteLength(jsonData);
    }

    const lib = urlObj.protocol === 'https:' ? https : http;
    const req = lib.request(options, (res) => {
      let responseData = '';
      res.on('data', (chunk) => {
        responseData += chunk;
      });
      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          headers: res.headers,
          data: responseData
        });
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    if (data) {
      req.write(JSON.stringify(data));
    }

    req.end();
  });
}

async function testApiEndpoints() {
  console.log('🚀 Testing ReportMate API endpoints...');
  console.log(`Base URL: ${API_BASE_URL}`);
  console.log('');

  // Test 1: Check if the main site is accessible
  try {
    console.log('1. Testing main site accessibility...');
    const response = await testEndpoint(`${API_BASE_URL}/`);
    console.log(`   Status: ${response.statusCode}`);
    console.log(`   ✅ Main site accessible`);
  } catch (error) {
    console.log(`   ❌ Main site failed: ${error.message}`);
  }

  // Test 2: Test /api/ingest endpoint with HEAD request
  try {
    console.log('2. Testing /api/ingest endpoint (HEAD)...');
    const response = await testEndpoint(`${API_BASE_URL}/api/ingest`, 'HEAD');
    console.log(`   Status: ${response.statusCode}`);
    if (response.statusCode === 200 || response.statusCode === 405) {
      console.log(`   ✅ /api/ingest endpoint exists`);
    } else {
      console.log(`   ⚠️  /api/ingest returned ${response.statusCode}`);
    }
  } catch (error) {
    console.log(`   ❌ /api/ingest failed: ${error.message}`);
  }

  // Test 3: Test /api/device endpoint
  try {
    console.log('3. Testing /api/device endpoint...');
    const response = await testEndpoint(`${API_BASE_URL}/api/device/test-device`);
    console.log(`   Status: ${response.statusCode}`);
    if (response.statusCode === 404) {
      console.log(`   ✅ /api/device endpoint exists (404 = device not found, which is expected)`);
    } else if (response.statusCode === 200) {
      console.log(`   ✅ /api/device endpoint exists and returned device data`);
    } else {
      console.log(`   ⚠️  /api/device returned ${response.statusCode}`);
    }
  } catch (error) {
    console.log(`   ❌ /api/device failed: ${error.message}`);
  }

  // Test 4: Test device registration (new_client event)
  try {
    console.log('4. Testing device registration (new_client event)...');
    const testDeviceData = {
      device: "TEST-DEVICE-123",
      kind: "new_client",
      ts: new Date().toISOString(),
      payload: {
        message: "Test device registration",
        source: "api-test",
        device_id: "TEST-DEVICE-123",
        name: "Test Computer",
        model: "Test Model",
        os: "Windows 11",
        manufacturer: "Test Manufacturer",
        platform: "windows",
        registration_time: new Date().toISOString()
      }
    };

    const response = await testEndpoint(`${API_BASE_URL}/api/ingest`, 'POST', testDeviceData);
    console.log(`   Status: ${response.statusCode}`);
    if (response.statusCode === 202) {
      console.log(`   ✅ Device registration successful (202 Accepted)`);
    } else if (response.statusCode === 401) {
      console.log(`   ⚠️  Device registration requires authentication (401 Unauthorized)`);
    } else {
      console.log(`   ❌ Device registration failed with ${response.statusCode}`);
      console.log(`   Response: ${response.data}`);
    }
  } catch (error) {
    console.log(`   ❌ Device registration failed: ${error.message}`);
  }

  // Test 5: Test data submission (device_data event)
  try {
    console.log('5. Testing data submission (device_data event)...');
    const testDataPayload = {
      device: "TEST-DEVICE-123",
      kind: "device_data",
      ts: new Date().toISOString(),
      payload: {
        device: {
          DeviceId: "TEST-DEVICE-123",
          ComputerName: "Test Computer",
          SerialNumber: "TEST-DEVICE-123",
          Model: "Test Model",
          OperatingSystem: "Windows 11",
          Manufacturer: "Test Manufacturer"
        },
        system: {
          uptime: 12345,
          cpu_usage: 25.5
        },
        collection_timestamp: new Date().toISOString(),
        client_version: "2025.7.1.3",
        source: "api-test"
      }
    };

    const response = await testEndpoint(`${API_BASE_URL}/api/ingest`, 'POST', testDataPayload);
    console.log(`   Status: ${response.statusCode}`);
    if (response.statusCode === 202) {
      console.log(`   ✅ Data submission successful (202 Accepted)`);
    } else if (response.statusCode === 401) {
      console.log(`   ⚠️  Data submission requires authentication (401 Unauthorized)`);
    } else {
      console.log(`   ❌ Data submission failed with ${response.statusCode}`);
      console.log(`   Response: ${response.data}`);
    }
  } catch (error) {
    console.log(`   ❌ Data submission failed: ${error.message}`);
  }

  console.log('');
  console.log('✅ API endpoint testing completed!');
  console.log('');
  console.log('📋 Summary:');
  console.log('- If registration/data submission shows 401 Unauthorized, authentication is required');
  console.log('- If registration/data submission shows 202 Accepted, the API is working correctly');
  console.log('- Check the dashboard at your ReportMate URL/dashboard to see if test data appeared');
}

// Run the tests
testApiEndpoints().catch(console.error);
