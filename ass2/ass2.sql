-- COMP3311 20T3 Assignment 2

-- by Daksh Mukhra
-- z5163002


-- Q1: students who've studied many courses
create view Q1(unswid,name)
as
    select p.unswid, p.name  from people p join course_enrolments c on (p.id = c.student)
    group by p.name, p.unswid having count(p.name) > 65 order by p.unswid;
;


-- Q2: numbers of students, staff and both
create or replace view Q2_pt1(nstudents)
as
    select Count(*)
    from ((select s.id from Students s) except (select staff.id from Staff))
    as no_students;

create or replace view Q2_pt2(nstaff)
as
    select Count(*)
    from ((select staff.id from Staff) except (select s.id from Students s))
    as no_staff;

create or replace view Q2_pt3(nboth)
as
    select Count(*)
    from ((select staff.id from Staff) intersect (select s.id from Students s))
    as no_both;

create or replace view Q2(nstudents,nstaff,nboth)
as
    select * from Q2_pt1, Q2_pt2, Q2_pt3;


-- Q3: prolific Course Convenor(s)
create or replace view Q3_pt1(staff_id, count_courses)
as
    select staff, count(course) from course_staff cs
    join staff_roles sr on (cs.role = sr.id)
    where sr.name like 'Course Convenor'
    group by staff
    order by count desc;

create or replace view Q3_pt2(name, count_courses)
as
    select name, q.count_courses from people p
    join Q3_pt1 q on (p.id = staff_id);

create or replace view Q3(name,ncourses)
as
    select name, count_courses  as ncourses from Q3_pt2
    where count_courses = (select max(count_courses) from Q3_pt2);


-- Q4: Comp Sci students in 05s2 and 17s1 ------
-- view of student names and there id's
create or replace view Q4a_pt1(name, id)
as
    select name, s.id from people p
    join students s on ( p.id = s.id);

create or replace view Q4a_pt2(stu_id, term, prog_code, prog_name)
as
    select student, term, p.code, p.name
    from program_enrolments pe
    join programs p on (pe.program = p.id);

create or replace view Q4a_pt3(name, stu_id, term, prog_code, prog_name)
as
    select name, id, q2.term, q2.prog_code, q2.prog_name
    from Q4a_pt1 q1
    join Q4a_pt2 q2 on (q1.id = q2.stu_id)
    where prog_code = '3978';

create or replace view Q4a_pt4(id,name)
as
    select q.stu_id, q.name
    from Q4a_pt3 q
    join terms t on (q.term = t.id)
    where t.name = 'Sem2 2005'
    order by q.stu_id;

create or replace view Q4a(id,name)
as
    select p.unswid, q.name
    from people p
    join Q4a_pt4 q on ( p.id = q.id);

------ part b ------
create or replace view Q4b_pt1(name, id)
as
    select name, s.id from people p
    join students s on ( p.id = s.id);

create or replace view Q4b_pt2(stu_id, term, prog_code, prog_name)
as
    select student, term, p.code, p.name
    from program_enrolments pe
    join programs p on (pe.program = p.id);

create or replace view Q4b_pt3(name, stu_id, term, prog_code, prog_name)
as
    select name, id, q2.term, q2.prog_code, q2.prog_name
    from Q4b_pt1 q1
    join Q4b_pt2 q2 on (q1.id = q2.stu_id)
    where prog_code = '3778';

create or replace view Q4b_pt4(id,name)
as
    select q.stu_id, q.name
    from Q4b_pt3 q
    join terms t on (q.term = t.id)
    where t.name = '2017 S1'
    order by q.stu_id;

create or replace view Q4b(id,name)
as
    select p.unswid, q.name
    from people p
    join Q4b_pt4 q on ( p.id = q.id);


-- Q5: most "committee"d faculty
create or replace view Q5_pt1(fac_id, fac_name, fac_utype,  committee, facultyof_id)
as
    select Orgunits.id, Orgunits.name, utype, Orgunit_types.name, facultyof(Orgunits.id)
    from Orgunits
    inner join Orgunit_types on (Orgunits.utype = Orgunit_types.id)
    where Orgunit_types.name = 'Committee';

create or replace view Q5_pt2(count,fac_id)
as
    select count(fac_id), facultyof_id
    from Q5_pt1
    where facultyof_id <> 0
    group by facultyof_id
    order by count desc;

create or replace view Q5_pt3(fac_id)
as
    select fac_id
    from Q5_pt2
    where count = (select max(count) from Q5_pt2);

create or replace view Q5(name)
as
    select longname
    from Orgunits
    where id in (select * from Q5_pt3);


-- Q6: nameOf function
create or replace function
   Q6(id integer) returns text
as $$
    select name
    from people
    where id = $1 or unswid = $1;
$$ language sql;


-- Q7: offerings of a subject
create or replace function Q7(text)
    returns table ( code text, term text, name text)
