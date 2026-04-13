import { spawnSync } from 'node:child_process';
import { cpSync, existsSync, rmSync } from 'node:fs';

const backendUrl = process.argv[2] || process.env.BACKEND_BASE_URL || '';

const args = ['build', 'web', '--release'];
if (backendUrl) {
  args.push(`--dart-define=BACKEND_BASE_URL=${backendUrl}`);
}

const result = spawnSync('flutter', args, {
  stdio: 'inherit',
  shell: true,
});

if (result.status !== 0) {
  process.exit(result.status ?? 1);
}

if (existsSync('web')) {
  rmSync('web', { recursive: true, force: true });
}
cpSync('build/web', 'web', { recursive: true });
