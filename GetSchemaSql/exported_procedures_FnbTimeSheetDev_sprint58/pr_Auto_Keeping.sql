ALTER PROCEDURE [dbo].[pr_Auto_Keeping]
(
    @tenantId    INT,
    @startTime   DATETIME,
    @endTime   DATETIME,
    @autoTimekeepingUid   NVARCHAR(255) = null,
	@branchIds nvarchar(max) = null
)
AS
BEGIN
    SET NOCOUNT ON

if @branchIds is not null
begin
	select convert(int, ltrim(rtrim([value]))) as Id into #branchIdsList from string_split(@branchIds, ',')
end

DECLARE @returnValue NVARCHAR(MAX)
SET @returnValue = ''
DROP TABLE IF EXISTS #TempCurrentClocking

--define the #TempCurrentClocking with dynamic columns first
--this query inserts no result into the temp table, just builds its schema
SELECT c.*,s.[From], s.[To], cast('1970-1-1' as datetime2) Cal_CheckInDate, cast('1970-1-1' as datetime2) Cal_CheckOutDate, 0 AS IsUpdated
INTO #TempCurrentClocking
FROM Clocking AS c WITH(NOLOCK)
INNER JOIN Employee AS e WITH(NOLOCK) ON e.Id = c.EmployeeId
INNER JOIN [Shift] AS s WITH(NOLOCK) ON c.ShiftId = s.Id
WHERE 1=0

declare @tempClockingQuery nvarchar(max) = N'INSERT INTO #TempCurrentClocking SELECT c.*,s.[From], s.[To],
		(CASE
			WHEN (c.ClockingStatus = 1) THEN ISNULL(c.CheckInDate,c.StartTime)
			WHEN (c.ClockingStatus = 3) THEN  ISNULL(c.CheckInDate,c.StartTime)
			ELSE  (c.CheckInDate)
		END )
		AS Cal_CheckInDate,
		( CASE
			WHEN (c.ClockingStatus = 1) THEN ISNULL(c.CheckOutDate,c.EndTime)
			WHEN (c.ClockingStatus = 2) THEN ISNULL(c.CheckOutDate,c.EndTime)
			ELSE  (c.CheckOutDate)
		END)
		AS Cal_CheckOutDate,
0 AS IsUpdated
FROM Clocking AS c WITH(NOLOCK)
INNER JOIN Employee AS e WITH(NOLOCK) ON e.Id = c.EmployeeId
INNER JOIN [Shift] AS s WITH(NOLOCK) ON c.ShiftId = s.Id
WHERE c.TenantId = @tenantId
AND  isnull(c.IsDeleted,0) <> 1
AND isnull(e.IsDeleted,0) <> 1
AND c.StartTime > @startTime AND c.StartTime < @endTime
AND (
	c.ClockingStatus = 1 -- chua vao chua ra
	OR c.ClockingStatus = 2 -- da vao chua ra
	OR (c.ClockingStatus = 3 AND c.CheckInDate IS NULL) -- chua vao da ra
)
AND e.IsDeleted <> 1'

if @branchIds is not null
begin
	set @tempClockingQuery = @tempClockingQuery + ' AND c.BranchId in (select Id from #branchIdsList)'
end
exec sp_executesql @tempClockingQuery, N'@tenantId int, @startTime datetime2, @endTime datetime2', @tenantId, @startTime, @endTime

CREATE CLUSTERED INDEX IX_TempCurrentClocking_Id ON #TempCurrentClocking(Id)
CREATE NONCLUSTERED INDEX IX_TempCurrentClocking_IsUpdated ON #TempCurrentClocking(IsUpdated)

-- Khai báo biến cấu hình kiểu chuỗi
DECLARE
	@IsAutoCalcLateTime VARCHAR(10),
	@IsAutoCalcLateTimeOT VARCHAR(10),
	@IsAutoCalcEarlyTime VARCHAR(10),
	@IsAutoCalcEarlyTimeOT VARCHAR(10),
	@LateTime INT = 0,
	@LateTimeOT INT = 0,
	@EarlyTime INT = 0,
	@EarlyTimeOT INT = 0;

-- Truy vấn cấu hình
SELECT
	@IsAutoCalcLateTime     = ISNULL(MAX(LOWER(CASE WHEN Name = 'IsAutoCalcLateTime'     THEN Value END)), 'false'),
	@IsAutoCalcLateTimeOT   = ISNULL(MAX(LOWER(CASE WHEN Name = 'IsAutoCalcLateTimeOT'   THEN Value END)), 'false'),
	@IsAutoCalcEarlyTime    = ISNULL(MAX(LOWER(CASE WHEN Name = 'IsAutoCalcEarlyTime'    THEN Value END)), 'false'),
	@IsAutoCalcEarlyTimeOT  = ISNULL(MAX(LOWER(CASE WHEN Name = 'IsAutoCalcEarlyTimeOT'  THEN Value END)), 'false'),
	@LateTime = ISNULL(CAST(MAX(CASE WHEN Name = 'LateTime' THEN Value END) AS INT), 0),
	@LateTimeOT = ISNULL(CAST(MAX(CASE WHEN Name = 'LateTimeOT' THEN Value END) AS INT), 0),
	@EarlyTime = ISNULL(CAST(MAX(CASE WHEN Name = 'EarlyTime' THEN Value END) AS INT), 0),
	@EarlyTimeOT = ISNULL(CAST(MAX(CASE WHEN Name = 'EarlyTimeOT' THEN Value END) AS INT), 0)
