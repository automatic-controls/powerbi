
-- bidtracer.alloc

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

-- bidtracer.materials

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

-- bidtracer.margin

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

CREATE TRIGGER trigger_clean_bidtracer_margin
AFTER INSERT ON bidtracer.margin
FOR EACH STATEMENT EXECUTE FUNCTION clean_bidtracer_margin();