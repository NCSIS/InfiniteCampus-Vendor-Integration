-- CTE: Dynamic calendar filter
WITH TargetCalendars AS (
  SELECT calendarID
  FROM dbo.Calendar
  WHERE endYear = CASE 
                    WHEN MONTH(GETDATE()) >= 7 THEN YEAR(GETDATE()) + 1
                    ELSE YEAR(GETDATE())
                  END
),

-- CTE: Qualified students based on Student table logic (no enrollment codes)
QualifiedStudents AS (
  SELECT s.personID, s.calendarID
  FROM dbo.Student s
  JOIN TargetCalendars tc ON s.calendarID = tc.calendarID
  WHERE s.serviceType = 'P'
    AND ISNULL(s.noShow, 0) = 0
    AND s.startDate <= CAST(GETDATE() AS date)
    AND (s.endDate IS NULL OR s.endDate >= CAST(GETDATE() AS date))
)

-- Inner: DISTINCT + compute RelOrder for fuzzy mother/father sort
, Base AS (
  SELECT DISTINCT
    qs.personID                                                 AS [StudentID],

    ccs.firstName                                               AS [ParentFirstName],
    ccs.middleName                                              AS [ParentMiddleName],
    ccs.lastName                                                AS [ParentLastName],

    -- Address line 1
    COALESCE(NULLIF(LTRIM(RTRIM(ccs.addressLine1)),''), ma.addressline1) AS [ParentAddressLine1],

    -- Address line 2 with CSZ scrubbed (handles commas/spaces/ZIP+4/various formats)
    CASE
      WHEN NULLIF(LTRIM(RTRIM(
             CASE 
               WHEN NULLIF(LTRIM(RTRIM(ccs.addressLine2)),'') IS NOT NULL THEN ccs.addressLine2
               ELSE ma.addressline2
             END
           )), '') IS NULL
        THEN NULL
      ELSE
        CASE 
          WHEN 
            -- Normalize: UPPER + strip spaces/commas/dots/dashes
            REPLACE(REPLACE(REPLACE(REPLACE(
              UPPER(
                CASE 
                  WHEN NULLIF(LTRIM(RTRIM(ccs.addressLine2)),'') IS NOT NULL THEN ccs.addressLine2
                  ELSE ma.addressline2
                END
              ), ' ', ''), ',', ''), '.', ''), '-', '') 
            IN (
              -- CityStateZip (from ccs or ma)
              REPLACE(REPLACE(REPLACE(REPLACE(UPPER(ISNULL(ccs.city, '') + ISNULL(ccs.state, '') + ISNULL(ccs.zip, '')),' ',''),',',''),'.',''),'-',''),
              REPLACE(REPLACE(REPLACE(REPLACE(UPPER(ISNULL(ma.city, '')  + ISNULL(ma.state, '')  + ISNULL(ma.zip,  '')),' ',''),',',''),'.',''),'-',''),
              -- StateZip only
              REPLACE(REPLACE(REPLACE(REPLACE(UPPER(ISNULL(ccs.state,'') + ISNULL(ccs.zip,'')),' ',''),',',''),'.',''),'-',''),
              REPLACE(REPLACE(REPLACE(REPLACE(UPPER(ISNULL(ma.state, '') + ISNULL(ma.zip, '')),' ',''),',',''),'.',''),'-',''),
              -- CityState only
              REPLACE(REPLACE(REPLACE(REPLACE(UPPER(ISNULL(ccs.city,'') + ISNULL(ccs.state,'')),' ',''),',',''),'.',''),'-',''),
              REPLACE(REPLACE(REPLACE(REPLACE(UPPER(ISNULL(ma.city, '') + ISNULL(ma.state, '')),' ',''),',',''),'.',''),'-','')
            )
            THEN NULL
          ELSE
            CASE 
              WHEN NULLIF(LTRIM(RTRIM(ccs.addressLine2)),'') IS NOT NULL THEN ccs.addressLine2
              ELSE ma.addressline2
            END
        END
    END                                                         AS [ParentAddressLine2],

    -- City/State/Zip
    COALESCE(NULLIF(LTRIM(RTRIM(ccs.city)),''),  ma.city)       AS [ParentCity],
    COALESCE(NULLIF(LTRIM(RTRIM(ccs.state)),''), ma.state)      AS [ParentState],
    COALESCE(NULLIF(LTRIM(RTRIM(ccs.zip)),''),   ma.zip)        AS [ParentZipCode],

    c.cellPhone                                                 AS [ParentPhone1],
    c.homePhone                                                 AS [ParentPhone2],
    ccs.email                                                   AS [ParentEmail],

    ccs.relationship                                            AS [Relationship],
    NULL                                                       AS [Description],
    CASE WHEN ccs.guardian = 1 THEN 'Y' ELSE 'N' END            AS [PrimaryContact],

    -- Fuzzy sort key: Mother first, then Father, then others
    CASE 
      WHEN UPPER(ccs.relationship) LIKE '%MOTHER%' OR UPPER(ccs.relationship) LIKE '%MOM%'   THEN 0
      WHEN UPPER(ccs.relationship) LIKE '%FATHER%' OR UPPER(ccs.relationship) LIKE '%DAD%'   THEN 1
      ELSE 2
    END AS RelOrder

  FROM QualifiedStudents qs
  JOIN dbo.v_CensusContactSummaryAll ccs
    ON ccs.personID = qs.personID
   AND ccs.guardian = 1

  LEFT JOIN dbo.Contact c
    ON c.personID = ccs.contactPersonID

  -- Fallback: parent’s CURRENT mailing address (robust date handling)
  OUTER APPLY (
      SELECT TOP (1)
          m.addressline1, m.addressline2, m.city, m.state, m.zip
      FROM dbo.v_MailingAddress m
      CROSS APPLY (
          SELECT
            TRY_CONVERT(date, NULLIF(NULLIF(LTRIM(RTRIM(CONVERT(varchar(50), m.startDate))),''),'0000-00-00')) AS start_dt,
            TRY_CONVERT(date, NULLIF(NULLIF(LTRIM(RTRIM(CONVERT(varchar(50), m.endDate))),''),'0000-00-00'))   AS end_dt
      ) d
      WHERE m.personID = ccs.contactPersonID
        AND (d.start_dt IS NULL OR d.start_dt <= CAST(GETDATE() AS date))
        AND (d.end_dt   IS NULL OR d.end_dt   >= CAST(GETDATE() AS date))
      ORDER BY
        CASE WHEN d.end_dt IS NULL THEN 0 ELSE 1 END,  -- open-ended first
        d.end_dt DESC,
        d.start_dt DESC
  ) ma
)

-- Outer: no DISTINCT -> can ORDER BY computed keys
SELECT
  StudentID,
  ParentFirstName,
  ParentMiddleName,
  ParentLastName,
  ParentAddressLine1,
  ParentAddressLine2,
  ParentCity,
  ParentState,
  ParentZipCode,
  ParentPhone1,
  ParentPhone2,
  ParentEmail,
  Relationship,
  [Description],
  PrimaryContact
FROM Base
ORDER BY
  RelOrder,
  ParentLastName,
  ParentFirstName;