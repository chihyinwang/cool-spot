"""Reproducible GLA adapter and conservative Apple candidate reconciliation.

No network calls; raw source and lookup checkpoints are inputs. Audit output is
separate from the compact app response. Re-running preserves registered IDs.
"""
import collections
import datetime as dt
import difflib
import hashlib
import json
from pathlib import Path
import re
import unicodedata
import uuid

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / 'data/catalogue'
SOURCE_URL = 'https://data.london.gov.uk/download/2z19p/blw/CoolSpaceSites_2025.json'
DATASET_URL = 'https://data.london.gov.uk/dataset/cool-space-data-2025-2z19p'
SOURCE_ID = 'gla-cool-spaces-2025'

def text(value):
    return re.sub(r'\s+', ' ', str(value)).strip() if value is not None else None

def normalized(value):
    value = unicodedata.normalize('NFKD', value or '').encode('ascii', 'ignore').decode().lower()
    value = re.sub(r"['’]", '', value).replace('&', ' and ')
    value = re.sub(r'\bsaint\b', 'st', value)
    value = re.sub(r'\b(rd|st|ave)\b', lambda m: {'rd':'road','st':'st','ave':'avenue'}[m[0]], value)
    return ' '.join(re.findall(r'[a-z0-9]+', value))

def availability(value):
    return {'yes':'yes','no':'no'}.get((text(value) or '').lower(), 'unknown')

def classify(name):
    name = normalized(name)
    for pattern, code in [(r'\blibrar', 'library'), (r'\b(church|cathedral|chapel|mosque|synagogue|temple|salvation army)\b', 'faith'),
                          (r'\b(museum|gallery|theatre|theater)\b', 'culture'), (r'\b(leisure|sports|gym|swimming)\b', 'leisure'),
                          (r'\b(community|resource|hub|civic|town hall)\b','community')]:
        if re.search(pattern,name): return code
    return 'unknown'

def source_fingerprint(feature):
    return hashlib.sha256(json.dumps(feature,sort_keys=True,separators=(',',':')).encode()).hexdigest()

def evaluate(p, candidates):
    output=[]
    for candidate in candidates:
        c=dict(candidate)
        a,b=normalized(p.get('cs_name')),normalized(c['name'])
        # Article differences do not change identity. Other differences remain evidence.
        a=re.sub(r'^the ', '', a); b=re.sub(r'^the ', '', b)
        similarity=difflib.SequenceMatcher(None,a,b).ratio()
        postcode=(text(p.get('cs_postcode')) or '').replace(' ','').upper()
        postcode_match=bool(postcode and postcode==c['postalCode'].replace(' ','').upper())
        postcode_conflict=bool(postcode and c['postalCode'] and not postcode_match)
        sa,ca=normalized(p.get('cs_address_one')),normalized(c['address'])
        nums_a=set(re.findall(r'\b\d+[a-z]?\b',sa)); nums_b=set(re.findall(r'\b\d+[a-z]?\b',ca))
        tokens_a=set(sa.split())-nums_a; tokens_b=set(ca.split())-nums_b
        street_overlap=len(tokens_a&tokens_b)/max(1,len(tokens_a|tokens_b))
        distinctive=(tokens_a&tokens_b)-{'road','rd','street','st','lane','avenue','way','london'}
        address_match=bool(distinctive and street_overlap>=.8 and
                           (not nums_a or not nums_b or bool(nums_a&nums_b)))
        number_conflict=bool(nums_a and nums_b and not nums_a&nums_b)
        close=c['distanceMetres']<=150
        strong_name=a==b or (similarity>=.94 and set(a.split())&set(b.split()))
        eligible=bool(c['placeID'] and close and strong_name and (postcode_match or address_match) and not number_conflict and not postcode_conflict)
        c['evidence']={'nameSimilarity':round(similarity,3),'exactName':a==b,'postcodeAgrees':postcode_match,
                       'streetAgrees':address_match,'streetNumberConflicts':number_conflict,'postcodeConflicts':postcode_conflict,
                       'within150Metres':close,'meetsAutomaticRule':eligible}
        output.append(c)
    return sorted(output,key=lambda c:(c['evidence']['meetsAutomaticRule'],c['evidence']['nameSimilarity'],-c['distanceMetres']),reverse=True)

