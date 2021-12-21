-- COMP3311 20T3 Assignment 1
-- Calendar schema
-- Written by Daksh Mukhra - z5163002

-- Types/domains
--------------------------------------------------------------------------
create type AccessibilityType as enum ('read-write','read-only','none');
create type InviteStatus as enum ('invited','accepted','declined');
create type VisibilityType as enum ('public','private');
create type InvitedType as enum ('Invited','Accepted','Declined');
create type Days_of_week as enum ('mon','tue','wed','thu','fri','sat','sun'); -- write as domian ??
create type Weeks_in_month as enum ('1','2','3','4','5'); -- write as domian ??
create domain Is_admin_b AS
	--default "N"
	char(1) CHECK (value in ('Y','N'));
create domain Days_of_month as int
   --default 1
   constraint constraint_1
      check (VALUE BETWEEN 1 AND 31); -- is this range inclusive or exclusive ??
--create type AdminStatus as enum ('yes','no');
--------------------------------------------------------------------------

-- Tables
-- go through and comment all relationships i.e. 1 2 1 , many 2 1 etc
-- each user maintains a list of members , how do you add this ??
create table Users (
	id          	serial, -- does serial need UNIQUE
	email       	text not null unique, -- coul potetniall define regex
	passwd 			text not null, -- create password type ?? or use the in built type ??
	is_admin 		Is_admin_b, 	-- binary data type? , maybe create and enum
	name 			text not null,	-- first name last name combined or sperate ?

	primary key (id)
);

create table Groups (
	id          	serial, -- does serial need UNIQUE
	name        	text not null,
	owner 			integer unique not null, -- see if you actually need unique

	foreign key (owner) references Users(id),
	primary key (id)

);
