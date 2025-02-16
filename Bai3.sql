-- 2
create table deleted_orders(
delete_id int primary key auto_increment,
order_id int not null,
customer_name varchar(100) not null,
products varchar(100) not null,
order_date date not null,
delete_at datetime not null
);
-- 3
DELIMITER //
CREATE TRIGGER after_delete_order
AFTER DELETE ON orders
FOR EACH ROW
BEGIN
    INSERT INTO deleted_orders(order_id, customer_name, product, order_date, deleted_at)
    VALUES (OLD.order_id, OLD.customer_name, OLD.product, OLD.order_date, NOW());
END;
//DELIMITER ;

-- 4
SET SQL_SAFE_UPDATES = 0;
DELETE FROM orders WHERE order_id = 4;
DELETE FROM orders WHERE order_id = 5;

-- 5
SELECT * FROM deleted_orders;