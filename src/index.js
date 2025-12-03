const config = require('../config');
const logger = require('../config/logger');
const app = require('./app');

const server = app.listen(config.port, config.host, () => {
  logger.info(`Server running on http://${config.host}:${config.port}`);
  logger.info(`Environment: ${config.env}`);
});

const gracefulShutdown = () => {
  logger.info('Received shutdown signal, closing server...');
  server.close(() => {
    logger.info('Server closed successfully');
    process.exit(0);
  });

  setTimeout(() => {
    logger.error('Forced shutdown after timeout');
    process.exit(1);
  }, 10000);
};

process.on('SIGTERM', gracefulShutdown);
process.on('SIGINT', gracefulShutdown);
