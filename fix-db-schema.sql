-- ReportMate Database Schema Update
-- Aligns database schema with osquery queries and fixes Cimian/Munki tables
-- Date: 2025-07-02

-- Fix the events table to use proper auto-incrementing ID
-- This resolves the "null value in column 'id'" constraint violation
DROP TABLE IF EXISTS events CASCADE;

-- Recreate events table with SERIAL (auto-incrementing) primary key
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL,
    kind VARCHAR(100) NOT NULL,
    ts TIMESTAMP WITH TIME ZONE NOT NULL,
    payload JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_events_device_ts ON events(device_id, ts DESC);
CREATE INDEX IF NOT EXISTS idx_events_kind_ts ON events(kind, ts DESC);
CREATE INDEX IF NOT EXISTS idx_events_ts ON events(ts DESC);

-- Now fix the Cimian/Munki table naming issue
-- Drop old cimian_runs table and create proper cimian and munki tables
DROP TABLE IF EXISTS cimian_runs CASCADE;

-- Windows Managed Installs via Cimian
CREATE TABLE IF NOT EXISTS cimian (
    id VARCHAR(255) PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    ts TIMESTAMP WITH TIME ZONE NOT NULL,
    exit_code INTEGER,
    duration INTEGER, 
    details TEXT,
    status VARCHAR(50),
    version VARCHAR(100),
    packages_installed JSONB,
    packages_removed JSONB,
    errors JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Mac Managed Installs via Munki  
CREATE TABLE IF NOT EXISTS munki (
    id VARCHAR(255) PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    ts TIMESTAMP WITH TIME ZONE NOT NULL,
    exit_code INTEGER,
    duration INTEGER,
    details TEXT, 
    status VARCHAR(50),
    version VARCHAR(100),
    packages_installed JSONB,
    packages_removed JSONB,
    errors JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_cimian_device_ts ON cimian(device_id, ts DESC);
CREATE INDEX IF NOT EXISTS idx_munki_device_ts ON munki(device_id, ts DESC);

-- Create normalized tables to match osquery data structure
-- This aligns with the queries.json osquery queries

-- System Info table (from system_info osquery)
CREATE TABLE IF NOT EXISTS system_info (
    id SERIAL PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    hostname VARCHAR(255),
    cpu_brand VARCHAR(255),
    cpu_physical_cores INTEGER,
    cpu_logical_cores INTEGER,
    physical_memory BIGINT,
    vendor VARCHAR(255),
    model VARCHAR(255),
    version VARCHAR(255),
    serial VARCHAR(255),
    hardware_vendor VARCHAR(255),
    hardware_model VARCHAR(255),  
    hardware_version VARCHAR(255),
    hardware_serial VARCHAR(255),
    collected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(device_id, collected_at)
);

-- OS Version table (from os_version osquery)
CREATE TABLE IF NOT EXISTS os_version (
    id SERIAL PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    name VARCHAR(255),
    version VARCHAR(255),
    build VARCHAR(255),
    platform VARCHAR(255),
    arch VARCHAR(255),
    collected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(device_id, collected_at)
);

-- Memory Devices table (from memory_info osquery)
CREATE TABLE IF NOT EXISTS memory_devices (
    id SERIAL PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    device VARCHAR(255),
    device_type VARCHAR(255),
    size BIGINT,
    form_factor VARCHAR(255),
    configured_clock_speed INTEGER,
    collected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Disk Info table (from disk_info osquery)
CREATE TABLE IF NOT EXISTS disk_info (
    id SERIAL PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    device VARCHAR(255),
    model VARCHAR(255),
    size BIGINT,
    type VARCHAR(255),
    collected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Network Interfaces table (from network_interfaces osquery)
CREATE TABLE IF NOT EXISTS network_interfaces (
    id SERIAL PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    interface VARCHAR(255),
    mac VARCHAR(255),
    ip VARCHAR(255),
    mask VARCHAR(255),
    broadcast VARCHAR(255),
    type VARCHAR(255),
    mtu INTEGER,
    collected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Installed Programs table (from installed_programs osquery)
CREATE TABLE IF NOT EXISTS installed_programs (
    id SERIAL PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    name VARCHAR(500),
    version VARCHAR(255),
    publisher VARCHAR(255),
    install_date VARCHAR(255),
    collected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Running Services table (from running_services osquery)
CREATE TABLE IF NOT EXISTS running_services (
    id SERIAL PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    name VARCHAR(255),
    display_name VARCHAR(500),
    status VARCHAR(50),
    start_type VARCHAR(50),
    path TEXT,
    collected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Security Center table (from security_center osquery)
CREATE TABLE IF NOT EXISTS security_center (
    id SERIAL PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    domain VARCHAR(255),
    antivirus VARCHAR(255),
    antispyware VARCHAR(255),
    firewall VARCHAR(255),
    autoupdate VARCHAR(255),
    uac VARCHAR(255),
    collected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(device_id, collected_at)
);

-- BitLocker Info table (from bitlocker_info osquery)
CREATE TABLE IF NOT EXISTS bitlocker_info (
    id SERIAL PRIMARY KEY,
    device_id VARCHAR(255) NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    device_id_bitlocker VARCHAR(255),
    drive_letter VARCHAR(10),
    conversion_status VARCHAR(255),
    protection_status VARCHAR(255),
    lock_status VARCHAR(255),
    encryption_method VARCHAR(255),
    collected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for all new tables
CREATE INDEX IF NOT EXISTS idx_system_info_device ON system_info(device_id);
CREATE INDEX IF NOT EXISTS idx_os_version_device ON os_version(device_id);
CREATE INDEX IF NOT EXISTS idx_memory_devices_device ON memory_devices(device_id);
CREATE INDEX IF NOT EXISTS idx_disk_info_device ON disk_info(device_id);
CREATE INDEX IF NOT EXISTS idx_network_interfaces_device ON network_interfaces(device_id);
CREATE INDEX IF NOT EXISTS idx_installed_programs_device ON installed_programs(device_id);
CREATE INDEX IF NOT EXISTS idx_running_services_device ON running_services(device_id);
CREATE INDEX IF NOT EXISTS idx_security_center_device ON security_center(device_id);
CREATE INDEX IF NOT EXISTS idx_bitlocker_info_device ON bitlocker_info(device_id);

-- Update devices table to better track event counts
-- Add trigger to update event counts automatically
CREATE OR REPLACE FUNCTION update_device_event_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE devices 
    SET 
        total_events = (SELECT COUNT(*) FROM events WHERE device_id = NEW.device_id),
        last_event_time = NEW.ts,
        last_seen = NOW(),
        updated_at = NOW()
    WHERE id = NEW.device_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update device stats when events are inserted
DROP TRIGGER IF EXISTS trigger_update_device_stats ON events;
CREATE TRIGGER trigger_update_device_stats
    AFTER INSERT ON events
    FOR EACH ROW
    EXECUTE FUNCTION update_device_event_count();

-- Fix existing event counts for all devices
UPDATE devices 
SET 
    total_events = (SELECT COUNT(*) FROM events WHERE device_id = devices.id),
    last_event_time = (SELECT MAX(ts) FROM events WHERE device_id = devices.id),
    last_seen = (SELECT MAX(created_at) FROM events WHERE device_id = devices.id)
WHERE id IN (SELECT DISTINCT device_id FROM events);

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO reportmate;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO reportmate;
