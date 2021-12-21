-- COMP3311 20T3 Ass3 ... extra database definitions
-- # by Daksh Mukhra


-- again double join conditions came in clutch as you need the acting roles to be tied to the specific name and movie
create or replace view Q4_pt1(title,start_year, movie_id, ordering, name_id, name, birth_year, role_played)
as
    select m.title,m.start_year, p.movie_id, p.ordering, p.name_id, n.name, n.birth_year, ar.played as role_played
    from principals p
    join movies m on (p.movie_id = m.id)
    join names n on (n.id = p.name_id)
    join acting_roles ar on (p.movie_id = ar.movie_id and n.id = ar.name_id)

    order by m.start_year, m.title, p.ordering, ascii(ar.played) ;

create or replace view Q4_pt2(title,start_year, movie_id, ordering, name_id, name, birth_year, role_played)
as
    select m.title,m.start_year, p.movie_id, p.ordering, p.name_id, n.name, n.birth_year, cr.role as role_played
    from principals p
    join movies m on (p.movie_id = m.id)
    join names n on (n.id = p.name_id)
    join crew_roles cr on (p.movie_id = cr.movie_id and n.id = cr.name_id)

    order by m.start_year,m.title, p.ordering, ascii(cr.role);


create or replace view Q4_pt3 (title,start_year, movie_id, ordering, name_id, name,birth_year, role_played)
as
    select * from Q4_pt1
    union
    select * from Q4_pt2
;
