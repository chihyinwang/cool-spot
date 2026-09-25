"""Write the producer contract used to validate this prototype response."""
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
def obj(properties, required=None):
    return {'type':'object','properties':properties,'required':list(properties) if required is None else required,'additionalProperties':True}
def string(description='', **extra): return {'type':'string',**({'description':description} if description else {}),**extra}
def nullable(schema): return {'anyOf':[schema,{'type':'null'}]}
def array(schema): return {'type':'array','items':schema}
def code(*values): return string(enum=list(values))
def ref(name): return {'$ref':'#/$defs/'+name}
availability=code('yes','no','unknown')
photo=obj({
    'id':string('Stable photo resource ID; not a URL.',minLength=1),
    'thumbnailURL':string(format='uri'),'imageURL':string(format='uri'),
    'width':{'type':'integer','minimum':1},'height':{'type':'integer','minimum':1},
    'caption':nullable(string(maxLength=500)),
    'capturedAt':nullable(string('Known capture time; never substitute upload time.',format='date-time')),
    'publishedAt':nullable(string(format='date-time')),
    'attribution':string(), 'source':code('community','provider','illustration'),
    'contributionID':nullable(string('Related reviewed place-information contribution, if any.'))})
item=obj({
    'id':string('Opaque Cool Spot identity; new records use UUIDs, older prototype identities remain valid.',minLength=1),
    'name':string(minLength=1,maxLength=300),
    'location':obj({'latitude':{'type':'number','minimum':-90,'maximum':90},'longitude':{'type':'number','minimum':-180,'maximum':180},'scope':code('venue','specific_area','unknown')}),
    'address':obj({'formatted':nullable(string()),'line1':nullable(string()),'line2':nullable(string()),'locality':nullable(string()),'borough':nullable(string()),'postalCode':nullable(string()),'countryCode':nullable(string(pattern='^[A-Z]{2}$'))}),
    'placeType':code('library','community','faith','culture','leisure','shop','food','park','square','waterside','transport','other','unknown'),
    'setting':code('indoors','outdoors','both','unknown'),
    'coolingFeatures':array(code('air_conditioning','fans','natural_ventilation','tree_shade','structural_shade','cooler_indoors','water_nearby')),
    'coolingDetails':nullable(string()),
    'additionalInformation':nullable(string('Reviewed public information; excludes correction/removal reasons.')),
    'access':obj({'cost':code('free','purchase_required','entry_fee','unknown'),'eligibility':code('everyone','limited','unknown'),
                  'eligibilityDetails':nullable(string()),'seating':code('yes','limited','no','unknown'),'drinkingWater':availability,
                  'toilets':code('on_site','nearby','not_on_site','none','unknown'),'wheelchairAccess':availability,
                  'staffedWhenOpen':availability,'tables':availability,
                  'areaDescription':nullable(string('Specific area identification, not turn-by-turn directions.')),
                  'postedStayLimit':{'oneOf':[
                      obj({'status':code('limited'),'minutes':{'type':'integer','minimum':1}}),
                      obj({'status':code('unknown','no_stated_limit'),'minutes':{'type':'null'}})]}}),
    'hours':nullable(obj({'text':string(minLength=1),'timeZone':string()})),
    'photos':array(ref('photo')),
    'sourceReferences':array(obj({'sourceID':string(),'recordID':string()})),
    'provenance':array(obj({'sourceID':string(),'recordID':string(),'recordedAt':nullable(string(format='date-time')),'method':code('imported','dataset_context','name_rule','reviewed_contribution'),
                          'fields':array(string('JSON Pointer to the field whose evidence this describes.'))})),
    'mapReferences':array(obj({'provider':code('apple_maps'),'placeID':string(minLength=1),
                              'relationship':code('same_place','within_place'),'verification':code('automatic','reviewed'),
                              'checkedAt':nullable(string(format='date-time'))}))})
schema={
    '$schema':'https://json-schema.org/draft/2020-12/schema',
    '$id':'https://coolspot.example/schemas/cool-spots-response-v4.json',
    'title':'Cool Spots list response v4',
    'description':'Read representation, not a database schema or write request. Only published photos and accepted same-place map links are returned. Candidate reconciliation lives in a separate audit export. Unknown facts are explicit, and omitted future fields must not break readers.',
    **obj({'schemaVersion':{'const':4},'datasetID':string(),'generatedAt':string(format='date-time'),
           'sources':array(obj({'id':string(),'provider':string(),'label':string(),'dataset':string(),'url':nullable(string(format='uri')),
                                'isExample':{'type':'boolean'},'downloadURL':string(format='uri'),'retrievedAt':nullable(string(format='date-time')),
                                'sourceUpdatedAt':nullable(string(format='date-time')),'sha256':string(pattern='^[0-9a-f]{64}$')},required=['id','provider','label'])),
           'items':array(ref('coolSpot'))}),
    '$defs':{'coolSpot':item,'photo':photo}}
(ROOT/'data/cool-spots/cool-spots-response.schema.json').write_text(json.dumps(schema,indent=2)+'\n')
