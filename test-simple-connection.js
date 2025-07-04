const { Client } = require('pg');

// Use the exact same connection string as the container app
const client = new Client({
  connectionString: "postgresql://reportmate:2sSWbVxyqjXp9WUpeMmzRaC@reportmate-database.postgres.database.azure.com:5432/reportmate?sslmode=require",
  ssl: { 
    rejectUnauthorized: false,
    require: true 
  }
});

async function testSimpleConnection() {
  console.log('Testing simple database connection...');
  console.log('Host: reportmate-database.postgres.database.azure.com');
  console.log('Database: reportmate');
  console.log('User: reportmate');
  
  try {
    await client.connect();
    console.log('✅ Connected successfully!');
    
    const result = await client.query('SELECT version(), current_user, current_database()');
    console.log('✅ Database info:', result.rows[0]);
    
    await client.end();
    console.log('✅ Connection closed');
    
  } catch (error) {
    console.error('❌ Connection failed:', error.message);
    if (error.code) {
      console.error('Error code:', error.code);
    }
    if (error.routine) {
      console.error('Error routine:', error.routine);
    }
  }
}

testSimpleConnection();
