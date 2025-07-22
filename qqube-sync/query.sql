SELECT
  "a"."link_for_job_id",
  "a"."id",
  "a"."active",
  "a"."name",
  "a"."end_user",
  "a"."vertical",
  "a"."project_manager",
  "a"."salesperson",
  "a"."type",
  "a"."proposal_price",
  "a"."change_orders",
  "a"."contract_price",
  COALESCE("b"."amount", "a"."billed_to_date") AS "billed_to_date",
  "a"."previous_invoices",
  "a"."time_created",
  "a"."time_modified",
  "a"."start_date",
  "a"."end_date",
  "a"."projected_end_date",
  "a"."est_cost"
FROM (
  SELECT
    "LinkForJobID" AS "link_for_job_id",
    "job_id" AS "id",
    CAST(
      CASE
        WHEN "Job Active" = 'Active' THEN 1 ELSE 0
      END AS BIT
    ) AS "active",
    "Job Name" AS "name",
    "Job Custom Field 07" AS "end_user",
    "Job Custom Field 06" AS "vertical",
    CASE
      WHEN "Job Customer Type"='No Customer Type' THEN NULL ELSE "Job Customer Type"
    END AS "project_manager",
    CASE
      WHEN "Job SalesRep Initial"='n/a' THEN NULL ELSE "Job SalesRep Initial"
    END AS "salesperson",
    "Job Type" AS "type",
    CAST(
      CASE
        WHEN "Job Custom Field 03" REGEXP '\d+(?:,\d+)*(?:\.\d+)?' THEN
          REPLACE("Job Custom Field 03", ',', '')
        ELSE
          NULL
      END AS MONEY
    ) AS "proposal_price",
    CAST(
      CASE
        WHEN "Job Custom Field 01" REGEXP '-?\d+(?:,\d+)*(?:\.\d+)?' THEN
          REPLACE("Job Custom Field 01", ',', '')
        ELSE
          NULL
      END AS MONEY
    ) AS "change_orders",
    CAST(
      CASE
        WHEN "Job Custom Field 05" REGEXP '\d+(?:,\d+)*(?:\.\d+)?' THEN
          REPLACE("Job Custom Field 05", ',', '')
        ELSE
          NULL
      END AS MONEY
    ) AS "contract_price",
    CAST(
      CASE
        WHEN "Job Custom Field 02" REGEXP '\d+(?:,\d+)*(?:\.\d+)?' THEN
          REPLACE("Job Custom Field 02", ',', '')
        ELSE
          NULL
      END AS MONEY
    ) AS "billed_to_date",
    CAST(
      CASE
        WHEN "Job Custom Field 04" REGEXP '\d+(?:,\d+)*(?:\.\d+)?' THEN
          REPLACE("Job Custom Field 04", ',', '')
        ELSE
          NULL
      END AS MONEY
    ) AS "previous_invoices",
    "JobTimeCreated" AS "time_created",
    "JobTimeModified" AS "time_modified",
    "Job Start Date" AS "start_date",
    "Job End Date" AS "end_date",
    "Job Projected End Date" AS "projected_end_date",
    CAST(
      CASE
        WHEN "Job Custom Field 10" REGEXP '\d+(?:,\d+)*(?:\.\d+)?' THEN
          REPLACE("Job Custom Field 10", ',', '')
        ELSE
          NULL
      END AS MONEY
    ) AS "est_cost"
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
  AND "s"."JobTimeModified">?
) "a" LEFT JOIN (
  SELECT
    "link_to_job_id",
    SUM("amount") AS "amount"
  FROM (
    SELECT
      "x"."LinkToJobID" AS "link_to_job_id",
      "x"."GLPLTxn Line Credit Amount"-"x"."GLPLTxn Line Debit Amount" AS "amount"
    FROM QQubeFinancials.vf_PANDLDETAIL "x"
    INNER JOIN (
      SELECT
        "LinkForAccountID" AS "link_for_account_id"
      FROM QQubeUser.vd_AccountPL_S
      WHERE "Account Type" = 'Income'
    ) "y"
    ON "x"."LinkToAccountID" = "y"."link_for_account_id"
  ) "x"
  GROUP BY "link_to_job_id"
) "b"
ON SUBSTRING("a"."link_for_job_id",3) = SUBSTRING("b"."link_to_job_id",3);