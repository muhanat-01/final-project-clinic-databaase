/***************************************************************
 Clinic Booking / Clinic Management System - Schema (MySQL)
 Save this as: clinic_system.sql
 Run: mysql -u root -p < clinic_system.sql   (or execute in Workbench)
***************************************************************/

-- 1) create database and use it
CREATE DATABASE IF NOT EXISTS clinic_system
  DEFAULT CHARACTER SET = 'utf8mb4'
  DEFAULT COLLATE = 'utf8mb4_unicode_ci';
USE clinic_system;

-- Ensure InnoDB for FK support
SET SESSION sql_mode = 'STRICT_ALL_TABLES';

-- 2) departments (e.g., Cardiology, Pediatrics)
CREATE TABLE IF NOT EXISTS departments (
  department_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 3) specialties (e.g., Pediatrics, Orthopedics) for many-to-many with doctors
CREATE TABLE IF NOT EXISTS specialties (
  specialty_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 4) doctors
CREATE TABLE IF NOT EXISTS doctors (
  doctor_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(80) NOT NULL,
  last_name VARCHAR(80) NOT NULL,
  email VARCHAR(150) UNIQUE,
  license_number VARCHAR(50) UNIQUE,
  department_id INT, -- FK to departments
  hire_date DATE,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_doctor_department
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 5) many-to-many: doctors <-> specialties
CREATE TABLE IF NOT EXISTS doctor_specialties (
  doctor_id INT NOT NULL,
  specialty_id INT NOT NULL,
  PRIMARY KEY (doctor_id, specialty_id),
  assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ds_doctor FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_ds_specialty FOREIGN KEY (specialty_id) REFERENCES specialties(specialty_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 6) patients
CREATE TABLE IF NOT EXISTS patients (
  patient_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(80) NOT NULL,
  last_name VARCHAR(80) NOT NULL,
  dob DATE,
  gender ENUM('Male','Female','Other') DEFAULT 'Other',
  email VARCHAR(150) UNIQUE,
  national_id VARCHAR(50) UNIQUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 7) patient_phones (support multiple phone numbers per patient)
CREATE TABLE IF NOT EXISTS patient_phones (
  phone_id INT AUTO_INCREMENT PRIMARY KEY,
  patient_id INT NOT NULL,
  phone_number VARCHAR(30) NOT NULL,
  phone_type ENUM('Mobile','Home','Work','Other') DEFAULT 'Mobile',
  is_primary TINYINT(1) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_pp_patient FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  UNIQUE (patient_id, phone_number)
) ENGINE=InnoDB;

-- 8) doctor_phones
CREATE TABLE IF NOT EXISTS doctor_phones (
  phone_id INT AUTO_INCREMENT PRIMARY KEY,
  doctor_id INT NOT NULL,
  phone_number VARCHAR(30) NOT NULL,
  phone_type ENUM('Mobile','Office','Home','Other') DEFAULT 'Office',
  is_primary TINYINT(1) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_dp_doctor FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  UNIQUE (doctor_id, phone_number)
) ENGINE=InnoDB;

-- 9) appointments
-- Important constraints:
--  - an appointment is linked to a patient and typically to a doctor
--  - prevent double-booking per doctor at an identical datetime using UNIQUE(doctor_id, appointment_datetime)
CREATE TABLE IF NOT EXISTS appointments (
  appointment_id INT AUTO_INCREMENT PRIMARY KEY,
  patient_id INT NOT NULL,
  doctor_id INT, -- allow NULL if appointment not yet assigned
  appointment_datetime DATETIME NOT NULL,
  duration_minutes INT NOT NULL DEFAULT 30,
  status ENUM('Scheduled','Completed','Cancelled','No-Show') NOT NULL DEFAULT 'Scheduled',
  reason VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_appt_patient FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_appt_doctor FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  -- Prevent double booking a doctor for the exact same datetime
  UNIQUE KEY ux_doctor_datetime (doctor_id, appointment_datetime)
) ENGINE=InnoDB;

