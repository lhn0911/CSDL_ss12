-- 2
DELIMITER //
CREATE PROCEDURE GetDoctorDetails(IN input_doctor_id INT)
BEGIN
    SELECT 
        d.name AS doctor_name,
        d.specialization,
        COUNT(DISTINCT a.patient_id) AS total_patients,
        COUNT(a.appointment_id) AS total_appointments,
        SUM(d.salary) AS total_revenue,
        COUNT(p.prescription_id) AS total_medicines_prescribed
    FROM doctors d
    LEFT JOIN appointments a ON d.doctor_id = a.doctor_id
    LEFT JOIN prescriptions p ON a.appointment_id = p.appointment_id
    WHERE d.doctor_id = input_doctor_id
    GROUP BY d.doctor_id;
END;
// DELIMITER ;

-- 3
CREATE TABLE cancellation_logs (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    appointment_id INT,
    log_message VARCHAR(255),
    log_date DATETIME,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
);

-- 4
CREATE TABLE appointment_logs (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    appointment_id INT,
    log_message VARCHAR(255),
    log_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
);

-- 5
DELIMITER //
CREATE TRIGGER AfterDeleteAppointment
AFTER DELETE ON appointments
FOR EACH ROW
BEGIN
    -- Xóa tất cả đơn thuốc liên quan
    DELETE FROM prescriptions WHERE appointment_id = OLD.appointment_id;

    -- Ghi log nếu cuộc hẹn bị hủy
    IF OLD.status = 'Cancelled' THEN
        INSERT INTO cancellation_logs (appointment_id, log_message)
        VALUES (OLD.appointment_id, 'Cancelled appointment was deleted');
    END IF;

    -- Ghi log nếu cuộc hẹn đã hoàn thành
    IF OLD.status = 'Completed' THEN
        INSERT INTO appointment_logs (appointment_id, log_message)
        VALUES (OLD.appointment_id, 'Completed appointment was deleted');
    END IF;
END;
// DELIMITER ;

-- 6
CREATE VIEW FullRevenueReport AS
SELECT 
    d.doctor_id,
    d.name AS doctor_name,
    COUNT(a.appointment_id) AS total_appointments,
    COUNT(DISTINCT a.patient_id) AS total_patients,
    SUM(d.salary) AS total_revenue,
    COUNT(p.prescription_id) AS total_medicines
FROM doctors d
LEFT JOIN appointments a ON d.doctor_id = a.doctor_id
LEFT JOIN prescriptions p ON a.appointment_id = p.appointment_id
GROUP BY d.doctor_id;

-- 7
CALL GetDoctorDetails(1);

-- 8
-- Xóa cuộc hẹn với trạng thái "Cancelled"
DELETE FROM appointments WHERE appointment_id = 3;

-- Xóa cuộc hẹn với trạng thái "Completed"
DELETE FROM appointments WHERE appointment_id = 2;

-- 9
SELECT * FROM FullRevenueReport;