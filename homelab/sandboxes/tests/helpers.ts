import { check } from 'k6';
import { Rate, Trend } from 'k6/metrics';
import http, { RefinedResponse, ResponseType } from 'k6/http';

export const errorRate = new Rate('errors');
export const latency = new Trend('request_latency', true);

export const defaultThresholds = {
  http_req_failed: ['rate<0.01'],
  http_req_duration: ['p(95)<500', 'p(99)<1000'],
  errors: ['rate<0.1'],
};

// Scenario presets for consistent test profiles across architectures
export const scenarios = {
  smoke: {
    executor: 'constant-vus',
    vus: 1,
    duration: '30s',
  },
  load: {
    executor: 'ramping-vus',
    startVUs: 0,
    stages: [
      { duration: '1m', target: 10 },
      { duration: '3m', target: 10 },
      { duration: '1m', target: 0 },
    ],
  },
  stress: {
    executor: 'ramping-vus',
    startVUs: 0,
    stages: [
      { duration: '1m', target: 20 },
      { duration: '2m', target: 50 },
      { duration: '2m', target: 100 },
      { duration: '1m', target: 0 },
    ],
  },
};

export function checkResponse(res: RefinedResponse<ResponseType>, name: string) {
  const passed = check(res, {
    [`${name}: status 200`]: (r) => r.status === 200,
    [`${name}: response time < 500ms`]: (r) => r.timings.duration < 500,
    [`${name}: has body`]: (r) => r.body !== null && r.body.toString().length > 0,
  });

  errorRate.add(!passed);
  latency.add(res.timings.duration);
  return passed;
}

export function httpGet(url: string, name: string) {
  const res = http.get(url, { tags: { name } });
  checkResponse(res, name);
  return res;
}
