#!/bin/bash
# Database setup and migration script

set -e

echo "🗄️  Setting up Reportmate database..."

# Get database connection from environment or Terraform
if [ -z "$DATABASE_URL" ]; then
    echo "❌ DATABASE_URL not set. Run 'source .env.production' or set manually."
    exit 1
fi

echo "📋 Creating database schema..."

# Create tables
psql "$DATABASE_URL" << 'EOF'
    -- Events table for storing all device events
    CREATE TABLE IF NOT EXISTS events (
        id VARCHAR(255) PRIMARY KEY,
        device VARCHAR(255) NOT NULL,
        kind VARCHAR(100) NOT NULL,
        ts TIMESTAMP WITH TIME ZONE NOT NULL,
        payload JSONB,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    
    -- Cimian runs table for managed installs tracking
    CREATE TABLE IF NOT EXISTS cimian_runs (
        id VARCHAR(255) PRIMARY KEY,
        device VARCHAR(255) NOT NULL,
        ts TIMESTAMP WITH TIME ZONE NOT NULL,
        exit_code INTEGER,
        duration INTEGER,
        details TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    
    -- Devices table for device inventory
    CREATE TABLE IF NOT EXISTS devices (
        id VARCHAR(255) PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        model VARCHAR(255),
        os VARCHAR(255),
        serial_number VARCHAR(255),
        asset_tag VARCHAR(255),
        ip_address INET,
        mac_address MACADDR,
        location VARCHAR(255),
        last_seen TIMESTAMP WITH TIME ZONE,
        status VARCHAR(50) DEFAULT 'unknown',
        uptime INTERVAL,
        metadata JSONB,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    
    -- Indexes for performance
    CREATE INDEX IF NOT EXISTS idx_events_device_ts ON events(device, ts DESC);
    CREATE INDEX IF NOT EXISTS idx_events_kind_ts ON events(kind, ts DESC);
    CREATE INDEX IF NOT EXISTS idx_events_ts ON events(ts DESC);
    CREATE INDEX IF NOT EXISTS idx_cimian_runs_device_ts ON cimian_runs(device, ts DESC);
    CREATE INDEX IF NOT EXISTS idx_devices_last_seen ON devices(last_seen DESC);
    CREATE INDEX IF NOT EXISTS idx_devices_status ON devices(status);
    
    -- Insert sample data for testing
    INSERT INTO devices (id, name, model, os, serial_number, last_seen, status, location) VALUES
    ('JY93C5YGGM', 'Celeste Martin', 'MacBook Air (15-inch, M2, 2023)', 'macOS 15.2.0', 'JY93C5YGGM', NOW() - INTERVAL '30 minutes', 'online', 'Marketing'),
    ('FVFXQ2P3JM', 'Alex Chen', 'MacBook Pro (16-inch, M3 Pro, 2023)', 'macOS 15.2.0', 'FVFXQ2P3JM', NOW() - INTERVAL '15 minutes', 'online', 'Engineering'),
    ('WS-ACC-001', 'Jennifer Davis', 'Dell OptiPlex 7090', 'Windows 11 Pro', 'WS-ACC-001', NOW() - INTERVAL '1 hour', 'warning', 'Accounting')
    ON CONFLICT (id) DO NOTHING;
EOF

echo "✅ Database schema created successfully!"
echo "🎉 Reportmate database is ready for deployment!"
