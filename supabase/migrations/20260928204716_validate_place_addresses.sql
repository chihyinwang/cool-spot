alter table public.places
    add constraint places_address_line1_not_blank
        check (
            address_line1 collate "C" ~
            U&'[^\0009-\000D\0020\0085\00A0\1680\2000-\200B\2028\2029\202F\205F\3000]'
        ),
    add constraint places_address_line2_not_blank
        check (
            address_line2 collate "C" ~
            U&'[^\0009-\000D\0020\0085\00A0\1680\2000-\200B\2028\2029\202F\205F\3000]'
        ),
    add constraint places_address_locality_not_blank
        check (
            address_locality collate "C" ~
            U&'[^\0009-\000D\0020\0085\00A0\1680\2000-\200B\2028\2029\202F\205F\3000]'
        ),
    add constraint places_address_borough_not_blank
        check (
            address_borough collate "C" ~
            U&'[^\0009-\000D\0020\0085\00A0\1680\2000-\200B\2028\2029\202F\205F\3000]'
        ),
    add constraint places_address_postal_code_not_blank
        check (
            address_postal_code collate "C" ~
            U&'[^\0009-\000D\0020\0085\00A0\1680\2000-\200B\2028\2029\202F\205F\3000]'
        ),
    add constraint places_address_formatted_not_blank
        check (
            address_formatted collate "C" ~
            U&'[^\0009-\000D\0020\0085\00A0\1680\2000-\200B\2028\2029\202F\205F\3000]'
        ),
    add constraint places_address_country_code_format
        check (address_country_code collate "C" ~ '^[A-Z]{2}$');
