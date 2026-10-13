const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

const serviceAccountPath = path.resolve(__dirname, '../service-account.json');
if (!fs.existsSync(serviceAccountPath)) {
  console.error('Service account not found at:', serviceAccountPath);
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: 'https://freewatch-a0bc7-default-rtdb.firebaseio.com',
  });
}

const db = admin.database();
const auth = admin.auth();

async function syncUsers() {
  console.log('🔄 Fetching Firebase Auth users...');
  const list = await auth.listUsers(100);
  console.log(`Found ${list.users.length} Firebase Auth user(s).`);

  for (const user of list.users) {
    const profileRef = db.ref(`users/${user.uid}/profile`);
    const snap = await profileRef.once('value');
    const existing = snap.val() || {};

    const name = existing.name || user.displayName || user.email.split('@')[0];
    const email = user.email || existing.email || '';
    const isSuperAdmin = email.toLowerCase().includes('smartdevoff') || email.toLowerCase().includes('admin');

    const updatedProfile = {
      uid: user.uid,
      email: email,
      name: name,
      avatar: existing.avatar || 'assets/avatars/avatar_mirabel.png',
      role: existing.role || (isSuperAdmin ? 'Admin' : 'Member'),
      status: existing.status || 'Active',
      createdAt: existing.createdAt || user.metadata.creationTime || new Date().toISOString(),
      lastLogin: existing.lastLogin || user.metadata.lastSignInTime || new Date().toISOString(),
      bio: existing.bio || 'FreeWatch Movie Lover • Luganda Translations Enthusiast',
    };

    await profileRef.update(updatedProfile);
    console.log(`✅ Synced profile for: ${updatedProfile.name} (${updatedProfile.email}) [${updatedProfile.role} - ${updatedProfile.status}]`);
  }

  // Also check if catalog is in RTDB
  console.log('🎬 Checking /munowatch/catalog in RTDB...');
  const catalogSnap = await db.ref('munowatch/catalog').once('value');
  if (!catalogSnap.exists()) {
    console.log('Fetching live catalog from MunoWatch to seed RTDB cache...');
    try {
      const resp = await fetch('https://munowatch.ai.studio/api/dashboard');
      const data = await resp.json();
      let allMovies = [];
      if (data.banner) allMovies.push(data.banner);
      if (data.dashboard) {
        data.dashboard.forEach(c => {
          if (c.movies) allMovies.push(...c.movies);
        });
      }
      const unique = new Map();
      allMovies.forEach(m => {
        const id = m.id || m.vid;
        if (id && !unique.has(id)) unique.set(id, m);
      });
      const uniqueList = Array.from(unique.values());
      await db.ref('munowatch/catalog').set(uniqueList);
      console.log(`✅ Saved ${uniqueList.length} movies to /munowatch/catalog in RTDB!`);
    } catch (e) {
      console.warn('Catalog seed warning:', e.message);
    }
  } else {
    console.log('✅ /munowatch/catalog already exists in RTDB.');
  }

  // Also seed initial audit log if empty
  const auditSnap = await db.ref('audit_logs').once('value');
  if (!auditSnap.exists()) {
    const logId = db.ref('audit_logs').push().key;
    await db.ref(`audit_logs/${logId}`).set({
      id: logId,
      timestamp: new Date().toISOString(),
      action: 'SYSTEM_SYNC',
      target: 'Firebase Database',
      actor: 'System Admin',
      category: 'Maintenance',
      details: 'Initial database synchronization completed. Real data live link established.',
    });
    console.log('✅ Created initial system audit log.');
  }

  console.log('✨ All Firebase sync operations completed successfully.');
  process.exit(0);
}

syncUsers().catch(err => {
  console.error('Sync failed:', err);
  process.exit(1);
});
