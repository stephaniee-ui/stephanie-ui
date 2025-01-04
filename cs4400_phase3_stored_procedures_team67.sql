-- CS4400: Introduction to Database Systems (Fall 2024)
-- Project Phase III: Stored Procedures SHELL [v0] Monday, Oct 21, 2024
set global transaction isolation level serializable;
set global SQL_MODE = 'ANSI,TRADITIONAL';
set names utf8mb4;
set SQL_SAFE_UPDATES = 0;

use business_supply;
-- -----------------------------------------------------------------------------
-- stored procedures and views
-- -----------------------------------------------------------------------------
/* Standard Procedure: If one or more of the necessary conditions for a procedure to
be executed is false, then simply have the procedure halt execution without changing
the database state. Do NOT display any error messages, etc. */

-- [1] add_owner()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new owner.  A new owner must have a unique
username. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_owner;
delimiter //
create procedure add_owner (in ip_username varchar(40), in ip_first_name varchar(100),
	in ip_last_name varchar(100), in ip_address varchar(500), in ip_birthdate date)
sp_main: begin
    -- ensure new owner has a unique username in users
    if ip_username in (select username from users) or ip_username in (select username from business_owners) then leave sp_main; end if;
    insert into users values(ip_username, ip_first_name, ip_last_name, ip_address, ip_birthdate);
    insert into business_owners values(ip_username);
end //
delimiter ;

-- [2] add_employee()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new employee without any designated driver or
worker roles.  A new employee must have a unique username and a unique tax identifier. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_employee;
delimiter //
create procedure add_employee (in ip_username varchar(40), in ip_first_name varchar(100),
	in ip_last_name varchar(100), in ip_address varchar(500), in ip_birthdate date,
    in ip_taxID varchar(40), in ip_hired date, in ip_employee_experience integer,
    in ip_salary integer)
sp_main: begin
    -- ensure new owner has a unique username
    -- ensure new employee has a unique tax identifier
    if ip_username in (select username from users) then leave sp_main; end if;
    if ip_taxID in (select taxID from employees) then leave sp_main; end if;
    insert into users values(ip_username, ip_first_name, ip_last_name, ip_address, ip_birthdate);
    insert into employees values(ip_username, ip_taxID, ip_hired, ip_employee_experience, ip_salary);
end //
delimiter ;