def build():
    raw=DATA/'gla-cool-spaces-2025.geojson'
    features=json.loads(raw.read_text())['features']
    registry=json.loads((DATA/'identity-registry.json').read_text())
    lookups=collections.defaultdict(list)
    for filename in ['apple-candidates.json','apple-address-candidates.json','apple-identifier-candidates.json']:
        if (DATA/filename).exists():
            for row in json.loads((DATA/filename).read_text()): lookups[row['siteID']].append(row)
    reviews={r['sourceRecordID']:r for r in json.loads((DATA/'review-decisions.json').read_text())} if (DATA/'review-decisions.json').exists() else {}
    now=dt.datetime.now(dt.timezone.utc).isoformat(timespec='seconds').replace('+00:00','Z')
    items=[]; results=[]
    for f in features:
        p=f['properties']; sid=str(p['cs_indoor_site_id']); lon,lat=f['geometry']['coordinates']
        registry.setdefault(sid,str(uuid.uuid5(uuid.NAMESPACE_URL,f'https://coolspot.invalid/sources/gla/2025/{sid}')))
        problems=[]
        if not (-90<=lat<=90 and -180<=lon<=180) or not text(p.get('cs_name')):
            raise ValueError(f'Invalid source identity/location: {sid}')
        cooling=[]
        code_map={'air conditioning':'air_conditioning','stand up fans':'fans','ceiling fans':'fans',
                  'natural cooling/ventilation':'natural_ventilation','natural colling/ventilation':'natural_ventilation'}
        for value in (p.get('cs_cooling_facilities') or '').split(','):
            key=value.strip().lower()
            if key in code_map: cooling.append(code_map[key])
            elif key and key not in ('other','none'): problems.append('Unrecognised cooling facility: '+value)
        if not cooling: problems.append('Source does not specify a recognised cooling feature')
        place_type=classify(p['cs_name'])
        if place_type=='unknown': problems.append('Place type needs classification')
        attempts=lookups.get(sid,[])
        row=attempts[-1] if attempts else None
        unique_candidates={}
        for attempt in attempts:
            for c in attempt.get('candidates',[]):
                key=c['placeID'] or (c['name'],c['latitude'],c['longitude'])
                unique_candidates[key]={**c,'query':attempt['query'],'queriedAt':attempt['queriedAt']}
        candidates=evaluate(p,unique_candidates.values())
        qualified=[c for c in candidates if c['evidence']['meetsAutomaticRule']]
        if row is None: status,reason='not_checked','Apple lookup has not completed'
        elif len(qualified)==1: status,reason='auto_matched','One candidate agrees on name, address and distance within 150 m'
        elif len(qualified)>1: status,reason='needs_review','Multiple candidates satisfy the automatic rule'
        elif not candidates:
            error=row.get('error')
            if error and not (error['domain']=='MKErrorDomain' and error['code']==4):
                status,reason='lookup_failed','Latest Apple lookup failed; this is not a no-match result'
            else: status,reason='no_candidate','Apple returned no place for the recorded queries; manual search may still find it'
        else: status,reason='needs_review','Candidates exist, but name/address/distance do not safely establish identity'
        chosen=qualified[0] if status=='auto_matched' else None
        review=reviews.get(sid)
        if review:
            reviewed_candidate=next((c for c in candidates if c['placeID']==review['placeID']),None)
            same_candidate=reviewed_candidate and all(reviewed_candidate.get(k)==v for k,v in review['candidateSnapshot'].items())
            if review['sourceFingerprint']==source_fingerprint(f) and same_candidate:
                status,reason='reviewed_matched',review['reason']
                chosen=reviewed_candidate
            else:
                status,reason,chosen='needs_review','Previous review no longer matches this source/candidate snapshot',None
        refs=[{'provider':'apple_maps','placeID':chosen['placeID'],'relationship':'same_place',
               'verification':'reviewed' if status=='reviewed_matched' else 'automatic',
               'checkedAt':review['reviewedAt'] if status=='reviewed_matched' else chosen['queriedAt']}] if chosen else []
        item={'id':registry[sid],'name':text(p['cs_name']),
              'location':{'latitude':lat,'longitude':lon,'scope':'venue'},
              'address':{'line1':text(p['cs_address_one']) or '', 'line2':text(p.get('cs_address_two')),
                         'locality':'London','borough':text(p.get('cs_borough')),'postalCode':text(p.get('cs_postcode')),'countryCode':'GB'},
              'placeType':place_type,'setting':'indoors','coolingFeatures':sorted(set(cooling)),
              'coolingDetails':text(p.get('cs_cooling_facilities_other')),
              'access':{'cost':'free' if availability(p.get('is_free_of_charge'))=='yes' else 'unknown',
                        'eligibility':'everyone','eligibilityDetails':None,
                        'seating':availability(p.get('has_seating')),'drinkingWater':availability(p.get('has_drinking_water')),
                        'toilets':{'available on site':'on_site','not available':'none','short walk and signposted from the site':'nearby'}.get((text(p.get('cs_toilets_available')) or '').lower(),'unknown'),
                        'wheelchairAccess':availability(p.get('cs_wheelchair_access')),
                        'staffedWhenOpen':availability(p.get('is_staffed_when_open')),'tables':'unknown',
                        'instructions':None,'postedStayLimitMinutes':None},
              'hours':{'text':text(p.get('cs_opening_hours')),'timeZone':'Europe/London'} if text(p.get('cs_opening_hours')) else None,
              'photos':[],
              'sourceReferences':[{'sourceID':SOURCE_ID,'recordID':sid}],
              'provenance':[
                  {'sourceID':SOURCE_ID,'method':'imported','fields':['/name','/location/latitude','/location/longitude','/address/line1','/address/line2','/address/borough','/address/postalCode','/coolingFeatures','/coolingDetails','/access/cost','/access/seating','/access/drinkingWater','/access/toilets','/access/wheelchairAccess','/access/staffedWhenOpen','/hours']},
                  {'sourceID':SOURCE_ID,'method':'dataset_context','fields':['/setting','/location/scope','/address/locality','/address/countryCode','/access/eligibility']},
                  {'sourceID':SOURCE_ID,'method':'name_rule','fields':['/placeType']}],
              'mapReferences':refs}
        items.append(item)
        results.append({'coolSpotID':item['id'],'sourceRecordID':sid,'sourceName':item['name'],
                        'borough':item['address']['borough'],'sourceAddress':item['address']['line1'],
                        'latitude':lat,'longitude':lon,'status':status,'reason':reason,
                        'selectedPlaceID':chosen['placeID'] if chosen else None,
                        'queriedAt':row.get('queriedAt') if row else None,'query':row.get('query') if row else None,
                        'error':row.get('error') if row else None,
                        'review':review,
                        'attempts':[{k:v for k,v in a.items() if k in ('query','queriedAt','error')} for a in attempts],
                        'dataWarnings':problems,'candidates':candidates})
    # Two GLA records pointing at one Apple venue require an explicit relationship decision.
    ids=collections.Counter(r['selectedPlaceID'] for r in results if r['selectedPlaceID'])
    for item,row in zip(items,results):
        if row['selectedPlaceID'] and ids[row['selectedPlaceID']]>1:
            row.update(status='needs_review',reason='Multiple GLA records point to this Apple place; do not merge automatically',selectedPlaceID=None)
            item['mapReferences']=[]
    source={'id':SOURCE_ID,'provider':'gla','label':'GLA · 2025','dataset':'Cool Space Data 2025',
            'url':DATASET_URL,'downloadURL':SOURCE_URL,'retrievedAt':dt.datetime.fromtimestamp(raw.stat().st_mtime,dt.timezone.utc).isoformat(timespec='seconds').replace('+00:00','Z'),'sourceUpdatedAt':None,
            'sha256':hashlib.sha256(raw.read_bytes()).hexdigest()}
    catalogue={'schemaVersion':2,'catalogID':'gla-2025-all','generatedAt':now,'sources':[source], 'items':items}
    counts=dict(collections.Counter(r['status'] for r in results))
    summary={'sourceRecords':len(features),'converted':len(items),'lookupsCompleted':sum(r['status']!='not_checked' for r in results),
             'byStatus':counts,'recordsWithDataWarnings':sum(bool(r['dataWarnings']) for r in results)}
    export={**catalogue,'mapping':{'algorithm':'conservative-v1','summary':summary,
          'automaticRule':'One named POI with a Place ID, exact or >=0.94 normalised name similarity, agreeing street or postcode, no street-number or postcode conflict and within 150 m; duplicate Apple destinations require review. This is a heuristic, not a calibrated probability or human verification.',
          'results':results}}
    (DATA/'identity-registry.json').write_text(json.dumps(registry,indent=2,sort_keys=True)+'\n')
    (DATA/'coolspot-catalogue-mapping.json').write_text(json.dumps(export,ensure_ascii=False,indent=2)+'\n')
    (ROOT/'cool-spot/Resources/CoolSpotCatalog.prototype.json').write_text(json.dumps(catalogue,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps(summary))

if __name__=='__main__': build()
