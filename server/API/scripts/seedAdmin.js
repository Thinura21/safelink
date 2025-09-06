require('dotenv').config();
const { connectDB } = require('../src/config/database');
const User = require('../src/models/User');

(async () => {
  await connectDB();
  const email = process.argv[2] || 'admin@example.com';
  const password = process.argv[3] || 'Admin@123';
  const fullName = 'System Admin';

  const existing = await User.findOne({ email });
  if (existing) {
    console.log('Admin already exists:', email);
    process.exit(0);
  }
  const u = await User.create({ email, password, fullName, role: 'admin', isVerified: true, profileComplete: true });
  console.log('Admin created:', { id: u._id.toString(), email });
  process.exit(0);
})().catch(e => { console.error(e); process.exit(1); });