FROM Settings
WHERE TenantId = @tenantId
  AND Name IN (
	'IsAutoCalcLateTime',
	'IsAutoCalcLateTimeOT',
	'IsAutoCalcEarlyTime',
	'IsAutoCalcEarlyTimeOT',
	'LateTime',
	'LateTimeOT',
	'EarlyTime',
	'EarlyTimeOT'
);

IF (
	@IsAutoCalcLateTime = 'true' OR
	@IsAutoCalcLateTimeOT = 'true' OR
	@IsAutoCalcEarlyTime = 'true' OR
	@IsAutoCalcEarlyTimeOT = 'true'
)
BEGIN
-- Tính lại các trường thời gian chấm công dựa vào cấu hình
	UPDATE #TempCurrentClocking
	SET
		-- Đi trễ: Đến muộn hơn StartTime + LateTime
		TimeIsLate = CASE
			WHEN @IsAutoCalcLateTime = 'true' AND Cal_CheckInDate > DATEADD(MINUTE, @LateTime, StartTime)
				THEN DATEDIFF(MINUTE, StartTime, Cal_CheckInDate) - @LateTime
			ELSE TimeIsLate
		END,

		-- Làm thêm TRƯỚC ca: Đến sớm hơn StartTime - EarlyTimeOT
		OverTimeBeforeShiftWork = CASE
			WHEN @IsAutoCalcEarlyTimeOT = 'true' AND Cal_CheckInDate < DATEADD(MINUTE, -@EarlyTimeOT, StartTime)
				THEN DATEDIFF(MINUTE, Cal_CheckInDate, StartTime) - @EarlyTimeOT
			ELSE OverTimeBeforeShiftWork
		END,

		-- Về sớm: Rời đi sớm hơn EndTime - EarlyTime
		TimeIsLeaveWorkEarly = CASE
			WHEN @IsAutoCalcEarlyTime = 'true' AND Cal_CheckOutDate < DATEADD(MINUTE, -@EarlyTime, EndTime)
				THEN DATEDIFF(MINUTE, Cal_CheckOutDate, EndTime) - @EarlyTime
			ELSE TimeIsLeaveWorkEarly
		END,

		-- Làm thêm SAU ca: Rời đi muộn hơn EndTime + LateTimeOT
		OverTimeAfterShiftWork = CASE
			WHEN @IsAutoCalcLateTimeOT = 'true'
				 AND Cal_CheckOutDate > DATEADD(MINUTE, @LateTimeOT, EndTime)
				THEN DATEDIFF(MINUTE, EndTime, Cal_CheckOutDate) - @LateTimeOT
			ELSE OverTimeAfterShiftWork
		END;
END;

INSERT INTO  [ClockingHistory]
		([Id] ,
		[ClockingId] ,
		[CheckedInDate] ,
		[CheckedOutDate] ,
		[TimeIsLate],
		[OverTimeBeforeShiftWork],
		[TimeIsLeaveWorkEarly],
		[OverTimeAfterShiftWork],
		[TenantId],
		[BranchId],
		[TimeKeepingType],
		[ClockingStatus],
		[ModifiedBy],
		[ModifiedDate],
		[CreatedBy],
		[CreatedDate],
		[ClockingHistoryStatus],
		[TimeIsLateAdjustment],
		[OverTimeBeforeShiftWorkAdjustment],
		[TimeIsLeaveWorkEarlyAdjustment],
		[OverTimeAfterShiftWorkAdjustment],
		[AbsenceType],
		[ShiftId],
		[ShiftFrom],
		[ShiftTo],
		[EmployeeId],
		[CheckTime],
		[AutoTimekeepingUid])
SELECT
		NEXT VALUE FOR [ClockingHistorySeq],
		t.Id,
		ISNULL(t.CheckInDate, t.StartTime),
		ISNULL(t.CheckOutDate, t.EndTime),
		t.TimeIsLate,
	    t.OverTimeBeforeShiftWork,
	    t.TimeIsLeaveWorkEarly,
	  t.OverTimeAfterShiftWork,
		t.TenantId,
		t.BranchId,
		6, -- cham cong tu dong theo thiet lap
		3,
		NULL,
		NULL,
		t.CreatedBy,
		GETDATE(),
		1,
		0,
		0,
		0,
		0,
		NULL,
		t.ShiftId,
		t.[From],
		t.[To],
		t.EmployeeId,
		GETDATE(),
		@autoTimekeepingUid
FROM #TempCurrentClocking  AS t

UPDATE ck
	SET ClockingStatus = 3,
	ModifiedDate = GETDATE(),
	CheckInDate = tc.Cal_CheckInDate,
	CheckOutDate = tc.Cal_CheckOutDate,
	TimeIsLate = tc.TimeIsLate,
	TimeIsLeaveWorkEarly = tc.TimeIsLeaveWorkEarly,
 	OverTimeBeforeShiftWork = tc.OverTimeBeforeShiftWork,
 	OverTimeAfterShiftWork = tc.OverTimeAfterShiftWork
FROM Clocking AS ck
INNER JOIN #TempCurrentClocking as tc ON ck.Id = tc.Id

select
	Id,
	ClockingStatus,
	ShiftId,
	TenantId,
	[EmployeeId],
	StartTime,
	EndTime,
	BranchId,
	Createdby,
	ModifiedDate,
	CheckInDate AS CheckInDate,
	CheckOutDate AS CheckOutDate
FROM #TempCurrentClocking

DROP TABLE IF EXISTS #TempCurrentClocking

END
;

GO
