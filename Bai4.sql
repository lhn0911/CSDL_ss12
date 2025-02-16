-- 2
CREATE TABLE order_warnings(
	warning_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    warning_message VARCHAR(255) NOT NULL
);

-- 3
DELIMITER //
CREATE TRIGGER after_insert_total
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
	SET @total = NEW.quantity * NEW.price;
    IF @total > 5000 THEN
		INSERT INTO order_warnings(order_id, warning_message)
		VALUES (NEW.order_id, 'Total value exceeds limit');
	END IF;
END;
// DELIMITER ;

-- 4
SET SQL_SAFE_UPDATES = 0;
INSERT INTO orders (customer_name, product, quantity, price, order_date) VALUES
('Mark', 'Monitor', 2, 3000.00, '2023-08-01'),
('Paul', 'Mouse', 1, 50.00, '2023-08-02');

-- 5
SELECT * FROM order_warnings;

DROP TRIGGER after_insert_total;