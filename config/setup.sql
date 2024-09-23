
--/*
DROP SCHEMA IF EXISTS asana_v2 CASCADE;
DROP SCHEMA IF EXISTS mailchimp CASCADE;
DROP SCHEMA IF EXISTS pd CASCADE;
DROP SCHEMA IF EXISTS zendesk_v2 CASCADE;
CREATE SCHEMA IF NOT EXISTS asana_v2;
CREATE SCHEMA IF NOT EXISTS bidtracer;
CREATE SCHEMA IF NOT EXISTS cradlepoint;
CREATE SCHEMA IF NOT EXISTS mailchimp;
CREATE SCHEMA IF NOT EXISTS payroll;
CREATE SCHEMA IF NOT EXISTS pd;
CREATE SCHEMA IF NOT EXISTS quickbooks;
CREATE SCHEMA IF NOT EXISTS timestar;
CREATE SCHEMA IF NOT EXISTS verizon;
CREATE SCHEMA IF NOT EXISTS zendesk_v2;
GRANT CONNECT ON DATABASE powerbi TO stitch;
GRANT ALL PRIVILEGES ON SCHEMA asana_v2 TO stitch;
GRANT ALL PRIVILEGES ON SCHEMA mailchimp TO stitch;
GRANT ALL PRIVILEGES ON SCHEMA pd TO stitch;
GRANT ALL PRIVILEGES ON SCHEMA zendesk_v2 TO stitch;
CREATE OR REPLACE FUNCTION format_asana_projects_current_status() RETURNS TRIGGER AS $$
  BEGIN
    IF NEW.current_status IS NOT NULL AND try_json_cast(NEW.current_status) IS NULL THEN
      NEW.current_status :=
        REGEXP_REPLACE(
          REGEXP_REPLACE(
            REGEXP_REPLACE(
              REGEXP_REPLACE(
                REGEXP_REPLACE(
                  REGEXP_REPLACE(
                    NEW.current_status,
                    '(?<=''[a-zA-Z_]+'' *: *''[^'']*?)"',
                    '',
                    'g'
                  ),
                  '(?<=''[a-zA-Z_]+'' *: *"[^"]*?)''',
                  '',
                  'g'
                ),
                '''([a-zA-Z_]+)'' *:',
                '"\1":',
                'g'
              ),
              '("[a-zA-Z_]+") *: *''([^'']*)''',
              '\1: "\2"',
              'g'
            ),
            '("[a-zA-Z_]+" *: * )None',
            '\1null',
            'g'
          ),
          '\\(?![bfnrt])',
          '\\\\',
          'g'
        );
    END IF;
    RETURN NEW;
  END;
$$ LANGUAGE plpgsql;
GRANT EXECUTE ON FUNCTION format_asana_projects_current_status() TO stitch;
--*/

