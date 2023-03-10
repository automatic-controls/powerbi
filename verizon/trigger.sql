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
CREATE TRIGGER trigger_clean_verizon_incidents
AFTER INSERT ON verizon.incidents
FOR EACH STATEMENT EXECUTE FUNCTION clean_verizon_incidents();

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
CREATE TRIGGER trigger_clean_verizon_movements
AFTER INSERT ON verizon.movements
FOR EACH STATEMENT EXECUTE FUNCTION clean_verizon_movements();

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
    SET "last_modified" = CURRENT_DATE
    WHERE "last_modified" IS NULL;
    RETURN NULL;
  END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trigger_clean_verizon_speeding
AFTER INSERT ON verizon.speeding
FOR EACH STATEMENT EXECUTE FUNCTION clean_verizon_speeding();

CREATE OR REPLACE FUNCTION set_verizon_service_date() RETURNS TRIGGER AS $$
  BEGIN
    NEW."date" := CURRENT_DATE;
    RETURN NEW;
  END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER set_verizon_service_date
BEFORE INSERT ON verizon.services
FOR EACH ROW EXECUTE FUNCTION set_verizon_service_date();
