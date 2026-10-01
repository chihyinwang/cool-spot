"""Rehearse migration thirteen against the populated OLD schema, then roll back.

Run before applying 20260930220000. Never reset an already migrated database to
rerun this rehearsal. Only the named local container/Unix Docker context is used.
"""
import json
import os
from pathlib import Path
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
MIGRATION = ROOT / 'supabase/migrations/20260930220000_clarify_catalogue_sources.sql'


def local_command():
    if os.environ.get('DOCKER_HOST') or os.environ.get('DOCKER_CONTEXT'):
        raise RuntimeError('Unset Docker endpoint/context overrides before rehearsal')
    docker = shutil.which('docker') or '/Applications/Docker.app/Contents/Resources/bin/docker'
    result = subprocess.run([docker, 'context', 'inspect'], capture_output=True, text=True, check=True)
    context = json.loads(result.stdout)[0]
    if not context['Endpoints']['docker']['Host'].startswith('unix://'):
        raise RuntimeError('Rehearsal requires a local Unix-socket Docker context')
    return [docker, '--context', context['Name'], 'exec', '-i',
            'supabase_db_cool-spot-prototype', 'psql', '-U', 'postgres', '-d',
            'postgres', '-X', '--no-password', '-v', 'ON_ERROR_STOP=1', '-qAt']


class SourceStructureMigrationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.command = local_command()
        result = subprocess.run(cls.command, input="select exists(select 1 from information_schema.columns where table_schema='public' and table_name='source_records' and column_name='mapped_data');", capture_output=True, text=True)
        if result.returncode or result.stdout.strip() != 't':
            raise RuntimeError('This rehearsal requires the pre-migration schema; do not reset the database')

    def execute(self, before='', after=''):
        return subprocess.run(self.command, input='begin;\n'+before+'\n'+MIGRATION.read_text()+'\n'+after+'\nrollback;', capture_output=True, text=True)

    def test_preserves_every_row_identity_fact_archive_and_acquisition_time(self):
        unchanged = ['places', 'cool_spots', 'place_map_links', 'place_photos']
        expected = {name: 'select to_jsonb(t) as row from public.'+name+' t' for name in unchanged}
        expected.update({
            'data_sources': """select jsonb_build_object('id',id,'provider',provider,'label',label,
                'raw_file_path',raw_file_path,'raw_file_sha256',raw_sha256,
                'dataset_name',metadata->>'dataset','source_url',metadata->>'url',
                'download_url',metadata->>'downloadURL','retrieved_at',(metadata->>'retrievedAt')::timestamptz,
                'source_updated_at',(metadata->>'sourceUpdatedAt')::timestamptz,
                'is_example',coalesce((metadata->>'isExample')::boolean,false)) as row from data_sources""",
            'source_records': "select jsonb_build_object('source_id',source_id,'source_record_id',record_id,'raw_record',raw_data,'import_audit',mapping_evidence) as row from source_records",
            'place_source_links': "select (to_jsonb(t)-'record_id')||jsonb_build_object('source_record_id',record_id) as row from place_source_links t",
            'place_field_inference_records': """select (to_jsonb(t)-'record_id'-'method')||jsonb_build_object(
                'source_record_id',record_id,'derivation_method',case method
                when 'imported' then 'mapped_from_source' when 'dataset_context' then 'inferred_from_context'
                when 'name_rule' then 'inferred_from_name' when 'reviewed_contribution' then 'example_data' end)
                as row from place_field_evidence t""",
            'catalogue_import_history': "select (to_jsonb(t)-'input_sha256')||jsonb_build_object('import_payload_sha256',input_sha256) as row from catalogue_import_history t",
        })
        before = '\n'.join('create temporary table expected_'+name+' as '+query+';' for name, query in expected.items())
        after = '\n'.join("do $$ begin if exists ((select row from expected_"+name+
            ") except all (select to_jsonb(t) from public."+name+" t)) or exists ((select to_jsonb(t) from public."+name+
            " t) except all (select row from expected_"+name+")) then raise exception 'Migration changed "+name+
            "'; end if; end $$;" for name in expected)
        result = self.execute(before, after)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_refuses_to_delete_an_item_without_an_identical_retained_snapshot(self):
        result = self.execute("update source_records set mapped_data=mapped_data||'{\"unexpected\":true}' where source_id='gla-cool-spaces-2025' and record_id='18';")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Source item is not fully archived', result.stderr)

    def test_refuses_to_drop_an_unarchived_source_header(self):
        result = self.execute("update data_sources set metadata=metadata||'{\"unexpected\":true}' where id='gla-cool-spaces-2025';")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Source header/hash is not consistently archived', result.stderr)

    def test_refuses_conflicting_raw_file_and_public_hashes(self):
        result = self.execute("update data_sources set raw_sha256=repeat('0',64) where id='gla-cool-spaces-2025';")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Source header/hash is not consistently archived', result.stderr)

    def test_refuses_to_relabel_non_example_reviews_as_example_data(self):
        result = self.execute("update place_field_evidence set method='reviewed_contribution' where source_id='gla-cool-spaces-2025' and record_id='18' and field_key='places.name';")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Non-example review needs separate migration', result.stderr)


if __name__ == '__main__':
    unittest.main()
