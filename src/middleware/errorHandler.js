const logger = require('../../config/logger');

const errorHandler = (err, req, res, _next) => {
  logger.error('Error occurred:', {
    message: err.message,
    stack: err.stack,
    url: req.url,
    method: req.method,
  });

  const statusCode = err.statusCode || 500;
  const message = err.message || 'Internal Server Error';

  res.status(statusCode).json({
    error: {
      message,
      ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
    },
  });
};

const notFoundHandler = (req, res, _next) => {
  res.status(404).json({
    error: {
      message: 'Route not found',
      path: req.url,
    },
  });
};

module.exports = {
  errorHandler,
  notFoundHandler,
};
