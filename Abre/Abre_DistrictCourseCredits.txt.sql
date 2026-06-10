SELECT DISTINCT
  s.studentNumber                               AS [StudentID],
  tc.creditsearned                              AS [TotalCredits],
  QUOTENAME(REPLACE(tc.actualterm, '"', '""'), '"')        AS [Term],
  QUOTENAME(REPLACE(tc.courseName, '"', '""'), '"')        AS [CourseName],
  tc.courseNumber                               AS [CourseCode],
  QUOTENAME(REPLACE(
    CASE 
      WHEN LEFT(tc.scedSubjectArea, 2) = '01' THEN 'English Language and Literature'
      WHEN LEFT(tc.scedSubjectArea, 2) = '02' THEN 'Mathematics'
      WHEN LEFT(tc.scedSubjectArea, 2) = '03' THEN 'Life and Physical Sciences'
      WHEN LEFT(tc.scedSubjectArea, 2) = '04' THEN 'Social Sciences and History'
      WHEN LEFT(tc.scedSubjectArea, 2) = '05' THEN 'Visual and Performing Arts'
      WHEN LEFT(tc.scedSubjectArea, 2) = '07' THEN 'Religious Education and Theology'
      WHEN LEFT(tc.scedSubjectArea, 2) = '08' THEN 'Physical, Health, and Safety Education'
      WHEN LEFT(tc.scedSubjectArea, 2) = '09' THEN 'Military Science'
      WHEN LEFT(tc.scedSubjectArea, 2) = '10' THEN 'Information Technology'
      WHEN LEFT(tc.scedSubjectArea, 2) = '11' THEN 'Communication and Audio/Visual Technology'
      WHEN LEFT(tc.scedSubjectArea, 2) = '12' THEN 'Business and Marketing'
      WHEN LEFT(tc.scedSubjectArea, 2) = '13' THEN 'Manufacturing'
      WHEN LEFT(tc.scedSubjectArea, 2) = '14' THEN 'Health Care Sciences'
      WHEN LEFT(tc.scedSubjectArea, 2) = '15' THEN 'Public, Protective, and Government Service'
      WHEN LEFT(tc.scedSubjectArea, 2) = '16' THEN 'Hospitality and Tourism'
      WHEN LEFT(tc.scedSubjectArea, 2) = '17' THEN 'Architecture and Construction'
      WHEN LEFT(tc.scedSubjectArea, 2) = '18' THEN 'Agriculture, Food, and Natural Resources'
      WHEN LEFT(tc.scedSubjectArea, 2) = '19' THEN 'Human Services'
      WHEN LEFT(tc.scedSubjectArea, 2) = '20' THEN 'Transportation, Distribution and Logistics'
      WHEN LEFT(tc.scedSubjectArea, 2) = '21' THEN 'Engineering and Technology'
      WHEN LEFT(tc.scedSubjectArea, 2) = '22' THEN 'Miscellaneous'
      WHEN LEFT(tc.scedSubjectArea, 2) = '23' THEN 'Non-Subject-Specific'
      WHEN LEFT(tc.scedSubjectArea, 2) = '24' THEN 'World Languages'
      ELSE tc.scedSubjectArea
    END, '"', '""'), '"')                       AS [SubjectArea],
  QUOTENAME(REPLACE(tc.stateCode, '"', '""'), '"')          AS [StateCode],
  QUOTENAME(REPLACE(tc.standardname1, '"', '""'), '"')      AS [GraduationAlignment],
  tc.endyear                                    AS [AcademicEndYear]
FROM dbo.v_TranscriptDetail tc
INNER JOIN dbo.Enrollment e
  ON tc.personID = e.personID
INNER JOIN dbo.SchoolYear y
  ON y.endYear = e.endYear
INNER JOIN dbo.Student s
  ON s.personID = tc.personID
WHERE tc.creditsearned > 0
  AND y.endYear = CASE 
                    WHEN MONTH(GETDATE()) >= 7 THEN YEAR(GETDATE()) + 1
                    ELSE YEAR(GETDATE())
                  END;