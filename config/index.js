const dotenv = require('dotenv');
const path = require('path');

dotenv.config();

const config = {
  env: process.env.NODE_ENV || 'development',
  port: process.env.PORT ? Number(process.env.PORT) : 3000,
  host: process.env.HOST || 'localhost',
  log: {
    level: process.env.LOG_LEVEL || 'info',
    dir: process.env.LOG_DIR || 'logs',
  },
};

module.exports = config;