-- 10) medical_records (notes, diagnoses, attachments reference)
CREATE TABLE IF NOT EXISTS medical_records (
  record_id INT AUTO_INCREMENT PRIMARY KEY,
  patient_id INT NOT NULL,
  recorded_by INT, -- doctor_id who recorded (nullable if recorded by admin)
  record_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  title VARCHAR(150),
  notes TEXT,
  CONSTRAINT fk_record_patient FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_record_doctor FOREIGN KEY (recorded_by) REFERENCES doctors(doctor_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 11) medicines (catalog)
CREATE TABLE IF NOT EXISTS medicines (
  medicine_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  brand VARCHAR(100),
  form VARCHAR(50), -- tablet, syrup, injection...
  description TEXT,
  UNIQUE (name, brand),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 12) prescriptions (issued for an appointment)
CREATE TABLE IF NOT EXISTS prescriptions (
  prescription_id INT AUTO_INCREMENT PRIMARY KEY,
  appointment_id INT UNIQUE, -- one prescription per appointment (optional design choice)
  prescribed_by INT NOT NULL, -- doctor_id
  notes TEXT,
  issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_presc_appointment FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_presc_doctor FOREIGN KEY (prescribed_by) REFERENCES doctors(doctor_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 13) prescription_items (many-to-many: prescription <-> medicine) with dosage and quantity
CREATE TABLE IF NOT EXISTS prescription_items (
  prescription_id INT NOT NULL,
  medicine_id INT NOT NULL,
  dosage VARCHAR(80) NOT NULL, -- e.g., "500 mg", "1 tablet twice daily"
  quantity INT NOT NULL DEFAULT 1,
  instructions TEXT,
  PRIMARY KEY (prescription_id, medicine_id),
  CONSTRAINT fk_pi_presc FOREIGN KEY (prescription_id) REFERENCES prescriptions(prescription_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_pi_medicine FOREIGN KEY (medicine_id) REFERENCES medicines(medicine_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 14) patient_allergies (simple list per patient)
CREATE TABLE IF NOT EXISTS patient_allergies (
  patient_id INT NOT NULL,
  allergy VARCHAR(150) NOT NULL,
  severity ENUM('Mild','Moderate','Severe') DEFAULT 'Moderate',
  noted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (patient_id, allergy),
  CONSTRAINT fk_pa_patient FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 15) audit_logs - basic audit trail for important actions (optional but useful)
CREATE TABLE IF NOT EXISTS audit_logs (
  log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  entity VARCHAR(100) NOT NULL,
  entity_id VARCHAR(100),
  action VARCHAR(50) NOT NULL,
  performed_by VARCHAR(150),
  details JSON,
  performed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 16) Example helper view (optional): upcoming appointments
DROP VIEW IF EXISTS vw_upcoming_appointments;
CREATE VIEW vw_upcoming_appointments AS
SELECT
  a.appointment_id,
  a.appointment_datetime,
  a.duration_minutes,
  a.status,
  p.patient_id,
  CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
  d.doctor_id,
  CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
  dep.department_id,
  dep.name AS department_name
FROM appointments a
  JOIN patients p ON a.patient_id = p.patient_id
  LEFT JOIN doctors d ON a.doctor_id = d.doctor_id
  LEFT JOIN departments dep ON d.department_id = dep.department_id
WHERE a.appointment_datetime >= NOW();

-- 17) Useful indexes for performance (non-unique)
CREATE INDEX idx_patient_lastname ON patients(last_name);
CREATE INDEX idx_doctor_lastname ON doctors(last_name);
CREATE INDEX idx_appointments_datetime ON appointments(appointment_datetime);
CREATE INDEX idx_records_patient_date ON medical_records(patient_id, record_date);

-- End of schema


-- data insertion to all 
/***************************************************************
 Clinic Booking / Clinic Management System - Sample Data
***************************************************************/

-- Switch to our DB
USE clinic_system;

-- 1) Departments
INSERT INTO departments (name, description) VALUES
  ('Cardiology', 'Heart and cardiovascular treatments'),
  ('Pediatrics', 'Child healthcare'),
  ('Orthopedics', 'Bones and muscles'),
  ('Dermatology', 'Skin care and treatments');

-- 2) Specialties
INSERT INTO specialties (name, description) VALUES
  ('Pediatrician', 'Specialist for children'),
  ('Orthopedic Surgeon', 'Specialist for bones and muscles'),
  ('Cardiologist', 'Specialist for heart diseases'),
  ('Dermatologist', 'Specialist for skin care');

-- 3) Doctors
INSERT INTO doctors (first_name, last_name, email, license_number, department_id, hire_date)
VALUES
  ('Alice', 'Smith', 'alice.smith@clinic.com', 'LIC1001', 1, '2020-01-15'),
  ('John', 'Doe', 'john.doe@clinic.com', 'LIC1002', 2, '2019-06-10'),
  ('Mary', 'Johnson', 'mary.johnson@clinic.com', 'LIC1003', 3, '2021-03-20');

