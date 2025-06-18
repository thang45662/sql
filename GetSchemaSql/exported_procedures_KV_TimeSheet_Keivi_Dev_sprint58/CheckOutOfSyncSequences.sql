ALTER PROCEDURE [dbo].[CheckOutOfSyncSequences] (@autoFix bit = 0) as
begin
declare @totalTables int = 0
declare @totalAffectedTables int = 0
declare @name nvarchar(100)
declare @value bigint
declare @step int
declare @report nvarchar(max) = ''
declare c cursor for select convert(bigint,current_value), convert(bigint,increment), SUBSTRING([name], 0, len([name]) - 2) from sys.sequences
open c
fetch next from c into @value, @step, @name
while @@FETCH_STATUS = 0
begin
	declare @max bigint
	if object_id(@name) is not null
	begin
		set @totalTables = @totalTables + 1
		declare @sequenceName nvarchar(100) = @name + 'Seq'
		set @name = '[' + @name + ']'
		declare @sql nvarchar(200) = N'select @mid = max(id) from ' + @name
		exec sp_executesql @sql, N'@mid bigint OUTPUT', @mid = @max OUTPUT

		if(@max > @value + @step)
		begin
			set @totalAffectedTables = @totalAffectedTables + 1
			set @report = @report + 'The sequence ' + @name + ' has the current value of ' + convert(nvarchar(100),@value) + ' (+' + convert(nvarchar(100),@step) + ') which is less than the max value ' + convert(nvarchar(100),@max) + char(13) + char(10)
			if(@autoFix = 1)
			begin
				set @sql = 'alter sequence ' + @sequenceName + ' restart with ' + convert(nvarchar(100), @max)
				exec sp_executesql @sql
			end
		end
	end
	fetch next from c into @value, @step, @name
end

close c
deallocate c

print 'Total affected tables/total tables: ' + convert(nvarchar(50),@totalAffectedTables) + '/' + convert(nvarchar(50),@totalTables)
print @report
end

GO
