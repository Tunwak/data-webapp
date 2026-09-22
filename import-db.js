#!/usr/bin/env node

const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');

function parseConnectionUrl(url) {
  // Parse mysql://user:pass@host:port/database
  const match = url.match(/mysql:\/\/([^:]+):([^@]+)@([^:]+):(\d+)\/(.+)/);
  if (!match) {
    throw new Error('Invalid MySQL URL format. Expected: mysql://user:pass@host:port/database');
  }
  
  return {
    user: match[1],
    password: match[2],
    host: match[3],
    port: parseInt(match[4]),
    database: match[5]
  };
}

async function importDatabase() {
  let connection;
  
  try {
    // Try to parse from MYSQL_URL first, otherwise use individual variables
    let config;
    
    if (process.env.MYSQL_URL) {
      console.log('📍 Using MYSQL_URL for connection...');
      config = parseConnectionUrl(process.env.MYSQL_URL);
    } else {
      config = {
        host: process.env.MYSQL_HOST || 'localhost',
        port: process.env.MYSQL_PORT || 3306,
        user: process.env.MYSQL_USER || 'root',
        password: process.env.MYSQL_PASSWORD || '',
        database: process.env.MYSQL_DB || 'db_northwind'
      };
    }
    
    config.waitForConnections = true;
    config.connectionLimit = 1;
    config.queueLimit = 0;
    config.multipleStatements = true;

    console.log('🔌 Connecting to MySQL...');
    console.log(`Host: ${config.host}:${config.port}`);
    console.log(`Database: ${config.database}`);
    console.log('');

    // Create connection
    connection = await mysql.createConnection(config);
    console.log('✓ Connected to MySQL');

    // Read SQL file
    const sqlFilePath = path.join(__dirname, 'dbNorthwind (2).sql');
    console.log(`📂 Reading SQL file: ${sqlFilePath}`);
    
    const sqlContent = fs.readFileSync(sqlFilePath, 'utf8');
    console.log(`✓ SQL file loaded (${sqlContent.length} bytes)`);
    console.log('');

    // Split SQL statements and filter empty ones
    const statements = sqlContent
      .split(';')
      .map(stmt => stmt.trim())
      .filter(stmt => stmt.length > 0 && !stmt.startsWith('--'));

    console.log(`📋 Found ${statements.length} SQL statements`);
    console.log('');
    console.log('⏳ Executing SQL statements...');
    
    let executed = 0;
    for (let i = 0; i < statements.length; i++) {
      const statement = statements[i];
      
      try {
        await connection.execute(statement + ';');
        executed++;
        
        // Show progress
        if ((i + 1) % 10 === 0) {
          console.log(`  [${i + 1}/${statements.length}] statements executed...`);
        }
      } catch (error) {
        // Skip certain errors
        if (error.message.includes('already exists') || 
            error.message.includes('Unknown database') ||
            error.message.includes('no such table')) {
          console.log(`  ⚠️  Skipping: ${error.message.substring(0, 50)}...`);
        } else {
          console.error(`❌ Error at statement ${i + 1}:`);
          console.error(`   ${statement.substring(0, 100)}...`);
          console.error(`   Error: ${error.message}`);
        }
      }
    }

    console.log('');
    console.log(`✅ Import completed!`);
    console.log(`   Successfully executed ${executed} statements`);
    
    // Verify tables
    const [tables] = await connection.query(`
      SELECT TABLE_NAME FROM information_schema.TABLES 
      WHERE TABLE_SCHEMA = DATABASE() 
      ORDER BY TABLE_NAME
    `);
    
    console.log('');
    console.log('📊 Tables in database:');
    tables.forEach(row => {
      console.log(`   - ${row.TABLE_NAME}`);
    });

  } catch (error) {
    console.error('❌ Fatal Error:', error.message);
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
      console.log('');
      console.log('🔌 Connection closed');
    }
  }
}

// Run the import
importDatabase().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});