-- 4) Doctor Specialties (M:N)
INSERT INTO doctor_specialties (doctor_id, specialty_id) VALUES
  (1, 3), -- Alice -> Cardiologist
  (2, 1), -- John -> Pediatrician
  (3, 2); -- Mary -> Orthopedic Surgeon

-- 5) Patients
INSERT INTO patients (first_name, last_name, dob, gender, email, national_id)
VALUES
  ('James', 'Brown', '1990-04-12', 'Male', 'james.brown@mail.com', 'ID9001'),
  ('Emma', 'Wilson', '2010-07-25', 'Female', 'emma.wilson@mail.com', 'ID9002'),
  ('Liam', 'Davis', '1985-11-02', 'Male', 'liam.davis@mail.com', 'ID9003');

-- 6) Patient Phones
INSERT INTO patient_phones (patient_id, phone_number, phone_type, is_primary) VALUES
  (1, '0700001111', 'Mobile', 1),
  (2, '0700002222', 'Mobile', 1),
  (3, '0700003333', 'Home', 1);

-- 7) Doctor Phones
INSERT INTO doctor_phones (doctor_id, phone_number, phone_type, is_primary) VALUES
  (1, '0711001111', 'Office', 1),
  (2, '0711002222', 'Mobile', 1),
  (3, '0711003333', 'Office', 1);

-- 8) Appointments
INSERT INTO appointments (patient_id, doctor_id, appointment_datetime, duration_minutes, status, reason)
VALUES
  (1, 1, '2025-09-20 09:00:00', 30, 'Scheduled', 'Routine checkup'),
  (2, 2, '2025-09-20 10:00:00', 30, 'Scheduled', 'Child fever'),
  (3, 3, '2025-09-21 14:00:00', 45, 'Scheduled', 'Knee pain');

-- 9) Medical Records
INSERT INTO medical_records (patient_id, recorded_by, record_date, title, notes)
VALUES
  (1, 1, '2025-09-01 10:30:00', 'General Checkup', 'Blood pressure slightly high.'),
  (2, 2, '2025-09-05 11:00:00', 'Fever Consultation', 'Prescribed paracetamol.'),
  (3, 3, '2025-09-07 15:00:00', 'Orthopedic Exam', 'Recommended X-ray for knee.');

-- 10) Medicines
INSERT INTO medicines (name, brand, form, description)
VALUES
  ('Paracetamol', 'MediPharma', 'Tablet', 'Pain reliever and fever reducer'),
  ('Ibuprofen', 'HealWell', 'Tablet', 'Anti-inflammatory and pain relief'),
  ('Amoxicillin', 'PharmaLife', 'Capsule', 'Antibiotic for infections');

-- 11) Prescriptions
INSERT INTO prescriptions (appointment_id, prescribed_by, notes)
VALUES
  (1, 1, 'Monitor BP, no medicine yet'),
  (2, 2, 'For fever management'),
  (3, 3, 'Pain relief for knee');

-- 12) Prescription Items
INSERT INTO prescription_items (prescription_id, medicine_id, dosage, quantity, instructions)
VALUES
  (2, 1, '500 mg', 10, 'Take 1 tablet every 6 hours'),
  (3, 2, '400 mg', 15, 'Take 1 tablet twice daily');

-- 13) Patient Allergies
INSERT INTO patient_allergies (patient_id, allergy, severity) VALUES
  (1, 'Penicillin', 'Severe'),
  (2, 'Dust', 'Mild'),
  (3, 'Peanuts', 'Moderate');

-- 14) Audit Logs (example entries)
INSERT INTO audit_logs (entity, entity_id, action, performed_by, details)
VALUES
  ('Patient', '1', 'INSERT', 'System', JSON_OBJECT('note','New patient added')),
  ('Appointment', '1', 'INSERT', 'System', JSON_OBJECT('note','New appointment created'));
