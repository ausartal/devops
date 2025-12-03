const express = require('express');
const router = express.Router();
const logger = require('../../config/logger');

router.get('/', (req, res) => {
  const healthCheck = {
    uptime: process.uptime(),
    message: 'OK',
    timestamp: Date.now(),
    environment: process.env.NODE_ENV || 'development',
  };

  logger.debug('Health check performed');
  res.status(200).json(healthCheck);
});

module.exports = router;
