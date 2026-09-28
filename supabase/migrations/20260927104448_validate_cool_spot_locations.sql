alter table public.cool_spots
    add constraint cool_spots_location_valid
        check (
            not gis.st_isempty(location::gis.geometry)
            and gis.st_isvalid(location::gis.geometry)
        );