-- [3] add_driver_role()
-- -----------------------------------------------------------------------------
/* This stored procedure adds the driver role to an existing employee.  The
employee/new driver must have a unique license identifier. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_driver_role;
delimiter //
create procedure add_driver_role (in ip_username varchar(40), in ip_licenseID varchar(40),
	in ip_license_type varchar(40), in ip_driver_experience integer)
sp_main: begin
    -- ensure employee exists and is not a worker 
    -- ensure new driver has a unique license identifier
    if ip_username not in (select username from employees) or ip_username in (select username from workers) then leave sp_main; end if;
    if ip_licenseID in (select licenseID from drivers) then leave sp_main; end if;
    insert into drivers values(ip_username, ip_licenseID, ip_license_type, ip_driver_experience);
end //
delimiter ;

-- [4] add_worker_role()
-- -----------------------------------------------------------------------------
/* This stored procedure adds the worker role to an existing employee. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_worker_role;
delimiter //
create procedure add_worker_role (in ip_username varchar(40))
sp_main: begin
    -- ensure employee exists and is not a driver
    -- doesnt need to ensure not in existing worker???
    if ip_username not in (select username from employees) or ip_username in (select username from drivers) 
     then leave sp_main; end if;
    insert into workers values(ip_username);
end //
delimiter ;

-- [5] add_product()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new product.  A new product must have a
unique barcode. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_product;
delimiter //
create procedure add_product (in ip_barcode varchar(40), in ip_name varchar(100),
	in ip_weight integer)
sp_main: begin
	-- ensure new product doesn't already exist
    if ip_barcode in (select barcode from products) then leave sp_main; end if;
    insert into products values(ip_barcode, ip_name, ip_weight);
end //
delimiter ;

-- [6] add_van()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new van.  A new van must be assigned 
to a valid delivery service and must have a unique tag.  Also, it must be driven
by a valid driver initially (i.e., driver works for the same service). And the van's starting
location will always be the delivery service's home base by default. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_van;
delimiter //
create procedure add_van (in ip_id varchar(40), in ip_tag integer, in ip_fuel integer,
	in ip_capacity integer, in ip_sales integer, in ip_driven_by varchar(40))
sp_main: begin
	declare location VARCHAR(40);
	-- ensure new van doesn't already exist
    -- ensure that the delivery service exists
    -- ensure that a valid driver will control the van
    if (select count(*) from vans where ip_id = id and tag = ip_tag ) > 0 then leave sp_main; end if;
    if ip_id not in (select id from delivery_services) then leave sp_main; end if;
    if ip_driven_by not in (select username from drivers) then leave sp_main; end if;
    -- Also, it must be driven by a valid driver initially (i.e., driver works for the same service)
    if ip_id!= (select id from vans where driven_by=ip_driven_by) then leave sp_main; end if;
    select home_base into location from delivery_services where id = ip_id;
	insert into vans values(ip_id, ip_tag, ip_fuel, ip_capacity, ip_sales, ip_driven_by, location);
end //
delimiter ;

-- [7] add_business()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new business.  A new business must have a
unique (long) name and must exist at a valid location, and have a valid rating.
And a resturant is initially "independent" (i.e., no owner), but will be assigned
an owner later for funding purposes. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_business;
delimiter //
create procedure add_business (in ip_long_name varchar(40), in ip_rating integer,
	in ip_spent integer, in ip_location varchar(40))
sp_main: begin
	-- ensure new business doesn't already exist
    -- ensure that the location is valid
    -- ensure that the rating is valid (i.e., between 1 and 5 inclusively)
    if ip_long_name in (select long_name from businesses) then leave sp_main; end if;
    if ip_location not in (select label from locations) then leave sp_main; end if;
    if ip_rating < 1 or ip_rating > 5 then leave sp_main; end if;
    insert into businesses values(ip_long_name, ip_rating, ip_spent, ip_location);
end //
delimiter ;

-- [8] add_service()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new delivery service.  A new service must have
a unique identifier, along with a valid home base and manager. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_service;
delimiter //
create procedure add_service (in ip_id varchar(40), in ip_long_name varchar(100),
	in ip_home_base varchar(40), in ip_manager varchar(40))
sp_main: begin
    if ip_id in (select id from delivery_services) then leave sp_main; end if;
    if ip_home_base not in (select label from locations) then leave sp_main; end if;
    if ip_manager not in (select username from workers) then leave sp_main; end if;
       insert into delivery_services values (ip_id, ip_long_name, ip_home_base, ip_manager);
	-- ensure new delivery service doesn't already exist
    -- ensure that the home base location is valid
    -- ensure that the manager is valid
end //
delimiter ;


-- [9] add_location()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new location that becomes a new valid van
destination.  A new location must have a unique combination of coordinates. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_location;
delimiter //
create procedure add_location (in ip_label varchar(40), in ip_x_coord integer,
	in ip_y_coord integer, in ip_space integer)
sp_main: begin 
    if ip_label in (select label from locations) then leave sp_main; end if;
    if (ip_x_coord, ip_y_coord) in (select x_coord, y_coord from locations) then leave sp_main; end if;
       insert into locations values (ip_label, ip_x_coord, ip_y_coord, ip_space);
	-- ensure new location doesn't already exist
    -- ensure that the coordinate combination is distinct
end //
delimiter ;
CALL add_location('elysium', 2, 10, 4);


-- [10] start_funding()
-- -----------------------------------------------------------------------------
/* This stored procedure opens a channel for a business owner to provide funds
to a business. The owner and business must be valid. */
-- -----------------------------------------------------------------------------
drop procedure if exists start_funding;
delimiter //
create procedure start_funding (in ip_owner varchar(40), in ip_amount integer, in ip_long_name varchar(40), in ip_fund_date date)
sp_main: begin
    if ip_owner not in (select username from business_owners) then leave sp_main; end if;
    if ip_long_name not in (select long_name from businesses) then leave sp_main; end if;
       insert into fund (username, invested, invested_date, business) 
       values (ip_owner, ip_amount, ip_fund_date, ip_long_name);
	-- ensure the owner and business are valid
