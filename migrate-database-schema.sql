-- ReportMate Database Schema Migration
-- Aligns with Prisma schema and osquery data collection
-- Version: 2025.7.2.1

-- First, create the core tables that don't depend on others

-- Business Units for access control and organization
CREATE TABLE IF NOT EXISTS business_units (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Machine Groups for device organization and passphrase-based access
CREATE TABLE IF NOT EXISTS machine_groups (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    passphrase_hash VARCHAR(255) NOT NULL, -- SHA-256 hash of the group's passphrase
    business_unit_id INTEGER REFERENCES business_units(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Business Unit User assignments (many-to-many)
CREATE TABLE IF NOT EXISTS business_unit_users (
    id SERIAL PRIMARY KEY,
    business_unit_id INTEGER NOT NULL REFERENCES business_units(id) ON DELETE CASCADE,
    user_identifier VARCHAR(255) NOT NULL, -- username or AD GUID
    role VARCHAR(100) DEFAULT 'viewer',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(business_unit_id, user_identifier)
);

-- Business Unit Group assignments (many-to-many)
CREATE TABLE IF NOT EXISTS business_unit_groups (
    id SERIAL PRIMARY KEY,
    business_unit_id INTEGER NOT NULL REFERENCES business_units(id) ON DELETE CASCADE,
    group_identifier VARCHAR(255) NOT NULL, -- AD group name prefixed with @
    role VARCHAR(100) DEFAULT 'viewer',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(business_unit_id, group_identifier)
);

-- Drop and recreate devices table with proper schema
DROP TABLE IF EXISTS devices CASCADE;

-- Core Device model - normalized approach
CREATE TABLE devices (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    model VARCHAR(255),
    os VARCHAR(255),
    serial_number VARCHAR(255),
    asset_tag VARCHAR(255),
    ip_address VARCHAR(255),
    mac_address VARCHAR(255),
    location VARCHAR(255),
    last_seen TIMESTAMP WITH TIME ZONE,
    status VARCHAR(50) DEFAULT 'unknown',
    uptime VARCHAR(255),
    total_events INTEGER DEFAULT 0,
    last_event_time TIMESTAMP WITH TIME ZONE,
    
    -- Machine Group assignment
    machine_group_id INTEGER REFERENCES machine_groups(id) ON DELETE SET NULL,
    
    -- Basic hardware fields (most commonly queried)
    processor VARCHAR(255),
    memory VARCHAR(255),
    storage VARCHAR(255),
    architecture VARCHAR(255),
    
    -- System Performance Metrics
    disk_utilization INTEGER,
    memory_utilization INTEGER,
    cpu_utilization INTEGER,
    temperature INTEGER,
    battery_level INTEGER,
    boot_time TIMESTAMP WITH TIME ZONE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enhanced Event model
CREATE TABLE IF NOT EXISTS events (
    id VARCHAR(255) PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    kind VARCHAR(100) NOT NULL,
    ts TIMESTAMP WITH TIME ZONE NOT NULL,
    payload JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Cimian runs table for Windows managed installs tracking
-- Using "Cimian" for Windows (vs "Munki" for Macs)
CREATE TABLE IF NOT EXISTS cimian_runs (
    id VARCHAR(255) PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    ts TIMESTAMP WITH TIME ZONE NOT NULL,
    exit_code INTEGER,
    duration INTEGER,
    managed_installs_system VARCHAR(50) DEFAULT 'Cimian', -- 'Cimian' for Windows, 'Munki' for Mac
    details TEXT,
    
    -- Additional Cimian-specific fields
    version VARCHAR(255),
    errors TEXT,
    warnings TEXT,
    installs_count INTEGER DEFAULT 0,
    removals_count INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Device Hardware details (normalized approach) - aligns with osquery system_info
CREATE TABLE IF NOT EXISTS device_hardware (
    id VARCHAR(255) PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    
    -- From osquery system_info
    cpu_brand VARCHAR(255),
    cpu_physical_cores INTEGER,
    cpu_logical_cores INTEGER,
    physical_memory BIGINT,
    hardware_vendor VARCHAR(255),
    hardware_model VARCHAR(255),
    hardware_version VARCHAR(255),
    hardware_serial VARCHAR(255),
    
    -- From osquery memory_devices
    memory_devices JSONB,
    
    -- From osquery disk_info
    disk_info JSONB,
    
    -- Additional hardware details
    manufacturer VARCHAR(255),
    product_name VARCHAR(255),
    bios_version VARCHAR(255),
    firmware_version VARCHAR(255),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Device Network Interfaces - aligns with osquery interface_details
CREATE TABLE IF NOT EXISTS network_interfaces (
    id VARCHAR(255) PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    interface_name VARCHAR(255) NOT NULL,
    mac_address VARCHAR(255),
    ip_address VARCHAR(255),
    netmask VARCHAR(255),
    broadcast VARCHAR(255),
    interface_type VARCHAR(255),
    mtu INTEGER,
    status VARCHAR(50),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Security Features - aligns with osquery security data
CREATE TABLE IF NOT EXISTS security_features (
    id VARCHAR(255) PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    
    -- From osquery bitlocker_info (Windows)
    bitlocker_status JSONB,
    
    -- From osquery windows_security_center
    antivirus VARCHAR(255),
    antispyware VARCHAR(255),
    firewall VARCHAR(255),
    autoupdate VARCHAR(255),
    uac VARCHAR(255),
    
    -- From osquery tpm_info
    tpm_activated BOOLEAN,
    tmp_enabled BOOLEAN,
    tpm_owned BOOLEAN,
    tpm_version VARCHAR(255),
    
    -- Additional security features
    secure_boot_enabled BOOLEAN,
    code_integrity_enabled BOOLEAN,
    credential_guard_enabled BOOLEAN,
    device_guard_enabled BOOLEAN,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Managed Installs (Cimian for Windows, Munki for Mac)
CREATE TABLE IF NOT EXISTS managed_installs (
    id VARCHAR(255) PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    version VARCHAR(255),
    installed_version VARCHAR(255),
    display_name VARCHAR(255),
    description TEXT,
    install_status VARCHAR(50),
    managed_installs_system VARCHAR(50) DEFAULT 'Cimian', -- 'Cimian' for Windows, 'Munki' for Mac
    
    -- Installation details
    install_date TIMESTAMP WITH TIME ZONE,
    update_available BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Applications inventory - aligns with osquery installed_programs
CREATE TABLE IF NOT EXISTS applications (
    id VARCHAR(255) PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    version VARCHAR(255),
    publisher VARCHAR(255),
    install_date VARCHAR(255), -- Keep as VARCHAR as osquery returns it as string
    install_path VARCHAR(500),
    size_mb INTEGER,
    
    -- Application categorization
    category VARCHAR(255),
    is_critical BOOLEAN DEFAULT FALSE,
    is_security_software BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- System Services - aligns with osquery services
CREATE TABLE IF NOT EXISTS system_services (
    id VARCHAR(255) PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    display_name VARCHAR(255),
    status VARCHAR(50),
    start_type VARCHAR(50),
    service_path VARCHAR(500),
    
    -- Service details
    pid INTEGER,
    description TEXT,
    is_critical BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_events_device_ts ON events(device_id, ts DESC);
CREATE INDEX IF NOT EXISTS idx_events_kind_ts ON events(kind, ts DESC);
CREATE INDEX IF NOT EXISTS idx_events_ts ON events(ts DESC);
CREATE INDEX IF NOT EXISTS idx_devices_last_seen ON devices(last_seen DESC);
CREATE INDEX IF NOT EXISTS idx_devices_status ON devices(status);
CREATE INDEX IF NOT EXISTS idx_devices_machine_group ON devices(machine_group_id);
CREATE INDEX IF NOT EXISTS idx_cimian_runs_device_ts ON cimian_runs(device_id, ts DESC);
CREATE INDEX IF NOT EXISTS idx_machine_groups_passphrase ON machine_groups(passphrase_hash);
CREATE INDEX IF NOT EXISTS idx_machine_groups_business_unit ON machine_groups(business_unit_id);

-- Insert sample business unit and machine group
INSERT INTO business_units (name, description) VALUES 
('Default', 'Default business unit for unassigned devices')
ON CONFLICT (name) DO NOTHING;

INSERT INTO machine_groups (name, description, passphrase_hash, business_unit_id) VALUES 
('Default', 'Default machine group', 
 encode(sha256('default-passphrase'::bytea), 'hex'), 
 (SELECT id FROM business_units WHERE name = 'Default'))
ON CONFLICT DO NOTHING;

-- Insert sample devices including the target laptop
INSERT INTO devices (id, name, model, os, serial_number, last_seen, status, location, machine_group_id) VALUES
('JY93C5YGGM', 'Celeste Martin', 'MacBook Air (15-inch, M2, 2023)', 'macOS 15.2.0', 'JY93C5YGGM', NOW() - INTERVAL '30 minutes', 'online', 'Marketing', (SELECT id FROM machine_groups WHERE name = 'Default')),
('FVFXQ2P3JM', 'Alex Chen', 'MacBook Pro (16-inch, M3 Pro, 2023)', 'macOS 15.2.0', 'FVFXQ2P3JM', NOW() - INTERVAL '15 minutes', 'online', 'Engineering', (SELECT id FROM machine_groups WHERE name = 'Default')),
('WS-ACC-001', 'Jennifer Davis', 'Dell OptiPlex 7090', 'Windows 11 Pro', 'WS-ACC-001', NOW() - INTERVAL '1 hour', 'warning', 'Accounting', (SELECT id FROM machine_groups WHERE name = 'Default')),
('0F33V9G25083HJ', 'Target Development Laptop', 'Unknown Model', 'Windows 11', '0F33V9G25083HJ', NOW() - INTERVAL '1 day', 'offline', 'Development', (SELECT id FROM machine_groups WHERE name = 'Default'))
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    model = EXCLUDED.model,
    os = EXCLUDED.os,
    serial_number = EXCLUDED.serial_number,
    last_seen = EXCLUDED.last_seen,
    status = EXCLUDED.status,
    location = EXCLUDED.location,
    machine_group_id = EXCLUDED.machine_group_id,
    updated_at = NOW();

-- Add a sample "New Client" event for the target laptop
INSERT INTO events (id, device_id, kind, ts, payload, created_at) VALUES
('init-0F33V9G25083HJ', '0F33V9G25083HJ', 'new_client', NOW(), 
 '{"message": "Device ready for registration", "source": "database_migration", "device_id": "0F33V9G25083HJ"}', NOW())
ON CONFLICT (id) DO NOTHING;
