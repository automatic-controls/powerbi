SELECT
  "x"."job_id",
  CAST(100*SUM("x"."amount") AS BIGINT) AS "amount",
  "x"."month"
FROM (
  SELECT
    "y"."id" AS "job_id",
    "x"."amount",
    "x"."month"
  FROM (
    SELECT
      "x"."LinkToJobID" AS "link_to_job_id",
      "x"."GLPLTxn Line Credit Amount"-"x"."GLPLTxn Line Debit Amount" AS "amount",
      DATEFORMAT(DATE('1997-01-01')+"x"."LinkToFiscalDateID"-1097, 'YYYY-MM') AS "month"
    FROM QQubeFinancials.vf_PANDLDETAIL "x"
    INNER JOIN (
      SELECT
        "LinkForAccountID" AS "link_for_account_id"
      FROM QQubeUser.vd_AccountPL_S
      WHERE "Account Type" = 'Income'
    ) "y"
    ON "x"."LinkToAccountID" = "y"."link_for_account_id"
    WHERE "x"."GLPLTxn Line Credit Amount" != "x"."GLPLTxn Line Debit Amount"
  ) "x" INNER JOIN (
    SELECT
      "LinkForJobID" AS "link_for_job_id",
      "job_id" AS "id"
    FROM (
      SELECT
        "job_id",
        "LinkForJobID",
        ROW_NUMBER() OVER(PARTITION BY "t"."job_id" ORDER BY "JobTimeCreated" DESC) AS "instance"
      FROM (
        SELECT
          REGEXP_SUBSTR("Job Name", '^[a-zA-Z]\w*(?:-[\w&]+)+(?:/\d+)?(?=$|\s)') AS "job_id",
          "LinkForJobID",
          "JobTimeCreated"
        FROM QQubeUser.vd_Job
        WHERE "Job Custom Field 06" IS NOT NULL
        AND "Job Active" = 'Active'
        AND (
          "Job Type" = 'Contract'
          OR "Job Type" = 'NTE'
        )
      ) "t" WHERE "t"."job_id" IS NOT NULL
    ) "s" WHERE "s"."instance" = 1
  ) "y"
  ON SUBSTRING("y"."link_for_job_id",3) = SUBSTRING("x"."link_to_job_id",3)
) "x"
GROUP BY "x"."job_id", "x"."month"
ORDER BY "x"."job_id" ASC, "x"."month" DESC;