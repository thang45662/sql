ALTER PROCEDURE [dbo].[pr_Auto_Keeping]
(
    @tenantId    INT,
    @startTime   DATETIME,
    @endTime   DATETIME,
    @autoTimekeepingUid   NVARCHAR,
    @JobId   BIGINT
)
AS
BEGIN
    SET NOCOUNT ON

DECLARE @returnValue NVARCHAR(MAX)
SET @returnValue = ''
DROP TABLE IF EXISTS #TempCurrentClocking

SELECT c.*,s.[From], s.[To],
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
INTO #TempCurrentClocking
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
AND e.IsDeleted <> 1

CREATE CLUSTERED INDEX IX_TempCurrentClocking_Id ON #TempCurrentClocking(Id)
CREATE NONCLUSTERED INDEX IX_TempCurrentClocking_IsUpdated ON #TempCurrentClocking(IsUpdated)

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
		t.StartTime,
		t.EndTime,
		0,
		0,
		0,
		0,
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
	SET ClockingStatus =3,
	ModifiedDate = GETDATE(),
	CheckInDate = tc.Cal_CheckInDate,
	CheckOutDate = tc.Cal_CheckOutDate
FROM Clocking AS ck
INNER JOIN #TempCurrentClocking as tc ON ck.Id = tc.Id

DECLARE @nextDate DATE = @endTime

UPDATE CronSchedule
SET IsRunning = 0,
	NextRun = dateadd(dd,1,@nextDate),
	LimitRun = dateadd(dd,2,@nextDate),
	LastSync = GETDATE(),
	Processed = (Processed + 1),
	ModifiedDate = GETDATE()
WHERE Id = @JobId

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

--SELECT * FROM Clocking AS c WHERE c.Id = 793006

GO
