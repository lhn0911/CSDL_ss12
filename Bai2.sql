-- 2
create table price_changes(
change_id int primary key auto_increment,
product varchar(100) not null,
old_price decimal(10,2) not null,
new_price decimal(10,2) not null
);
-- 3
DELIMITER //
CREATE TRIGGER after_update_price_changes
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
    INSERT INTO price_changes(product, old_price, new_price)
    VALUES (OLD.product, OLD.price, NEW.price);
END;
// DELIMITER ;
-- 4
update orders set price= 1400.00 where product = 'Laptop';
update orders set price= 800.00 where product = 'Smartphone';
-- 5
select * from price_changes;
