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
    'id':string('Cool Spot identity owned by this service, independent of GLA/Apple IDs.',format='uuid'),
    'name':string(minLength=1,maxLength=300),
    'location':obj({'latitude':{'type':'number','minimum':-90,'maximum':90},'longitude':{'type':'number','minimum':-180,'maximum':180},'scope':code('venue','specific_area','unknown')}),
    'address':obj({'line1':string(),'line2':nullable(string()),'locality':string(),'borough':nullable(string()),'postalCode':nullable(string()),'countryCode':string(pattern='^[A-Z]{2}$')}),
    'placeType':code('library','community','faith','culture','leisure','shop','food','park','square','waterside','transport','unknown'),
    'setting':code('indoors','outdoors','both','unknown'),
    'coolingFeatures':array(code('air_conditioning','fans','natural_ventilation','tree_shade','structural_shade','cooler_indoors')),
    'coolingDetails':nullable(string()),
    'access':obj({'cost':code('free','purchase_required','entry_fee','unknown'),'eligibility':code('everyone','limited','unknown'),
                  'eligibilityDetails':nullable(string()),'seating':availability,'drinkingWater':availability,
                  'toilets':code('on_site','nearby','none','unknown'),'wheelchairAccess':availability,
                  'staffedWhenOpen':availability,'tables':availability,
                  'instructions':nullable(string('Specific area identification, not turn-by-turn directions.')),
                  'postedStayLimitMinutes':nullable({'type':'integer','minimum':1})}),
    'hours':nullable(obj({'text':string(minLength=1),'timeZone':string()})),
    'photos':array(ref('photo')),
    'sourceReferences':array(obj({'sourceID':string(),'recordID':string()})),
    'provenance':array(obj({'sourceID':string(),'method':code('imported','dataset_context','name_rule','reviewed_contribution'),
                          'fields':array(string('JSON Pointer to the field whose evidence this describes.'))})),
    'mapReferences':array(obj({'provider':code('apple_maps'),'placeID':string(minLength=1),
                              'relationship':code('same_place'),'verification':code('automatic','reviewed'),
                              'checkedAt':string(format='date-time')}))})
schema={
    '$schema':'https://json-schema.org/draft/2020-12/schema',
    '$id':'https://coolspot.example/schemas/catalogue-v2.json',
    'title':'Cool Spot prototype catalogue response v2',
    'description':'Read representation, not a database schema or write request. Only published photos and accepted same-place map links are returned. Candidate reconciliation lives in a separate audit export. Unknown facts are explicit, and omitted future fields must not break readers.',
    **obj({'schemaVersion':{'const':2},'catalogID':string(),'generatedAt':string(format='date-time'),
           'sources':array(obj({'id':string(),'provider':string(),'label':string(),'dataset':string(),'url':nullable(string(format='uri')),
                                'downloadURL':string(format='uri'),'retrievedAt':string(format='date-time'),
                                'sourceUpdatedAt':nullable(string(format='date-time')),'sha256':string(pattern='^[0-9a-f]{64}$')},required=['id','provider','label'])),
           'items':array(ref('coolSpot'))}),
    '$defs':{'coolSpot':item,'photo':photo}}
(ROOT/'data/catalogue/coolspot-catalogue.schema.json').write_text(json.dumps(schema,indent=2)+'\n')
