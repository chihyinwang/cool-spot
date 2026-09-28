-- Evidence keys refer only to supported adopted fields, including address_line1/2.
alter table public.place_field_evidence
    drop constraint place_field_evidence_field_key_check,
    add constraint place_field_evidence_field_key_check
    check (field_key in (
        'cool_spots.additional_information',
        'cool_spots.area_description',
        'cool_spots.cooling_details',
        'cool_spots.cooling_features',
        'cool_spots.cost',
        'cool_spots.drinking_water',
        'cool_spots.eligibility',
        'cool_spots.hours_text',
        'cool_spots.hours_time_zone',
        'cool_spots.posted_stay_limit_minutes',
        'cool_spots.posted_stay_limit_status',
        'cool_spots.seating',
        'cool_spots.setting',
        'cool_spots.staffed_when_open',
        'cool_spots.tables',
        'cool_spots.toilets',
        'cool_spots.wheelchair_access',
        'places.address_borough',
        'places.address_country_code',
        'places.address_formatted',
        'places.address_line1',
        'places.address_line2',
        'places.address_locality',
        'places.address_postal_code',
        'places.location.latitude',
        'places.location.longitude',
        'places.name',
        'places.place_type'
    ));
