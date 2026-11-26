import assert from 'node:assert/strict';
import { generateKeyPairSync, sign } from 'node:crypto';
import test from 'node:test';

import {
  firebaseClaims,
  firebaseLogin,
  firebaseProjectId,
  FirebaseTokenError,
} from '../api/feature-routes.ts';

const { privateKey, publicKey } = generateKeyPairSync('rsa', {
  modulusLength: 2048,
});
const publicKeyPem = publicKey.export({ type: 'spki', format: 'pem' });

globalThis.fetch = async () => ({
  ok: true,
  headers: { get: () => 'max-age=3600' },
  json: async () => ({ testKid: publicKeyPem }),
});

function createFirebaseToken(overrides = {}) {
  const now = Math.floor(Date.now() / 1000);
  const header = Buffer.from(
    JSON.stringify({ alg: 'RS256', kid: 'testKid', typ: 'JWT' }),
  ).toString('base64url');
  const payload = Buffer.from(JSON.stringify({
    aud: firebaseProjectId,
    iss: `https://securetoken.google.com/${firebaseProjectId}`,
    sub: 'google-user-123',
    email: 'customer@example.com',
    email_verified: true,
    iat: now - 5,
    auth_time: now - 10,
    exp: now + 3600,
    ...overrides,
  })).toString('base64url');
  const input = `${header}.${payload}`;
  const signature = sign('RSA-SHA256', Buffer.from(input), privateKey)
    .toString('base64url');
  return `${input}.${signature}`;
}

test('Firebase ID token remains valid when Vercel has a stale project ID env', async () => {
  const previousProjectId = process.env.FIREBASE_PROJECT_ID;
  process.env.FIREBASE_PROJECT_ID = 'old-project-id';
  try {
    const claims = await firebaseClaims(createFirebaseToken());
    assert.equal(claims.sub, 'google-user-123');
  } finally {
    if (previousProjectId === undefined) delete process.env.FIREBASE_PROJECT_ID;
    else process.env.FIREBASE_PROJECT_ID = previousProjectId;
  }
});

test('Firebase ID token from another project is rejected with a clear auth error', async () => {
  await assert.rejects(
    firebaseClaims(createFirebaseToken({ aud: 'another-project' })),
    (error) => error instanceof FirebaseTokenError && /proyek Firebase yang berbeda/.test(error.message),
  );
});

test('expired Firebase ID token is rejected as expired', async () => {
  const now = Math.floor(Date.now() / 1000);
  await assert.rejects(
    firebaseClaims(createFirebaseToken({ exp: now - 1 })),
    (error) => error instanceof FirebaseTokenError && /kedaluwarsa/.test(error.message),
  );
});

test('Google login cannot authenticate an admin account', async () => {
  const calls = [];
  const sql = {
    query: async (...args) => {
      calls.push(args);
      return { rows: [{ id: 'admin-1', name: 'Admin', email: 'customer@example.com', role: 'admin' }] };
    },
  };
  const response = {
    statusCode: 200,
    status(code) { this.statusCode = code; return this; },
    json(body) { this.body = body; return this; },
  };

  await firebaseLogin(
    { method: 'POST', body: { id_token: createFirebaseToken() } },
    response,
    sql,
  );

  assert.equal(response.statusCode, 403);
  assert.match(response.body.message, /Akun admin/);
  assert.equal(calls.length, 1);
});
