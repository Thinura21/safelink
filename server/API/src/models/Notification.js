const mongoose = require('mongoose');

const NotificationSchema = new mongoose.Schema({
  recipientId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, // null for broadcast
  title: String,
  message: String,
  data: Object,
  read: { type: Boolean, default: false },
}, { timestamps: true });

NotificationSchema.index({ recipientId: 1, createdAt: -1 });

module.exports = mongoose.model('Notification', NotificationSchema);
