-- COMP3311 20T3 Assignment 1
-- Calendar schema
-- Written by Daksh Mukhra - z5163002

-- Types/domains
--------------------------------------------------------------------------
create type AccessibilityType as enum ('read-write','read-only','none');
create type InviteStatus as enum ('invited','accepted','declined');
create type VisibilityType as enum ('public','private');
create type Day_Of_Week as enum ('monday','tuesday','wednesday','thursday','friday','saturday','sunday');
--------------------------------------------------------------------------

-- Tables

create table Users (
	id          	serial,
	email       	text not null unique,
	passwd 			text not null,
	is_admin    	boolean not null default false,
	name 			text not null,

	primary key (id)
);

create table Groups (
	id          	serial,
	name        	text not null, -- should be not null but no mention of it
	owner 			integer unique not null,

	foreign key (owner) references Users(id),
	primary key (id)

);
-- each user maintains a list of members , how do you add this ??
create table Members (
	user_id 		integer,
	group_id 		integer,

	foreign key (user_id) references Users(id),
	foreign key (group_id) references Groups(id),
	primary key (user_id,group_id)

);

-- if a user has read permission on a calendar, they see private event titles instead of "Busy"
-- users may subscribe to other peoples' calendars (if they can read them)
create table Calendars (
	id      		serial,
	colour   		text not null,
	name 			text not null,
	default_access 	AccessibilityType  not null -- whats the difference between this field and the table access ??
					default 'none',
	owner 			integer not null,

	foreign key (owner) references Users(id),
	primary key (id)

);

create table Accessibility (
	calendar_id 	integer,
	user_id 		integer,
	access 			AccessibilityType not null,

	foreign key (calendar_id) references Calendars(id),
	primary key (user_id,calendar_id),foreign key (user_id) references Users(id)

);

create table Subscribed (
	calendar_id 	integer,
	user_id 		integer,
	colour 			text,-- whats the difference between this field in the table Calendar ??

	foreign key (user_id) references Users(id),
	foreign key (calendar_id) references Calendars(id),
	primary key (user_id,calendar_id)

);

create table Events (
	id				serial,
	title			text not null,
	visibility 		VisibilityType not null, --a private event is shown simply as "Busy" in the interface
	location		text,
	start_time		time ,
	end_time		time,
	Part_of			integer not null,-- each event is attached to a specific calendar
	Created_By		integer not null,-- ttotal participation in accordance with diagram

	foreign key (Part_of) references Calendars(id),
	foreign key (Created_By) references Users(id),
	primary key (id)

);
-- from spec : multi-valued attributes typically have pluralised names,in the SQL schema these names should be written in singular form
create table Alarms (
	alarm       	interval, -- time interval e.g 15mins before
	Event_id    	integer not null,

	foreign key (Event_id) references Events(id),
	primary key (alarm,Event_id)
);

create table Invited (
	User_id       	integer not null,
	Event_id        integer not null,
	status 			InviteStatus not null
					default 'invited',

	foreign key (Event_id) references Events(id),
	foreign key (User_id) references Users(id),
	primary key (User_id,Event_id)

);

create table One_day_Events (
	date          date not null,
	Event_id        integer not null,

	foreign key (Event_id) references Events(id),
	primary key (Event_id)
);

create table Spanning_Events (
	start_date      date not null,
	end_date        date not null,
	Event_id        integer not null,

	foreign key (Event_id) references Events(id),
	primary key (Event_id)
);

create table Recurring_Events (
	n_times			integer ,
	Event_id        integer not null,
	start_date      date not null,
	end_date        date,

	foreign key (Event_id) references Events(id),
	primary key (Event_id)
);

create table Weekly_Events (
	day_of_week     Day_Of_Week not null,
	frequency		integer not null,
	Recurring_Event_id        integer not null,

	foreign key (Recurring_Event_id) references Recurring_Events(Event_id),
	primary key (Recurring_Event_id)
);

create table Monthly_By_Day_Events (
	day_of_week     Day_Of_Week not null,
	week_in_month	integer not null
    constraint       constraint_2
                     check (week_in_month BETWEEN 1 AND 5),
	Recurring_Event_id        integer not null,

	foreign key (Recurring_Event_id) references Recurring_Events(Event_id),
	primary key (Recurring_Event_id)
);

create table Monthly_By_Date_Events (
	date_in_month    integer not null
    constraint       constraint_1
                     check (date_in_month BETWEEN 1 AND 31),
	Recurring_Event_id        integer not null,

	foreign key (Recurring_Event_id) references Recurring_Events(Event_id),
	primary key (Recurring_Event_id)
);

create table Annual_Events (
	date         	 date not null, -- example had 'Feb 12'
	Recurring_Event_id        integer not null,

	foreign key (Recurring_Event_id) references Recurring_Events(Event_id),
	primary key (Recurring_Event_id)
);
