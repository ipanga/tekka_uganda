/**
 * Script to copy data from production to development database
 * and create an admin user for development.
 *
 * Usage:
 *   PROD_DATABASE_URL="postgresql://..." DEV_DATABASE_URL="postgresql://..." npx ts-node prisma/scripts/copy-to-dev.ts
 */
import { Client } from 'pg';
import * as bcrypt from 'bcrypt';

const PROD_DATABASE_URL = process.env.PROD_DATABASE_URL;
const DEV_DATABASE_URL = process.env.DEV_DATABASE_URL;

if (!PROD_DATABASE_URL || !DEV_DATABASE_URL) {
  console.error('Error: PROD_DATABASE_URL and DEV_DATABASE_URL environment variables are required.');
  process.exit(1);
}

const prodClient = new Client({ connectionString: PROD_DATABASE_URL });
const devClient = new Client({ connectionString: DEV_DATABASE_URL });

// Tables to copy in order (respecting foreign key constraints)
// Note: Prisma uses lowercase table names by default
const TABLES_TO_COPY = [
  'cities',
  'divisions',
  'categories',
  'attribute_definitions',
  'attribute_values',
  'category_attributes',
  'safe_locations',
  'users',
  'listings',
];

async function copyTable(tableName: string) {
  console.log(`Copying ${tableName}...`);

  try {
    // Get all records from production
    const result = await prodClient.query(`SELECT * FROM "${tableName}"`);
    const records = result.rows;

    if (records.length === 0) {
      console.log(`  No records in ${tableName}`);
      return;
    }

    // Get column names from the first record
    const columns = Object.keys(records[0]);
    const columnList = columns.map(c => `"${c}"`).join(', ');
    const valuePlaceholders = columns.map((_, i) => `$${i + 1}`).join(', ');
    const updateSet = columns
      .filter(c => c !== 'id')
      .map(c => `"${c}" = EXCLUDED."${c}"`)
      .join(', ');

    let copied = 0;
    for (const record of records) {
      const values = columns.map(c => record[c]);

      try {
        // Upsert: insert or update on conflict
        const query = `
          INSERT INTO "${tableName}" (${columnList})
          VALUES (${valuePlaceholders})
          ON CONFLICT (id) DO UPDATE SET ${updateSet}
        `;
        await devClient.query(query, values);
        copied++;
      } catch (err: any) {
        console.log(`  Warning: ${err.message.split('\n')[0]}`);
      }
    }

    console.log(`  Copied ${copied}/${records.length} records`);
  } catch (err: any) {
    console.log(`  Error: ${err.message}`);
  }
}

async function copyData() {
  console.log('Starting data copy from production to development...\n');

  for (const table of TABLES_TO_COPY) {
    await copyTable(table);
  }

  console.log('\nData copy completed!');
}

async function createAdminUser() {
  console.log('\nCreating admin user for development...');

  const adminEmail = 'admin@tekka.ug';
  const adminPassword = 'admin123';
  const adminPhone = '+256700000001';

  try {
    const passwordHash = await bcrypt.hash(adminPassword, 10);

    // Check if admin exists
    const existing = await devClient.query(
      `SELECT id FROM users WHERE email = $1 OR phone_number = $2`,
      [adminEmail, adminPhone]
    );

    if (existing.rows.length > 0) {
      // Update existing admin
      await devClient.query(
        `UPDATE users SET
          email = $1,
          password_hash = $2,
          role = 'ADMIN',
          display_name = 'Admin',
          is_phone_verified = true,
          is_email_verified = true,
          is_onboarding_complete = true
        WHERE id = $3`,
        [adminEmail, passwordHash, existing.rows[0].id]
      );
      console.log('  Updated existing admin user');
    } else {
      // Create new admin
      await devClient.query(
        `INSERT INTO users (
          phone_number, email, password_hash, display_name,
          role, is_phone_verified, is_email_verified, is_onboarding_complete
        ) VALUES ($1, $2, $3, 'Admin', 'ADMIN', true, true, true)`,
        [adminPhone, adminEmail, passwordHash]
      );
      console.log('  Created new admin user');
    }

    console.log(`\nAdmin user ready:`);
    console.log(`   Email: ${adminEmail}`);
    console.log(`   Password: ${adminPassword}`);
    console.log(`   Phone: ${adminPhone}`);

  } catch (error: any) {
    console.error('Error creating admin user:', error.message);
  }
}

async function main() {
  try {
    console.log('Connecting to databases...\n');
    await prodClient.connect();
    await devClient.connect();

    await copyData();
    await createAdminUser();

    console.log('\nAll done! Development database is ready.');

  } catch (error) {
    console.error('Script failed:', error);
    process.exit(1);
  } finally {
    await prodClient.end();
    await devClient.end();
  }
}

main();
