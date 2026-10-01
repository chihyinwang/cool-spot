"""Run the local backend without exposing credentials or accepting cloud URLs."""
import argparse
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import sys
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
FUNCTION = 'supabase/functions/cool-spots/'
DENO = '/opt/homebrew/bin/deno'
DOCKER = '/Applications/Docker.app/Contents/Resources/bin/docker'


def settings():
    path = ROOT / '.env.backend.local'
    info = path.lstat()
    if not stat.S_ISREG(info.st_mode) or stat.S_IMODE(info.st_mode) != 0o600 or info.st_uid != os.getuid():
        raise ValueError('Backend settings must be a regular owner-only 0600 file')
    ignored = subprocess.run(['git', 'check-ignore', '-q', '--', str(path)], cwd=ROOT, capture_output=True)
    if ignored.returncode:
        raise ValueError('Backend settings must remain ignored by Git')
    lines = [line.strip() for line in path.read_text().splitlines() if line.strip() and not line.lstrip().startswith('#')]
    if len(lines) != 1 or not lines[0].startswith('COOL_SPOTS_DATABASE_URL='):
        raise ValueError('Backend settings require only COOL_SPOTS_DATABASE_URL')
    value = lines[0].split('=', 1)[1].strip().strip('\"\'')
    url = urlsplit(value)
    if (url.scheme != 'postgresql' or url.hostname != '127.0.0.1' or url.port != 54322
            or url.username != 'cool_spots_api' or not url.password or url.path != '/postgres' or url.query or url.fragment):
        raise ValueError('Only the dedicated prototype backend login on 127.0.0.1:54322 is allowed')
    return value, [value, url.password, unquote(url.password)]


def local_database():
    if os.environ.get('DOCKER_HOST') or os.environ.get('DOCKER_CONTEXT'):
        raise ValueError('Unset Docker endpoint/context overrides for local verification')
    result = subprocess.run([DOCKER, 'context', 'inspect'], capture_output=True, text=True, check=True)
    context = json.loads(result.stdout)[0]
    if not context['Endpoints']['docker']['Host'].startswith('unix://'):
        raise ValueError('A local Unix-socket Docker context is required')
    command = [DOCKER, '--context', context['Name']]
    health = subprocess.run(command + ['inspect', '--format', '{{.State.Health.Status}}', 'supabase_db_cool-spot-prototype'], capture_output=True, text=True, check=True)
    if health.stdout.strip() != 'healthy':
        raise ValueError('The prototype database is not healthy; no services were changed')


def redact(output, secrets):
    for value in sorted(set(secrets), key=len, reverse=True):
        if value:
            output = output.replace(value, '[REDACTED]')
    return re.sub(r'postgres(?:ql)?://[^\s\"\'<>]+', '[REDACTED_DATABASE_URL]', output)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('operation', choices=['test', 'serve'])
    parser.add_argument('--api-only', action='store_true', help='Run only the API integration batch')
    args = parser.parse_args()
    value, secrets = settings()
    local_database()
    environment = {key: item for key, item in os.environ.items() if not key.startswith('PG')}
    environment['COOL_SPOTS_DATABASE_URL'] = value
    flags = ['--no-prompt', '--cached-only', '--frozen', '--lock=' + FUNCTION + 'deno.lock',
             '--allow-env=COOL_SPOTS_DATABASE_URL,PGHOST,PGPORT,PGDATABASE,PGUSERNAME,PGUSER,PGPASSWORD,PGAPPNAME,PGSSLMODE,PGCONNECT_TIMEOUT,PGTARGETSESSIONATTRS,PGMAX,PGSSL,PGSSLNEGOTIATION,PGIDLE_TIMEOUT,PGMAX_LIFETIME,PGMAX_PIPELINE,PGBACKOFF,PGKEEP_ALIVE,PGPREPARE,PGDEBUG,PGFETCH_TYPES,PGPUBLICATIONS,PGTARGET_SESSION_ATTRS',
             '--allow-net=127.0.0.1']
    if args.operation == 'test':
        files = ['api_integration_test.ts'] if args.api_only else ['handler_test.ts', 'response_test.ts', 'database_integration_test.ts', 'api_integration_test.ts', 'server_test.ts']
        result = subprocess.run([DENO, 'test', *flags, *[FUNCTION + name for name in files]], cwd=ROOT, env=environment, capture_output=True, text=True)
        print(redact(result.stdout + result.stderr, secrets), end='')
        return result.returncode
    process = subprocess.Popen([DENO, 'run', *flags, FUNCTION + 'serve_local.ts'], cwd=ROOT, env=environment, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    try:
        for line in process.stdout:
            print(redact(line, secrets), end='', flush=True)
        return process.wait()
    finally:
        if process.poll() is None:
            process.terminate()
            process.wait(timeout=10)


if __name__ == '__main__':
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
    except ValueError as error:
        # These messages are authored above; parser/driver values are withheld.
        if str(error).startswith(('Backend settings', 'Only the dedicated', 'Unset Docker', 'A local Unix', 'The prototype')):
            print(str(error), file=sys.stderr)
        else:
            print('Local backend configuration failed; details withheld', file=sys.stderr)
        sys.exit(1)
    except Exception:
        print('Local backend operation failed; details withheld', file=sys.stderr)
        sys.exit(1)
