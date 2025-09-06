const mongoose = require('mongoose');

const IncidentSchema = new mongoose.Schema({
  incidentId: { type: String, unique: true, index: true }, 
  reporterId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },

  type: { type: String, required: true, enum: ['medical', 'fire', 'crime', 'accident', 'other'], index: true },
  description: { type: String },

  location: {
    type: { type: String, enum: ['Point'], default: 'Point' },
    coordinates: { type: [Number], required: true }
  },
  locationText: String,

  images: [String],
  imagesCount: { type: Number, default: 0 },

  priority: { type: String, enum: ['low','normal','high','critical'], default: 'normal', index: true },

  status: { type: String, enum: ['open','assigned','en_route','arrived','resolved','cancelled'], default: 'open', index: true },

  assignedOfficerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  etaMinutes: { type: Number, default: null },
  assignmentNote: { type: String, default: null },

  casualties: { type: Number, default: null },
  bystander: { type: Boolean, default: null },

}, { timestamps: true });

IncidentSchema.index({ location: '2dsphere' });
IncidentSchema.index({ createdAt: -1 });

module.exports = mongoose.model('Incident', IncidentSchema);
