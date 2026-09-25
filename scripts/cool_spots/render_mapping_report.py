"""Generate the explorable review view from the same audited export as the app."""
import json
import sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
payload=json.loads((ROOT/'data/cool-spots/cool-spots-mapping.json').read_text())
audit_path=ROOT/'data/cool-spots/discovery-audit.json'
samples={r['sourceRecordID']:r for r in json.loads(audit_path.read_text())['cases']} if audit_path.exists() else {}
rows=[]
for row in payload['mapping']['results']:
    row=dict(row)
    row['sample']=samples.get(row['sourceRecordID'])
    row['candidateCount']=len(row['candidates'])
    chosen=next((c for c in row['candidates'] if c['placeID']==row['selectedPlaceID']),None)
    row['candidates']=([chosen] if chosen else [])+[c for c in row['candidates'] if c is not chosen][:3 if not chosen else 2]
    rows.append(row)
data=json.dumps({'summary':payload['mapping']['summary'],'rows':rows},ensure_ascii=False,separators=(',',':')).replace('<','\\u003c')
fragment=(Path(__file__).parent/'mapping-report.fragment.html').read_text().replace('__MAPPING_DATA__',data)
destination=Path(sys.argv[1]);destination.write_text(fragment)
assert destination.stat().st_size<1_000_000
print(str(destination),destination.stat().st_size,'bytes')
