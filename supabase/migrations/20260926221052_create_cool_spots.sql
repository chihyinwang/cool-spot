create schema gis;

create extension postgis with schema gis;

create table public.cool_spots (
    id text primary key,
    name text not null,
    location gis.geography(Point, 4326) not null
);