--/*
-- bidtracer.alloc
DROP TABLE IF EXISTS bidtracer.alloc CASCADE;
CREATE TABLE bidtracer.alloc (
  "bid_id" TEXT,
  "bid_title" TEXT,
  "cost_code" TEXT,
  "cost_description" TEXT,
  "hours" NUMERIC,
  "amount" MONEY,
  "last_processed" TIMESTAMPTZ
);
CREATE OR REPLACE FUNCTION clean_bidtracer_alloc() RETURNS TRIGGER AS $$
  BEGIN
    UPDATE bidtracer.alloc
    SET "last_processed" = CURRENT_TIMESTAMP
    WHERE "last_processed" IS NULL;
    WITH "duplicates" AS (
      SELECT "row_id" FROM (
        SELECT
          ctid AS "row_id",
          row_number() OVER (PARTITION BY bid_id, cost_code, cost_description ORDER BY last_processed DESC) AS "rank"
        FROM bidtracer.alloc
      ) "t" WHERE "t"."rank" > 1
    )
    DELETE FROM bidtracer.alloc "alloc"
    WHERE EXISTS (SELECT 1 FROM "duplicates" WHERE "duplicates"."row_id" = "alloc".ctid LIMIT 1);
    RETURN NULL;
  END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE TRIGGER trigger_clean_bidtracer_alloc
AFTER INSERT ON bidtracer.alloc
FOR EACH STATEMENT EXECUTE FUNCTION clean_bidtracer_alloc();
-- bidtracer.margin
DROP TABLE IF EXISTS bidtracer.margin CASCADE;
CREATE TABLE bidtracer.margin (
  "bid_id" TEXT,
  "margin" NUMERIC,
  "contract" MONEY,
  "cost" MONEY,
  "last_processed" TIMESTAMPTZ
);
CREATE INDEX bidtracer_margin_bid_id ON bidtracer.margin ("bid_id" ASC);
CREATE INDEX bidtracer_margin_last_processed ON bidtracer.margin ("last_processed" DESC);
CREATE OR REPLACE FUNCTION clean_bidtracer_margin() RETURNS TRIGGER AS $$
  BEGIN
    UPDATE bidtracer.margin
    SET "last_processed" = CURRENT_TIMESTAMP
    WHERE "last_processed" IS NULL;
    WITH "duplicates" AS (
      SELECT "row_id" FROM (
        SELECT
          ctid AS "row_id",
          row_number() OVER (PARTITION BY bid_id ORDER BY last_processed DESC) AS "rank"
        FROM bidtracer.margin
      ) "t" WHERE "t"."rank" > 1
    )
    DELETE FROM bidtracer.margin "margin"
    WHERE EXISTS (SELECT 1 FROM "duplicates" WHERE "duplicates"."row_id" = "margin".ctid LIMIT 1);
    RETURN NULL;
  END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE TRIGGER trigger_clean_bidtracer_margin
AFTER INSERT ON bidtracer.margin
FOR EACH STATEMENT EXECUTE FUNCTION clean_bidtracer_margin();
-- bidtracer.materials
DROP TABLE IF EXISTS bidtracer.materials CASCADE;
CREATE TABLE bidtracer.materials (
  "bid_id" TEXT,
  "name" TEXT,
  "part" TEXT,
  "description" TEXT,
  "list_price" MONEY,
  "cost" MONEY,
  "quantity" NUMERIC,
  "total_cost" MONEY,
  "manufacturer" TEXT,
  "cost_code" TEXT,
  "ordering" NUMERIC
);
CREATE INDEX bidtracer_materials_bid_id ON bidtracer.materials ("bid_id" ASC);
CREATE INDEX bidtracer_materials_part ON bidtracer.materials ("part" ASC);
--*/

