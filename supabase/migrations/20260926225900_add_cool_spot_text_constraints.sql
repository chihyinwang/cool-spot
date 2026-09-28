alter table public.cool_spots
    add constraint cool_spots_id_not_empty
        check (char_length(id) > 0),
    add constraint cool_spots_name_length
        check (char_length(name) between 1 and 300);