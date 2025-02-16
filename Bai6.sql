-- 2
CREATE TABLE budget_warnings(
	warning_id INT PRIMARY KEY AUTO_INCREMENT,
    project_id INT NOT NULL,
    warning_message VARCHAR(255) NOT NULL
);

-- 3
DELIMITER //
CREATE TRIGGER after_update_projects
AFTER UPDATE ON projects
FOR EACH ROW
BEGIN
    IF NEW.total_salary > NEW.budget AND 
       NOT EXISTS (SELECT 1 FROM budget_warnings WHERE project_id = NEW.project_id) THEN
        INSERT INTO budget_warnings (project_id, warning_message)
        VALUES (NEW.project_id, 'Budget exceeded due to high salary');
    END IF;
END;
// DELIMITER ;

-- 4
CREATE VIEW ProjectOverview AS
SELECT 
    p.project_id, 
    p.name, 
    p.budget, 
    p.total_salary, 
    bw.warning_message
FROM projects p
LEFT JOIN budget_warnings bw ON p.project_id = bw.project_id;

-- 5
INSERT INTO workers (name, project_id, salary) VALUES ('Michael', 1, 6000.00);
INSERT INTO workers (name, project_id, salary) VALUES ('Sarah', 2, 10000.00);
INSERT INTO workers (name, project_id, salary) VALUES ('David', 3, 1000.00);

-- 6
SELECT * FROM budget_warnings;
SELECT * FROM ProjectOverview;