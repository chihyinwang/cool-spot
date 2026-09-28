alter table public.cool_spots
    add constraint cool_spots_id_not_blank
        check (
            id collate "C" ~
            U&'[^\0009-\000D\0020\0085\00A0\1680\2000-\200B\2028\2029\202F\205F\3000]'
        ),
    add constraint cool_spots_name_not_blank
        check (
            name collate "C" ~
            U&'[^\0009-\000D\0020\0085\00A0\1680\2000-\200B\2028\2029\202F\205F\3000]'
        );