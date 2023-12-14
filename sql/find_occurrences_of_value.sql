-- Find all occurrences of a value X in columns named Y in any table of schema Z, and return a list of the tables containing the target column and a count of the rows containing the target value.
USE mydb;

DROP TABLE IF EXISTS #tbls_to_search
GO

DECLARE @schema VARCHAR(255); -- Schema name to search all tables in
DECLARE @col VARCHAR(255); -- Column name to search for @value
DECLARE @value VARCHAR(255); -- Value to search for in all columns named @col
DECLARE @sql NVARCHAR(750); -- Select statement to run in each table
DECLARE @cursor CURSOR; -- Cursor over all table names that contain a column named @col
DECLARE @tbl VARCHAR(255); -- Table name to search, will be populated dynamically from @cursor
DECLARE @paramdef NVARCHAR(255); -- Parameter definition passed to sp_executesql
DECLARE @n_rows INT; -- Row count returned in each iteration over the tables

SET @schema = 'dbo'; -- Schema to search
SET @col = 'searchMe'; -- Column name to search for in all tables of @schema
SET @value = '999'; -- Value to search for in @col

SELECT      c.name  AS 'ColumnName'
            ,t.name AS 'TableName'
			,0 AS nRows
INTO #tbls_to_search
FROM        sys.columns c
JOIN        sys.tables  t   ON c.object_id = t.object_id
JOIN        sys.schemas  s   ON t.schema_id = s.schema_id
WHERE       c.name = @col
AND			s.name = @schema
ORDER BY    TableName
            ,ColumnName;

BEGIN
    SET @cursor = CURSOR FOR
	    SELECT TableName FROM #tbls_to_search       

    OPEN @cursor 
    FETCH NEXT FROM @cursor 
    INTO @tbl
	
    WHILE @@FETCH_STATUS = 0
    BEGIN
      SET @sql  = N'SELECT @n_rowsOUT=COUNT(*) FROM [' + @schema + '].[' +  @tbl + '] WHERE CAST([' + @col + '] AS VARCHAR(255))=''' + @value + '''';
	  SET @paramdef = N'@n_rowsOUT INT OUTPUT';
	  PRINT @sql;

	  EXECUTE sp_executesql @sql
	  , @paramdef
	  , @n_rowsOUT = @n_rows OUTPUT;
	  
	  -- Update table with number of rows containing the specified value
	  UPDATE #tbls_to_search
	  SET nRows = (SELECT @n_rows)
	  FROM #tbls_to_search
	  WHERE TableName = @tbl

      FETCH NEXT FROM @cursor 
      INTO @tbl 
    END; 

    CLOSE @cursor ;
    DEALLOCATE @cursor;
END

-- Return results table
SELECT * FROM #tbls_to_search
ORDER BY nRows DESC;
