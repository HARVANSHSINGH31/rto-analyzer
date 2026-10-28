DROP DATABASE IF EXISTS rto_db;
CREATE DATABASE rto_db;
USE rto_db;

CREATE TABLE couriers (
  courier_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE,
  service_type ENUM('STANDARD','EXPRESS') NOT NULL
);

CREATE TABLE customers (
  customer_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(80) NOT NULL,
  city VARCHAR(50) NOT NULL,
  pincode CHAR(6) NOT NULL,
  address_quality ENUM('GOOD','INCOMPLETE') NOT NULL
);

CREATE TABLE shipments (
  shipment_id INT AUTO_INCREMENT PRIMARY KEY,
  order_ref VARCHAR(20) NOT NULL UNIQUE,
  customer_id INT NOT NULL,
  courier_id INT NOT NULL,
  payment_mode ENUM('COD','PREPAID') NOT NULL,
  order_value DECIMAL(10,2) NOT NULL CHECK (order_value > 0),
  weight_kg DECIMAL(6,2) NOT NULL,
  status ENUM('CREATED','SHIPPED','OUT_FOR_DELIVERY','ATTEMPT_FAILED','DELIVERED','RTO')
         NOT NULL DEFAULT 'CREATED',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  FOREIGN KEY (courier_id) REFERENCES couriers(courier_id),
  INDEX idx_courier_status (courier_id, status)
);

CREATE TABLE delivery_attempts (
  attempt_id INT AUTO_INCREMENT PRIMARY KEY,
  shipment_id INT NOT NULL,
  attempt_no TINYINT NOT NULL,
  attempt_time DATETIME NOT NULL,
  time_slot ENUM('MORNING','AFTERNOON','EVENING') NOT NULL,
  outcome ENUM('DELIVERED','FAILED') NOT NULL,
  failure_reason ENUM('CUSTOMER_UNAVAILABLE','WRONG_ADDRESS','REFUSED','COD_NOT_READY') NULL,
  remarks JSON NULL,
  UNIQUE (shipment_id, attempt_no),
  FOREIGN KEY (shipment_id) REFERENCES shipments(shipment_id),
  INDEX idx_slot_outcome (time_slot, outcome)
);

CREATE TABLE rto_costs (
  shipment_id INT PRIMARY KEY,
  forward_cost DECIMAL(8,2) NOT NULL,
  return_cost DECIMAL(8,2) NOT NULL,
  lost_margin DECIMAL(8,2) NOT NULL,
  FOREIGN KEY (shipment_id) REFERENCES shipments(shipment_id)
);

CREATE TABLE status_audit (
  audit_id INT AUTO_INCREMENT PRIMARY KEY,
  shipment_id INT NOT NULL,
  old_status VARCHAR(20),
  new_status VARCHAR(20),
  changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE analysis_results (
  id INT AUTO_INCREMENT PRIMARY KEY,
  test_name VARCHAR(60) NOT NULL,
  dimension VARCHAR(60),
  statistic VARCHAR(40),
  value DOUBLE,
  run_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

DELIMITER $$
CREATE TRIGGER trg_status_audit
AFTER UPDATE ON shipments
FOR EACH ROW
BEGIN
  IF OLD.status <> NEW.status THEN
    INSERT INTO status_audit (shipment_id, old_status, new_status)
    VALUES (NEW.shipment_id, OLD.status, NEW.status);
  END IF;
END$$
DELIMITER ;