as $$
    select cast(s.code as text), termname(courses.term) as term, p.name
    from courses
    join course_staff cs on ( courses.id = cs.course)
    join staff_roles sr on (cs.role = sr.id)
    join subjects s on (courses.subject = s.id)
    join people p on ( p.id = cs.staff)
    where sr.name = 'Course Convenor' and  s.code = $1;
$$ language sql;


-- Q8: transcript
create or replace function
   Q8(zid integer) returns setof TranscriptRecord
as $$
declare
    t_rec transcriptrecord;
    temp integer;
    wamvalue decimal = 0;
    UOC_pass integer= 0;
    total_UOC decimal= 0;
    w_sum_marks integer= 0;
begin
-- check if the id provided is a student id
    select s.id into temp
    from   Students s join People p on (s.id = p.id)
    where  p.unswid = $1;
            if (not found) then
                    raise EXCEPTION 'Invalid student %',_sid;
            end if;
-- loop through the tuples for a particular student and obtain the wam vairbles through calcs
    for t_rec in
        select cast(s.code as text), termname(c.term) as term,
        p.code as prog, substr(s.name,1,20) as name, ce.mark,
        ce.grade, s.uoc
        from people
        join course_enrolments ce on (people.id = ce.student)
        join courses c on (ce.course = c.id)
        join terms t on (c.term = t.id)
        join program_enrolments pe on (people.id = pe.student and pe.term = c.term)
        join programs p on (pe.program = p.id)
        join subjects s on (c.subject = s.id)
        where people.unswid = $1 order by  t.starting,code
    loop
    -- calcs
    -- Do not include in the WAM calculations any course that has a null grade.
    -- If a course has a null mark but has a SY or XE T or PE grade, include the UOC in the  -----> UOCpassed only <----. Round the WAM value to the nearest integer.
    if (t_rec.grade in ('SY','XE','T','PE')) then
        UOC_pass = t_rec.UOC + UOC_pass;
    elsif (t_rec.mark is not null) then
        -- total ouc passed
        if (t_rec.grade in ('PT', 'PC', 'PS', 'CR', 'DN', 'HD', 'A', 'B', 'C')) then
            UOC_pass = t_rec.UOC + UOC_pass;
        end if;
        -- fails count towards total UOC , unlike 'SY','XE','T','PE'
        total_UOC := total_UOC + t_rec.uoc;
        w_sum_marks := w_sum_marks + (t_rec.mark * t_rec.uoc);
        -- setting uoc to zero as speficied
        if (t_rec.grade not in ('PT','PC','PS','CR','DN','HD','A','B','C')) then
            t_rec.uoc := NULL;
        end if;
    end if;
    return next t_rec;
    end loop;
    -- calculate wam value ,
    -- retrun the final tuple
    if (total_UOC = 0) then
                    t_rec := (null,null,null,'No WAM available',null,null,null);
            else
                    wamvalue :=  w_sum_marks / total_UOC;
                    --raise EXCEPTION 'wam % w_sum_marks % total_UOC %',wamvalue,w_sum_marks,total_UOC;
                    t_rec := (null,null,null,'Overall WAM/UOC',round(wamvalue),null,UOC_pass);
            end if;
    return next t_rec;
end;
$$ language plpgsql;


-- Q9: members of academic object group
create or replace function
   Q9(gid integer) returns setof AcObjRecord
as $$
declare
    _rec AcObjRecord;
    _temp3 AcObjRecord;
    _patternArr text[];     --Array to store the patterns after splitting
    _substrArr text[];
    _childArr text[];
    _pattern text;          --Variable to hold a pattern in for each
    _substr text;
    _substr1 text;
    _info record;
    _temp record;

