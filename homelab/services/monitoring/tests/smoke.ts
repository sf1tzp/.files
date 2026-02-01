import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');

const domain = 'fitz.gg'

// List of frontend apps to test
const domains = [
  `http://${domain}`,
  // `http://auth.${domain}`,
  `http://dial-in.${domain}`,
  `http://sketches.${domain}`,
  `http://streetfortress.com`,
  `http://symbology.online`,
];

// Test configuration
export const options = {
  vus: 10, // virtual users
  duration: '300s',
  thresholds: {
    http_req_failed: ['rate<0.01'], // http errors should be less than 1%
    http_req_duration: ['p(95)<500'], // 95% of requests should be below 500ms
    errors: ['rate<0.1'], // error rate should be less than 10%
  },
};

export default function () {
  // Rotate through domains
  const endpoint = domains[Math.floor(Math.random() * domains.length)];

  // Make HTTP request
  const response = http.get(endpoint);

  // Check response
  const checkRes = check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
    'has content': (r) => r.body && r.body.length > 0,
  });

  // Track errors
  errorRate.add(!checkRes);

  // Sleep for 1 second between iterations
  sleep(1);
}