/*
-- cradlepoint.routers
DROP TABLE IF EXISTS cradlepoint.routers CASCADE;
CREATE TABLE cradlepoint.routers (
  "config_status" TEXT,
  "created_at" TIMESTAMPTZ,
  "description" TEXT,
  "device_type" TEXT,
  "full_product_name" TEXT,
  "id" INTEGER,
  "ipv4_address" TEXT,
  "locality" TEXT,
  "mac" TEXT,
  "name" TEXT,
  "reboot_required" BOOLEAN,
  "serial_number" TEXT,
  "state" TEXT,
  "state_updated_at" TIMESTAMPTZ,
  "updated_at" TIMESTAMPTZ,
  "upgrade_pending" BOOLEAN
);
CREATE INDEX cradlepoint_routers_id ON cradlepoint.routers ("id" ASC);
-- cradlepoint.net_devices
DROP TABLE IF EXISTS cradlepoint.net_devices CASCADE;
CREATE TABLE cradlepoint.net_devices (
  "apn" TEXT,
  "bsid" TEXT,
  "carrier" TEXT,
  "carrier_id" TEXT,
  "channel" INTEGER,
  "connection_state" TEXT,
  "dns0" TEXT,
  "dns1" TEXT,
  "esn" TEXT,
  "gateway" TEXT,
  "gsn" TEXT,
  "homecarrid" TEXT,
  "hostname" TEXT,
  "iccid" TEXT,
  "id" INTEGER,
  "imei" TEXT,
  "imsi" TEXT,
  "ipv4_address" TEXT,
  "ipv6_address" TEXT,
  "is_asset" BOOLEAN,
  "is_gps_supported" BOOLEAN,
  "is_upgrade_supported" BOOLEAN,
  "ltebandwidth" TEXT,
  "mac" TEXT,
  "manufacturer" TEXT,
  "mdn" TEXT,
  "meid" TEXT,
  "mfg_model" TEXT,
  "mfg_product" TEXT,
  "mn_ha_spi" TEXT,
  "mn_ha_ss" TEXT,
  "mode" TEXT,
  "model" TEXT,
  "modem_fw" TEXT,
  "mtu" INTEGER,
  "nai" TEXT,
  "name" TEXT,
  "netmask" TEXT,
  "pin_status" TEXT,
  "port" TEXT,
  "prlv" TEXT,
  "profile" TEXT,
  "rfband" TEXT,
  "rfband5g" TEXT,
  "rfchannel" TEXT,
  "roam" TEXT,
  "router" TEXT,
  "rxchannel" TEXT,
  "serial" TEXT,
  "service_type" TEXT,
  "ssid" TEXT,
  "summary" TEXT,
  "txchannel" TEXT,
  "type" TEXT,
  "uid" TEXT,
  "updated_at" TIMESTAMPTZ,
  "uptime" DOUBLE PRECISION,
  "ver_pkg" TEXT,
  "version" TEXT,
  "wimax_realm" TEXT,
  "router_id" INTEGER
);
CREATE INDEX cradlepoint_net_devices_id ON cradlepoint.net_devices ("id" ASC);
CREATE INDEX cradlepoint_net_devices_router_id ON cradlepoint.net_devices ("router_id" ASC);
-- cradlepoint.net_device_usage_samples
DROP TABLE IF EXISTS cradlepoint.net_device_usage_samples CASCADE;
CREATE TABLE cradlepoint.net_device_usage_samples (
  "bytes_in" BIGINT,
  "bytes_out" BIGINT,
  "created_at" TIMESTAMPTZ,
  "net_device" TEXT,
  "period" DOUBLE PRECISION,
  "uptime" DOUBLE PRECISION,
  "net_device_id" INTEGER
);
CREATE INDEX cradlepoint_net_device_usage_samples_created_at ON cradlepoint.net_device_usage_samples ("created_at" DESC);
CREATE INDEX cradlepoint_net_device_usage_samples_id ON cradlepoint.net_device_usage_samples ("net_device_id" ASC);
-- cradlepoint.net_device_signal_samples
DROP TABLE IF EXISTS cradlepoint.net_device_signal_samples CASCADE;
CREATE TABLE cradlepoint.net_device_signal_samples (
  "cinr" DOUBLE PRECISION,
  "created_at" TIMESTAMPTZ,
  "dbm" INTEGER,
  "ecio" INTEGER,
  "net_device" TEXT,
  "rsrp" DOUBLE PRECISION,
  "rsrp5g" DOUBLE PRECISION,
  "rsrp5g_highband" DOUBLE PRECISION,
  "rsrq" DOUBLE PRECISION,
  "rsrq5g" DOUBLE PRECISION,
  "rsrq5g_highband" DOUBLE PRECISION,
  "rssi" INTEGER,
  "rssnr" INTEGER,
  "signal_percent" INTEGER,
  "sinr" DOUBLE PRECISION,
  "sinr5g" DOUBLE PRECISION,
  "sinr5g_highband" DOUBLE PRECISION,
  "uptime" DOUBLE PRECISION,
  "net_device_id" INTEGER
);
CREATE INDEX cradlepoint_net_device_signal_samples_created_at ON cradlepoint.net_device_signal_samples ("created_at" DESC);
CREATE INDEX cradlepoint_net_device_signal_samples_id ON cradlepoint.net_device_signal_samples ("net_device_id" ASC);
--*/