begin
    -- get info realted to  id
    select * into _info from acad_object_groups AOG where AOG.id = gid;
    -- put parent into array - put children into array loop through all the ids and conduct the process
    _childArr := array_append(_childArr, _info.id::text);
    for _temp3.objcode in
        select id
        from acad_object_groups
        where parent = _info.id
    loop
        _childArr := array_append(_childArr, _temp3.objcode);
        _temp3.objtype := _info.gtype;
    end loop;

    foreach _substr1 in array _childArr loop
        -- get info of each id present in the parent child array and conduct the whole process for each one
        select * into _info from acad_object_groups AOG where AOG.id = _substr1::integer;
        if (_info.gdefby = 'pattern') then
           select regexp_split_to_array(_info.definition,',') into _patternArr; --- could use regexp_split_to_table() instead of array handling
           foreach _pattern in array _patternArr
           loop
                -- base case
                if((_pattern ~ 'FREE') or (_pattern ~ 'F=') or (_pattern ~ 'GEN') ) then
                    continue;
                -- 2 cases either it has regex then we need to filter and use andother fucntion to check the tables or it doesnt have regex and we just just output directly
                elsif(_pattern !~ '[\;\#\{\}\|\[\]\(\)]' ) then
                    _rec.objtype := _info.gtype;
                    _rec.objcode := _pattern;
                    return next _rec;
                elsif(_pattern ~ '[;\#\{\}\|\[\]\(\)]' ) then
                    -- case sesnistive for the x otehrise X is part of the code itself
                    if (_pattern ~ '#|x') then
                        _pattern := regexp_replace(_pattern,'(#|x)','.','g');
                    end if;
                    if (_pattern ~ '\[.*\]') then
                        --- String concatenation on start and end with ^ and $
                        _pattern := '^'||_pattern||'$';
                    end if;
                    -- if circle brackets --> () <-- dont need to change
                    if (_pattern ~ '\{.*\}') then
                        _pattern := regexp_replace(_pattern,'[\{\}]','','g');
                        _pattern := regexp_replace(_pattern,';',',','g');
                    -- 1 - split array just like before select regexp_split_to_array(_info.definition,',') into _patternArr;
                    -- 2 - for loop through each entry insub array and call the xternal function -- assuming {xxx;yyy;zzz}  wont have xxx where this itself is another regex
                        select regexp_split_to_array(_pattern,',') into _substrArr;
                        foreach _substr in array _substrArr loop
                                -- can use dynamically generated query here
                                _rec.objtype := _info.gtype;
                                _rec.objcode := _substr;
                                return next _rec;
                        end loop;
                    end if;
                    -- now that we have filtered out everything
                        -- can use dynamically generated query here
                    if (_info.gtype ~ 'subject') then
                        for _rec.objcode in
                            select distinct s.code
                            from Subjects s
                            where s.code ~ _pattern
                            order by s.code
                        loop
                            _rec.objtype := _info.gtype;
                            return next _rec;
                        end loop;
                    end if;
                    if (_info.gtype ~ 'program') then
                        for _rec.objcode in
                            select distinct p.code
                            from Programs p
                            where p.code ~ _substr
                            order by p.code
                        loop
                            _rec.objtype := _info.gtype;
                            return next _rec;
                        end loop;
                    end if;
                end if;
            end loop;
        elsif (_info.gdefby = 'enumerated') then
        -- could use dynamically generated query --- didnt know how :(
            if (_info.gtype ~ 'subject') then
                for _rec.objcode in
                    select distinct s.code from acad_object_groups AOG
                    join subject_group_members SGM on (AOG.id = SGM.ao_group)
                    join subjects s on (SGM.subject = s.id)
                    where ao_group =_info.id
                loop
                    _rec.objtype := _info.gtype;
                    return next _rec;
                end loop;
            elsif (_info.gtype ~ 'program') then
                for _rec.objcode in
                    select distinct p.code from acad_object_groups AOG
                    join program_group_members PGM on (AOG.id = PGM.ao_group)
                    join programs p on (PGM.program = p.id)
                    where ao_group =_info.id
                loop
                    _rec.objtype := _info.gtype;
                    return next _rec;
                end loop;
            elsif (_info.gtype ~ 'stream') then
                for _rec.objcode in
                    select distinct s.code from acad_object_groups AOG
                    join stream_group_members SGM on (AOG.id = SGM.ao_group)
                    join streams s on (SGM.stream = s.id)
                    where ao_group =_info.id
                loop
                    _rec.objtype := _info.gtype;
                    return next _rec;
                end loop;
            end if;
        else
        -- dont need to handle queries
            continue;
        end if;
    end loop;
end;
$$ language plpgsql;


-- Q10: follow-on courses
create or replace function
   Q10(code text) returns setof text
as $$
declare
    _temp text;
    _substr text;
begin
-- not sure why i needed to use a dynamically generated query ...????
    _substr := 'select distinct s.code
    from subject_prereqs sp
    join rules r on (sp.rule = r.id)
    join Acad_object_groups aog on (r.ao_group = aog.id)
    join subjects s on (sp.subject = s.id)
    where aog.definition ~ ' || quote_literal(code);
    for _temp in
        execute _substr
    loop
        return next _temp;
    end loop;
end ;
$$ language plpgsql;


-------- Testing funcitons --------------
-----------------------------------------
create  or replace function
   Q9_test(code text) returns void
as $$
declare
    _temp record;
    _temp2 AcObjRecord;
    _temp3 text;
    _temp4 AcObjRecord;
    _subjectList text[];
    _substrArr text[];
    _childArr text[];
    _substr text;
    _subject text;
    _child text;
    _rec AcObjRecord;
begin
    _substr := 'select  s.code
    from subject_prereqs sp
    join rules r on (sp.rule = r.id)
    join Acad_object_groups aog on (r.ao_group = aog.id)
    join subjects s on (sp.subject = s.id)
    where aog.definition ~ ' || quote_literal(code);
         execute _substr;


end;
$$ language plpgsql;
-----------------------------------------
-----------------------------------------
