WITH queried_list AS (
  SELECT row_number() OVER (
      ORDER BY r.id
    ) AS "myid",
    sa.view AS "stake_address",
    r.amount AS "amount"
  FROM reward r
    JOIN stake_address sa ON (sa.id = r.addr_id)
    JOIN pool_hash ph ON (ph.id = r.pool_id)
  WHERE r.earned_epoch = $1
    AND ph.view = $4
  ORDER BY es.id ASC
)
SELECT stake_address AS "stake_address",
  amount::TEXT AS "amount" -- cast to TEXT to avoid number overflow
FROM (
    SELECT myid,
      stake_address AS "stake_address",
      amount AS "amount"
    FROM queried_list
    WHERE myid > (
        CASE
          -- query.count
          WHEN $2 >= 1
          AND $2 <= 100 THEN $2
          ELSE 100
        END * CASE
          -- query.page
          WHEN $3 > 1
          AND $3 < 2147483647 THEN $3 - 1
          ELSE 0
        END
      )
      AND myid <= (
        CASE
          -- query.count
          WHEN $2 >= 1
          AND $2 <= 100 THEN $2
          ELSE 100
        END * CASE
          -- query.page
          WHEN $3 > 1
          AND $3 < 2147483647 THEN $3
          ELSE 1
        END
      )
  ) AS "staked_addresses"