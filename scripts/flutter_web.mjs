import { readFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';

const mode = process.argv[2] ?? 'build';
const webPort = process.env.WEB_PORT ?? '7357';
if (!['build', 'run'].includes(mode)) {
  throw new Error('Gunakan: node scripts/flutter_web.mjs [build|run]');
}

const firebaseConfig = JSON.parse(
  readFileSync('android/app/google-services.json', 'utf8'),
);
const apiKey = firebaseConfig.client?.[0]?.api_key?.[0]?.current_key;
if (!apiKey) throw new Error('current_key tidak ditemukan di google-services.json.');

const flutterArgs = mode === 'run'
  ? [
      'run',
      '--no-pub',
      '-d', 'web-server',
      '--web-hostname', 'localhost',
      '--web-port', webPort,
      '--dart-define=API_BASE_URL=https://geminiflo-api.vercel.app/api',
    ]
  : ['build', 'web', '--release', '--no-pub'];

flutterArgs.push(`--dart-define=FIREBASE_WEB_API_KEY=${apiKey}`);

const result = spawnSync('flutter', flutterArgs, {
  stdio: 'inherit',
  shell: process.platform === 'win32',
});
if (result.error) throw result.error;
process.exitCode = result.status ?? 1;
