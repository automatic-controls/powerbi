SELECT
  "Job Name" AS "name",
  "JobTimeCreated" AS "creation_time",
  "Job Custom Field 03" AS "proposal_price",
  "Job Custom Field 01" AS "change_orders",
  "Job Custom Field 05" AS "contract_price",
  "Job Custom Field 02" AS "billed_to_date",
  "Job Custom Field 04" AS "previous_invoices"
FROM QQubeUser.vd_Job
  WHERE "Job Start Date" IS NOT NULL
  OR "Job End Date" IS NOT NULL;