end //
delimiter ;



-- [11] hire_employee()
-- -----------------------------------------------------------------------------
/* This stored procedure hires a worker to work for a delivery service.
If a worker is actively serving as manager for a different service, then they are
not eligible to be hired.  Otherwise, the hiring is permitted. */
-- -----------------------------------------------------------------------------
drop procedure if exists hire_employee;
delimiter //
create procedure hire_employee (in ip_username varchar(40), in ip_id varchar(40))
sp_main: begin
    if ip_username in (select username from work_for where id = ip_id) then leave sp_main; end if;    
    if ip_username not in (select username from workers) then leave sp_main; end if;
    if ip_id not in (select id from delivery_services) then leave sp_main; end if;
    if ip_username in (select manager from delivery_services where id != ip_id) then leave sp_main; end if;
       insert into work_for (username, id) values(ip_username, ip_id);
	-- ensure that the employee hasn't already been hired by that service  # check when id = ip_id, whether ip_username is in the result set
	-- ensure that the employee and delivery service are valid
    -- ensure that the employee isn't a manager for another service
end //
delimiter ;


-- [12] fire_employee()
-- -----------------------------------------------------------------------------
/* This stored procedure fires a worker who is currently working for a delivery
service.  The only restriction is that the employee must not be serving as a manager 
for the service. Otherwise, the firing is permitted. */
-- -----------------------------------------------------------------------------
drop procedure if exists fire_employee;
delimiter //
create procedure fire_employee (in ip_username varchar(40), in ip_id varchar(40))
sp_main: begin
    if ip_username not in (select username from work_for where id = ip_id) then leave sp_main; end if;
    if ip_username in (select manager from delivery_services) then leave sp_main; end if;
       delete from work_for where username = ip_username and id = ip_id;
	-- ensure that the employee is currently working for the service
    -- ensure that the employee isn't an active manager
end //
delimiter ;



-- [13] manage_service()
-- -----------------------------------------------------------------------------
/* This stored procedure appoints a worker who is currently hired by a delivery
service as the new manager for that service.  The only restrictions is that
the worker must not be working for any other delivery service. Otherwise, the appointment 
to manager is permitted.  The current manager is simply replaced. */
-- -----------------------------------------------------------------------------
drop procedure if exists manage_service;
delimiter //
create procedure manage_service (in ip_username varchar(40), in ip_id varchar(40))
sp_main: begin
    if not exists (select 1 from work_for where id = ip_id and username = ip_username) then leave sp_main; end if;
    if (select count(*) from work_for where username = ip_username) > 1 then leave sp_main; end if;
    update delivery_services set manager = ip_username where id = ip_id;   # 
	-- ensure that the employee is currently working for the service
    -- ensure that the employee isn't working for any other services
end //
delimiter ;
CALL manage_service('ckann5', 'lcc');


-- [14] takeover_van()
-- -----------------------------------------------------------------------------
/* This stored procedure allows a valid driver to take control of a van owned by 
the same delivery service. The current controller of the van is simply relieved 
of those duties. */
-- -----------------------------------------------------------------------------
drop procedure if exists takeover_van;
delimiter //
create procedure takeover_van (in ip_username varchar(40), in ip_id varchar(40),
	in ip_tag integer)
sp_main: begin
    if ip_username not in (select username from drivers) then leave sp_main; end if; 
    if exists (select 1 from vans where driven_by = ip_username and id != ip_id) then leave sp_main; end if; 
    update vans set driven_by = ip_username where id = ip_id and tag = ip_tag;
    
	-- ensure that the driver is not driving for another service
	-- ensure that the selected van is owned by the same service???
    -- ensure that the employee is a valid driver
end //
delimiter ;

-- [15] load_van()
-- -----------------------------------------------------------------------------
/* This stored procedure allows us to add some quantity of fixed-size packages of
a specific product to a van's payload so that we can sell them for some
specific price to other businesses.  The van can only be loaded if it's located
at its delivery service's home base, and the van must have enough capacity to
carry the increased number of items.

The change/delta quantity value must be positive, and must be added to the quantity
of the product already loaded onto the van as applicable.  And if the product
already exists on the van, then the existing price must not be changed. */
-- -----------------------------------------------------------------------------
drop procedure if exists load_van;
delimiter //
create procedure load_van (in ip_id varchar(40), in ip_tag integer, in ip_barcode varchar(40),
	in ip_more_packages integer, in ip_price integer)
