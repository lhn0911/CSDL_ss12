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

CREATE TABLE dept_warnings (
    id INT PRIMARY KEY AUTO_INCREMENT,
    dept_id INT NOT NULL,
    warning_message VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

-- 2
DELIMITER //
CREATE TRIGGER before_insert_employee
BEFORE INSERT ON employees
FOR EACH ROW
BEGIN
    IF NEW.salary < 500 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lương nhân viên không được dưới 500';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM departments WHERE dept_id = NEW.dept_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Phòng ban không tồn tại';
    END IF;
    IF (SELECT COUNT(*) FROM projects p
        JOIN employees e ON p.emp_id = e.emp_id
        WHERE e.dept_id = NEW.dept_id AND p.status != 'Completed') = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Tất cả dự án trong phòng ban đã hoàn thành, không thể thêm nhân viên mới';
    END IF;
END;
// DELIMITER ;

-- 3
DELIMITER //
CREATE TRIGGER after_update_project_status
AFTER UPDATE ON projects
FOR EACH ROW
BEGIN
    IF NEW.status = 'Delayed' THEN
        INSERT INTO project_warnings (project_id, warning_message)
        VALUES (NEW.project_id, 'Dự án bị trì hoãn');
    END IF;
    IF NEW.status = 'Completed' THEN
        UPDATE projects 
        SET end_date = NOW() 
        WHERE project_id = NEW.project_id;
        SET @total_salary = (
            SELECT SUM(salary) 
            FROM employees 
            WHERE dept_id = (SELECT dept_id FROM employees WHERE emp_id = NEW.emp_id)
        );
        SET @dept_budget = (
            SELECT budget 
            FROM departments 
            WHERE dept_id = (SELECT dept_id FROM employees WHERE emp_id = NEW.emp_id)
        );
        IF @total_salary > @dept_budget THEN
            INSERT INTO dept_warnings (dept_id, warning_message)
            VALUES (
                (SELECT dept_id FROM employees WHERE emp_id = NEW.emp_id), 
                'Tổng lương nhân viên vượt ngân sách của phòng ban'
            );
        END IF;
    END IF;
END;
// DELIMITER ;

-- 4
CREATE VIEW FullOverview AS
SELECT 
    e.emp_id, 
    e.name AS employee_name, 
    d.name AS department_name, 
    p.name AS project_name, 
    p.status, 
    CONCAT('$', FORMAT(e.salary, 2)) AS salary,
    (SELECT warning_message FROM dept_warnings WHERE dept_id = e.dept_id ORDER BY created_at DESC LIMIT 1) AS warning_message
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
LEFT JOIN projects p ON e.emp_id = p.emp_id;

-- 5
INSERT INTO employees (name, dept_id, salary, hire_date)
VALUES ('Alice', 1, 400, '2023-07-01'); 
INSERT INTO employees (name, dept_id, salary, hire_date)
VALUES ('Bob', 999, 1000, '2023-07-01'); 
INSERT INTO employees (name, dept_id, salary, hire_date)
VALUES ('Charlie', 2, 1500, '2023-07-01');
INSERT INTO employees (name, dept_id, salary, hire_date)
VALUES ('David', 1, 2000, '2023-07-01');

-- 6
UPDATE projects SET status = 'Delayed' WHERE project_id = 1;
UPDATE projects SET status = 'Completed', end_date = NULL WHERE project_id = 2;
UPDATE projects SET status = 'Completed' WHERE project_id = 3;
UPDATE projects SET status = 'In Progress' WHERE project_id = 4;

-- 7
SELECT * FROM FullOverview;