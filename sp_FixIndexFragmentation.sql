Declare @db_id SMALLINT;
Declare @db_name NVARCHAR(50);

--Enter the database to search the index for here
Set @db_name = '<dbname>';
SET @db_id = DB_ID(@db_name);

If @db_id Is Null
	Begin
		Print N'Invalid Database';
	End

--Look at the indexes for all tables in the DB and return any that have more than 10% fragmentation
Select 
	@db_name As [DatabaseName],
	OBJECT_NAME(sys.dm_db_index_physical_stats.object_id,@db_id) As [TableName],
	CONCAT(object_id,index_id) As [TableID],
	avg_fragmentation_in_percent As [Avg_Fragmentation_BeforeFix],
	fragment_count,
	avg_fragment_size_in_pages
Into
	#TempFragment
From 
	sys.dm_db_index_physical_stats(@db_id,Null,Null,Null,'LIMITED')
Where
	avg_fragmentation_in_percent > 10


--REORGANIZE the indexes for the returned tables. This is the quickest procedure and does not lock the tables when running 
Declare @TableID NVARCHAR(100);
Declare @sql NVARCHAR(200);
Select @TableID = Min(TableName) From #TempFragment;
While @TableID Is Not Null
Begin
	Select @sql = 'Use ' + @db_name + '; Alter Index ALL on ' + @TableID + ' REORGANIZE;';
	Exec sp_sqlexec @sql;
	Select @TableID = Min(TableName) From #TempFragment Where TableName > @TableID;
End

--Look at the indexes for all tables in the DB and return any that have more than 10% fragmentation
Select 
	@db_name As [DatabaseName],
	OBJECT_NAME(sys.dm_db_index_physical_stats.object_id,@db_id) As [TableName],
	CONCAT(object_id,index_id) As [TableID],
	avg_fragmentation_in_percent As [Avg_Fragmentation_AfterFix],
	fragment_count,
	avg_fragment_size_in_pages
Into
	#TempFix
From 
	sys.dm_db_index_physical_stats(@db_id,Null,Null,Null,'LIMITED')


--Display results after fragmentation fix
Select
	#TempFragment.DatabaseName,
	#TempFragment.TableName,
	Avg_Fragmentation_BeforeFix,
	Avg_Fragmentation_AfterFix,
	#TempFix.avg_fragment_size_in_pages
From #TempFragment Inner Join #TempFix On #TempFragment.TableID = #TempFix.TableID

--Cleanup the temp tables
If (OBJECT_ID('tempdb..#TempFragment') Is Not Null)
Begin
	Drop Table #TempFragment
End
If (OBJECT_ID('tempdb..#TempFix') Is Not Null)
Begin
	Drop Table #TempFix
End