/*
-- NOT CURRENTLY USED
-- cradlepoint.net_device_health
DROP TABLE IF EXISTS cradlepoint.net_device_health CASCADE;
CREATE TABLE cradlepoint.net_device_health (
  "cellular_health_category" TEXT,
  "cellular_health_score" INTEGER,
  "id" INTEGER,
  "net_device" TEXT,
  "date" DATE DEFAULT CURRENT_DATE
);
CREATE INDEX cradlepoint_net_device_health_id ON cradlepoint.net_device_health ("id" ASC);
CREATE INDEX cradlepoint_net_device_health_date ON cradlepoint.net_device_health ("date" DESC);
--*/

--/*
-- payroll.benefits
DROP TABLE IF EXISTS payroll.benefits CASCADE;
CREATE TABLE payroll.benefits (
  "pay_date" DATE,
  "employee_id" TEXT,
  "employee_name" TEXT,
  "plan_id" TEXT,
  "plan_description" TEXT,
  "amount_billed" MONEY,
  "employee_contribution" MONEY,
  "net_amount_billed" MONEY,
  "last_modified" TIMESTAMPTZ
);
CREATE INDEX payroll_benefits_pay_date ON payroll.benefits ("pay_date" DESC);
-- payroll.compensation
DROP TABLE IF EXISTS payroll.compensation CASCADE;
CREATE TABLE payroll.compensation (
    "payroll_number" TEXT,
    "employee_id" TEXT,
    "employee_name" TEXT,
    "charge_date" DATE,
    "location" TEXT,
    "position" TEXT,
    "pay_code" TEXT,
    "pay_description" TEXT,
    "shift" TEXT,
    "hours_units_paid" DOUBLE PRECISION,
    "hourly_rate" MONEY,
    "hours_worked" DOUBLE PRECISION,
    "pay_amount" MONEY,
    "last_modified" TIMESTAMPTZ,
    "allocation" BOOLEAN
);
CREATE INDEX payroll_compensation_charge_date ON payroll.compensation ("charge_date" DESC);
--*/

--/*
-- quickbooks.change_orders
DROP TABLE IF EXISTS quickbooks.change_orders CASCADE;
CREATE TABLE quickbooks.change_orders (
  "id" TEXT,
  "change_orders" MONEY,
  "date" DATE
);
CREATE INDEX quickbooks_change_orders_id ON quickbooks.change_orders ("id" ASC);
CREATE INDEX quickbooks_change_orders_date ON quickbooks.change_orders ("date" DESC);
-- quickbooks.jobs
DROP TABLE IF EXISTS quickbooks.jobs CASCADE;
CREATE TABLE quickbooks.jobs (
  "link_for_job_id" TEXT,
  "id" TEXT,
  "active" BOOLEAN,
  "name" TEXT,
  "end_user" TEXT,
  "vertical" TEXT,
  "project_manager" TEXT,
  "salesperson" TEXT,
  "type" TEXT,
  "proposal_price" MONEY,
  "change_orders" MONEY,
  "contract_price" MONEY,
  "billed_to_date" MONEY,
  "previous_invoices" MONEY,
  "time_created" TIMESTAMPTZ,
  "time_modified" TIMESTAMPTZ,
  "start_date" DATE,
  "end_date" DATE,
  "projected_end_date" DATE
);
CREATE INDEX quickbooks_jobs_id ON quickbooks.jobs ("id" ASC);
--*/