sp_main: begin
    DECLARE total_capacity INTEGER;
    DECLARE current_load INTEGER DEFAULT 0;
    DECLARE new_total_load INTEGER;
	-- ensure that the van being loaded is owned by the service
	-- ensure that the van is located at the service home base
    if ip_id not in (select id from delivery_services) then leave sp_main; end if;
	SELECT ds.home_base INTO @home_base
	FROM delivery_services ds
	JOIN vans v ON ds.id = v.id
	WHERE v.id = ip_id AND v.tag = ip_tag;
	IF  @home_base != (SELECT located_at FROM vans WHERE id = ip_id AND tag = ip_tag) then leave sp_main; end if;

	-- ensure that the quantity of new packages is greater than zero
    IF ip_more_packages <= 0 then leave sp_main; end if;

	-- ensure that the van has sufficient capacity to carry the new packages
	SELECT capacity INTO total_capacity FROM vans WHERE id = ip_id AND tag = ip_tag;
	SELECT SUM(quantity) INTO current_load FROM contain WHERE id = ip_id AND tag = ip_tag;
	SET new_total_load = current_load + ip_more_packages;
	IF new_total_load > total_capacity then leave sp_main; end if;
    

   -- add more of the product to the van
   -- Ensure if the product already exists on the van, then the existing price must not be changed
   IF EXISTS (SELECT 1 FROM contain WHERE id = ip_id AND tag = ip_tag AND barcode = ip_barcode) THEN
    UPDATE contain SET quantity = quantity + ip_more_packages
    WHERE id = ip_id AND tag = ip_tag AND barcode = ip_barcode;
	ELSE
    INSERT INTO contain (id, tag, barcode, quantity, price)
    VALUES (ip_id, ip_tag, ip_barcode, ip_more_packages, ip_price);
	END IF;

end //
delimiter ;

-- [16] refuel_van()
-- -----------------------------------------------------------------------------
/* This stored procedure allows us to add more fuel to a van. The van can only
be refueled if it's located at the delivery service's home base. */
-- -----------------------------------------------------------------------------
drop procedure if exists refuel_van;
delimiter //
create procedure refuel_van (in ip_id varchar(40), in ip_tag integer, in ip_more_fuel integer)
sp_main: begin
	DECLARE home_base VARCHAR(40);
    DECLARE current_fuel INTEGER;
    if ip_id is null or ip_tag is null then leave sp_main; end if;
	-- ensure that the van being switched is valid and owned by the service
    IF NOT EXISTS (SELECT 1 FROM vans WHERE id = ip_id AND tag = ip_tag) then leave sp_main; end if;
        
    -- ensure that the van is located at the service home base
    SELECT home_base INTO home_base
    FROM delivery_services
    JOIN vans ON delivery_services.id = vans.id  
    WHERE vans.id = ip_id AND vans.tag = ip_tag;
	IF home_base != (SELECT located_at FROM vans WHERE id = ip_id AND tag = ip_tag) then leave sp_main; end if;

    -- Check the current fuel and add more fuel
    SELECT fuel INTO current_fuel FROM vans WHERE id = ip_id AND tag = ip_tag;
    UPDATE vans SET fuel = current_fuel + ip_more_fuel
    WHERE id = ip_id AND tag = ip_tag;

END //
delimiter ;

-- [17] drive_van()
-- -----------------------------------------------------------------------------
/* This stored procedure allows us to move a single van to a new
location (i.e., destination). This will also update the respective driver's 
experience and van's fuel. The main constraints on the van(s) being able to 
move to a new  location are fuel and space.  A van can only move to a destination
if it has enough fuel to reach the destination and still move from the destination
back to home base.  And a van can only move to a destination if there's enough
space remaining at the destination. */
-- -----------------------------------------------------------------------------
drop function if exists fuel_required;
delimiter //
create function fuel_required (ip_departure varchar(40), ip_arrival varchar(40))
	returns integer reads sql data
