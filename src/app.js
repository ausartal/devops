const express = require('express');
const config = require('../config');
const logger = require('../config/logger');
const { errorHandler, notFoundHandler } = require('./middleware/errorHandler');
const healthRouter = require('./routes/health');

const app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use('/health', healthRouter);

app.get('/', (req, res) => {
  logger.info('Root endpoint accessed');
  res.json({
    message: 'CI/CD Level 3 - Professional Grade Application',
    version: '1.0.0',
    environment: config.env,
    status: 'running',
  });
});

app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;
