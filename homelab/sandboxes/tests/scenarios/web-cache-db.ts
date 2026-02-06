import { sleep } from 'k6';
import { defaultThresholds, scenarios, httpGet } from '../helpers.ts';

const WEB_HOST = __ENV.WEB_HOST || 'http://10.0.0.42';
const CACHE_HOST = __ENV.CACHE_HOST || '10.0.0.43';
const DB_HOST = __ENV.DB_HOST || '10.0.0.44';

export const options = {
  scenarios: {
    default: scenarios[__ENV.K6_SCENARIO || 'smoke'],
  },
  thresholds: {
    ...defaultThresholds,
    // Cache-backed responses should be faster
    'http_req_duration{name:web_cached}': ['p(95)<100'],
  },
};

// web-cache-db: Hit the web tier repeatedly to observe cache behavior.
// First request should be a cache miss (populates from DB), subsequent
// requests for the same resource should be served from Redis.
export default function () {
  // Cold request - likely cache miss
  httpGet(`${WEB_HOST}/`, 'web_index');

  // Warm requests - should hit cache
  httpGet(`${WEB_HOST}/`, 'web_cached');
  httpGet(`${WEB_HOST}/`, 'web_cached');

  httpGet(`${WEB_HOST}/health`, 'web_health');

  sleep(1);
}
