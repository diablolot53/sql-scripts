Declare @db_id SMALLINT;
--Enter the database to search the index for here
SET @db_id = DB_ID(N'<dbname>');

If @db_id Is Null
	Begin
		Print N'Invalid Database';
	End

--Look at the indexes for all tables in the DB and return any that have more than 10% fragmentation
Select 
	DB_NAME(@db_id) As [Database],
	OBJECT_NAME(sys.dm_db_index_physical_stats.object_id,@db_id) As [TableName],
	avg_fragmentation_in_percent,
	fragment_count,
	avg_fragment_size_in_pages
Into
	#TempFragment
From 
	sys.dm_db_index_physical_stats(@db_id,Null,Null,Null,'LIMITED')
Where
	avg_fragmentation_in_percent > 10
Select * From #TempFragment

--Cleanup the temp table
If (OBJECT_ID('tempdb..#TempFragment') Is Not Null)
Begin
	Drop Table #TempFragment
End