"""Validate the public response and cross-file mapping invariants (requires jsonschema)."""
import json
from pathlib import Path
import jsonschema

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / 'data/catalogue'
def load(path): return json.loads(path.read_text())
export = load(DATA / 'coolspot-catalogue-mapping.json')
response = load(ROOT / 'cool-spot/Resources/CoolSpotCatalog.prototype.json')
schema = load(DATA / 'coolspot-catalogue.schema.json')
jsonschema.Draft202012Validator.check_schema(schema)
validator = jsonschema.Draft202012Validator(schema, format_checker=jsonschema.FormatChecker())
validator.validate(response)
validator.validate(export)
community = load(ROOT / "cool-spot/Resources/CommunityCatalog.prototype.json")
validator.validate(community)
assert {i["id"] for i in community["items"]}.isdisjoint(i["id"] for i in response["items"])
assert all(i["location"]["scope"] == "unknown" and i["access"]["eligibility"] == "unknown" for i in response["items"])
assert response["sources"][0]["retrievedAt"] is None
assert community["sources"][0]["isExample"] is True
assert response['items'] == export['items']
source_ids = {str(f['properties']['cs_indoor_site_id']) for f in load(DATA / 'gla-cool-spaces-2025.geojson')['features']}
registry = load(DATA / 'identity-registry.json')
items = response['items']
assert len(items) == len(source_ids) == 250
assert len({i['id'] for i in items}) == len(items)
assert {i['sourceReferences'][0]['recordID'] for i in items} == source_ids
accepted = []
for item, row in zip(items, export['mapping']['results']):
    sid = item['sourceReferences'][0]['recordID']
    assert item['id'] == registry[sid] == row['coolSpotID']
    assert row['sourceRecordID'] == sid
    assert item['photos'] == []  # This source supplies no photographs.
    if row['status'] in ('auto_matched', 'reviewed_matched', 'reviewed_related'):
        assert len(item['mapReferences']) == 1
        assert item['mapReferences'][0]['placeID'] == row['selectedPlaceID']
        selected = next(c for c in row['candidates'] if c['placeID'] == row['selectedPlaceID'])
        if row['status'] == 'auto_matched': assert selected['evidence']['meetsAutomaticRule']
        else: assert row['review']['evidenceURLs']
        assert item['mapReferences'][0]['relationship'] == ('within_place' if row['status'] == 'reviewed_related' else 'same_place')
        if row['status'] != 'reviewed_related': accepted.append(row['selectedPlaceID'])
    else: assert not item['mapReferences'] and row['selectedPlaceID'] is None
    for evidence in item['provenance']:
        for pointer in evidence['fields']:
            value = item
            for key in pointer.lstrip('/').split('/'): value = value[key]
assert len(accepted) == len(set(accepted))
assert sum(export['mapping']['summary']['byStatus'].values()) == len(items)
photo_validator = jsonschema.Draft202012Validator(schema['$defs']['photo'], format_checker=jsonschema.FormatChecker())
for photo in load(ROOT / 'cool-spot/Resources/ExamplePlacePhotos.json'): photo_validator.validate(photo)
print('PASS: v3 JSON Schema, 250 GLA + 3 community records, unique IDs, provenance, accepted links, unknown source scope/eligibility, photos')