begin
	if (ip_departure = ip_arrival) then return 0;
    else return (select 1 + truncate(sqrt(power(arrival.x_coord - departure.x_coord, 2) + power(arrival.y_coord - departure.y_coord, 2)), 0) as fuel
		from (select x_coord, y_coord from locations where label = ip_departure) as departure,
        (select x_coord, y_coord from locations where label = ip_arrival) as arrival);
	end if;
end //
delimiter ;

drop procedure if exists drive_van;
delimiter //
create procedure drive_van (in ip_id varchar(40), in ip_tag integer, in ip_destination varchar(40))
sp_main: begin
	declare v_home_base varchar(40);
    declare v_fuel_needed integer;
    declare v_current_location varchar(40);
    declare v_current_fuel integer;
    declare v_driver_username varchar(40);

   if ip_id is null or ip_tag is null or ip_destination is null then leave sp_main; end if;
    -- ensure that the destination is a valid location
    if ip_destination not in (select label from locations) then leave sp_main; end if;

    -- Get the current location, fuel, and driver of the van
    select located_at, fuel, driven_by into v_current_location, v_current_fuel, v_driver_username
    from vans
    where id = ip_id and tag = ip_tag;

    -- ensure that the van isn't already at the location
    if ip_destination = v_current_location then leave sp_main; end if;

    -- ensure that the van has enough fuel to reach the destination and home base
    set v_home_base = (select home_base from delivery_services where id = ip_id);
    set v_fuel_needed = fuel_required(v_current_location, ip_destination) + fuel_required(ip_destination, v_home_base);
    if v_current_fuel < v_fuel_needed then leave sp_main; end if;

    -- ensure that the destination has enough space
    if (select space from locations where label = ip_destination) <= (select count(*) from vans where located_at = ip_destination) then leave sp_main; end if;

    -- update the van's location and fuel
    update vans
    set located_at = ip_destination,
        fuel = ifnull(v_current_fuel - fuel_required(v_current_location, ip_destination), 0)
    where id = ip_id and tag = ip_tag;

    -- update the driver's experience
    update drivers
    set successful_trips = successful_trips + 1
    where username = v_driver_username;
end //
delimiter ;



-- [18] purchase_product()
-- -----------------------------------------------------------------------------
/* This stored procedure allows a business to purchase products from a van
at its current location.  The van must have the desired quantity of the product
being purchased.  And the business must have enough money to purchase the
products.  If the transaction is otherwise valid, then the van and business
information must be changed appropriately.  Finally, we need to ensure that all
quantities in the payload table (post transaction) are greater than zero. */
-- -----------------------------------------------------------------------------
drop procedure if exists purchase_product;
delimiter //
create procedure purchase_product (in ip_long_name varchar(40), in ip_id varchar(40),
	in ip_tag integer, in ip_barcode varchar(40), in ip_quantity integer)
sp_main: begin
	declare v_location varchar(40);
    declare v_business_location varchar(40);
    declare v_price integer;
    declare v_current_quantity integer;
    declare v_current_spent integer;
    declare v_total_cost integer;

 -- Ensure that the business is valid
	if ip_long_name not in (select long_name from businesses) then leave sp_main;end if;
	select location, ifnull(spent, 0) into v_business_location, v_current_spent
	from businesses
	where long_name = ip_long_name;

    -- Ensure that the van is valid and exists at the business's location
	IF NOT EXISTS (SELECT 1 FROM vans WHERE id = ip_id AND tag = ip_tag) THEN LEAVE sp_main;END IF;
    select located_at into v_location
    from vans
    where id = ip_id and tag = ip_tag;
    if v_location <> v_business_location then leave sp_main; end if;
       

    -- Ensure that the van has enough of the requested product
    select quantity, price into v_current_quantity, v_price
    from contain
    where id = ip_id and tag = ip_tag and barcode = ip_barcode
    for update;
    if v_current_quantity < ip_quantity then leave sp_main; end if;

    -- Calculate total cost
    set v_total_cost = v_price * ip_quantity;

   -- Update business's spent money
	set v_current_spent = ifnull(v_current_spent, 0) + IFNULL(v_total_cost,0);
	update businesses
	set spent = IFNULL(v_current_spent,0)
	where long_name = ip_long_name;
    
    -- Update the van's payload
    update contain
    set quantity = greatest(quantity - ip_quantity, 0)
    where id = ip_id and tag = ip_tag and barcode = ip_barcode;
    
  -- ensure that all quantities in the payload table (post transaction) are greater than zero
	delete from contain where quantity <= 0 and id = ip_id and tag = ip_tag and barcode = ip_barcode;
    
    -- Update the monies spent and gained for the van 
    update vans
    set sales = ifnull(sales + v_total_cost,0)
    where id = ip_id and tag = ip_tag;
	

