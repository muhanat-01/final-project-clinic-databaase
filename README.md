clinic-database-final-project
📖 Clinic Management System Database
📌 Overview
This project is a relational database design and implementation for a Clinic Management System, created as part of Week 8 Final Project – Question 1.

The database models a real-world healthcare clinic, supporting patients, doctors, departments, appointments, medical records, prescriptions, and medicines.

Deliverables:

clinic_system.sql – Database schema (tables + constraints + relationships)
clinic_system_data.sql – Sample seed data for testing queries
🎯 Objectives
Design a normalized relational database.
Demonstrate entity relationships:
One-to-One
One-to-Many
Many-to-Many
Implement constraints:
Primary Keys (PK)
Foreign Keys (FK)
NOT NULL, UNIQUE
Provide sample data to validate the design.
🗄️ Database Schema
Main Entities & Relationships
Departments – groups doctors by medical department
Doctors – medical professionals linked to a department
Specialties – doctors can have multiple specialties (M:N)
Patients – individuals receiving treatment
Appointments – scheduled visits between patients and doctors
Medical Records – notes/diagnoses linked to patients and doctors
Medicines – catalog of drugs
Prescriptions – issued during appointments
Prescription Items – links prescriptions to medicines (M:N)
Phones – patients and doctors can have multiple contact numbers
Allergies – records patient allergies
Audit Logs – tracks system actions
