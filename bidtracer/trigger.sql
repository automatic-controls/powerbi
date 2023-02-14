CREATE OR REPLACE FUNCTION clean_bidtracer_alloc() RETURNS TRIGGER AS $$
  BEGIN
    UPDATE bidtracer.alloc
    SET "last_processed" = NOW()::TIMESTAMP
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

CREATE TRIGGER trigger_clean_bidtracer_alloc
AFTER INSERT ON bidtracer.alloc
FOR EACH STATEMENT EXECUTE FUNCTION clean_bidtracer_alloc();