end //
delimiter ;

-- [19] remove_product()
-- -----------------------------------------------------------------------------
/* This stored procedure removes a product from the system.  The removal can
occur if, and only if, the product is not being carried by any vans. */
-- -----------------------------------------------------------------------------
drop procedure if exists remove_product;
delimiter //
create procedure remove_product (in ip_barcode varchar(40))
sp_main: begin
	declare v_product_count integer;

    -- Ensure that the product exists
    if not exists (select 1 from products where barcode = ip_barcode) then leave sp_main; end if;

    -- Ensure that the product is not being carried by any vans
    select count(*) into v_product_count
    from contain
    where barcode = ip_barcode;
    if v_product_count > 0 then leave sp_main; end if;
      
    -- Remove the product from the system
    delete from products
    where barcode = ip_barcode;
end //
delimiter ;

-- [20] remove_van()
-- -----------------------------------------------------------------------------
/* This stored procedure removes a van from the system.  The removal can
occur if, and only if, the van is not carrying any products.*/
-- -----------------------------------------------------------------------------
drop procedure if exists remove_van;
delimiter //
create procedure remove_van (in ip_id varchar(40), in ip_tag integer)
sp_main: begin
	declare v_product_count integer;

    -- Ensure that the van exists
    if not exists (select 1 from vans where id = ip_id and tag = ip_tag) then leave sp_main; end if;

    -- Ensure that the van is not carrying any products
    select count(*) into v_product_count
    from contain
    where id = ip_id and tag = ip_tag;
    if v_product_count > 0 then leave sp_main; end if;

    -- Remove the van from the system
    delete from vans
    where id = ip_id and tag = ip_tag;
end //
delimiter ;

-- [21] remove_driver_role()
-- -----------------------------------------------------------------------------
/* This stored procedure removes a driver from the system.  The removal can
occur if, and only if, the driver is not controlling any vans.  
The driver's information must be completely removed from the system. */
-- -----------------------------------------------------------------------------
drop procedure if exists remove_driver_role;
delimiter //
create procedure remove_driver_role (in ip_username varchar(40))
sp_main: begin
	declare v_van_count integer;

    -- Ensure that the driver exists
    if not exists (select 1 from drivers where username = ip_username) then leave sp_main; end if;

    -- Ensure that the driver is not controlling any vans
    select count(*) into v_van_count
    from vans
    where driven_by = ip_username;
    if v_van_count > 0 then leave sp_main; end if;
        

    -- Remove the driver from the system
    delete from drivers where username = ip_username;
    delete from employees where username = ip_username;
    delete from users where username = ip_username;
end //
delimiter ;

-- [22] display_owner_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of an owner.
For each owner, it includes the owner's information, along with the number of
businesses for which they provide funds and the number of different places where
those businesses are located.  It also includes the highest and lowest ratings
for each of those businesses, as well as the total amount of debt based on the
monies spent purchasing products by all of those businesses. And if an owner
doesn't fund any businesses then display zeros for the highs, lows and debt. */
-- -----------------------------------------------------------------------------
create or replace view display_owner_view as
select o.username, u.first_name, u.last_name, u.address, num_businesses, num_places, highs, lows, debt
	from business_owners o inner join users u on u.username = o.username
    inner join
    (select f.username, count(f.business) as num_businesses, count(b.location) as num_places, max(b.rating) as highs, min(b.rating) as lows, sum(b.spent) as debt
		from fund f inner join businesses b on b.long_name = f.business
		group by f.username
	union
	select distinct o.username, 0 as num_businesses, 0 as num_places, 0 as highs, 0 as lows, 0 as invested
		from business_owners o
		where not exists (
		select 1 
		from fund f
		where f.username = o.username)
    ) as sub on sub.username = u.username;

