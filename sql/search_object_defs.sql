-- Search sys.objects to find all items in a specific schema whose object definitions contain a search term.

DECLARE @schema VARCHAR(255); -- Schema name in which stored procedures and views will be searched
DECLARE @searchTerm VARCHAR(255); -- Term to search for in object definitions. Wildcards will be prepended and appended.

SET @schema = 'dbo';
SET @searchTerm = 'searchMe';

--Search object definitions
SELECT 
type_desc AS ObjectType
,o.Name AS ObjectName
FROM sys.objects AS o
JOIN sys.schemas AS s
ON o.schema_id = s.schema_id
WHERE OBJECT_DEFINITION(OBJECT_ID) LIKE '%' + @searchTerm + '%'
AND s.Name = @schema
UNION
-- Also search columns in table definitions
SELECT 'USER_TABLE' AS ObjectType
,t.name AS ObjectName
FROM sys.columns AS c
JOIN sys.tables  AS t
ON c.object_id = t.object_id
JOIN sys.schemas AS s
ON s.schema_id = t.schema_id
WHERE c.name LIKE @searchTerm
AND s.Name = @schema
ORDER BY    
ObjectType;
GO
