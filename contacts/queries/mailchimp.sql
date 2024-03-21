SELECT
  "email",
  "first_name",
  "last_name",
  "title",
  "company",
  "address_1",
  "address_2",
  "city",
  "state",
  "zip_code",
  "phone"[1] AS "phone_1",
  "phone"[2] AS "phone_2",
  "audience" || ARRAY(
    SELECT DISTINCT e FROM UNNEST("tags") AS a(e)
  ) AS "tags",
  "last_modified"
FROM (
  SELECT
    *, ARRAY(
      SELECT e FROM UNNEST(
        ARRAY_REMOVE(
          CONCAT(
            '{"',"phone_1",'","',"phone_2",'","',"phone_3",'"}'
          )::TEXT[]
          ,''
        )
      ) WITH ORDINALITY AS a(e,n)
      GROUP BY "e"
      ORDER BY MIN("n")
    ) AS "phone"
  FROM (
    SELECT
      "email",
      (ARRAY_AGG("first_name" ORDER BY "last_modified" DESC) FILTER (WHERE "first_name" IS NOT NULL))[1] AS "first_name",
      (ARRAY_AGG("last_name" ORDER BY "last_modified" DESC) FILTER (WHERE "last_name" IS NOT NULL))[1] AS "last_name",
      (ARRAY_AGG("title" ORDER BY "last_modified" DESC) FILTER (WHERE "title" IS NOT NULL))[1] AS "title",
      (ARRAY_AGG("company" ORDER BY "last_modified" DESC) FILTER (WHERE "company" IS NOT NULL))[1] AS "company",
      (ARRAY_AGG("address_1" ORDER BY "last_modified" DESC) FILTER (WHERE "address_1" IS NOT NULL))[1] AS "address_1",
      (ARRAY_AGG("address_2" ORDER BY "last_modified" DESC) FILTER (WHERE "address_2" IS NOT NULL))[1] AS "address_2",
      (ARRAY_AGG("city" ORDER BY "last_modified" DESC) FILTER (WHERE "city" IS NOT NULL))[1] AS "city",
      (ARRAY_AGG("state" ORDER BY "last_modified" DESC) FILTER (WHERE "state" IS NOT NULL))[1] AS "state",
      (ARRAY_AGG("zip_code" ORDER BY "last_modified" DESC) FILTER (WHERE "zip_code" IS NOT NULL))[1] AS "zip_code",
      (ARRAY_AGG("phone_1" ORDER BY "last_modified" DESC) FILTER (WHERE "phone_1" IS NOT NULL))[1] AS "phone_1",
      (ARRAY_AGG("phone_2" ORDER BY "last_modified" DESC) FILTER (WHERE "phone_2" IS NOT NULL))[1] AS "phone_2",
      (ARRAY_AGG("phone_3" ORDER BY "last_modified" DESC) FILTER (WHERE "phone_3" IS NOT NULL))[1] AS "phone_3",
      (
        '{' ||
        REGEXP_REPLACE(
          REGEXP_REPLACE(
            STRING_AGG(RIGHT(LEFT("tags"::TEXT,-1),-1),','),
          ',+', ',', 'g'),
        '^,|,$', '', 'g')
        || '}'
      )::TEXT[] AS "tags",
      ARRAY_AGG(DISTINCT "audience") AS "audience",
      MAX("last_modified") AS "last_modified"
    FROM (
      WITH "tags" AS (
        SELECT
          "id",
          ARRAY_AGG('mailchimp_tag_'||"name") AS "tags"
        FROM (
          SELECT DISTINCT
            "_sdc_source_key_id" AS "id",
            REGEXP_REPLACE("name", '[^\x00-\x7F]', '', 'g') as "name"
          FROM mailchimp.list_members__tags
        ) "t"
        WHERE "name" IS NOT NULL AND LENGTH("name")>0
        GROUP BY "id"
      ),
      "auds" AS (
        SELECT
          "id",
          'mailchimp_audience_'||REGEXP_REPLACE("name", '[^\x00-\x7F]', '', 'g') as "name"
        FROM mailchimp.lists
      ) SELECT
        LOWER(REGEXP_REPLACE("email_address", '[^\x00-\x7F]', '', 'g')) AS "email",
        REGEXP_REPLACE(NULLIF("merge_fields__FNAME", ''), '[^\x00-\x7F]', '', 'g') AS "first_name",
        REGEXP_REPLACE(NULLIF("merge_fields__LNAME", ''), '[^\x00-\x7F]', '', 'g') AS "last_name",
        REGEXP_REPLACE(NULLIF("merge_fields__MMERGE6", ''), '[^\x00-\x7F]', '', 'g') AS "title",
        REGEXP_REPLACE(COALESCE(NULLIF("merge_fields__MMERGE3", ''), NULLIF("merge_fields__MMERGE5", '')), '[^\x00-\x7F]', '', 'g') AS "company",
        REGEXP_REPLACE(COALESCE(NULLIF("merge_fields__ADDRESS__addr1", ''), NULLIF("merge_fields__MMERGE4__addr1", '')), '[^\x00-\x7F]', '', 'g') AS "address_1",
        REGEXP_REPLACE(COALESCE(NULLIF("merge_fields__ADDRESS__addr2", ''), NULLIF("merge_fields__MMERGE4__addr2", '')), '[^\x00-\x7F]', '', 'g') AS "address_2",
        REGEXP_REPLACE(COALESCE(NULLIF("merge_fields__ADDRESS__city", ''), NULLIF("merge_fields__MMERGE4__city", '')), '[^\x00-\x7F]', '', 'g') AS "city",
        REGEXP_REPLACE(COALESCE(NULLIF("merge_fields__ADDRESS__state", ''), NULLIF("merge_fields__MMERGE4__state", '')), '[^\x00-\x7F]', '', 'g') AS "state",
        REGEXP_REPLACE(COALESCE(NULLIF("merge_fields__ADDRESS__zip", ''), NULLIF("merge_fields__MMERGE4__zip", '')), '[^\x00-\x7F]', '', 'g') AS "zip_code",
        NULLIF(RIGHT(REGEXP_REPLACE("merge_fields__PHONE", '[^\d]', '', 'g'), 10), '') AS "phone_1",
        NULLIF(RIGHT(REGEXP_REPLACE("merge_fields__MMERGE7", '[^\d]', '', 'g'), 10), '') AS "phone_2",
        NULLIF(RIGHT(REGEXP_REPLACE("merge_fields__MMERGE8", '[^\d]', '', 'g'), 10), '') AS "phone_3",
        COALESCE("tags", '{}'::TEXT[]) AS "tags",
        "a"."name" AS "audience",
        COALESCE("last_changed", CURRENT_TIMESTAMP) AS "last_modified"
      FROM mailchimp.list_members "x"
      LEFT JOIN "tags" "t" ON "x"."id" = "t"."id"
      LEFT JOIN "auds" "a" ON "x"."list_id" = "a"."id"
      WHERE "email_address" IS NOT NULL
      AND "email_address" !~ '^\d+@.*$'
      AND "status" <> 'cleaned'
      AND "status" <> 'archived'
    ) "t"
    WHERE "t"."first_name" IS NOT NULL
    OR "t"."last_name" IS NOT NULL
    OR "t"."title" IS NOT NULL
    GROUP BY "email"
  ) "t"
) "t";