-- [23] display_employee_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of an employee.
For each employee, it includes the username, tax identifier, hiring date and
experience level, along with the license identifer and drivering experience (if
applicable), and a 'yes' or 'no' depending on the manager status of the employee. */
-- -----------------------------------------------------------------------------
create or replace view display_employee_view as
select e.username, e.taxID, e.salary, e.hired, e.experience as employee_experience, coalesce(d.licenseID, 'n/a'),
	coalesce(d.successful_trips, 'n/a') as driving_experience, (case when ds.manager is null then 'no' else 'yes' end) as manager_status
	from employees e left join drivers d on d.username = e.username
    left join delivery_services ds on ds.manager = e.username;

-- [24] display_driver_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of a driver.
For each driver, it includes the username, licenseID and drivering experience, along
with the number of vans that they are controlling. */
-- -----------------------------------------------------------------------------
create or replace view display_driver_view as
select d.username, d.licenseID, d.successful_trips, count(v.driven_by) as num_vans
	from drivers d
	left join vans v on v.driven_by = d.username
    group by d.username, d.licenseID, d.successful_trips;

-- [25] display_location_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of a location.
For each location, it includes the label, x- and y- coordinates, along with the
name of the business or service at that location, the number of vans as well as 
the identifiers of the vans at the location (sorted by the tag), and both the 
total and remaining capacity at the location. */
-- -----------------------------------------------------------------------------
create or replace view display_location_view as
select l.label, sub1.long_name, l.x_coord, l.y_coord, l.space, sub2.num_vans, sub2.van_ids, (l.space - sub2.num_vans) as remaining_capacity
	from locations l
	inner join (
    select location, long_name from businesses union
	select home_base as location, long_name from delivery_services) as sub1 on sub1.location = l.label
    inner join (
    select located_at, count(tag) as num_vans, GROUP_CONCAT(DISTINCT CONCAT(id, tag) ORDER BY id, tag SEPARATOR ', ') AS van_ids
    from vans group by located_at) as sub2 on sub2.located_at = l.label;

-- [26] display_product_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of the products.
For each product that is being carried by at least one van, it includes a list of
the various locations where it can be purchased, along with the total number of packages
that can be purchased and the lowest and highest prices at which the product is being
sold at that location. */
-- -----------------------------------------------------------------------------
create or replace view display_product_view as
select p.iname as product_name, sub1.location, sub1.amount_available, sub2.low_price, sub2.high_price from products p
	inner join (
    select c.barcode, v.located_at as location, c.quantity as amount_available, c.price as low_price
    from vans v inner join contain c on v.id = c.id and v.tag = c.tag) as sub1 on sub1.barcode = p.barcode
    inner join (
    select c.barcode, v.located_at as location, min(c.price) as low_price, max(c.price) as high_price from vans v
	inner join contain c on v.id = c.id and v.tag = c.tag
    group by c.barcode, v.located_at) as sub2 on sub2.barcode = sub1.barcode and sub2.location = sub1.location
    order by p.iname;

-- [27] display_service_view()
-- -----------------------------------------------------------------------------
/* This view displays information in the system from the perspective of a delivery
service.  It includes the identifier, name, home base location and manager for the
service, along with the total sales from the vans.  It must also include the number
of unique products along with the total cost and weight of those products being
carried by the vans. */
-- -----------------------------------------------------------------------------
create or replace view display_service_view as
select ds.id, ds.long_name, ds.home_base, ds.manager, sum(v.sales) as revenue, 
	sub.products_carried, sub.cost_carried, sub.weight_carried
	from delivery_services ds
	left join vans v on v.id = ds.id
    inner join
    (select c.id, count(distinct c.barcode) as products_carried, sum(distinct c.quantity * c.price) as cost_carried, 
	sum(p.weight*c.quantity) as weight_carried
    from contain c inner join products p on p.barcode = c.barcode
    group by c.id) as sub on v.id = sub.id
    group by ds.id, ds.long_name, ds.home_base, ds.manager;