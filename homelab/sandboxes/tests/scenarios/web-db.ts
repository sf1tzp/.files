import { sleep } from 'k6';
import { defaultThresholds, scenarios, httpGet } from '../helpers.ts';

// Sandbox node IPs - override via environment variables
const WEB_HOST = __ENV.WEB_HOST || 'http://10.0.0.40';
const DB_HOST = __ENV.DB_HOST || '10.0.0.41';

export const options = {
  scenarios: {
    // Default to smoke test; override with K6_SCENARIO env var or --scenario flag
    default: scenarios[__ENV.K6_SCENARIO || 'smoke'],
  },
  thresholds: defaultThresholds,
};

// web-db: Exercises the web tier, which proxies to an app server.
// The app connects to Postgres on the db node.
// This baseline measures raw request handling + DB round-trip latency.
export default function () {
  httpGet(`${WEB_HOST}/`, 'web_index');
  httpGet(`${WEB_HOST}/health`, 'web_health');

  sleep(1);
}
