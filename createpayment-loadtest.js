import http from 'k6/http';
import { check } from 'k6';
import { uuidv4 } from 'https://jslib.k6.io/k6-utils/1.4.0/index.js';

// =============================================================================
// PaymentServices RTPSend — full-pipeline load test (QA)
//
// Drives CreatePayment at a constant arrival rate. Each iteration sends a
// UNIQUE paymentReference (CreatePayment dedupes on it via Cosmos 409), so
// every request exercises the full async pipeline:
//   CreatePayment -> ProcessPayment -> Gateway -> AccountResolution
//   -> Transfer (ledger debit + limits + screening) -> RTPSend outcome -> TabaPay
//
// Config via environment variables (set in Azure Load Testing):
//   BASE_URL      e.g. https://fa-pmtsvc-rtpsend-qa-centralus.azurewebsites.net
//   FUNCTION_KEY  the CreatePayment function key (x-functions-key)
//   TPS           target transactions/sec (default 20)
//   DURATION      test duration (default 2m)
//   AMOUNT        per-payment amount (default 0.90)
// =============================================================================

const BASE_URL = __ENV.BASE_URL;
const FUNCTION_KEY = __ENV.FUNCTION_KEY || '';
const TPS = parseInt(__ENV.TPS || '20', 10);
const DURATION = __ENV.DURATION || '2m';
const AMOUNT = __ENV.AMOUNT || '0.90';

export const options = {
  scenarios: {
    full_pipeline: {
      executor: 'constant-arrival-rate',
      rate: TPS,            // iterations per timeUnit
      timeUnit: '1s',       // => TPS requests per second
      duration: DURATION,
      preAllocatedVUs: TPS * 3,
      maxVUs: TPS * 10,
    },
  },
  thresholds: {
    // Intake (HTTP 202) should stay fast and not error. Pipeline outcome is
    // async and NOT measured by these HTTP thresholds.
    http_req_failed: ['rate<0.01'],          // <1% intake errors
    http_req_duration: ['p(95)<2000'],       // 95% of intake calls under 2s
    'checks{type:intake}': ['rate>0.99'],
  },
};

export default function () {
  // Unique per iteration so CreatePayment never dedupes (409).
  const ref = uuidv4();

  const body = {
    paymentReference: ref,
    sourceAccountId: null,
    sourceAccount: {
      accountNumber: '9010010000000001',
      name: { company: null, first: 'Earnin', last: 'Merchant' },
      address: null,
      routingNumber: '084009593',
      accountType: 'S',
      debtorBankMemberID: null,
      debtorIdOther: null,
    },
    destinationAccountId: null,
    destinationAccount: {
      accountNumber: '900397187386253',
      name: { company: null, first: 'Sarah', last: 'Robinson' },
      routingNumber: '101115315',
      accountType: 'C',
      address: {
        addressLines: ['123 First Street'],
        city: 'Omaha',
        county: null,
        countryISOCode: '840',
        postalCode: '',
        stateCode: 'NE',
      },
      phoneNumber: '4022221144',
      creditorAgentTCHMemberID: null,
      creditorIdOther: null,
    },
    amount: AMOUNT,
    ultimateDebtor: { name: 'ultimate' },
    sourceCurrency: null,
    paymentCurrency: null,
    softDescriptor: null,
  };

  const headers = { 'Content-Type': 'application/json' };
  if (FUNCTION_KEY) headers['x-functions-key'] = FUNCTION_KEY;

  const res = http.post(`${BASE_URL}/api/CreatePayment`, JSON.stringify(body), { headers });

  check(res, {
    'intake accepted (200/202)': (r) => r.status === 200 || r.status === 202,
    'not deduped (409)': (r) => r.status !== 409,
    'not server error (5xx)': (r) => r.status < 500,
  }, { type: 'intake' });
}
