SELECT
  "job_id" AS "id",
  "Job Name" AS "name",
  "JobTimeCreated" AS "creation_time",
  "Job Custom Field 03" AS "proposal_price",
  "Job Custom Field 01" AS "change_orders",
  "Job Custom Field 05" AS "contract_price",
  "Job Custom Field 02" AS "billed_to_date",
  "Job Custom Field 04" AS "previous_invoices"
FROM (
  SELECT
    *,
    ROW_NUMBER() OVER(PARTITION BY "t"."job_id" ORDER BY "JobTimeCreated" DESC) AS "instance"
  FROM (
    SELECT
      REGEXP_SUBSTR("Job Name", '^[a-zA-Z]\w*(?:-[\w&]+)+(?:/\d+)?(?=$|\s)') AS "job_id",
      *
    FROM QQubeUser.vd_Job
    WHERE "Job Custom Field 06" IS NOT NULL
  ) "t" WHERE "t"."job_id" IS NOT NULL
) "s" WHERE "s"."instance" = 1
ORDER BY "job_id"