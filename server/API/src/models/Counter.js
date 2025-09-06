const mongoose = require('mongoose');

const CounterSchema = new mongoose.Schema(
  {
    _id: { type: String, required: true }, 
    seq: { type: Number, default: 0 },
  },
  { timestamps: true, versionKey: false }
);

module.exports = mongoose.model('Counter', CounterSchema);
