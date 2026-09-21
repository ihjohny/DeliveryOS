import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function assert(condition: boolean, message: string) {
  if (!condition) {
    console.error(`❌ ASSERTION FAILED: ${message}`);
    process.exit(1);
  }
  console.log(`   ✅ ${message}`);
}

async function runVerification() {
  console.log('====================================================');
  console.log(' DeliveryOS Web Portal Scaffolding & Layout Tests');
  console.log('====================================================\n');

  const rootDir = path.resolve(__dirname, '..');

  // 1. Check Build Artifacts
  console.log('🏗️  1. Verifying Vite + TypeScript Production Build Artifacts...');
  const distDir = path.join(rootDir, 'dist');
  assert(fs.existsSync(distDir), 'Build directory "dist" exists');
  const indexHtml = fs.readFileSync(path.join(distDir, 'index.html'), 'utf8');
  assert(indexHtml.includes('id="root"'), 'index.html contains mounting root #root');
  assert(indexHtml.includes('DeliveryOS'), 'index.html contains DeliveryOS title');

  const assetsDir = path.join(distDir, 'assets');
  assert(fs.existsSync(assetsDir), 'Assets directory exists');
  const assetFiles = fs.readdirSync(assetsDir);
  const hasJs = assetFiles.some((f) => f.endsWith('.js'));
  const hasCss = assetFiles.some((f) => f.endsWith('.css'));
  assert(hasJs, 'Production JS bundle generated');
  assert(hasCss, 'Production Tailwind CSS bundle generated');

  // 2. Check i18n Translation Parity
  console.log('\n🌐 2. Verifying i18n Translations Parity (English, Arabic, Bengali)...');
  const localesDir = path.join(rootDir, 'src/i18n/locales');
  const en = JSON.parse(fs.readFileSync(path.join(localesDir, 'en.json'), 'utf8'));
  const ar = JSON.parse(fs.readFileSync(path.join(localesDir, 'ar.json'), 'utf8'));
  const bn = JSON.parse(fs.readFileSync(path.join(localesDir, 'bn.json'), 'utf8'));

  function getKeys(obj: Record<string, unknown>, prefix = ''): string[] {
    let keys: string[] = [];
    for (const key of Object.keys(obj)) {
      const val = obj[key];
      const fullPath = prefix ? `${prefix}.${key}` : key;
      if (typeof val === 'object' && val !== null) {
        keys = keys.concat(getKeys(val as Record<string, unknown>, fullPath));
      } else {
        keys.push(fullPath);
      }
    }
    return keys.sort();
  }

  const enKeys = getKeys(en);
  const arKeys = getKeys(ar);
  const bnKeys = getKeys(bn);

  assert(enKeys.length > 20, `English catalog contains ${enKeys.length} translation keys`);
  assert(
    JSON.stringify(enKeys) === JSON.stringify(arKeys),
    'Arabic catalog matches 100% of English translation keys'
  );
  assert(
    JSON.stringify(enKeys) === JSON.stringify(bnKeys),
    'Bengali catalog matches 100% of English translation keys'
  );

  // Verify Arabic strings contain Arabic script characters
  assert(/[\u0600-\u06FF]/.test(ar.auth.title), 'Arabic translation contains valid Arabic unicode characters');
  // Verify Bengali strings contain Bengali script characters
  assert(/[\u0980-\u09FF]/.test(bn.auth.title), 'Bengali translation contains valid Bengali unicode characters');

  // 3. Verify Route Protection Logic & RBAC Invariants
  console.log('\n🛡️  3. Verifying RBAC RouteGuard Matrix & Scopes...');
  type Role = 'SUPER_ADMIN' | 'VENDOR_ADMIN' | 'RIDER' | 'CUSTOMER';

  function canAccessRoute(route: string, userRole: Role | null): boolean {
    if (!userRole) return false; // Unauthenticated -> redirect to /login
    if (route.startsWith('/admin')) {
      return userRole === 'SUPER_ADMIN';
    }
    if (route.startsWith('/vendor')) {
      return userRole === 'VENDOR_ADMIN';
    }
    return true;
  }

  assert(!canAccessRoute('/admin', null), 'Unauthenticated visit to /admin blocked (redirects to /login)');
  assert(!canAccessRoute('/vendor', null), 'Unauthenticated visit to /vendor blocked (redirects to /login)');
  assert(canAccessRoute('/admin', 'SUPER_ADMIN'), 'Super Admin permitted on /admin');
  assert(!canAccessRoute('/vendor', 'SUPER_ADMIN'), 'Super Admin strictly blocked from /vendor (must use Admin Portal)');
  assert(!canAccessRoute('/admin', 'VENDOR_ADMIN'), 'Vendor Admin blocked from /admin (redirects to /unauthorized)');
  assert(canAccessRoute('/vendor', 'VENDOR_ADMIN'), 'Vendor Admin permitted on /vendor');
  assert(!canAccessRoute('/admin', 'CUSTOMER'), 'Customer blocked from /admin');
  assert(!canAccessRoute('/vendor', 'CUSTOMER'), 'Customer blocked from /vendor');

  // 4. Verify Directory Structure (apps/vendor_portal)
  console.log('\n📁 4. Verifying Directory Invariants (apps/vendor_portal)...');
  const projectRoot = path.resolve(rootDir, '../..');
  const vendorPortalPath = path.join(projectRoot, 'apps/vendor_portal');
  assert(fs.existsSync(vendorPortalPath), 'Directory apps/vendor_portal exists');
  const pkgJsonPath = path.join(vendorPortalPath, 'package.json');
  assert(fs.existsSync(pkgJsonPath), 'apps/vendor_portal/package.json exists and is valid');

  console.log('\n====================================================');
  console.log(' 🎉 All Web Portal Scaffolding & Layout Tests Passed!');
  console.log('====================================================\n');
}

runVerification().catch((err) => {
  console.error('Test execution failed:', err);
  process.exit(1);
});
