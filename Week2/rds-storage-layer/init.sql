CREATE DATABASE mydb;

USE mydb;

CREATE TABLE employees (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100),
  department VARCHAR(50)
);

INSERT INTO employees (name, department) VALUES
('Alice Johnson', 'HR'),
('Bob Smith', 'Engineering'),
('Charlie Rose', 'Marketing');