--/*
-- timestar.accruals
DROP TABLE IF EXISTS timestar.accruals CASCADE;
CREATE TABLE timestar.accruals (
  "employee_number" TEXT,
  "employee_name" TEXT,
  "category" TEXT,
  "hours" DOUBLE PRECISION
);
CREATE INDEX timestar_accruals_employee_number ON timestar.accruals ("employee_number" ASC);
-- timestar.pto_requests
DROP TABLE IF EXISTS timestar.pto_requests CASCADE;
CREATE TABLE timestar.pto_requests (
  "created_at" TIMESTAMPTZ,
  "employee_number" TEXT,
  "employee_name" TEXT,
  "category" TEXT,
  "date" DATE,
  "hours" DOUBLE PRECISION,
  "status" TEXT,
  "approved_by" TEXT,
  "approved_at" TIMESTAMPTZ,
  "comments" TEXT
);
CREATE INDEX timestar_pto_requests_date ON timestar.pto_requests ("date" DESC);
CREATE INDEX timestar_pto_requests_employee_number ON timestar.pto_requests ("employee_number" ASC);
-- timestar.timesheets_processed
DROP TABLE IF EXISTS timestar.timesheets_processed CASCADE;
CREATE TABLE timestar.timesheets_processed (
  "employee_number" TEXT,
  "employee_name" TEXT,
  "date" DATE,
  "hours" REAL,
  "pay_type" TEXT,
  "regular_flag" BOOLEAN,
  "overtime_flag" BOOLEAN,
  "work_category" TEXT,
  "job" TEXT,
  "notes" TEXT,
  "last_modified" DATE
);
CREATE OR REPLACE FUNCTION timestar_set_last_modified() RETURNS TRIGGER AS $$
  BEGIN
    NEW.last_modified := NOW();
    RETURN NEW;
  END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE TRIGGER timestar_set_last_modified
BEFORE INSERT OR UPDATE ON timestar.timesheets_processed
FOR EACH ROW EXECUTE FUNCTION timestar_set_last_modified();
CREATE INDEX timestar_timesheets_processed_date ON timestar.timesheets_processed ("date" DESC);
CREATE INDEX timestar_timesheets_processed_employee_number ON timestar.timesheets_processed ("employee_number" ASC);
--*/

