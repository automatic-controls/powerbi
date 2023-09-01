WITH "users" AS (
  SELECT
    "id",
    "name",
    "email"
  FROM zendesk_v2.users
  WHERE "id" IS NOT NULL
  AND "name" IS NOT NULL
  AND "email" IS NOT NULL
  AND COALESCE("role" = 'agent' OR "role" = 'admin' OR "organization_id" = 22826152, FALSE)
)
SELECT DISTINCT ON ("tickets"."id")
  "tickets"."id",
  "orgs"."name" AS "organization",
  "tickets"."subject",
  "assignee"."name" AS "assignee_name",
  "assignee"."email" AS "assignee_email",
  "job_id"."value" AS "job_id"
FROM (
  SELECT
    "id",
    "assignee_id",
    "subject",
    "status",
    "organization_id"
  FROM zendesk_v2.tickets
  WHERE "status" = 'solved'
) "tickets"
INNER JOIN "users" "assignee"
ON "assignee"."id" = "tickets"."assignee_id"
LEFT JOIN (
  SELECT
    _sdc_source_key_id AS "ticket_id",
    UPPER(value__st) AS "value"
  FROM zendesk_v2.tickets__custom_fields
  WHERE id=22017617
  AND value__st IS NOT NULL
) "job_id"
ON "tickets"."id" = "job_id"."ticket_id"
LEFT JOIN ( SELECT "id", "name" FROM zendesk_v2.organizations ) "orgs"
ON "orgs"."id" = "tickets"."organization_id"
ORDER BY "tickets"."id" DESC;