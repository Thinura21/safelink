const mongoose = require('mongoose');
const bcrypt = require('bcrypt');

const GuardianSchema = new mongoose.Schema({
  name: String,
  contact: String,
  address: String,
}, { _id: false });

const UserSchema = new mongoose.Schema({
  email: { type: String, unique: true, required: true, index: true },
  password: { type: String, required: true },
  fullName: { type: String, required: true },
  contact: String,
  address: String,
  nic: String,
  nicImage: String,
  profileImage: String,
  guardian: GuardianSchema,
  role: { type: String, enum: ['user','officer','authority','admin'], default: 'user', index: true },
  department: String,
  badgeNumber: String,
  specializations: [String],
  isVerified: { type: Boolean, default: false, index: true },
  nicVerified: { type: String, enum: ['pending','verified','rejected'], default: 'pending' },
  verifierNote: String,
  verifiedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  profileComplete: { type: Boolean, default: false },
  fcmToken: String,
  lastLogin: Date,
  isActive: { type: Boolean, default: true, index: true },
  deletedAt: { type: Date, default: null },
}, { timestamps: true });

UserSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  const rounds = Number(process.env.BCRYPT_ROUNDS || 12);
  this.password = await bcrypt.hash(this.password, rounds);
  next();
});

UserSchema.methods.comparePassword = function(candidate) {
  return bcrypt.compare(candidate, this.password);
};

UserSchema.index({ email: 1, deletedAt: 1 }, { unique: true, partialFilterExpression: { deletedAt: null } });
UserSchema.index({ nicVerified: 1, deletedAt: 1, createdAt: -1 });

module.exports = mongoose.model('User', UserSchema);