--/*
-- verzion.incidents
DROP TABLE IF EXISTS verizon.incidents CASCADE;
CREATE TABLE verizon.incidents (
  "vehicle" TEXT,
  "driver" TEXT,
  "datetime" TIMESTAMP,
  "event" TEXT,
  "location" TEXT,
  "initial_speed" SMALLINT,
  "duration" DOUBLE PRECISION,
  "severity" TEXT,
  "last_modified" TIMESTAMP
);
CREATE OR REPLACE FUNCTION clean_verizon_incidents() RETURNS TRIGGER AS $$
  DECLARE
    d TIMESTAMP;
  BEGIN
    SELECT MIN("datetime") INTO d
    FROM verizon.incidents
    WHERE "last_modified" IS NULL;
    DELETE FROM verizon.incidents
    WHERE "last_modified" IS NOT NULL
    AND "datetime">=d;
    UPDATE verizon.incidents
    SET "last_modified" = LOCALTIMESTAMP
    WHERE "last_modified" IS NULL;
    RETURN NULL;
  END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE TRIGGER trigger_clean_verizon_incidents
AFTER INSERT ON verizon.incidents
FOR EACH STATEMENT EXECUTE FUNCTION clean_verizon_incidents();
CREATE INDEX verizon_incidents_datetime ON verizon.incidents ("datetime" DESC);
-- verzion.movements
DROP TABLE IF EXISTS verizon.movements CASCADE;
CREATE TABLE verizon.movements (
  "vehicle_number" TEXT,
  "vehicle_name" TEXT,
  "registration_number" TEXT,
  "driver_number" TEXT,
  "driver_name" TEXT,
  "employee_id" TEXT,
  "datetime" TIMESTAMP,
  "timezone_offset" SMALLINT,
  "timezone" TEXT,
  "status" TEXT,
  "latitude" DOUBLE PRECISION,
  "longitude" DOUBLE PRECISION,
  "address" TEXT,
  "city" TEXT,
  "state" TEXT,
  "postal_code" TEXT,
  "speed" SMALLINT,
  "speed_limit" SMALLINT,
  "heading" TEXT,
  "odometer" DOUBLE PRECISION,
  "delta_time_text" TEXT,
  "delta_time_seconds" INTEGER,
  "delta_distance" DOUBLE PRECISION,
  "accumulated_time_text" TEXT,
  "accumulated_time_seconds" INTEGER,
  "accumulated_distance" DOUBLE PRECISION,
  "place_id" TEXT,
  "place_name" TEXT,
  "ignition" TEXT,
  "daily_accumulated_distance" DOUBLE PRECISION,
  "esn" TEXT,
  "is_asset" BOOLEAN,
  "fuel_type" TEXT,
  "last_modified" TIMESTAMP
);
CREATE OR REPLACE FUNCTION clean_verizon_movements() RETURNS TRIGGER AS $$
  DECLARE
    d TIMESTAMP;
  BEGIN
    SELECT MIN("datetime") INTO d
    FROM verizon.movements
    WHERE "last_modified" IS NULL;
    DELETE FROM verizon.movements
    WHERE "last_modified" IS NOT NULL
    AND "datetime">=d;
    UPDATE verizon.movements
    SET "last_modified" = LOCALTIMESTAMP
    WHERE "last_modified" IS NULL;
    RETURN NULL;
  END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE TRIGGER trigger_clean_verizon_movements
AFTER INSERT ON verizon.movements
FOR EACH STATEMENT EXECUTE FUNCTION clean_verizon_movements();
CREATE INDEX verizon_movements_ordering1 ON verizon.movements ("datetime" DESC);
CREATE INDEX verizon_movements_ordering2 ON verizon.movements ("driver_number" ASC);
CREATE INDEX verizon_movements_ordering3 ON verizon.movements ("driver_number" ASC, "datetime" DESC);
-- verizon.services
DROP TABLE IF EXISTS verizon.services CASCADE;
CREATE TABLE verizon.services (
  "service_name" TEXT,
  "vehicle_name" TEXT,
  "odometer" DOUBLE PRECISION,
  "days_left" TEXT,
  "due_date" TEXT,
  "distance_left" TEXT,
  "engine_hours_left" TEXT,
  "date" DATE
);
CREATE OR REPLACE FUNCTION set_verizon_service_date() RETURNS TRIGGER AS $$
  BEGIN
    NEW."date" := CURRENT_DATE;
    RETURN NEW;
  END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE TRIGGER set_verizon_service_date
BEFORE INSERT ON verizon.services
FOR EACH ROW EXECUTE FUNCTION set_verizon_service_date();
CREATE INDEX verizon_services_date ON verizon.services ("date" DESC);
-- verizon.speeding
DROP TABLE IF EXISTS verizon.speeding CASCADE;
CREATE TABLE verizon.speeding (
  "date" DATE,
  "time" TIME,
  "driver" TEXT,
  "vehicle" TEXT,
  "speed_limit" SMALLINT,
  "limit_source" TEXT,
  "speed" SMALLINT,
  "percentage_over" TEXT,
  "location" TEXT,
  "latitude" DOUBLE PRECISION,
  "longitude" DOUBLE PRECISION,
  "timezone" TEXT,
  "driver_number" TEXT,
  "last_modified" TIMESTAMP
);
CREATE OR REPLACE FUNCTION clean_verizon_speeding() RETURNS TRIGGER AS $$
  DECLARE
    d DATE;
  BEGIN
    SELECT MIN("date") INTO d
    FROM verizon.speeding
    WHERE "last_modified" IS NULL;
    DELETE FROM verizon.speeding
    WHERE "last_modified" IS NOT NULL
    AND "date">=d;
    UPDATE verizon.speeding
    SET "last_modified" = LOCALTIMESTAMP
    WHERE "last_modified" IS NULL;
    RETURN NULL;
  END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE TRIGGER trigger_clean_verizon_speeding
AFTER INSERT ON verizon.speeding
FOR EACH STATEMENT EXECUTE FUNCTION clean_verizon_speeding();
CREATE INDEX verizon_speeding_date ON verizon.speeding ("date" DESC);
--*/