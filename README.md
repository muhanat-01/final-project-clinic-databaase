
# Clinic Management System Database

## 📖 Overview
This project is a **relational database management system** (RDBMS) for managing a clinic.  
It is designed using **MySQL** and includes tables for patients, doctors, appointments, and other essential clinic data.  
The database supports **CRUD operations**, ensuring efficient management of clinic information.

---

## 🗂️ Database Schema

### Tables
1. **Patients**
   - `patient_id` (PK)
   - `first_name`
   - `last_name`
   - `gender`
   - `date_of_birth`
   - `phone_number`

2. **Doctors**
   - `doctor_id` (PK)
   - `first_name`
   - `last_name`
   - `specialization`
   - `phone_number`

3. **Appointments**
   - `appointment_id` (PK)
   - `patient_id` (FK → Patients.patient_id)
   - `doctor_id` (FK → Doctors.doctor_id)
   - `appointment_date`
   - `status`

4. **Departments** (optional)
   - `department_id` (PK)
   - `department_name`

5. **Prescriptions** (optional)
   - `prescription_id` (PK)
   - `appointment_id` (FK → Appointments.appointment_id)
   - `medicine_name`
   - `dosage`
   - `instructions`

### Relationships
- **Patients ↔ Appointments**: One-to-Many (a patient can have multiple appointments).  
- **Doctors ↔ Appointments**: One-to-Many (a doctor can have multiple appointments).  
- **Departments ↔ Doctors**: One-to-Many (a department can have multiple doctors).

---

## 💾 SQL Files
1. `clinic_system.sql` – Contains `CREATE DATABASE` and all `CREATE TABLE` statements with constraints.  
2. `clinic_system_data.sql` – Contains sample seed data for testing the database.

---

## 🚀 Setup Instructions

1. **Clone the repository**:


