CREATE TABLE departments(
	dept_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    manager VARCHAR(100) NOT NULL,
    budget DECIMAL(10, 2) NOT NULL
);

CREATE TABLE employees(
	emp_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    dept_id INT,
    salary DECIMAL(10, 2) NOT NULL,
    hire_date DATE NOT NULL,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

CREATE TABLE projects(
	project_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    emp_id INT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(50) NOT NULL,
	FOREIGN KEY (emp_id) REFERENCES employees(emp_id)
);

-- 2
CREATE TABLE salary_history(
	history_id INT PRIMARY KEY AUTO_INCREMENT,
    emp_id INT NOT NULL,
    old_salary DECIMAL(10, 2) NOT NULL,
    new_salary DECIMAL(10, 2) NOT NULL,
    change_date DATETIME NOT NULL,
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id)
);

-- 3
CREATE TABLE salary_warnings(
	warning_id INT PRIMARY KEY AUTO_INCREMENT,
    emp_id INT NOT NULL,
    warning_message VARCHAR(255) NOT NULL,
    warning_date DATETIME NOT NULL,
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id)
);

-- 4
DELIMITER //
CREATE TRIGGER after_salary_update
AFTER UPDATE ON employees
FOR EACH ROW
BEGIN
    IF OLD.salary <> NEW.salary THEN
        INSERT INTO salary_history (emp_id, old_salary, new_salary, change_date)
        VALUES (OLD.emp_id, OLD.salary, NEW.salary, NOW());
        IF NEW.salary < OLD.salary * 0.7 THEN
            INSERT INTO salary_warnings (emp_id, warning_message, warning_date)
            VALUES (NEW.emp_id, 'Salary decreased by more than 30%', NOW());
        END IF;
        IF NEW.salary > OLD.salary * 1.5 THEN
            UPDATE employees
            SET salary = OLD.salary * 1.5
            WHERE emp_id = NEW.emp_id;

            INSERT INTO salary_warnings (emp_id, warning_message, warning_date)
            VALUES (NEW.emp_id, 'Salary increased above allowed threshold (adjusted to 150% of previous salary)', NOW());
        END IF;
    END IF;
END;
// DELIMITER ;

-- 5
DELIMITER //
CREATE TRIGGER after_project_insert
AFTER INSERT ON projects
FOR EACH ROW
BEGIN
    DECLARE project_count INT;
    SELECT COUNT(*) INTO project_count FROM projects 
    WHERE emp_id = NEW.emp_id AND status = 'In Progress';
    IF project_count > 3 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Employee cannot be assigned to more than 3 active projects';
    END IF;
    IF NEW.start_date > CURDATE() AND NEW.status = 'In Progress' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Project cannot be In Progress if start date is in the future';
    END IF;
END;
// DELIMITER ;

-- 6
CREATE VIEW PerformanceOverview AS
SELECT 
    p.project_id,
    p.name AS project_name,
    COUNT(e.emp_id) AS employee_count,
    DATEDIFF(p.end_date, p.start_date) AS total_days,
    p.status
FROM projects p
LEFT JOIN employees e ON p.emp_id = e.emp_id
GROUP BY p.project_id, p.name, p.start_date, p.end_date, p.status;

-- 7
-- trường hợp 1
UPDATE employees SET salary = salary * 0.5 WHERE emp_id = 1;

-- trường hợp 2
UPDATE employees SET salary = salary * 2 WHERE emp_id = 2;

-- 8
-- trường hợp 1
INSERT INTO projects (name, emp_id, start_date, end_date, status) 
VALUES ('New Project 1', 1, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 30 DAY), 'In Progress');
INSERT INTO projects (name, emp_id, start_date, end_date, status) 
VALUES ('New Project 2', 1, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 30 DAY), 'In Progress');
INSERT INTO projects (name, emp_id, start_date, end_date, status) 
VALUES ('New Project 3', 1, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 30 DAY), 'In Progress');
INSERT INTO projects (name, emp_id, start_date, end_date, status) 
VALUES ('New Project 4', 1, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 30 DAY), 'In Progress');

-- trường hợp 2
INSERT INTO projects (name, emp_id, start_date, end_date, status) 
VALUES ('Future Project', 2, DATE_ADD(CURDATE(), INTERVAL 5 DAY), DATE_ADD(CURDATE(), INTERVAL 35 DAY), 'In Progress');