import { sleep } from 'k6';
import http from 'k6/http';
import { check } from 'k6';
import encoding from 'k6/encoding';
import { defaultThresholds, scenarios, errorRate, httpGet } from '../helpers.ts';

const POLLER_HOST = __ENV.POLLER_HOST || 'http://10.0.0.46';
const QUEUE_HOST = __ENV.QUEUE_HOST || 'http://10.0.0.47:15672';
const QUEUE_USER = __ENV.QUEUE_USER || 'sandbox';
const QUEUE_PASS = __ENV.QUEUE_PASS || 'sandbox';

export const options = {
  scenarios: {
    default: scenarios[__ENV.K6_SCENARIO || 'smoke'],
  },
  thresholds: {
    ...defaultThresholds,
    // Queue management API can be slower
    'http_req_duration{name:queue_overview}': ['p(95)<2000'],
  },
};

// poller-queue-worker-db: Submit work via the poller endpoint and monitor
// queue depth through the RabbitMQ management API. Measures end-to-end
// throughput of the async processing pipeline.
export default function () {
  // Submit work via poller
  httpGet(`${POLLER_HOST}/`, 'poller_submit');

  // Check RabbitMQ management API for queue health
  const queueRes = http.get(`${QUEUE_HOST}/api/overview`, {
    headers: {
      Authorization: `Basic ${encoding.b64encode(`${QUEUE_USER}:${QUEUE_PASS}`)}`,
    },
    tags: { name: 'queue_overview' },
  });

  const queueOk = check(queueRes, {
    'queue API reachable': (r) => r.status === 200,
  });
  errorRate.add(!queueOk);

  sleep(1);
}
