CREATE OR REPLACE FUNCTION timestar_set_last_modified() RETURNS TRIGGER AS $$
  BEGIN
    NEW.last_modified := NOW();
    RETURN NEW;
  END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER timestar_set_last_modified
BEFORE INSERT OR UPDATE ON timestar.timesheets_processed
FOR EACH ROW EXECUTE FUNCTION timestar_set_last_modified();