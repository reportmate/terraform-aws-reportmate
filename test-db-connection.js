const { Pool } = require('pg');

// Database connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL || "postgresql://reportmate:2sSWbVxyqjXp9WUpeMmzRaC@reportmate-database.postgres.database.azure.com:5432/reportmate?sslmode=require",
  ssl: { rejectUnauthorized: false },
  max: 5,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000
});

async function testConnection() {
  console.log('Testing database connection...');
  
  try {
    const client = await pool.connect();
    console.log('✅ Connected to database successfully!');
    
    // Test query
    const result = await client.query('SELECT NOW() as current_time');
    console.log('✅ Current time from database:', result.rows[0].current_time);
    
    // Check if tables exist
    const tables = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
      ORDER BY table_name
    `);
    
    console.log('📋 Existing tables:', tables.rows.map(r => r.table_name));
    
    if (tables.rows.length === 0) {
      console.log('🔧 No tables found, initializing database...');
      
      // Create basic tables
      await client.query(`
        CREATE TABLE IF NOT EXISTS devices (
          id VARCHAR(255) PRIMARY KEY,
          name VARCHAR(255) NOT NULL,
          model VARCHAR(255),
          os VARCHAR(255),
          serial_number VARCHAR(255),
          last_seen TIMESTAMP WITH TIME ZONE,
          status VARCHAR(50) DEFAULT 'unknown',
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
      `);
      
      await client.query(`
        CREATE TABLE IF NOT EXISTS events (
          id SERIAL PRIMARY KEY,
          device_id VARCHAR(255) NOT NULL,
          kind VARCHAR(100) NOT NULL,
          ts TIMESTAMP WITH TIME ZONE NOT NULL,
          payload JSONB,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
      `);
      
      // Create indexes
      await client.query(`
        CREATE INDEX IF NOT EXISTS idx_events_device_ts ON events(device_id, ts DESC);
        CREATE INDEX IF NOT EXISTS idx_events_kind_ts ON events(kind, ts DESC);
        CREATE INDEX IF NOT EXISTS idx_devices_last_seen ON devices(last_seen DESC);
      `);
      
      console.log('✅ Basic tables created');
      
      // Insert test device
      await client.query(`
        INSERT INTO devices (id, name, model, os, serial_number, last_seen, status) 
        VALUES ('0F33V9G25083HJ', 'Test Laptop', 'Unknown', 'Windows 11', '0F33V9G25083HJ', NOW(), 'online')
        ON CONFLICT (id) DO UPDATE SET
          name = EXCLUDED.name,
          last_seen = EXCLUDED.last_seen,
          updated_at = NOW()
      `);
      
      console.log('✅ Test device inserted');
    }
    
    client.release();
    console.log('🎉 Database initialization complete!');
    
  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
    console.error('Stack:', error.stack);
  } finally {
    await pool.end();
  }
}

testConnection();
