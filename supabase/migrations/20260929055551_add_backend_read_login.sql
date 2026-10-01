create role cool_spots_api
    login
    nosuperuser
    nocreatedb
    nocreaterole
    noreplication
    nobypassrls;

grant cool_spots_reader to cool_spots_api
    with inherit true, set false;