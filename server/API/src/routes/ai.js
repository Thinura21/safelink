const router = require('express').Router();
const requireAuth = require('../middleware/requireAuth');
const upload = require('../middleware/upload');

// POST /api/ai/analyze  (accepts multipart image or a JSON body with imageUrl)
router.post('/analyze', requireAuth, upload.single('image'), async (req, res) => {
  const imageUrl = req.body.imageUrl || (req.file ? `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}` : null);
  if (!imageUrl) return res.status(400).json({ success: false, error: { code: 'NO_IMAGE', message: 'Provide image via multipart field `image` or JSON `imageUrl`' } });

  // Stub: your ML model can fetch imageUrl
  const fake = {
    imageUrl,
    severity: 'high',
    objects: ['person', 'blood', 'injury'],
    recommendedResponse: 'Dispatch ambulance immediately',
  };
  res.json({ success: true, analysis: fake });
});

module.exports = router;
