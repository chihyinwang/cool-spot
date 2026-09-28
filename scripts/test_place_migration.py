"""Rehearse the Places migration locally, before applying it permanently.

Run from the prototype checkout:
    prove --exec python3 scripts/test_place_migration.py

The SQL suite owns BEGIN/ROLLBACK. This runner inlines the actual migration
because the Supabase pgTAP container copies test files without their includes.
It never resets a database or records an applied migration version.
"""

from pathlib import Path
import subprocess
import sys


root = Path(__file__).resolve().parents[1]
migration_name = "20260928145903_split_places_from_cool_spots.sql"
test_path = root / "supabase/tests/migrations/split_places_from_cool_spots.test.sql"
migration_path = root / "supabase/migrations" / migration_name
include = f"\\ir ../../migrations/{migration_name}"
test_sql = test_path.read_text()

if test_sql.count(include) != 1:
    sys.exit("Expected one migration include in the rehearsal test.")

result = subprocess.run(
    [
        "docker", "exec", "-i", "supabase_db_cool-spot-prototype",
        "psql", "-U", "postgres", "-d", "postgres", "-X", "--no-password",
        "-qAt", "-v", "ON_ERROR_STOP=1",
    ],
    input=test_sql.replace(include, migration_path.read_text()),
    text=True,
    cwd=root,
)
sys.exit(result.returncode)
