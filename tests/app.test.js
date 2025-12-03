const request = require('supertest');
const app = require('../src/app');

describe('Application Tests', () => {
  describe('GET /', () => {
    it('should return application info', async () => {
      const response = await request(app).get('/');

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('message');
      expect(response.body).toHaveProperty('version');
      expect(response.body).toHaveProperty('status', 'running');
    });

    it('should return JSON content type', async () => {
      const response = await request(app).get('/');

      expect(response.headers['content-type']).toMatch(/json/);
    });
  });

  describe('GET /health', () => {
    it('should return health check', async () => {
      const response = await request(app).get('/health');

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('message', 'OK');
      expect(response.body).toHaveProperty('uptime');
      expect(response.body).toHaveProperty('timestamp');
    });

    it('should return uptime as a number', async () => {
      const response = await request(app).get('/health');

      expect(typeof response.body.uptime).toBe('number');
      expect(response.body.uptime).toBeGreaterThanOrEqual(0);
    });
  });

  describe('404 Handler', () => {
    it('should return 404 for unknown routes', async () => {
      const response = await request(app).get('/unknown-route');

      expect(response.status).toBe(404);
      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toHaveProperty('message', 'Route not found');
    });
  });
});
