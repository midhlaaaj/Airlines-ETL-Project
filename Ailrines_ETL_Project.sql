-- Database setup
CREATE DATABASE IF NOT EXISTS airlines_project;
USE airlines_project;

-- Create raw table (CSV imported via Workbench)
CREATE TABLE airline_delay_cause (
    year INT,
    month INT,
    carrier VARCHAR(10),
    carrier_name VARCHAR(100),
    airport VARCHAR(10),
    airport_name VARCHAR(200),
    arr_flights FLOAT,
    arr_del15 FLOAT,
    carrier_ct FLOAT,
    weather_ct FLOAT,
    nas_ct FLOAT,
    security_ct FLOAT,
    late_aircraft_ct FLOAT,
    arr_cancelled FLOAT,
    arr_diverted FLOAT,
    arr_delay FLOAT,
    carrier_delay FLOAT,
    weather_delay FLOAT,
    nas_delay FLOAT,
    security_delay FLOAT,
    late_aircraft_delay FLOAT
);

-- Extract United Airlines records
CREATE TABLE ua_cause AS
SELECT *
FROM airline_delay_cause
WHERE carrier = 'UA';

SELECT COUNT(*) FROM ua_cause;

-- Remove unused columns
ALTER TABLE ua_cause
DROP COLUMN carrier,
DROP COLUMN carrier_name;

-- Rename columns
ALTER TABLE ua_cause
CHANGE COLUMN airport airport_code VARCHAR(10),
CHANGE COLUMN airport_name airport_name VARCHAR(200),
CHANGE COLUMN arr_flights total_flights FLOAT,
CHANGE COLUMN arr_del15 delayed_flights FLOAT,
CHANGE COLUMN carrier_ct carrier_delay_count FLOAT,
CHANGE COLUMN weather_ct weather_delay_count FLOAT,
CHANGE COLUMN nas_ct nas_delay_count FLOAT,
CHANGE COLUMN security_ct security_delay_count FLOAT,
CHANGE COLUMN late_aircraft_ct late_aircraft_delay_count FLOAT,
CHANGE COLUMN arr_cancelled cancelled_flights FLOAT,
CHANGE COLUMN arr_diverted diverted_flights FLOAT,
CHANGE COLUMN arr_delay total_delay_minutes FLOAT,
CHANGE COLUMN carrier_delay carrier_delay_minutes FLOAT,
CHANGE COLUMN weather_delay weather_delay_minutes FLOAT,
CHANGE COLUMN nas_delay nas_delay_minutes FLOAT,
CHANGE COLUMN security_delay security_delay_minutes FLOAT,
CHANGE COLUMN late_aircraft_delay late_aircraft_minutes FLOAT;

-- Clean values (trim + uppercase)
UPDATE ua_cause
SET airport_code = TRIM(UPPER(airport_code)),
    airport_name = TRIM(airport_name);

-- Feature engineering: On-Time %
ALTER TABLE ua_cause ADD COLUMN on_time_pct FLOAT;
UPDATE ua_cause
SET on_time_pct = ROUND(((total_flights - delayed_flights) / total_flights) * 100, 2)
WHERE total_flights > 0;

-- Delay rate
ALTER TABLE ua_cause ADD COLUMN delay_rate FLOAT;
UPDATE ua_cause
SET delay_rate = ROUND((delayed_flights / total_flights) * 100, 2)
WHERE total_flights > 0;

-- Cancellation rate
ALTER TABLE ua_cause ADD COLUMN cancellation_rate FLOAT;
UPDATE ua_cause
SET cancellation_rate = ROUND((cancelled_flights / total_flights) * 100, 2)
WHERE total_flights > 0;

-- Diversion rate
ALTER TABLE ua_cause ADD COLUMN diversion_rate FLOAT;
UPDATE ua_cause
SET diversion_rate = ROUND((diverted_flights / total_flights) * 100, 2)
WHERE total_flights > 0;

-- Primary delay reason
ALTER TABLE ua_cause ADD COLUMN delay_reason VARCHAR(50);
UPDATE ua_cause
SET delay_reason = CASE
    WHEN carrier_delay_minutes >= weather_delay_minutes
     AND carrier_delay_minutes >= nas_delay_minutes
     AND carrier_delay_minutes >= security_delay_minutes
     AND carrier_delay_minutes >= late_aircraft_minutes
        THEN 'Carrier'
    WHEN weather_delay_minutes >= carrier_delay_minutes
     AND weather_delay_minutes >= nas_delay_minutes
     AND weather_delay_minutes >= security_delay_minutes
     AND weather_delay_minutes >= late_aircraft_minutes
        THEN 'Weather'
    WHEN nas_delay_minutes >= carrier_delay_minutes
     AND nas_delay_minutes >= weather_delay_minutes
     AND nas_delay_minutes >= security_delay_minutes
     AND nas_delay_minutes >= late_aircraft_minutes
        THEN 'NAS'
    WHEN security_delay_minutes >= carrier_delay_minutes
     AND security_delay_minutes >= weather_delay_minutes
     AND security_delay_minutes >= nas_delay_minutes
     AND security_delay_minutes >= late_aircraft_minutes
        THEN 'Security'
    ELSE 'Late Aircraft'
END;
