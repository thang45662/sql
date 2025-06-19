BEGIN TRANSACTION;
GO
ALTER PROCEDURE CheckOutOfSyncSequences (@autoFix bit = 0) as
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

-- EXEC [pr_Booking_Delete_TrialData] 594151, 23823
ALTER PROCEDURE [dbo].[pr_Booking_Delete_TrialData]
(
    @tenantId    INT,			-- ID gian hàng
	@userId		BIGINT			-- ID tài khoản admin
)
AS
BEGIN
	-- Xóa ca làm việc
	EXEC [pr_Booking_Delete_TrialData_Shifts] @tenantId, @userId

	-- Xóa nhân viên
	EXEC [pr_Booking_Delete_TrialData_Employees] @tenantId, @userId

	-- Xóa phụ cấp
	EXEC [pr_Booking_Delete_TrialData_Allowance] @tenantId, @userId

	-- Xóa giảm trừ
	EXEC [pr_Booking_Delete_TrialData_Deduction] @tenantId, @userId

	-- Xóa mẫu lương
	EXEC [pr_Booking_Delete_TrialData_PayRateTemplate] @tenantId, @userId

	-- Xóa ca làm việc
	EXEC [pr_Booking_Delete_TrialData_TimeSheet] @tenantId,	@userId

	-- Xóa chấm công
	EXEC [pr_Booking_Delete_TrialData_Clocking] @tenantId, @userId

	-- Xóa bảng lương
	EXEC [pr_Booking_Delete_TrialData_Paysheet] @tenantId, @userId

	-- Xóa phiếu lương
	EXEC [pr_Booking_Delete_TrialData_Payslip] @tenantId, @userId

	--
	EXEC [pr_Booking_Delete_TrialData_PayslipClocking] @tenantId

	SELECT * FROM Employee WHERE TenantId = @tenantId AND IsDeleted = 0 AND UserId != @userId
END

GO

ALTER PROCEDURE [dbo].[pr_Booking_Delete_TrialData_Allowance]
(
    @tenantId	INT,			-- ID gian hàng
	@userId		BIGINT			-- ID tài khoản admin
)
AS
BEGIN
	UPDATE       Allowance
	SET                [Name] += '{DEL}', ModifiedBy = @userId, ModifiedDate = GETDATE(), Code += '{DEL}', IsDeleted = 1, DeletedDate = GETDATE(), DeletedBy = @userId
	WHERE        (TenantId = @tenantId) AND (IsDeleted = 0)
END

GO

ALTER PROCEDURE [dbo].[pr_Booking_Delete_TrialData_Clocking]
(
    @tenantId	INT,			-- ID gian hàng
	@userId	BIGINT				-- ID tài khoản admin
)
AS
BEGIN
	UPDATE       Clocking
	SET                ClockingStatus = 0, ModifiedBy = @userId, ModifiedDate = GETDATE()
	WHERE        (TenantId = @tenantId)
END

GO

ALTER PROCEDURE [dbo].[pr_Booking_Delete_TrialData_Deduction]
(
    @tenantId	INT,			-- ID gian hàng
	@userId		BIGINT			-- ID tài khoản admin
)
AS
BEGIN
	UPDATE       Deduction
	SET                [Name] += '{DEL}', ModifiedBy = @userId, ModifiedDate = GETDATE(), Code += '{DEL}', IsDeleted = 1, DeletedDate = GETDATE(), DeletedBy = @userId
	WHERE        (TenantId = @tenantId) AND (IsDeleted = 0)
END

GO

ALTER PROCEDURE [dbo].[pr_Booking_Delete_TrialData_Employees]
(
    @tenantId	INT,			-- ID gian hàng
	@userId		BIGINT			-- ID tài khoản admin
)
AS
BEGIN
	UPDATE       Employee
	SET                [Code] += '{DEL}', [Name] += '{DEL}', ModifiedBy = @userId, ModifiedDate = GETDATE(), IsDeleted = 1, DeletedBy = @userId, DeletedDate = GETDATE()
	WHERE        (TenantId = @tenantId) AND (IsDeleted = 0) AND (UserId <> @userId OR UserId IS NULL)
END

GO

ALTER PROCEDURE [dbo].[pr_Booking_Delete_TrialData_PayRateTemplate]
(
    @tenantId	INT,		-- ID gian hàng
	@userId		BIGINT		-- ID tài khoản admin
)
AS
BEGIN
	UPDATE       PayRateTemplate
	SET                [Name] += '{DEL}', ModifiedBy = @userId, ModifiedDate = GETDATE(), [Status] = 1
	WHERE        (TenantId = @tenantId) AND [Status] = 0
END

GO

ALTER PROCEDURE [dbo].[pr_Booking_Delete_TrialData_Paysheet]
(
    @tenantId	INT,			-- ID gian hàng
	@userId	BIGINT				-- ID tài khoản admin
)
AS
BEGIN
	UPDATE       Paysheet
	SET                PaysheetStatus = 0, ModifiedBy = @userId, ModifiedDate = GETDATE()
	WHERE        (TenantId = @tenantId) AND PaysheetStatus != 0
END

GO

ALTER PROCEDURE [dbo].[pr_Booking_Delete_TrialData_Payslip]
(
    @tenantId	INT,			-- ID gian hàng
	@userId	BIGINT				-- ID tài khoản admin
)
AS
BEGIN
	UPDATE       Payslip
	SET                PayslipStatus = 0, ModifiedBy = @userId, ModifiedDate = GETDATE()
	WHERE        (TenantId = @tenantId)
END

GO

ALTER PROCEDURE [dbo].[pr_Booking_Delete_TrialData_PayslipClocking]
(
    @tenantId	INT			-- ID gian hàng
)
AS
BEGIN
	DELETE FROM PayslipClocking
	WHERE        ClockingId IN (SELECT Id FROM Clocking WHERE TenantId = @tenantId)
END

GO

ALTER PROCEDURE [dbo].[pr_Booking_Delete_TrialData_Shifts]
(
    @tenantId	INT,		-- ID gian hàng
	@userId		BIGINT		-- ID tài khoản admin
)
AS
BEGIN
	UPDATE       [Shift]
	SET                IsDeleted = 1, DeletedBy = @userId, DeletedDate = GETDATE(), ModifiedBy = @userId, ModifiedDate = GETDATE()
	WHERE        (TenantId = @tenantId) AND (IsDeleted = 0)
END

GO

ALTER PROCEDURE [dbo].[pr_Booking_Delete_TrialData_TimeSheet]
(
    @tenantId	INT,			-- ID gian hàng
	@userId	BIGINT				-- ID tài khoản admin
)
AS
BEGIN
	UPDATE       TimeSheet
	SET                ModifiedBy = @userId, ModifiedDate = GETDATE(), IsDeleted = 1, DeletedBy = @userId, DeletedDate = GETDATE(), TimeSheetStatus = 0
	WHERE        (TenantId = @tenantId)
END

GO

ALTER PROCEDURE [dbo].[pr_Booking_Insert_SampleData]
(
    @tenantId			INT,			-- ID gian hàng
	@userIdAdmin		BIGINT,			-- ID tài khoản admin
    @language			NVARCHAR(50)	-- ngôn ngữ (en-US/vi-VN)
)
AS
BEGIN
    SET NOCOUNT ON
	-- tạo phòng ban
	EXEC [pr_Booking_Insert_Sample_Department] @tenantId, @userIdAdmin, @language
	-- tạo chức danh
	EXEC [pr_Booking_Insert_SampleData_JobTitles] @tenantId, @userIdAdmin, @language
END

GO

ALTER PROCEDURE [dbo].[pr_Booking_Insert_SampleData_JobTitles]
(
    @tenantId   INT,            -- ID gian hàng
    @userId     BIGINT,         -- ID tài khoản admin
    @language   NVARCHAR(50)    -- ngôn ngữ (en-US/vi-VN)
)
AS
BEGIN
    IF @language = 'en-US'
    BEGIN
        INSERT INTO JobTitle (
            Id, [Name], Description, IsActive, TenantId, CreatedBy, CreatedDate,
            ModifiedBy, ModifiedDate, IsDeleted, DeletedBy, DeletedDate
        )
        VALUES
            (NEXT VALUE FOR JobTitleSeq, N'Sales Staff','', 1, @tenantId, @userId, GETDATE(), NULL, NULL, 0, NULL, NULL),
            (NEXT VALUE FOR JobTitleSeq, N'Service Staff','', 1, @tenantId, @userId, GETDATE(), NULL, NULL, 0, NULL, NULL),
            (NEXT VALUE FOR JobTitleSeq, N'Accountant','', 1, @tenantId, @userId, GETDATE(), NULL, NULL, 0, NULL, NULL),
            (NEXT VALUE FOR JobTitleSeq, N'Cashier','', 1, @tenantId, @userId, GETDATE(), NULL, NULL, 0, NULL, NULL),
            (NEXT VALUE FOR JobTitleSeq, N'Manager','', 1, @tenantId, @userId, GETDATE(), NULL, NULL, 0, NULL, NULL)
    END
    ELSE
    BEGIN
        INSERT INTO JobTitle (
            Id, [Name], Description, IsActive, TenantId, CreatedBy, CreatedDate,
            ModifiedBy, ModifiedDate, IsDeleted, DeletedBy, DeletedDate
        )
        VALUES
            (NEXT VALUE FOR JobTitleSeq, N'Nhân viên bán hàng','', 1, @tenantId, @userId, GETDATE(), NULL, NULL, 0, NULL, NULL),
            (NEXT VALUE FOR JobTitleSeq, N'Nhân viên làm dịch vụ','', 1, @tenantId, @userId, GETDATE(), NULL, NULL, 0, NULL, NULL),
            (NEXT VALUE FOR JobTitleSeq, N'Kế toán','', 1, @tenantId, @userId, GETDATE(), NULL, NULL, 0, NULL, NULL),
            (NEXT VALUE FOR JobTitleSeq, N'Thu ngân','', 1, @tenantId, @userId, GETDATE(), NULL, NULL, 0, NULL, NULL),
            (NEXT VALUE FOR JobTitleSeq, N'Quản lý','', 1, @tenantId, @userId, GETDATE(), NULL, NULL, 0, NULL, NULL)
    END
END

GO

ALTER PROCEDURE [dbo].[pr_Booking_Insert_Sample_Department]
(
    @tenantId	INT,			-- ID gian hàng
	@userId		BIGINT,			-- ID tài khoản admin
    @language	NVARCHAR(50)	-- ngôn ngữ (en-US/vi-VN)
)
AS
BEGIN
    IF @language = 'en-US'
    BEGIN
        INSERT INTO Department(
            Id, [Name], Description, IsActive, TenantId, CreatedBy, CreatedDate,
            ModifiedBy, ModifiedDate, IsDeleted, DeletedBy, DeletedDate
        )
        VALUES
        (NEXT VALUE FOR DepartmentSeq, N'Business','', 1, @tenantId,@userId, GETDATE(), NULL, NULL, 0, NULL, NULL),
            (NEXT VALUE FOR DepartmentSeq, N'Accounting','', 1, @tenantId,@userId, GETDATE(), NULL, NULL, 0, NULL, NULL),
            (NEXT VALUE FOR DepartmentSeq, N'Cashier','', 1, @tenantId,@userId, GETDATE(), NULL, NULL, 0, NULL, NULL),
            (NEXT VALUE FOR DepartmentSeq, N'Management','', 1, @tenantId,@userId, GETDATE(), NULL, NULL, 0, NULL, NULL)
    END
    ELSE
    BEGIN
        INSERT INTO Department(
            Id, [Name], Description, IsActive, TenantId, CreatedBy, CreatedDate,
            ModifiedBy, ModifiedDate, IsDeleted, DeletedBy, DeletedDate
        )
        VALUES
            (NEXT VALUE FOR DepartmentSeq, N'Kinh doanh','', 1, @tenantId,@userId, GETDATE(), NULL, NULL, 0, NULL, NULL),
            (NEXT VALUE FOR DepartmentSeq, N'Kế toán','', 1, @tenantId,@userId, GETDATE(), NULL, NULL, 0, NULL, NULL),
            (NEXT VALUE FOR DepartmentSeq, N'Thu ngân ','', 1, @tenantId,@userId, GETDATE(), NULL, NULL, 0, NULL, NULL),
            (NEXT VALUE FOR DepartmentSeq, N'Quản lý','', 1, @tenantId,@userId, GETDATE(), NULL, NULL, 0, NULL, NULL)
    END
END

GO

-- ========================
-- File: pr_Booking_Insert_TrialData.sql
-- ========================
ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData]
(
    @tenantId			INT,			-- ID gian hàng
	@branchId			INT,			-- ID chi nhánh
	@userIdAdmin		BIGINT,			-- ID tài khoản admin
	@userId1			BIGINT,			-- ID tài khoản nhân viên 1
	@userId2			BIGINT,			-- ID tài khoản nhân viên 2
	@commissionId		BIGINT,			-- ID bảng hoa hồng
	@useNewTimeSheet	BIT,			-- Gian hàng dùng Lịch làm việc 1.0/2.0
	@language			NVARCHAR(50)= N'vi-VN'	-- Ngôn ngữ
)
AS
BEGIN
    SET NOCOUNT ON

	DECLARE @shiftId1 BIGINT
	DECLARE @shiftId2 BIGINT
	DECLARE @employeeId1 BIGINT
	DECLARE @employeeId2 BIGINT
	DECLARE @allowanceId BIGINT
	DECLARE @deductionId BIGINT
	DECLARE @payRateTemplateId BIGINT
	DECLARE @payRateId1 BIGINT
	DECLARE @payRateId2 BIGINT
	DECLARE @timeSheetId1 BIGINT
	DECLARE @timeSheetId2 BIGINT
	DECLARE @paysheetId BIGINT
	DECLARE @payslipId1 BIGINT
	DECLARE @payslipId2 BIGINT
	DECLARE @prevTimeSheetId1 BIGINT
	DECLARE @prevTimeSheetId2 BIGINT
	DECLARE @paysheetIdPrev BIGINT
	DECLARE @payslipIdPrev1 BIGINT
	DECLARE @payslipIdPrev2 BIGINT

	DECLARE @workingDays1 INT			-- Số ngày công tháng hiện tại nhân viên 1
	DECLARE @workingDays2 INT			-- Số ngày công tháng hiện tại nhân viên 2
	DECLARE @workingDaysPrev1 INT		-- Số ngày công tháng trước nhân viên 1
	DECLARE @workingDaysPrev2 INT		-- Số ngày công tháng trước nhân viên 2

	-- Tạo ca làm việc
	EXEC [pr_Booking_Insert_TrialData_Shifts] @tenantId, @branchId, @userIdAdmin, @language, @shiftId1 OUTPUT, @shiftId2 OUTPUT

	-- Tạo nhân viên
	EXEC [pr_Booking_Insert_TrialData_Employees] @tenantId, @branchId, @userIdAdmin, @userId1, @userId2, @employeeId1 OUTPUT, @employeeId2 OUTPUT, @language

	-- tạo phụ cấp
	EXEC [pr_Booking_Insert_TrialData_Allowance] @tenantId, @userIdAdmin, @language, @allowanceId OUTPUT

	-- tạo giảm trừ
	EXEC [pr_Booking_Insert_TrialData_Deduction] @tenantId, @userIdAdmin, @language, @deductionId OUTPUT

	-- tạo mẫu lương
	EXEC [pr_Booking_Insert_TrialData_PayRateTemplate] @tenantId, @branchId, @userIdAdmin, @language, @payRateTemplateId OUTPUT
	EXEC [pr_Booking_Insert_TrialData_PayRateTemplateDetail] @tenantId, @userIdAdmin, @payRateTemplateId, @commissionId, @allowanceId, @deductionId

	-- tạo thiết lập lương
	EXEC [pr_Booking_Insert_TrialData_PayRate]  @tenantId, @userIdAdmin, @payRateTemplateId, @employeeId1, @employeeId2, @payRateId1 OUTPUT, @payRateId2 OUTPUT
	EXEC [pr_Booking_Insert_TrialData_PayRateDetail] @tenantId,	@commissionId, @allowanceId, @deductionId, @payRateId1, @payRateId2, @employeeId1, @employeeId2

	-- tạo ca làm việc
	DECLARE @monday DATETIME
	DECLARE @sunday DATETIME
	SET @monday = (SELECT CAST(CONVERT(CHAR(8), DATEADD(dd, 0 - (@@DATEFIRST + 5 + DATEPART(dw, GETDATE())) % 7, GETDATE()), 112) + ' 00:00:00.00' AS datetime))
	SET @sunday = (SELECT CAST(CONVERT(CHAR(8), DATEADD(dd, 6 - (@@DATEFIRST + 5 + DATEPART(dw, GETDATE())) % 7, GETDATE()), 112) + ' 23:59:59.00' AS datetime))

	DECLARE @startDate DATETIME
	DECLARE @endDate DATETIME
	SET @startDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)
	SET @endDate = (SELECT CAST(CONVERT(CHAR(8), GETDATE() - 1, 112) + ' 23:59:59.00' AS datetime))

	-- Tạo TimeSheet đồng bộ
	EXEC [pr_Booking_Insert_TrialData_TimeSheet]
		@tenantId,	@branchId, @userIdAdmin, @employeeId1, @employeeId2, @startDate, @endDate, @useNewTimeSheet, @monday, @sunday,
		@timeSheetId1 OUTPUT, @timeSheetId2 OUTPUT, @prevTimeSheetId1 OUTPUT, @prevTimeSheetId2 OUTPUT

	--Tạo TimeSheetShift và lấy số ngày công
	EXEC [pr_Booking_Insert_TrialData_TimeSheetShift]
		@shiftId1, @shiftId2, @timeSheetId1, @timeSheetId2, @prevTimeSheetId1, @prevTimeSheetId2, @useNewTimeSheet,
		@workingDays1 OUTPUT, @workingDays2 OUTPUT, @workingDaysPrev1 OUTPUT, @workingDaysPrev2 OUTPUT

	--Tạo chấm công
	EXEC [pr_Booking_Insert_TrialData_Clocking]
		@tenantId, @branchId, @userIdAdmin, @employeeId1, @employeeId2, @startDate, @endDate, @shiftId1, @shiftId2, @timeSheetId1, @timeSheetId2,
		@useNewTimeSheet, @monday, @sunday, @prevTimeSheetId1, @prevTimeSheetId2

	--Tạo bảng lương đồng bộ với TimeSheet
	EXEC [pr_Booking_Insert_TrialData_Paysheet]
		@tenantId,	@branchId, @userIdAdmin, @startDate, @language,
		@paysheetId OUTPUT, @paysheetIdPrev OUTPUT

	--Tạo phiếu lương với số ngày công chính xác
	EXEC [pr_Booking_Insert_TrialData_Payslip]
		@tenantId, @branchId, @userIdAdmin, @employeeId1, @employeeId2, @paysheetId, @paysheetIdPrev, @workingDays1, @workingDays2, @workingDaysPrev1, @workingDaysPrev2,
		@payslipId1 OUTPUT, @payslipId2 OUTPUT, @payslipIdPrev1 OUTPUT, @payslipIdPrev2 OUTPUT

	--Tạo PayslipClocking
	EXEC [pr_Booking_Insert_TrialData_PayslipClocking]
		@tenantId, @userIdAdmin, @employeeId1, @employeeId2, @payslipId1, @payslipId2

	--Tạo chi tiết phiếu lương đồng bộ hoàn toàn
	EXEC [pr_Booking_Insert_TrialData_PayslipDetail]
		@tenantId, @userIdAdmin, @employeeId1, @employeeId2, @payslipId1, @payslipId2, @payslipIdPrev1, @payslipIdPrev2,
		@allowanceId, @deductionId, @workingDays1, @workingDays2, @workingDaysPrev1, @workingDaysPrev2,@shiftId1, @shiftId2

	SELECT * FROM Employee WHERE TenantId = @tenantId AND IsDeleted = 0 AND UserId != @userIdAdmin
END

GO

ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_Allowance]
(
    @tenantId	INT,			-- ID gian hàng
	@userId		BIGINT,			-- ID tài khoản admin
    @language	NVARCHAR(50),	-- Ngôn ngữ
	@allowanceId	BIGINT OUTPUT
)
AS
BEGIN
    IF (@language = 'en-US')
    BEGIN
	    SET @allowanceId = NEXT VALUE FOR AllowanceSeq

	    INSERT INTO Allowance (Id, [Name], CreatedBy, CreatedDate, TenantId, Code, IsDeleted, [Value], ValueRatio, [Type], IsChecked, [Rank], test)
	    VALUES        (@allowanceId, N'Food & Beverage', @userId, GETDATE(), @tenantId, 'PC000001', 0, 50000, 0, 1, 1, 0, 0)
    END
    ELSE
    BEGIN
	    SET @allowanceId = NEXT VALUE FOR AllowanceSeq
	    INSERT INTO Allowance (Id, [Name], CreatedBy, CreatedDate, TenantId, Code, IsDeleted, [Value], ValueRatio, [Type], IsChecked, [Rank], test)
	    VALUES        (@allowanceId, N'Ăn uống', @userId, GETDATE(), @tenantId, 'PC000001', 0, 50000, 0, 1, 1, 0, 0)
    END
END

GO

-- ========================
-- File: pr_Booking_Insert_TrialData_Clocking.sql
-- ========================
ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_Clocking]
(
    @tenantId			INT,				-- ID gian hàng
	@branchId			INT,				-- ID chi nhánh
	@userId				BIGINT,				-- ID tài khoản admin
	@employeeId1		BIGINT,				-- ID nhân viên 1
	@employeeId2		BIGINT,				-- ID nhân viên 2
	@startDate			DATETIME,			-- Ngày bắt đầu tháng hiện tại (ví dụ: 2024-12-01)
	@endDate			DATETIME,			-- Ngày kết thúc tháng hiện tại (ví dụ: 2024-12-17)
	@shiftId1			BIGINT,				-- ID ca 1
	@shiftId2			BIGINT,				-- ID ca 2
	@timeSheetId1		BIGINT,				-- ID lịch làm việc tháng hiện tại ca 1
	@timeSheetId2		BIGINT,				-- ID lịch làm việc tháng hiện tại ca 2
	@useNewTimeSheet	BIT,				-- Gian hàng dùng Lịch làm việc 1.0/2.0
	@monday				DATETIME,			-- Thứ 2 của tuần hiện tại
	@sunday				DATETIME,			-- Chủ nhật của tuần hiện tại
	@prevTimeSheetId1	BIGINT,				-- ID lịch làm việc tháng trước ca 1 (tuần đầu tiên nếu là 2.0)
	@prevTimeSheetId2	BIGINT				-- ID lịch làm việc tháng trước ca 2 (tuần đầu tiên nếu là 2.0)
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @clockingStartDate DATETIME
	DECLARE @clockingEndDate DATETIME
	DECLARE @startDateCaSang DATETIME
	DECLARE @startDateCaSangDiTre DATETIME
	DECLARE @startDateCaChieu DATETIME
	DECLARE @startDateCaChieuDiTre DATETIME
	DECLARE @endDateCaSang DATETIME
	DECLARE @endDateCaChieu DATETIME
	DECLARE @clockingId BIGINT
	DECLARE @clockingHistoryId BIGINT

	-- Xác định khoảng thời gian cho tháng hiện tại
	IF @useNewTimeSheet = 1
	BEGIN
		SET @clockingStartDate = @monday
		SET @clockingEndDate = @sunday
	END
	ELSE
	BEGIN
		SET @clockingStartDate = @startDate
		SET @clockingEndDate = @endDate
	END

	-- Tính tổng số ngày trong khoảng thời gian hiện tại để lặp
	DECLARE @totalDaysCurrentPeriod INT = DATEDIFF(DAY, @clockingStartDate, @clockingEndDate) + 1;
	DECLARE @currentLoopDate DATETIME = @clockingStartDate;
	DECLARE @dayCounter INT = 0;

	-- =====================================================
	-- 1. TẠO CLOCKING CHO THÁNG HIỆN TẠI
	-- =====================================================

	-- Insert đi trễ ca sáng lần 1 (Ngày đầu tiên của khoảng hiện tại)
	SET @clockingId = NEXT VALUE FOR ClockingSeq
	SET @startDateCaSang = (SELECT CAST(CONVERT(CHAR(8), @currentLoopDate, 112) + ' 09:00:00' AS datetime))
	SET @startDateCaSangDiTre = (SELECT CAST(CONVERT(CHAR(8), @currentLoopDate, 112) + ' 09:15:00' AS datetime))
	SET @endDateCaSang = (SELECT CAST(CONVERT(CHAR(8), @currentLoopDate, 112) + ' 15:00:00' AS datetime))
	INSERT INTO Clocking (Id, TimeSheetId, ShiftId, EmployeeId, WorkById, ClockingStatus, StartTime, EndTime, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted, CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork,  ClockingPaymentStatus)
	VALUES        (@clockingId, @timeSheetId1, @shiftId1, @employeeId1, @employeeId1, 3, @startDateCaSang, @endDateCaSang, @tenantId, @branchId, @userId, GETDATE(), 0, @startDateCaSangDiTre, @endDateCaSang, 15, 0, 0, 0, 0)

	SET @clockingHistoryId = NEXT VALUE FOR ClockingHistorySeq
	INSERT INTO ClockingHistory (Id, ClockingId, CheckedInDate, CheckedOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, TenantId, BranchId, TimeKeepingType, ClockingStatus, CreatedBy, CreatedDate, ClockingHistoryStatus, TimeIsLateAdjustment, OverTimeBeforeShiftWorkAdjustment, TimeIsLeaveWorkEarlyAdjustment, OverTimeAfterShiftWorkAdjustment, ShiftId, ShiftFrom, ShiftTo, EmployeeId, CheckTime)
	VALUES        (@clockingHistoryId, @clockingId, @startDateCaSangDiTre, @endDateCaSang, 15, 0, 0, 0, @tenantId, @branchId, 1, 3, @userId, GETDATE(), 1, 0, 0, 0, 0, @shiftId1, 540, 900, @employeeId1, GETDATE())

	-- Insert đi trễ ca chiều lần 1 (Ngày đầu tiên của khoảng hiện tại)
	SET @startDateCaChieu = (SELECT CAST(CONVERT(CHAR(8), @currentLoopDate, 112) + ' 15:00:00' AS datetime))
	SET @startDateCaChieuDiTre = (SELECT CAST(CONVERT(CHAR(8), @currentLoopDate, 112) + ' 15:15:00' AS datetime))
	SET @endDateCaChieu = (SELECT CAST(CONVERT(CHAR(8), @currentLoopDate, 112) + ' 22:30:00' AS datetime))
	SET @clockingId = NEXT VALUE FOR ClockingSeq
	INSERT INTO Clocking (Id, TimeSheetId, ShiftId, EmployeeId, WorkById, ClockingStatus, StartTime, EndTime, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted, CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork,  ClockingPaymentStatus)
	VALUES        (@clockingId, @timeSheetId2, @shiftId2, @employeeId2, @employeeId2, 3, @startDateCaChieu, @endDateCaChieu, @tenantId, @branchId, @userId, GETDATE(), 0, @startDateCaChieuDiTre, @endDateCaChieu, 15, 0, 0, 0, 0)

	SET @clockingHistoryId = NEXT VALUE FOR ClockingHistorySeq
	INSERT INTO ClockingHistory (Id, ClockingId, CheckedInDate, CheckedOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, TenantId, BranchId, TimeKeepingType, ClockingStatus, CreatedBy, CreatedDate, ClockingHistoryStatus, TimeIsLateAdjustment, OverTimeBeforeShiftWorkAdjustment, TimeIsLeaveWorkEarlyAdjustment, OverTimeAfterShiftWorkAdjustment, ShiftId, ShiftFrom, ShiftTo, EmployeeId, CheckTime)
	VALUES        (@clockingHistoryId, @clockingId, @startDateCaChieuDiTre, @endDateCaChieu, 15, 0, 0, 0, @tenantId, @branchId, 1, 3, @userId, GETDATE(), 1, 0, 0, 0, 0, @shiftId2, 900, 1350, @employeeId2, GETDATE()) -- ✅ SỬA: employeeId2

	SET @currentLoopDate = DATEADD(DAY, 1, @currentLoopDate); -- Chuyển sang ngày thứ 2
	SET @dayCounter = @dayCounter + 1;

	-- Insert đi trễ ca sáng lần 2 (Ngày thứ 2 của khoảng hiện tại)
	SET @clockingId = NEXT VALUE FOR ClockingSeq
	SET @startDateCaSang = (SELECT CAST(CONVERT(CHAR(8), @currentLoopDate, 112) + ' 09:00:00' AS datetime))
	SET @startDateCaSangDiTre = (SELECT CAST(CONVERT(CHAR(8), @currentLoopDate, 112) + ' 09:15:00' AS datetime))
	SET @endDateCaSang = (SELECT CAST(CONVERT(CHAR(8), @currentLoopDate, 112) + ' 15:00:00' AS datetime))
	INSERT INTO Clocking (Id, TimeSheetId, ShiftId, EmployeeId, WorkById, ClockingStatus, StartTime, EndTime, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted, CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork,  ClockingPaymentStatus)
	VALUES        (@clockingId, @timeSheetId1, @shiftId1, @employeeId1, @employeeId1, 3, @startDateCaSang, @endDateCaSang, @tenantId, @branchId, @userId, GETDATE(), 0, @startDateCaSangDiTre, @endDateCaSang, 15, 0, 0, 0, 0)

	SET @clockingHistoryId = NEXT VALUE FOR ClockingHistorySeq
	INSERT INTO ClockingHistory (Id, ClockingId, CheckedInDate, CheckedOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, TenantId, BranchId, TimeKeepingType, ClockingStatus, CreatedBy, CreatedDate, ClockingHistoryStatus, TimeIsLateAdjustment, OverTimeBeforeShiftWorkAdjustment, TimeIsLeaveWorkEarlyAdjustment, OverTimeAfterShiftWorkAdjustment, ShiftId, ShiftFrom, ShiftTo, EmployeeId, CheckTime)
	VALUES        (@clockingHistoryId, @clockingId, @startDateCaSangDiTre, @endDateCaSang, 15, 0, 0, 0, @tenantId, @branchId, 1, 3, @userId, GETDATE(), 1, 0, 0, 0, 0, @shiftId1, 540, 900, @employeeId1, GETDATE())

	IF @useNewTimeSheet = 0 -- Logic cũ cho TimeSheet 1.0
	BEGIN
		-- Insert đi trễ ca chiều lần 2 (Ngày thứ 2 của khoảng hiện tại)
		SET @startDateCaChieu = (SELECT CAST(CONVERT(CHAR(8), @currentLoopDate, 112) + ' 15:00:00' AS datetime))
		SET @startDateCaChieuDiTre = (SELECT CAST(CONVERT(CHAR(8), @currentLoopDate, 112) + ' 15:15:00' AS datetime))
		SET @endDateCaChieu = (SELECT CAST(CONVERT(CHAR(8), @currentLoopDate, 112) + ' 22:30:00' AS datetime))
		SET @clockingId = NEXT VALUE FOR ClockingSeq
		INSERT INTO Clocking (Id, TimeSheetId, ShiftId, EmployeeId, WorkById, ClockingStatus, StartTime, EndTime, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted, CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork,  ClockingPaymentStatus)
		VALUES        (@clockingId, @timeSheetId2, @shiftId2, @employeeId2, @employeeId2, 3, @startDateCaChieu, @endDateCaChieu, @tenantId, @branchId, @userId, GETDATE(), 0, @startDateCaChieuDiTre, @endDateCaChieu, 15, 0, 0, 0, 0)

		SET @clockingHistoryId = NEXT VALUE FOR ClockingHistorySeq
		INSERT INTO ClockingHistory (Id, ClockingId, CheckedInDate, CheckedOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, TenantId, BranchId, TimeKeepingType, ClockingStatus, CreatedBy, CreatedDate, ClockingHistoryStatus, TimeIsLateAdjustment, OverTimeBeforeShiftWorkAdjustment, TimeIsLeaveWorkEarlyAdjustment, OverTimeAfterShiftWorkAdjustment, ShiftId, ShiftFrom, ShiftTo, EmployeeId, CheckTime)
		VALUES        (@clockingHistoryId, @clockingId, @startDateCaChieuDiTre, @endDateCaChieu, 15, 0, 0, 0, @tenantId, @branchId, 1, 3, @userId, GETDATE(), 1, 0, 0, 0, 0, @shiftId2, 900, 1350, @employeeId2, GETDATE()) -- ✅ SỬA: employeeId2
	END

	SET @currentLoopDate = DATEADD(DAY, 1, @currentLoopDate); -- Chuyển sang ngày thứ 3
	SET @dayCounter = @dayCounter + 1;

	-- Loop cho các ngày còn lại của tháng hiện tại (từ ngày thứ 3 trở đi)
	WHILE @dayCounter < @totalDaysCurrentPeriod
	BEGIN
		-- Insert ca sáng (nhân viên 1)
		SET @startDateCaSang = (SELECT CAST(CONVERT(CHAR(8), @currentLoopDate, 112) + ' 09:00:00' AS datetime))
		SET @endDateCaSang = (SELECT CAST(CONVERT(CHAR(8), @currentLoopDate, 112) + ' 15:00:00' AS datetime))
		SET @clockingId = NEXT VALUE FOR ClockingSeq
		INSERT INTO Clocking (Id, TimeSheetId, ShiftId, EmployeeId, WorkById, ClockingStatus, StartTime, EndTime, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted, CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork,  ClockingPaymentStatus)
		VALUES        (@clockingId, @timeSheetId1, @shiftId1, @employeeId1, @employeeId1, 3, @startDateCaSang, @endDateCaSang, @tenantId, @branchId, @userId, GETDATE(), 0, @startDateCaSang, @endDateCaSang, 0, 0, 0, 0, 0)

		SET @clockingHistoryId = NEXT VALUE FOR ClockingHistorySeq
		INSERT INTO ClockingHistory (Id, ClockingId, CheckedInDate, CheckedOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, TenantId, BranchId, TimeKeepingType, ClockingStatus, CreatedBy, CreatedDate, ClockingHistoryStatus, TimeIsLateAdjustment, OverTimeBeforeShiftWorkAdjustment, TimeIsLeaveWorkEarlyAdjustment, OverTimeAfterShiftWorkAdjustment, ShiftId, ShiftFrom, ShiftTo, EmployeeId, CheckTime)
		VALUES        (@clockingHistoryId, @clockingId, @startDateCaSang, @endDateCaSang, 0, 0, 0, 0, @tenantId, @branchId, 1, 3, @userId, GETDATE(), 1, 0, 0, 0, 0, @shiftId1, 540, 900, @employeeId1, GETDATE())

		-- Insert ca chiều (nhân viên 2)
		IF (@useNewTimeSheet = 0 OR (@useNewTimeSheet = 1 AND @dayCounter % 2 = 1)) --Cho TimeSheet 1.0 hoặc ngày lẻ cho 2.0
		BEGIN
			SET @startDateCaChieu = (SELECT CAST(CONVERT(CHAR(8), @currentLoopDate, 112) + ' 15:00:00' AS datetime))
			SET @endDateCaChieu = (SELECT CAST(CONVERT(CHAR(8), @currentLoopDate, 112) + ' 22:30:00' AS datetime))
			SET @clockingId = NEXT VALUE FOR ClockingSeq
			INSERT INTO Clocking (Id, TimeSheetId, ShiftId, EmployeeId, WorkById, ClockingStatus, StartTime, EndTime, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted,  CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork,  ClockingPaymentStatus)
			VALUES        (@clockingId, @timeSheetId2, @shiftId2, @employeeId2, @employeeId2, 3, @startDateCaChieu, @endDateCaChieu, @tenantId, @branchId, @userId, GETDATE(), 0, @startDateCaChieu, @endDateCaChieu, 0, 0, 0, 0, 0)

			SET @clockingHistoryId = NEXT VALUE FOR ClockingHistorySeq
			INSERT INTO ClockingHistory (Id, ClockingId, CheckedInDate, CheckedOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, TenantId, BranchId, TimeKeepingType, ClockingStatus, CreatedBy, CreatedDate, ClockingHistoryStatus, TimeIsLateAdjustment, OverTimeBeforeShiftWorkAdjustment, TimeIsLeaveWorkEarlyAdjustment, OverTimeAfterShiftWorkAdjustment, ShiftId, ShiftFrom, ShiftTo, EmployeeId, CheckTime)
			VALUES        (@clockingHistoryId, @clockingId, @startDateCaChieu, @endDateCaChieu, 0, 0, 0, 0, @tenantId, @branchId, 1, 3, @userId, GETDATE(), 1, 0, 0, 0, 0, @shiftId2, 900, 1350, @employeeId2, GETDATE()) -- ✅ SỬA: employeeId2
		END

		SET @currentLoopDate = DATEADD(DAY, 1, @currentLoopDate)
		SET @dayCounter = @dayCounter + 1
	END

	-- =====================================================
	-- 2. TẠO CLOCKING CHO THÁNG TRƯỚC (FULL THÁNG THEO CA LÀM VIỆC)
	-- =====================================================
	DECLARE @prevMonthStartDate DATETIME = DATEADD(MONTH, -1, DATEADD(DAY, 1 - DAY(GETDATE()), GETDATE())); -- Ngày đầu tiên của tháng trước
	DECLARE @prevMonthEndDate DATETIME = EOMONTH(DATEADD(MONTH, -1, GETDATE())); -- Ngày cuối cùng của tháng trước

	-- Lấy RepeatDaysOfWeek từ TimeSheetShift cho ca 1 và ca 2 (tháng trước)
	-- TimeSheetShift cho tháng trước đã được tạo và có RepeatDaysOfWeek tương ứng
	DECLARE @repeatDaysOfWeek1_Prev NVARCHAR(500);
	DECLARE @repeatDaysOfWeek2_Prev NVARCHAR(500);

	-- Lấy RepeatDaysOfWeek cho NV1 (ca 1) từ TimeSheetShift của tháng trước
	SELECT TOP 1 @repeatDaysOfWeek1_Prev = RepeatDaysOfWeek
	FROM TimeSheetShift
	WHERE TimeSheetId = @prevTimeSheetId1 AND ShiftIds = @shiftId1;

	-- Lấy RepeatDaysOfWeek cho NV2 (ca 2) từ TimeSheetShift của tháng trước
	SELECT TOP 1 @repeatDaysOfWeek2_Prev = RepeatDaysOfWeek
	FROM TimeSheetShift
	WHERE TimeSheetId = @prevTimeSheetId2 AND ShiftIds = @shiftId2;

	-- Nếu không tìm thấy, dùng giá trị mặc định (hoặc giá trị từ tháng hiện tại nếu hợp lý)
	IF @repeatDaysOfWeek1_Prev IS NULL AND @useNewTimeSheet = 1 SET @repeatDaysOfWeek1_Prev = '1,2,3,4,5,6';
	IF @repeatDaysOfWeek2_Prev IS NULL AND @useNewTimeSheet = 1 SET @repeatDaysOfWeek2_Prev = '1,3,5';

	-- Nếu là TimeSheet 1.0, RepeatDaysOfWeek sẽ là NULL, cần logic khác
	IF @useNewTimeSheet = 0
	BEGIN
		-- TimeSheet 1.0: Giả định NV1 làm tất cả các ngày, NV2 làm ngày lẻ
		-- Logic này sẽ tạo clocking cho tất cả các ngày trong tháng trước
		DECLARE @prevLoopDate DATETIME = @prevMonthStartDate;
		DECLARE @prevDayCounter INT = 0;
		WHILE @prevLoopDate <= @prevMonthEndDate
		BEGIN
			-- Insert ca sáng cho NV1
			SET @startDateCaSang = (SELECT CAST(CONVERT(CHAR(8), @prevLoopDate, 112) + ' 09:00:00' AS datetime))
			SET @endDateCaSang = (SELECT CAST(CONVERT(CHAR(8), @prevLoopDate, 112) + ' 15:00:00' AS datetime))
			SET @clockingId = NEXT VALUE FOR ClockingSeq
			INSERT INTO Clocking (Id, TimeSheetId, ShiftId, EmployeeId, WorkById, ClockingStatus, StartTime, EndTime, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted, CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork,  ClockingPaymentStatus)
			VALUES        (@clockingId, @prevTimeSheetId1, @shiftId1, @employeeId1, @employeeId1, 3, @startDateCaSang, @endDateCaSang, @tenantId, @branchId, @userId, GETDATE(), 0, @startDateCaSang, @endDateCaSang, 0, 0, 0, 0, 0)

			SET @clockingHistoryId = NEXT VALUE FOR ClockingHistorySeq
			INSERT INTO ClockingHistory (Id, ClockingId, CheckedInDate, CheckedOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, TenantId, BranchId, TimeKeepingType, ClockingStatus, CreatedBy, CreatedDate, ClockingHistoryStatus, TimeIsLateAdjustment, OverTimeBeforeShiftWorkAdjustment, TimeIsLeaveWorkEarlyAdjustment, OverTimeAfterShiftWorkAdjustment, ShiftId, ShiftFrom, ShiftTo, EmployeeId, CheckTime)
			VALUES        (@clockingHistoryId, @clockingId, @startDateCaSang, @endDateCaSang, 0, 0, 0, 0, @tenantId, @branchId, 1, 3, @userId, GETDATE(), 1, 0, 0, 0, 0, @shiftId1, 540, 900, @employeeId1, GETDATE())

			-- Insert ca chiều cho NV2 (ngày lẻ)
			IF @prevDayCounter % 2 = 0 -- Ngày đầu tiên là 0, ngày thứ 2 là 1, v.v.
			BEGIN
				SET @startDateCaChieu = (SELECT CAST(CONVERT(CHAR(8), @prevLoopDate, 112) + ' 15:00:00' AS datetime))
				SET @endDateCaChieu = (SELECT CAST(CONVERT(CHAR(8), @prevLoopDate, 112) + ' 22:30:00' AS datetime))
				SET @clockingId = NEXT VALUE FOR ClockingSeq
				INSERT INTO Clocking (Id, TimeSheetId, ShiftId, EmployeeId, WorkById, ClockingStatus, StartTime, EndTime, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted,  CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork,  ClockingPaymentStatus)
				VALUES        (@clockingId, @prevTimeSheetId2, @shiftId2, @employeeId2, @employeeId2, 3, @startDateCaChieu, @endDateCaChieu, @tenantId, @branchId, @userId, GETDATE(), 0, @startDateCaChieu, @endDateCaChieu, 0, 0, 0, 0, 0)

				SET @clockingHistoryId = NEXT VALUE FOR ClockingHistorySeq
				INSERT INTO ClockingHistory (Id, ClockingId, CheckedInDate, CheckedOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, TenantId, BranchId, TimeKeepingType, ClockingStatus, CreatedBy, CreatedDate, ClockingHistoryStatus, TimeIsLateAdjustment, OverTimeBeforeShiftWorkAdjustment, TimeIsLeaveWorkEarlyAdjustment, OverTimeAfterShiftWorkAdjustment, ShiftId, ShiftFrom, ShiftTo, EmployeeId, CheckTime)
				VALUES        (@clockingHistoryId, @clockingId, @startDateCaChieu, @endDateCaChieu, 0, 0, 0, 0, @tenantId, @branchId, 1, 3, @userId, GETDATE(), 1, 0, 0, 0, 0, @shiftId2, 900, 1350, @employeeId2, GETDATE())
			END
			SET @prevLoopDate = DATEADD(DAY, 1, @prevLoopDate);
			SET @prevDayCounter = @prevDayCounter + 1;
		END
	END
	ELSE -- @useNewTimeSheet = 1 (TimeSheet 2.0)
	BEGIN
		-- TimeSheet 2.0: Lặp qua từng ngày của tháng trước, kiểm tra RepeatDaysOfWeek
		DECLARE @prevLoopDate_20 DATETIME = @prevMonthStartDate;
		WHILE @prevLoopDate_20 <= @prevMonthEndDate
		BEGIN
			DECLARE @dayOfWeek INT = DATEPART(dw, @prevLoopDate_20); -- 1=Monday, 7=Sunday (assuming @@DATEFIRST = 1)
			-- Adjust for @@DATEFIRST if needed. The TimeSheet procedure uses (@@DATEFIRST + 5 + DATEPART(dw, GETDATE())) % 7, which makes Monday=1.
			-- So, if @@DATEFIRST is 7 (Sunday), DATEPART(dw) for Monday is 2. We need to convert it to 1.
			-- If @@DATEFIRST is 1 (Monday), DATEPART(dw) for Monday is 1. No conversion needed.
			-- Let's assume @@DATEFIRST is 1 for consistency with '1,2,3,4,5,6'
			-- Or, safer:
			SET @dayOfWeek = (DATEPART(dw, @prevLoopDate_20) + @@DATEFIRST - 1) % 7;
			IF @dayOfWeek = 0 SET @dayOfWeek = 7; -- Make Sunday 7, not 0.

			-- Check if employee 1 works on this day
			IF CHARINDEX(CAST(@dayOfWeek AS VARCHAR(1)), @repeatDaysOfWeek1_Prev) > 0
			BEGIN
				SET @startDateCaSang = (SELECT CAST(CONVERT(CHAR(8), @prevLoopDate_20, 112) + ' 09:00:00' AS datetime))
				SET @endDateCaSang = (SELECT CAST(CONVERT(CHAR(8), @prevLoopDate_20, 112) + ' 15:00:00' AS datetime))
				SET @clockingId = NEXT VALUE FOR ClockingSeq
				INSERT INTO Clocking (Id, TimeSheetId, ShiftId, EmployeeId, WorkById, ClockingStatus, StartTime, EndTime, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted, CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork,  ClockingPaymentStatus)
				VALUES        (@clockingId, @prevTimeSheetId1, @shiftId1, @employeeId1, @employeeId1, 3, @startDateCaSang, @endDateCaSang, @tenantId, @branchId, @userId, GETDATE(), 0, @startDateCaSang, @endDateCaSang, 0, 0, 0, 0, 0)

				SET @clockingHistoryId = NEXT VALUE FOR ClockingHistorySeq
				INSERT INTO ClockingHistory (Id, ClockingId, CheckedInDate, CheckedOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, TenantId, BranchId, TimeKeepingType, ClockingStatus, CreatedBy, CreatedDate, ClockingHistoryStatus, TimeIsLateAdjustment, OverTimeBeforeShiftWorkAdjustment, TimeIsLeaveWorkEarlyAdjustment, OverTimeAfterShiftWorkAdjustment, ShiftId, ShiftFrom, ShiftTo, EmployeeId, CheckTime)
				VALUES        (@clockingHistoryId, @clockingId, @startDateCaSang, @endDateCaSang, 0, 0, 0, 0, @tenantId, @branchId, 1, 3, @userId, GETDATE(), 1, 0, 0, 0, 0, @shiftId1, 540, 900, @employeeId1, GETDATE())
			END

			-- Check if employee 2 works on this day
			IF CHARINDEX(CAST(@dayOfWeek AS VARCHAR(1)), @repeatDaysOfWeek2_Prev) > 0
			BEGIN
				SET @startDateCaChieu = (SELECT CAST(CONVERT(CHAR(8), @prevLoopDate_20, 112) + ' 15:00:00' AS datetime))
				SET @endDateCaChieu = (SELECT CAST(CONVERT(CHAR(8), @prevLoopDate_20, 112) + ' 22:30:00' AS datetime))
				SET @clockingId = NEXT VALUE FOR ClockingSeq
				INSERT INTO Clocking (Id, TimeSheetId, ShiftId, EmployeeId, WorkById, ClockingStatus, StartTime, EndTime, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted,  CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork,  ClockingPaymentStatus)
				VALUES        (@clockingId, @prevTimeSheetId2, @shiftId2, @employeeId2, @employeeId2, 3, @startDateCaChieu, @endDateCaChieu, @tenantId, @branchId, @userId, GETDATE(), 0, @startDateCaChieu, @endDateCaChieu, 0, 0, 0, 0, 0)

				SET @clockingHistoryId = NEXT VALUE FOR ClockingHistorySeq
				INSERT INTO ClockingHistory (Id, ClockingId, CheckedInDate, CheckedOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, TenantId, BranchId, TimeKeepingType, ClockingStatus, CreatedBy, CreatedDate, ClockingHistoryStatus, TimeIsLateAdjustment, OverTimeBeforeShiftWorkAdjustment, TimeIsLeaveWorkEarlyAdjustment, OverTimeAfterShiftWorkAdjustment, ShiftId, ShiftFrom, ShiftTo, EmployeeId, CheckTime)
				VALUES        (@clockingHistoryId, @clockingId, @startDateCaChieu, @endDateCaChieu, 0, 0, 0, 0, @tenantId, @branchId, 1, 3, @userId, GETDATE(), 1, 0, 0, 0, 0, @shiftId2, 900, 1350, @employeeId2, GETDATE())
			END
			SET @prevLoopDate_20 = DATEADD(DAY, 1, @prevLoopDate_20);
		END
	END
END

GO

ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_Deduction]
(
    @tenantId	INT,			-- ID gian hàng
	@userId		BIGINT,			-- ID tài khoản admin
    @language	NVARCHAR(50),	-- Ngôn ngữ
	@deductionId BIGINT OUTPUT
)
AS
BEGIN
    IF (@language = 'en-US')
	BEGIN
		SET @deductionId = NEXT VALUE FOR DeductionSeq

		INSERT INTO Deduction (Id, [Name], CreatedBy, CreatedDate, TenantId, Code, IsDeleted, [Value], ValueType, DeductionRuleId, DeductionTypeId, BlockTypeTimeValue, BlockTypeMinuteValue)
		VALUES        (@deductionId, N'Late Arrival', @userId, GETDATE(), @tenantId, 'GT000001', 0, 10000, 1, 1, 1, 1, 10)
	END
	ELSE
	BEGIN
		SET @deductionId = NEXT VALUE FOR DeductionSeq

		INSERT INTO Deduction (Id, [Name], CreatedBy, CreatedDate, TenantId, Code, IsDeleted, [Value], ValueType, DeductionRuleId, DeductionTypeId, BlockTypeTimeValue, BlockTypeMinuteValue)
		VALUES        (@deductionId, N'Đi trễ', @userId, GETDATE(), @tenantId, 'GT000001', 0, 10000, 1, 1, 1, 1, 10)
	END
END

GO

ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_Employees]
(
    @tenantId	    INT,            -- ID gian hàng
    @branchId	    INT,            -- ID chi nhánh
    @userId		    BIGINT,         -- ID tài khoản admin
    @taikhoan1		BIGINT,         -- ID tài khoản nhân viên 1
    @taikhoan2		BIGINT,         -- ID tài khoản nhân viên 2
    @employeeId1	BIGINT OUTPUT,
    @employeeId2	BIGINT OUTPUT,
    @language	    NVARCHAR(50)    -- Ngôn ngữ
)
AS
BEGIN
    DECLARE @employeeBranch BIGINT
    DECLARE @employeeId3 BIGINT

    IF (@language = 'en-US')
    BEGIN
        -- English records
        SET @employeeId1 = NEXT VALUE FOR EmployeeSeq;
        INSERT INTO Employee (Id, Code, [Name], IsActive, UserId, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted, [MobilePhone])
        VALUES (@employeeId1, 'NV000002', N'Mailee Sovan', 1, @taikhoan1, @tenantId, @branchId, @userId, GETDATE(), 0, '+1 323-555-0456');

        SET @employeeBranch = NEXT VALUE FOR EmployeeBranchSeq;
        INSERT INTO EmployeeBranch (Id, TenantId, BranchId, EmployeeId)
        VALUES (@employeeBranch, @tenantId, @branchId, @employeeId1);

        SET @employeeId2 = NEXT VALUE FOR EmployeeSeq;
        INSERT INTO Employee (Id, Code, [Name], IsActive, UserId, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted, [MobilePhone])
        VALUES (@employeeId2, 'NV000003', N'Chanlina Pheng', 1, @taikhoan2, @tenantId, @branchId, @userId, GETDATE(), 0, '+1 626-555-0789');

        SET @employeeBranch = NEXT VALUE FOR EmployeeBranchSeq;
        INSERT INTO EmployeeBranch (Id, TenantId, BranchId, EmployeeId)
        VALUES (@employeeBranch, @tenantId, @branchId, @employeeId2);
    END
    ELSE
    BEGIN
        -- Vietnamese records
        SET @employeeId1 = NEXT VALUE FOR EmployeeSeq;
        INSERT INTO Employee (Id, Code, [Name], IsActive, UserId, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted,[MobilePhone])
        VALUES (@employeeId1, 'NV000002', N'Hoàng Long 22', 1, @taikhoan1, @tenantId, @branchId, @userId, GETDATE(), 0,'0326895656');

        SET @employeeBranch = NEXT VALUE FOR EmployeeBranchSeq;
        INSERT INTO EmployeeBranch (Id, TenantId, BranchId, EmployeeId)
        VALUES (@employeeBranch, @tenantId, @branchId, @employeeId1);

        SET @employeeId2 = NEXT VALUE FOR EmployeeSeq;
        INSERT INTO Employee (Id, Code, [Name], IsActive, UserId, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted,[MobilePhone])
        VALUES (@employeeId2, 'NV000003', N'Mai Hương', 1, @taikhoan2, @tenantId, @branchId, @userId, GETDATE(), 0,'0357200282');

        SET @employeeBranch = NEXT VALUE FOR EmployeeBranchSeq;
        INSERT INTO EmployeeBranch (Id, TenantId, BranchId, EmployeeId)
        VALUES (@employeeBranch, @tenantId, @branchId, @employeeId2);
    END
END

GO

ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_PayRate]
(
    @tenantId	INT,			-- ID gian hàng
	@userId	BIGINT,				-- ID tài khoản admin
	@payRateTemplateId	BIGINT,	-- ID mẫu lương
	@employeeId1	BIGINT,		-- ID nhân viên Hoàng Long
    @employeeId2	BIGINT,		-- ID nhân viên Mai Hương
	@payRateId1 BIGINT OUTPUT,
	@payRateId2 BIGINT OUTPUT
)
AS
BEGIN
	SET @payRateId1 = NEXT VALUE FOR PayRateSeq
	INSERT INTO PayRate (Id, EmployeeId, PayRateTemplateId, TenantId, CreatedDate, CreatedBy, SalaryPeriod)
	VALUES        (@payRateId1, @employeeId1, @payRateTemplateId, @tenantId, GETDATE(), @userId, 1)

	SET @payRateId2 = NEXT VALUE FOR PayRateSeq
	INSERT INTO PayRate (Id, EmployeeId, PayRateTemplateId, TenantId, CreatedDate, CreatedBy, SalaryPeriod)
	VALUES        (@payRateId2, @employeeId2, @payRateTemplateId, @tenantId, GETDATE(), @userId, 1)
END

GO

ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_PayRateDetail]
(
    @tenantId	INT,			-- ID gian hàng
	@commissionId	BIGINT,		-- ID hoa hồng
    @allowanceId	BIGINT,		-- ID phụ cấp
    @deductionId	BIGINT,		-- ID giảm trừ
	@payRateId1	BIGINT,			-- ID thiết lập lương 1
	@payRateId2	BIGINT,			-- ID thiết lập lương 2
	@employeeId1	BIGINT,		-- ID nhân viên Hoàng Long
    @employeeId2	BIGINT		-- ID nhân viên Mai Hương
)
AS
BEGIN
	INSERT INTO PayRateDetail (PayRateId, RuleType, RuleValue, TenantId)
	VALUES        (@payRateId1, 'AllowanceRule', '{"AllowanceRuleValueDetails":[{"AllowanceId":' + CAST(@allowanceId AS VARCHAR(50)) + ',"Name":null,"Value":50000.0,"ValueRatio":null,"Rank":0,"Type":1,"IsChecked":true}]}', @tenantId)
	INSERT INTO PayRateDetail (PayRateId, RuleType, RuleValue, TenantId)
	VALUES        (@payRateId1, 'CommissionSalaryRuleV2', '{"Type":1,"FormalityTypes":0,"IsAllBranch":false,"BranchIds":[],"MinCommission":null,"UseMinCommission":false,"CommissionSalaryRuleValueDetails":[{"Group":"7172ff88-0668-44c2-81b0-845c582a416b","CommissionType":1,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"CommissionTableId":' + CAST(@commissionId AS VARCHAR(50)) + '},{"Group":"7172ff88-0668-44c2-81b0-845c582a416b","CommissionType":2,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"CommissionTableId":' + CAST(@commissionId AS VARCHAR(50)) + '}]}', @tenantId)

	INSERT INTO PayRateDetail (PayRateId, RuleType, RuleValue, TenantId)
	VALUES        (@payRateId1, 'DeductionRule', '{"DeductionRuleValueDetails":[{"DeductionId":' + CAST(@deductionId AS VARCHAR(50)) + ',"Name":null,"Value":10000.0,"ValueRatio":null,"Rank":0,"Type":1,"DeductionRuleId":1,"DeductionTypeId":1,"BlockTypeTimeValue":1,"BlockTypeMinuteValue":10}]}', @tenantId)
	INSERT INTO PayRateDetail (PayRateId, RuleType, RuleValue, TenantId)
	VALUES        (@payRateId1, 'MainSalaryRule', '{"Type":4,"MainSalaryValueDetails":[{"ShiftId":0,"Default":10000000.0,"MainSalaryHolidays":[],"Rank":0}]}', @tenantId)

	INSERT INTO PayRateDetail (PayRateId, RuleType, RuleValue, TenantId)
	VALUES        (@payRateId2, 'AllowanceRule', '{"AllowanceRuleValueDetails":[{"AllowanceId":' + CAST(@allowanceId AS VARCHAR(50)) + ',"Name":null,"Value":50000.0,"ValueRatio":null,"Rank":0,"Type":1,"IsChecked":true}]}', @tenantId)
	INSERT INTO PayRateDetail (PayRateId, RuleType, RuleValue, TenantId)
	VALUES        (@payRateId2, 'CommissionSalaryRuleV2', '{"Type":1,"FormalityTypes":0,"IsAllBranch":false,"BranchIds":[],"MinCommission":null,"UseMinCommission":false,"CommissionSalaryRuleValueDetails":[{"Group":"7172ff88-0668-44c2-81b0-845c582a416b","CommissionType":1,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"CommissionTableId":' + CAST(@commissionId AS VARCHAR(50)) + '},{"Group":"7172ff88-0668-44c2-81b0-845c582a416b","CommissionType":2,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"CommissionTableId":' + CAST(@commissionId AS VARCHAR(50)) + '}]}', @tenantId)
	INSERT INTO PayRateDetail (PayRateId, RuleType, RuleValue, TenantId)
	VALUES        (@payRateId2, 'DeductionRule', '{"DeductionRuleValueDetails":[{"DeductionId":' + CAST(@deductionId AS VARCHAR(50)) + ',"Name":null,"Value":10000.0,"ValueRatio":null,"Rank":0,"Type":0,"DeductionRuleId":1,"DeductionTypeId":1,"BlockTypeTimeValue":1,"BlockTypeMinuteValue":10}]}', @tenantId)
	INSERT INTO PayRateDetail (PayRateId, RuleType, RuleValue, TenantId)
	VALUES        (@payRateId2, 'MainSalaryRule', '{"Type":4,"MainSalaryValueDetails":[{"ShiftId":0,"Default":7000000.0,"MainSalaryHolidays":[],"Rank":0}]}', @tenantId)
END

GO

ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_PayRateTemplate]
(
    @tenantId	INT,		-- ID gian hàng
    @branchId	INT,		-- ID chi nhánh
	@userId		BIGINT,		-- ID tài khoản admin
    @language	NVARCHAR(50),	-- Ngôn ngữ
	@payRateTemplateId BIGINT OUTPUT
)
AS
BEGIN
	IF (@language = 'en-US')
	BEGIN
		SET @payRateTemplateId = NEXT VALUE FOR PayRateTemplateSeq

		INSERT INTO PayRateTemplate (Id, TenantId, [Name], SalaryPeriod, BranchId, CreatedDate, CreatedBy, [Status])
		VALUES        (@payRateTemplateId, @tenantId, N'Service staff - consultant', 1, @branchId, GETDATE(), @userId, 0)
	END
	ELSE
	BEGIN
		SET @payRateTemplateId = NEXT VALUE FOR PayRateTemplateSeq

		INSERT INTO PayRateTemplate (Id, TenantId, [Name], SalaryPeriod, BranchId, CreatedDate, CreatedBy, [Status])
		VALUES        (@payRateTemplateId, @tenantId, N'Nhân viên dịch vụ - tư vấn', 1, @branchId, GETDATE(), @userId, 0)
	END
END

GO

ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_PayRateTemplateDetail]
(
    @tenantId	INT,			-- ID gian hàng
	@userId	BIGINT,				-- ID tài khoản admin
	@payRateTemplateId	BIGINT,	-- ID mẫu lương
	@commissionId	BIGINT,		-- ID hoa hồng
    @allowanceId	BIGINT,		-- ID phụ cấp
    @deductionId	BIGINT		-- ID giảm trừ
)
AS
BEGIN
	DECLARE @guid uniqueidentifier
	SET @guid = NEWID()

	INSERT INTO PayRateTemplateDetail (TenantId, PayRateTemplateId, RuleType, RuleValue, CreatedBy, CreatedDate)
	VALUES        (@tenantId, @payRateTemplateId, 'CommissionSalaryRuleV2', '{"Type":1,"FormalityTypes":0,"IsAllBranch":false,"BranchIds":[],"MinCommission":null,"UseMinCommission":false,"CommissionSalaryRuleValueDetails":[{"Group":"' +  CONVERT(NVARCHAR(MAX), @guid) + '","CommissionType":1,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"CommissionTableId":' + CAST(@commissionId AS VARCHAR(50)) + '},{"Group":"' +  CONVERT(NVARCHAR(MAX), @guid) + '","CommissionType":2,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"CommissionTableId":' + CAST(@commissionId AS VARCHAR(50)) + '}]}', @userId, GETDATE())

	INSERT INTO PayRateTemplateDetail (TenantId, PayRateTemplateId, RuleType, RuleValue, CreatedBy, CreatedDate)
	VALUES        (@tenantId, @payRateTemplateId, 'AllowanceRule', '{"AllowanceRuleValueDetails":[{"AllowanceId":' + CAST(@allowanceId AS VARCHAR(50)) + ',"Name":null,"Value":50000.0,"ValueRatio":null,"Rank":0,"Type":1,"IsChecked":true}]}', @userId, GETDATE())

	INSERT INTO PayRateTemplateDetail (TenantId, PayRateTemplateId, RuleType, RuleValue, CreatedBy, CreatedDate)
	VALUES        (@tenantId, @payRateTemplateId, 'DeductionRule', '{"DeductionRuleValueDetails":[{"DeductionId":' + CAST(@deductionId AS VARCHAR(50)) + ',"Name":null,"Value":10000.0,"ValueRatio":null,"Rank":0,"Type":0,"DeductionRuleId":1,"DeductionTypeId":1,"BlockTypeTimeValue":1,"BlockTypeMinuteValue":10}]}', @userId, GETDATE())
END

GO

-- ========================
-- File: pr_Booking_Insert_TrialData_Paysheet.sql
-- ========================
ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_Paysheet]
(
    @tenantId	INT,					-- ID gian hàng
	@branchId	INT,					-- ID chi nhánh
	@userId	BIGINT,						-- ID tài khoản admin
	@startDate	DATETIME,				-- Ngày bắt đầu
    @language	    NVARCHAR(50),    	-- Ngôn ngữ
    @paysheetId BIGINT OUTPUT,			-- ID bảng lương tháng hiện tại
    @paysheetIdPrev BIGINT OUTPUT  		-- ID bảng lương tháng trước
)
AS
BEGIN
 ------------------------------------------
    -- 1. Tạo bảng lương tháng trước
    ------------------------------------------

    DECLARE @firstDayPrevMonth DATE, @lastDayPrevMonth DATE;
    IF MONTH(@startDate) = 1
        SET @firstDayPrevMonth = DATEFROMPARTS(YEAR(@startDate) - 1, 12, 1);
    ELSE
    SET @firstDayPrevMonth = DATEFROMPARTS(YEAR(@startDate), MONTH(@startDate) - 1, 1);

    SET @lastDayPrevMonth = EOMONTH(@startDate, -1);

    DECLARE @paysheetPeriodNamePrev NVARCHAR(100);
    SET @paysheetPeriodNamePrev = CONVERT(VARCHAR(10), @firstDayPrevMonth, 103) + ' - ' + CONVERT(VARCHAR(10), @lastDayPrevMonth, 103);
    SET @paysheetIdPrev = NEXT VALUE FOR PaysheetSeq

    IF (@language = N'en-US')
    BEGIN
        INSERT INTO Paysheet (Id, Code, TenantId, BranchId, IsDeleted, CreatedBy, CreatedDate, [Name], SalaryPeriod, StartTime, EndTime, PaysheetStatus, Note, WorkingDayNumber, PaysheetPeriodName, CreatorBy, PaysheetCreatedDate, [Version], IsDraft, TimeOfStandardWorkingDay)
	    VALUES (@paysheetIdPrev, 'BL000001', @tenantId, @branchId, 0, @userId, GETDATE(), N'General Salary Table ' + @paysheetPeriodNamePrev, 1, @startDate, CAST(CONVERT(char(8), @lastDayPrevMonth, 112) + ' 23:59:59.000' AS datetime2), 1, '', DATEDIFF(DAY, @firstDayPrevMonth, @lastDayPrevMonth) + 1, @paysheetPeriodNamePrev, @userId, GETDATE(), 0, 0, 8)
    END
    ELSE
    BEGIN
        INSERT INTO Paysheet (Id, Code, TenantId, BranchId, IsDeleted, CreatedBy, CreatedDate, [Name], SalaryPeriod, StartTime, EndTime, PaysheetStatus, Note, WorkingDayNumber, PaysheetPeriodName, CreatorBy, PaysheetCreatedDate, [Version], IsDraft, TimeOfStandardWorkingDay)
	    VALUES (@paysheetIdPrev, 'BL000001', @tenantId, @branchId, 0, @userId, GETDATE(), N'Bảng lương ' + @paysheetPeriodNamePrev, 1, @firstDayPrevMonth, CAST(CONVERT(char(8), @lastDayPrevMonth, 112) + ' 23:59:59.000' AS datetime2), 1, '', DATEDIFF(DAY, @firstDayPrevMonth, @lastDayPrevMonth) + 1, @paysheetPeriodNamePrev, @userId, GETDATE(), 0, 0, 8)
    END

	------------------------------------------
    -- 2. Tạo bảng lương tháng hiện tại (từ ngày hiện tại)
    ------------------------------------------
	DECLARE @currentStartDate DATE = CAST(GETDATE() AS DATE)
	DECLARE @endDate DATETIME = EOMONTH(@currentStartDate)
    DECLARE @workingDayNumber INT
    SET @workingDayNumber = DAY(EOMONTH(GETDATE()))
	DECLARE @paysheetPeriodName VARCHAR(100) = CONVERT(VARCHAR, @currentStartDate, 103) + ' - ' + CONVERT(VARCHAR, @endDate, 103)
	SET @paysheetId = NEXT VALUE FOR PaysheetSeq

    IF (@language = N'en-US')
    BEGIN
        INSERT INTO Paysheet (
            Id, Code, TenantId, BranchId, IsDeleted, CreatedBy, CreatedDate, [Name],
            SalaryPeriod, StartTime, EndTime, PaysheetStatus, Note, WorkingDayNumber,
            PaysheetPeriodName, CreatorBy, PaysheetCreatedDate, [Version], IsDraft, TimeOfStandardWorkingDay
        )
	    VALUES (
            @paysheetId, 'BL000002', @tenantId, @branchId, 0, @userId, GETDATE(),
            N'General Salary Table ' + @paysheetPeriodName,
            1, @currentStartDate, CAST(CONVERT(char(8), @endDate, 112) + ' 23:59:59.000' AS datetime2),
            1, '', @workingDayNumber, @paysheetPeriodName,
            @userId, GETDATE(), 0, 0, 8
        )
    END
    ELSE
    BEGIN
        INSERT INTO Paysheet (
            Id, Code, TenantId, BranchId, IsDeleted, CreatedBy, CreatedDate, [Name],
            SalaryPeriod, StartTime, EndTime, PaysheetStatus, Note, WorkingDayNumber,
            PaysheetPeriodName, CreatorBy, PaysheetCreatedDate, [Version], IsDraft, TimeOfStandardWorkingDay
        )
	    VALUES (
            @paysheetId, 'BL000002', @tenantId, @branchId, 0, @userId, GETDATE(),
            N'Bảng lương ' + @paysheetPeriodName,
            1, @currentStartDate, CAST(CONVERT(char(8), @endDate, 112) + ' 23:59:59.000' AS datetime2),
            1, '', @workingDayNumber, @paysheetPeriodName,
            @userId, GETDATE(), 0, 0, 8
        )
    END

END

GO

-- ========================
-- File: pr_Booking_Insert_TrialData_Payslip.sql
-- ========================
ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_Payslip]
(
    @tenantId	INT,
	@branchId	INT,
	@userId		BIGINT,
	@employeeId1 BIGINT,
	@employeeId2 BIGINT,
    @paysheetId BIGINT,
	@paysheetIdPrev BIGINT,
	@workingDays1 INT,			-- Số ngày công tháng hiện tại nhân viên 1
	@workingDays2 INT,			-- Số ngày công tháng hiện tại nhân viên 2
	@workingDaysPrev1 INT,		-- Số ngày công tháng trước nhân viên 1
	@workingDaysPrev2 INT,		-- Số ngày công tháng trước nhân viên 2
    @payslipId1 BIGINT OUTPUT,
    @payslipId2 BIGINT OUTPUT,
	@payslipIdPrev1 BIGINT OUTPUT,
    @payslipIdPrev2 BIGINT OUTPUT
)
AS
BEGIN
	-- Phiếu lương tháng trước - Nhân viên 1
	SET @payslipIdPrev1 = NEXT VALUE FOR PayslipSeq
	INSERT INTO Payslip (Id, Code, PaysheetId, TenantId, IsDeleted, PayslipStatus, EmployeeId, CreatedDate, CreatedBy, ModifiedBy, ModifiedDate, MainSalary, CommissionSalary, OvertimeSalary, Allowance, Deduction, Bonus, NetSalary, GrossSalary, TotalPayment, IsDraft, PayslipCreatedDate, PayslipCreatedBy)
	VALUES (@payslipIdPrev1, dbo.[GenerateCodePayslip](@tenantId), @paysheetIdPrev, @tenantId, 0, 1, @employeeId1, DATEADD(MONTH, -1, GETDATE()), @userId, @userId, DATEADD(MONTH, -1, GETDATE()), 10000000, 0, 0, 50000 * @workingDaysPrev1, 30000, 0, 10000000 + (50000 * @workingDaysPrev1) - 30000, 10000000 + (50000 * @workingDaysPrev1), 0, 0, DATEADD(MONTH, -1, GETDATE()), @userId)

	-- Phiếu lương tháng trước - Nhân viên 2
	SET @payslipIdPrev2 = NEXT VALUE FOR PayslipSeq
	INSERT INTO Payslip (Id, Code, PaysheetId, TenantId, IsDeleted, PayslipStatus, EmployeeId, CreatedDate, CreatedBy, ModifiedBy, ModifiedDate, MainSalary, CommissionSalary, OvertimeSalary, Allowance, Deduction, Bonus, NetSalary, GrossSalary, TotalPayment, IsDraft, PayslipCreatedDate, PayslipCreatedBy)
	VALUES (@payslipIdPrev2, dbo.[GenerateCodePayslip](@tenantId), @paysheetIdPrev, @tenantId, 0, 1, @employeeId2, DATEADD(MONTH, -1, GETDATE()), @userId, @userId, DATEADD(MONTH, -1, GETDATE()), 7000000, 0, 0, 50000 * @workingDaysPrev2, 30000, 0, 7000000 + (50000 * @workingDaysPrev2) - 30000, 7000000 + (50000 * @workingDaysPrev2), 0, 0, DATEADD(MONTH, -1, GETDATE()), @userId)

	-- Phiếu lương tháng hiện tại - Nhân viên 1
	SET @payslipId1 = NEXT VALUE FOR PayslipSeq
	INSERT INTO Payslip (Id, Code, PaysheetId, TenantId, IsDeleted, PayslipStatus, EmployeeId, CreatedDate, CreatedBy, ModifiedBy, ModifiedDate, MainSalary, CommissionSalary, OvertimeSalary, Allowance, Deduction, Bonus, NetSalary, GrossSalary, TotalPayment, IsDraft, PayslipCreatedDate, PayslipCreatedBy)
	VALUES (@payslipId1, dbo.[GenerateCodePayslip](@tenantId), @paysheetId, @tenantId, 0, 1, @employeeId1, GETDATE(), @userId, @userId, GETDATE(), 10000000, 0, 0, 50000 * @workingDays1, 30000, 0, 10000000 + (50000 * @workingDays1) - 30000, 10000000 + (50000 * @workingDays1), 0, 0, GETDATE(), @userId)

	-- Phiếu lương tháng hiện tại - Nhân viên 2
	SET @payslipId2 = NEXT VALUE FOR PayslipSeq
	INSERT INTO Payslip (Id, Code, PaysheetId, TenantId, IsDeleted, PayslipStatus, EmployeeId, CreatedDate, CreatedBy, ModifiedBy, ModifiedDate, MainSalary, CommissionSalary, OvertimeSalary, Allowance, Deduction, Bonus, NetSalary, GrossSalary, TotalPayment, IsDraft, PayslipCreatedDate, PayslipCreatedBy)
	VALUES (@payslipId2, dbo.[GenerateCodePayslip](@tenantId), @paysheetId, @tenantId, 0, 1, @employeeId2, GETDATE(), @userId, @userId, GETDATE(), 7000000, 0, 0, 50000 * @workingDays2, 30000, 0, 7000000 + (50000 * @workingDays2) - 30000, 7000000 + (50000 * @workingDays2), 0, 0, GETDATE(), @userId)
END

GO

ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_PayslipClocking]
(
    @tenantId	INT,			-- ID gian hàng
	@userId	BIGINT,				-- ID tài khoản admin
	@employeeId1 BIGINT,		-- ID nhân viên 1
	@employeeId2 BIGINT,		-- ID nhân viên 2
    @payslipId1 BIGINT,			-- ID phiếu lương 1
    @payslipId2 BIGINT			-- ID phiếu lương 2
)
AS
BEGIN
	INSERT INTO PayslipClocking (PayslipId, ClockingId, CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, AbsenceType, ClockingStatus, StartTime, EndTime, ShiftId)
	SELECT @payslipId1, Id, CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, AbsenceType, ClockingStatus, StartTime, EndTime, ShiftId
	FROM Clocking
	WHERE TenantId = @tenantId AND EmployeeId = @employeeId1

	INSERT INTO PayslipClocking (PayslipId, ClockingId, CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, AbsenceType, ClockingStatus, StartTime, EndTime, ShiftId)
	SELECT @payslipId2, Id, CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, AbsenceType, ClockingStatus, StartTime, EndTime, ShiftId
	FROM Clocking
	WHERE TenantId = @tenantId AND EmployeeId = @employeeId2
END

GO

-- ========================
-- File: pr_Booking_Insert_TrialData_PayslipDetail.sql
-- ========================
ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_PayslipDetail]
(
    @tenantId			INT,
	@userId				BIGINT,
	@employeeId1		BIGINT,
	@employeeId2		BIGINT,
    @payslipId1			BIGINT,
    @payslipId2			BIGINT,
	@payslipIdPrev1		BIGINT,
    @payslipIdPrev2		BIGINT,
	@allowanceId		BIGINT,
	@deductionId		BIGINT,
	@workingDays1		INT,			-- Số ngày công tháng hiện tại nhân viên 1
	@workingDays2		INT,			-- Số ngày công tháng hiện tại nhân viên 2
	@workingDaysPrev1	INT,			-- Số ngày công tháng trước nhân viên 1
	@workingDaysPrev2	INT,			-- Số ngày công tháng trước nhân viên 2
	@shiftId1			BIGINT,
	@shiftId2			BIGINT
)
AS
BEGIN
	-- =====================================================
	-- PHIẾU LƯƠNG THÁNG HIỆN TẠI
	-- =====================================================

	-- Chi tiết phiếu lương tháng hiện tại - Nhân viên 1
	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipId1, RuleType, RuleValue, '{"Allowances":[{"AllowanceId":' +  CAST(@allowanceId AS VARCHAR(50)) + ',"Value":50000.0,"ValueRatio":null,"Name":null,"CalculatedValue":50000.0,"CalculatedValueRatio":null,"NumberWorkingDay":' +  CAST(@workingDays1 AS VARCHAR(10)) + ',"SelectedItem":null,"Type":1,"StandardWorkingDayNumber":' +  CAST(@workingDays1 AS VARCHAR(10)) + ',"IsChecked":true}]}', @tenantId
	FROM PayRateTemplateDetail WHERE TenantId = @tenantId AND RuleType = 'AllowanceRule' ORDER BY Id DESC

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipId1, RuleType, RuleValue, '{"Deductions":[{"DeductionId":' +  CAST(@deductionId AS VARCHAR(50)) + ',"Value":30000.0,"ValueRatio":null,"Name":null,"CalculatedValue":30000.0,"CalculatedValueRatio":null,"SelectedItem":null,"Type":1}]}', @tenantId
	FROM PayRateTemplateDetail WHERE TenantId = @tenantId AND RuleType = 'DeductionRule'

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipId1, RuleType, RuleValue, '{"Type":1,"TotalRevenue":0.0,"TotalCounselorRevenue":0.0,"TotalGrossProfit":0.0,"CommissionSalary":null,"CommissionSalaryOrigin":0.0,"CommissionParams":[{"CommissionType":1,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"ValueOrigin":null,"ValueRatioOrigin":null,"IsDirty":null,"ProductRevenues":[],"CommissionTable":null,"CommissionSetting":0},{"CommissionType":2,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"ValueOrigin":null,"ValueRatioOrigin":null,"IsDirty":null,"ProductRevenues":[],"CommissionTable":null,"CommissionSetting":0}]}', @tenantId
	FROM PayRateTemplateDetail WHERE TenantId = @tenantId AND RuleType = 'CommissionSalaryRuleV2' ORDER BY Id DESC

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	VALUES (@payslipId1, 'MainSalaryRule',
		'{"Type":4,"MainSalaryValueDetails":[{"ShiftId":' + CAST(@shiftId1 AS VARCHAR(50)) + ',"Default":10000000.0,"MainSalaryHolidays":[],"Rank":0}]}',
		'{"MainSalaryShifts":[{"ShiftId":' + CAST(@shiftId1 AS VARCHAR(50)) + ',"Salary":10000000.0,"CalculatedSalary":10000000.0,"Default":' + CAST(@workingDays1 AS VARCHAR(10)) + '.0,"CalculatedDefault":' + CAST(@workingDays1 AS VARCHAR(50)) + '.0,"MainSalaryByShiftParamDetails":null,"Type":4}]}',
		@tenantId)

	-- Chi tiết phiếu lương tháng hiện tại - Nhân viên 2
	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipId2, RuleType, RuleValue, '{"Allowances":[{"AllowanceId":' +  CAST(@allowanceId AS VARCHAR(50)) + ',"Value":50000.0,"ValueRatio":null,"Name":null,"CalculatedValue":50000.0,"CalculatedValueRatio":null,"NumberWorkingDay":' +  CAST(@workingDays2 AS VARCHAR(10)) + ',"SelectedItem":null,"Type":1,"StandardWorkingDayNumber":' +  CAST(@workingDays2 AS VARCHAR(10)) + ',"IsChecked":true}]}', @tenantId
	FROM PayRateTemplateDetail WHERE TenantId = @tenantId AND RuleType = 'AllowanceRule' ORDER BY Id DESC

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipId2, RuleType, RuleValue, '{"Deductions":[{"DeductionId":' +  CAST(@deductionId AS VARCHAR(50)) + ',"Value":30000.0,"ValueRatio":null,"Name":null,"CalculatedValue":30000.0,"CalculatedValueRatio":null,"SelectedItem":null,"Type":1}]}', @tenantId
	FROM PayRateTemplateDetail WHERE TenantId = @tenantId AND RuleType = 'DeductionRule' ORDER BY Id DESC

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipId2, RuleType, RuleValue, '{"Type":1,"TotalRevenue":0.0,"TotalCounselorRevenue":0.0,"TotalGrossProfit":0.0,"CommissionSalary":null,"CommissionSalaryOrigin":0.0,"CommissionParams":[{"CommissionType":1,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"ValueOrigin":null,"ValueRatioOrigin":null,"IsDirty":null,"ProductRevenues":[],"CommissionTable":null,"CommissionSetting":0},{"CommissionType":2,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"ValueOrigin":null,"ValueRatioOrigin":null,"IsDirty":null,"ProductRevenues":[],"CommissionTable":null,"CommissionSetting":0}]}', @tenantId
	FROM PayRateTemplateDetail WHERE TenantId = @tenantId AND RuleType = 'CommissionSalaryRuleV2' ORDER BY Id DESC

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	VALUES (@payslipId2, 'MainSalaryRule',
		'{"Type":4,"MainSalaryValueDetails":[{"ShiftId":' + CAST(@shiftId2 AS VARCHAR(50)) + ',"Default":7000000.0,"MainSalaryHolidays":[],"Rank":0}]}',
		'{"MainSalaryShifts":[{"ShiftId":' + CAST(@shiftId2 AS VARCHAR(50)) + ',"Salary":7000000.0,"CalculatedSalary":7000000.0,"Default":' + CAST(@workingDays2 AS VARCHAR(10)) + '.0,"CalculatedDefault":' + CAST(@workingDays2 AS VARCHAR(50)) + '.0,"MainSalaryByShiftParamDetails":null,"Type":4}]}',
		@tenantId)

	-- =====================================================
	-- PHIẾU LƯƠNG THÁNG TRƯỚC
	-- =====================================================

	-- Chi tiết phiếu lương tháng trước - Nhân viên 1
	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipIdPrev1, RuleType, RuleValue, '{"Allowances":[{"AllowanceId":' +  CAST(@allowanceId AS VARCHAR(50)) + ',"Value":50000.0,"ValueRatio":null,"Name":null,"CalculatedValue":50000.0,"CalculatedValueRatio":null,"NumberWorkingDay":' +  CAST(@workingDaysPrev1 AS VARCHAR(10)) + ',"SelectedItem":null,"Type":1,"StandardWorkingDayNumber":' +  CAST(@workingDaysPrev1 AS VARCHAR(10)) + ',"IsChecked":true}]}', @tenantId
	FROM PayRateTemplateDetail WHERE TenantId = @tenantId AND RuleType = 'AllowanceRule' ORDER BY Id DESC

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipIdPrev1, RuleType, RuleValue, '{"Deductions":[{"DeductionId":' +  CAST(@deductionId AS VARCHAR(50)) + ',"Value":30000.0,"ValueRatio":null,"Name":null,"CalculatedValue":30000.0,"CalculatedValueRatio":null,"SelectedItem":null,"Type":1}]}', @tenantId
	FROM PayRateTemplateDetail WHERE TenantId = @tenantId AND RuleType = 'DeductionRule'

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipIdPrev1, RuleType, RuleValue, '{"Type":1,"TotalRevenue":0.0,"TotalCounselorRevenue":0.0,"TotalGrossProfit":0.0,"CommissionSalary":null,"CommissionSalaryOrigin":0.0,"CommissionParams":[{"CommissionType":1,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"ValueOrigin":null,"ValueRatioOrigin":null,"IsDirty":null,"ProductRevenues":[],"CommissionTable":null,"CommissionSetting":0},{"CommissionType":2,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"ValueOrigin":null,"ValueRatioOrigin":null,"IsDirty":null,"ProductRevenues":[],"CommissionTable":null,"CommissionSetting":0}]}', @tenantId
	FROM PayRateTemplateDetail WHERE TenantId = @tenantId AND RuleType = 'CommissionSalaryRuleV2' ORDER BY Id DESC

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	VALUES (@payslipIdPrev1, 'MainSalaryRule',
		'{"Type":4,"MainSalaryValueDetails":[{"ShiftId":' + CAST(@shiftId1 AS VARCHAR(50)) + ',"Default":10000000.0,"MainSalaryHolidays":[],"Rank":0}]}',
		'{"MainSalaryShifts":[{"ShiftId":' + CAST(@shiftId1 AS VARCHAR(50)) + ',"Salary":10000000.0,"CalculatedSalary":10000000.0,"Default":' + CAST(@workingDaysPrev1 AS VARCHAR(10)) + '.0,"CalculatedDefault":' + CAST(@workingDaysPrev1 AS VARCHAR(50)) + '.0,"MainSalaryByShiftParamDetails":null,"Type":4}]}',
		@tenantId)

	-- Chi tiết phiếu lương tháng trước - Nhân viên 2
	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipIdPrev2, RuleType, RuleValue, '{"Allowances":[{"AllowanceId":' +  CAST(@allowanceId AS VARCHAR(50)) + ',"Value":50000.0,"ValueRatio":null,"Name":null,"CalculatedValue":50000.0,"CalculatedValueRatio":null,"NumberWorkingDay":' +  CAST(@workingDaysPrev2 AS VARCHAR(10)) + ',"SelectedItem":null,"Type":1,"StandardWorkingDayNumber":' +  CAST(@workingDaysPrev2 AS VARCHAR(10)) + ',"IsChecked":true}]}', @tenantId
	FROM PayRateTemplateDetail WHERE TenantId = @tenantId AND RuleType = 'AllowanceRule' ORDER BY Id DESC

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipIdPrev2, RuleType, RuleValue, '{"Deductions":[{"DeductionId":' +  CAST(@deductionId AS VARCHAR(50)) + ',"Value":30000.0,"ValueRatio":null,"Name":null,"CalculatedValue":30000.0,"CalculatedValueRatio":null,"SelectedItem":null,"Type":1}]}', @tenantId
	FROM PayRateTemplateDetail WHERE TenantId = @tenantId AND RuleType = 'DeductionRule' ORDER BY Id DESC

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipIdPrev2, RuleType, RuleValue, '{"Type":1,"TotalRevenue":0.0,"TotalCounselorRevenue":0.0,"TotalGrossProfit":0.0,"CommissionSalary":null,"CommissionSalaryOrigin":0.0,"CommissionParams":[{"CommissionType":1,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"ValueOrigin":null,"ValueRatioOrigin":null,"IsDirty":null,"ProductRevenues":[],"CommissionTable":null,"CommissionSetting":0},{"CommissionType":2,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"ValueOrigin":null,"ValueRatioOrigin":null,"IsDirty":null,"ProductRevenues":[],"CommissionTable":null,"CommissionSetting":0}]}', @tenantId
	FROM PayRateTemplateDetail WHERE TenantId = @tenantId AND RuleType = 'CommissionSalaryRuleV2' ORDER BY Id DESC

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	VALUES (@payslipIdPrev2, 'MainSalaryRule',
		'{"Type":4,"MainSalaryValueDetails":[{"ShiftId":' + CAST(@shiftId2 AS VARCHAR(50)) + ',"Default":7000000.0,"MainSalaryHolidays":[],"Rank":0}]}',
		'{"MainSalaryShifts":[{"ShiftId":' + CAST(@shiftId2 AS VARCHAR(50)) + ',"Salary":7000000.0,"CalculatedSalary":7000000.0,"Default":' + CAST(@workingDaysPrev2 AS VARCHAR(10)) + '.0,"CalculatedDefault":' + CAST(@workingDaysPrev2 AS VARCHAR(50)) + '.0,"MainSalaryByShiftParamDetails":null,"Type":4}]}',
		@tenantId)
END

GO

-- ========================
-- File: pr_Booking_Insert_TrialData_Shifts.sql
-- ========================
ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_Shifts]
(
    @tenantId   INT,        	-- ID gian hàng
    @branchId   INT,        	-- ID chi nhánh
    @userId     BIGINT,     	-- ID tài khoản admin
    @language   NVARCHAR(50),   -- ngôn ngữ (en-US/vi-VN)
    @shiftId1   BIGINT OUTPUT,
    @shiftId2   BIGINT OUTPUT
)
AS
BEGIN
    IF @language = N'en-US'
    BEGIN
        SET @shiftId1 = NEXT VALUE FOR ShiftSeq;
        INSERT INTO [Shift] ([Id], [Name], [From], [To], IsActive, IsDeleted, BranchId, CheckInBefore, CheckOutAfter, TenantId, CreatedBy, CreatedDate)
        VALUES (@shiftId1, N'Morning Shift', 540, 900, 1, 0, @branchId, 360, 1080, @tenantId, @userId, GETDATE());

        SET @shiftId2 = NEXT VALUE FOR ShiftSeq;
        INSERT INTO [Shift] ([Id], [Name], [From], [To], IsActive, IsDeleted, BranchId, CheckInBefore, CheckOutAfter, TenantId, CreatedBy, CreatedDate)
        VALUES (@shiftId2, N'Afternoon - Evening Shift', 900, 1350, 1, 0, @branchId, 720, 90, @tenantId, @userId, GETDATE());
    END
    ELSE
    BEGIN
        SET @shiftId1 = NEXT VALUE FOR ShiftSeq;
        INSERT INTO [Shift] ([Id], [Name], [From], [To], IsActive, IsDeleted, BranchId, CheckInBefore, CheckOutAfter, TenantId, CreatedBy, CreatedDate)
        VALUES (@shiftId1, N'Ca sáng', 540, 900, 1, 0, @branchId, 360, 1080, @tenantId, @userId, GETDATE());

        SET @shiftId2 = NEXT VALUE FOR ShiftSeq;
        INSERT INTO [Shift] ([Id], [Name], [From], [To], IsActive, IsDeleted, BranchId, CheckInBefore, CheckOutAfter, TenantId, CreatedBy, CreatedDate)
        VALUES (@shiftId2, N'Ca chiều - tối', 900, 1350, 1, 0, @branchId, 720, 90, @tenantId, @userId, GETDATE());
    END
END

GO

-- ========================
-- File: pr_Booking_Insert_TrialData_TimeSheet.sql
-- ========================
ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_TimeSheet]
(
    @tenantId			INT,			-- ID gian hàng
	@branchId			INT,			-- ID chi nhánh
	@userId				BIGINT,			-- ID tài khoản admin
	@employeeId1		BIGINT,			-- ID nhân viên 1
	@employeeId2		BIGINT,			-- ID nhân viên 2
	@startDate			DATETIME,		-- Ngày bắt đầu
	@endDate			DATETIME,		-- Ngày kết thúc
	@useNewTimeSheet	BIT,			-- Gian hàng dùng Lịch làm việc 1.0/2.0
	@monday				DATETIME,		-- Thứ 2 của tuần hiện tại
	@sunday				DATETIME,		-- Chủ nhật của tuần hiện tại
    @timeSheetId1		BIGINT OUTPUT,
    @timeSheetId2		BIGINT OUTPUT,
    @prevTimeSheetId1	BIGINT OUTPUT,
    @prevTimeSheetId2	BIGINT OUTPUT
)
AS
BEGIN
	-- Tạo TimeSheet tháng hiện tại
	DECLARE @timeSheetStartDate DATETIME
	DECLARE @timeSheetEndDate DATETIME
	SET @timeSheetStartDate = (SELECT case when @useNewTimeSheet = 1 then @monday else @startDate end)
	SET @timeSheetEndDate = (SELECT case when @useNewTimeSheet = 1 then @sunday else @endDate end)

	DECLARE @timeSheetRepeatType TINYINT
	SET @timeSheetRepeatType = (SELECT case when @useNewTimeSheet = 1 then 2 else 1 end)

	SET @timeSheetId1 = NEXT VALUE FOR TimeSheetSeq
	INSERT INTO TimeSheet (Id, EmployeeId, StartDate, EndDate, IsRepeat, RepeatType, RepeatEachDay, BranchId, TenantId, CreatedBy, CreatedDate, IsDeleted, TimeSheetStatus, SaveOnDaysOffOfBranch, SaveOnHoliday, AutoGenerateClockingStatus)
	VALUES (@timeSheetId1, @employeeId1, @timeSheetStartDate, @timeSheetEndDate, 1, @timeSheetRepeatType, 1, @branchId, @tenantId, @userId, GETDATE(), 0, 1, 0, 0, 0)

	SET @timeSheetId2 = NEXT VALUE FOR TimeSheetSeq
	INSERT INTO TimeSheet (Id, EmployeeId, StartDate, EndDate, IsRepeat, RepeatType, RepeatEachDay, BranchId, TenantId, CreatedBy, CreatedDate, IsDeleted, TimeSheetStatus, SaveOnDaysOffOfBranch, SaveOnHoliday, AutoGenerateClockingStatus)
	VALUES (@timeSheetId2, @employeeId2, @timeSheetStartDate, @timeSheetEndDate, 1, @timeSheetRepeatType, 1, @branchId, @tenantId, @userId, GETDATE(), 0, 1, 0, 0, 0)

	--Tạo TimeSheet tháng trước
	IF @useNewTimeSheet = 1
	BEGIN
		-- TimeSheet 2.0: Tạo 4 tuần cho tháng trước
		DECLARE @prevMonthStart DATETIME = DATEADD(MONTH, -1, DATEADD(DAY, 1 - DAY(GETDATE()), GETDATE()))
		DECLARE @week1Monday DATETIME = CAST(CONVERT(CHAR(8), DATEADD(dd, 0 - (@@DATEFIRST + 5 + DATEPART(dw, @prevMonthStart)) % 7, @prevMonthStart), 112) + ' 00:00:00.00' AS datetime)

		IF @week1Monday < @prevMonthStart
			SET @week1Monday = DATEADD(DAY, 7, @week1Monday)

		-- Tạo 4 tuần
		DECLARE @weekCounter INT = 0
		DECLARE @currentMonday DATETIME = @week1Monday
		DECLARE @currentSunday DATETIME

		WHILE @weekCounter < 4
		BEGIN
			SET @currentSunday = CAST(CONVERT(CHAR(8), DATEADD(dd, 6 - (@@DATEFIRST + 5 + DATEPART(dw, @currentMonday)) % 7, @currentMonday), 112) + ' 23:59:59.00' AS datetime)

			IF @weekCounter = 0
			BEGIN
				-- Tuần 1 - save temp ID để return
				SET @prevTimeSheetId1 = NEXT VALUE FOR TimeSheetSeq
				INSERT INTO TimeSheet (Id, EmployeeId, StartDate, EndDate, IsRepeat, RepeatType, RepeatEachDay, BranchId, TenantId, CreatedBy, CreatedDate, IsDeleted, TimeSheetStatus, SaveOnDaysOffOfBranch, SaveOnHoliday, AutoGenerateClockingStatus)
				VALUES (@prevTimeSheetId1, @employeeId1, @currentMonday, @currentSunday, 1, @timeSheetRepeatType, 1, @branchId, @tenantId, @userId, DATEADD(MONTH, -1, GETDATE()), 0, 1, 0, 0, 0)

				SET @prevTimeSheetId2 = NEXT VALUE FOR TimeSheetSeq
				INSERT INTO TimeSheet (Id, EmployeeId, StartDate, EndDate, IsRepeat, RepeatType, RepeatEachDay, BranchId, TenantId, CreatedBy, CreatedDate, IsDeleted, TimeSheetStatus, SaveOnDaysOffOfBranch, SaveOnHoliday, AutoGenerateClockingStatus)
				VALUES (@prevTimeSheetId2, @employeeId2, @currentMonday, @currentSunday, 1, @timeSheetRepeatType, 1, @branchId, @tenantId, @userId, DATEADD(MONTH, -1, GETDATE()), 0, 1, 0, 0, 0)
			END
			ELSE
			BEGIN
				-- Tuần 2, 3, 4
				DECLARE @tempId1 BIGINT = NEXT VALUE FOR TimeSheetSeq
				INSERT INTO TimeSheet (Id, EmployeeId, StartDate, EndDate, IsRepeat, RepeatType, RepeatEachDay, BranchId, TenantId, CreatedBy, CreatedDate, IsDeleted, TimeSheetStatus, SaveOnDaysOffOfBranch, SaveOnHoliday, AutoGenerateClockingStatus)
				VALUES (@tempId1, @employeeId1, @currentMonday, @currentSunday, 1, @timeSheetRepeatType, 1, @branchId, @tenantId, @userId, DATEADD(MONTH, -1, GETDATE()), 0, 1, 0, 0, 0)

				DECLARE @tempId2 BIGINT = NEXT VALUE FOR TimeSheetSeq
				INSERT INTO TimeSheet (Id, EmployeeId, StartDate, EndDate, IsRepeat, RepeatType, RepeatEachDay, BranchId, TenantId, CreatedBy, CreatedDate, IsDeleted, TimeSheetStatus, SaveOnDaysOffOfBranch, SaveOnHoliday, AutoGenerateClockingStatus)
				VALUES (@tempId2, @employeeId2, @currentMonday, @currentSunday, 1, @timeSheetRepeatType, 1, @branchId, @tenantId, @userId, DATEADD(MONTH, -1, GETDATE()), 0, 1, 0, 0, 0)
			END

			SET @currentMonday = DATEADD(DAY, 7, @currentMonday)
			SET @weekCounter = @weekCounter + 1
		END
	END
	ELSE
	BEGIN
		-- TimeSheet 1.0: Cả tháng trước
		DECLARE @firstDayPrevMonth DATE = DATEFROMPARTS(YEAR(@startDate), MONTH(@startDate) - 1, 1)
		DECLARE @lastDayPrevMonth DATE = EOMONTH(@startDate, -1)

		SET @prevTimeSheetId1 = NEXT VALUE FOR TimeSheetSeq
		INSERT INTO TimeSheet (Id, EmployeeId, StartDate, EndDate, IsRepeat, RepeatType, RepeatEachDay, BranchId, TenantId, CreatedBy, CreatedDate, IsDeleted, TimeSheetStatus, SaveOnDaysOffOfBranch, SaveOnHoliday, AutoGenerateClockingStatus)
		VALUES (@prevTimeSheetId1, @employeeId1, @firstDayPrevMonth, @lastDayPrevMonth, 1, @timeSheetRepeatType, 1, @branchId, @tenantId, @userId, DATEADD(MONTH, -1, GETDATE()), 0, 1, 0, 0, 0)

		SET @prevTimeSheetId2 = NEXT VALUE FOR TimeSheetSeq
		INSERT INTO TimeSheet (Id, EmployeeId, StartDate, EndDate, IsRepeat, RepeatType, RepeatEachDay, BranchId, TenantId, CreatedBy, CreatedDate, IsDeleted, TimeSheetStatus, SaveOnDaysOffOfBranch, SaveOnHoliday, AutoGenerateClockingStatus)
		VALUES (@prevTimeSheetId2, @employeeId2, @firstDayPrevMonth, @lastDayPrevMonth, 1, @timeSheetRepeatType, 1, @branchId, @tenantId, @userId, DATEADD(MONTH, -1, GETDATE()), 0, 1, 0, 0, 0)
	END
END

GO

-- ========================
-- File: pr_Booking_Insert_TrialData_TimeSheetShift.sql
-- ========================
ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_TimeSheetShift]
(
	@shiftId1			VARCHAR(50),
	@shiftId2			VARCHAR(50),
	@timeSheetId1		BIGINT,
	@timeSheetId2		BIGINT,
	@prevTimeSheetId1	BIGINT,
	@prevTimeSheetId2	BIGINT,
	@useNewTimeSheet	BIT,
	@workingDays1		INT OUTPUT,		-- Số ngày công tháng hiện tại nhân viên 1
	@workingDays2		INT OUTPUT,		-- Số ngày công tháng hiện tại nhân viên 2
	@workingDaysPrev1	INT OUTPUT,		-- Số ngày công tháng trước nhân viên 1
	@workingDaysPrev2	INT OUTPUT		-- Số ngày công tháng trước nhân viên 2
)
AS
BEGIN
	DECLARE @repeatDaysOfWeek1 NVARCHAR(500)
	DECLARE @repeatDaysOfWeek2 NVARCHAR(500)

	--Thiết lập RepeatDaysOfWeek chính xác
	IF @useNewTimeSheet = 1
	BEGIN
		-- TimeSheet 2.0: Sử dụng RepeatDaysOfWeek
		SET @repeatDaysOfWeek1 = '1,2,3,4,5,6'  -- Thứ 2-7 (6 ngày)
		SET @repeatDaysOfWeek2 = '1,3,5'        -- Thứ 2,4,6 (3 ngày)
	END
	ELSE
	BEGIN
		-- TimeSheet 1.0: Không sử dụng RepeatDaysOfWeek
		SET @repeatDaysOfWeek1 = NULL
		SET @repeatDaysOfWeek2 = NULL
	END

	-- Tạo TimeSheetShift cho tháng hiện tại
	INSERT INTO [TimeSheetShift] (TimeSheetId, ShiftIds, RepeatDaysOfWeek)
	VALUES (@timeSheetId1, @shiftId1, @repeatDaysOfWeek1)

	INSERT INTO [TimeSheetShift] (TimeSheetId, ShiftIds, RepeatDaysOfWeek)
	VALUES (@timeSheetId2, @shiftId2, @repeatDaysOfWeek2)

	-- Tạo TimeSheetShift cho tháng trước
	IF @useNewTimeSheet = 1
	BEGIN
		-- Tìm tất cả TimeSheet của tháng trước
		DECLARE @employeeId1 BIGINT = (SELECT EmployeeId FROM TimeSheet WHERE Id = @timeSheetId1)
		DECLARE @employeeId2 BIGINT = (SELECT EmployeeId FROM TimeSheet WHERE Id = @timeSheetId2)
		DECLARE @prevMonth DATETIME = DATEADD(MONTH, -1, GETDATE())

		-- Tạo cho tất cả TimeSheet tháng trước
		INSERT INTO [TimeSheetShift] (TimeSheetId, ShiftIds, RepeatDaysOfWeek)
		SELECT Id, @shiftId1, @repeatDaysOfWeek1
		FROM TimeSheet
		WHERE EmployeeId = @employeeId1
		  AND MONTH(CreatedDate) = MONTH(@prevMonth)
		  AND YEAR(CreatedDate) = YEAR(@prevMonth)
		  AND Id != @timeSheetId1

		INSERT INTO [TimeSheetShift] (TimeSheetId, ShiftIds, RepeatDaysOfWeek)
		SELECT Id, @shiftId2, @repeatDaysOfWeek2
		FROM TimeSheet
		WHERE EmployeeId = @employeeId2
		  AND MONTH(CreatedDate) = MONTH(@prevMonth)
		  AND YEAR(CreatedDate) = YEAR(@prevMonth)
		  AND Id != @timeSheetId2
	END
	ELSE
	BEGIN
		-- TimeSheet 1.0
		INSERT INTO [TimeSheetShift] (TimeSheetId, ShiftIds, RepeatDaysOfWeek)
		VALUES (@prevTimeSheetId1, @shiftId1, @repeatDaysOfWeek1)

		INSERT INTO [TimeSheetShift] (TimeSheetId, ShiftIds, RepeatDaysOfWeek)
		VALUES (@prevTimeSheetId2, @shiftId2, @repeatDaysOfWeek2)
	END

	-- Logic tính số ngày làm việc CHÍNH XÁC
	IF @useNewTimeSheet = 1
	BEGIN
		-- TimeSheet 2.0: Dựa trên RepeatDaysOfWeek
		DECLARE @weeklyDays1 INT
		DECLARE @weeklyDays2 INT

		-- Đếm số ngày trong tuần từ RepeatDaysOfWeek
		-- '1,2,3,4,5,6' = 6 ngày
		-- '1,3,5' = 3 ngày
		SET @weeklyDays1 = (LEN(@repeatDaysOfWeek1) - LEN(REPLACE(@repeatDaysOfWeek1, ',', '')) + 1)
		SET @weeklyDays2 = (LEN(@repeatDaysOfWeek2) - LEN(REPLACE(@repeatDaysOfWeek2, ',', '')) + 1)

		-- Tháng hiện tại: 1 tuần
		SET @workingDays1 = @weeklyDays1      -- 6 ngày
		SET @workingDays2 = @weeklyDays2      -- 3 ngày

		-- Tháng trước: 4 tuần
		SET @workingDaysPrev1 = @weeklyDays1 * 4  -- 24 ngày
		SET @workingDaysPrev2 = @weeklyDays2 * 4  -- 12 ngày
	END
	ELSE
	BEGIN
		-- TimeSheet 1.0: Dựa trên số ngày trong tháng
		DECLARE @currentMonthDays INT = DAY(EOMONTH(GETDATE()))
		DECLARE @prevMonthDays INT = DAY(EOMONTH(DATEADD(MONTH, -1, GETDATE())))

		-- Giả sử làm việc tất cả các ngày trong tháng
		SET @workingDays1 = @currentMonthDays
		SET @workingDays2 = @currentMonthDays
		SET @workingDaysPrev1 = @prevMonthDays
		SET @workingDaysPrev2 = @prevMonthDays
	END

END

GO

ALTER PROC [dbo].[pr_GetNextEmployeeCode]
@RetailerId INT = 0
AS
BEGIN

DECLARE @Identity BIGINT = 1;
		DECLARE @MaxCode NVARCHAR(64);

		SELECT TOP 1 @MaxCode = Code
		FROM Employee
		WHERE TenantId = @RetailerId
		AND  Code LIKE N'NV[0-9]%'
		AND SUBSTRING(Code, LEN(N'NV') + 1, LEN(Code)) NOT LIKE N'%[^0-9]%'
		AND LEN(SUBSTRING(Code, LEN('NV') + 1, LEN(Code))) <= 10
		ORDER BY Code DESC

		IF @MaxCode IS NULL
		BEGIN
		    SET @Identity = 1
		END
		ELSE
		BEGIN
			DECLARE @CurrentIdentity NVARCHAR(64)
			SELECT @CurrentIdentity = REPLACE(@MaxCode, 'NV','')
			SELECT @Identity = CAST( @CurrentIdentity AS BIGINT) + 1;
		END

	SELECT @MaxCode as NextCode

END

GO

ALTER PROCEDURE [dbo].[pr_Update_Clocking_Time]
(
    @tenantId    INT,
    @branchId    INT,
    @shiftId     BIGINT,
    @shiftFrom   BIGINT,
    @shiftTo     BIGINT,
    @returnValue BIGINT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @comparedDate DATETIME2= CONVERT(DATE, DATEADD(day, -30, GETDATE()));
	DECLARE @increment INT = 0;
	IF @shiftFrom < @shiftTo -- Ca trong ngày
		SET @increment = 0
	ELSE -- Ca qua đêm
		SET @increment = 1
    UPDATE dbo.Clocking
    SET    StartTime = DATEADD(minute, @shiftFrom, CONVERT(DATETIME2, CONVERT(DATE, StartTime))),
           EndTime = DATEADD(minute, @shiftTo, CONVERT(DATETIME2, CONVERT(DATE, DATEADD(day, @increment, StartTime))))
    WHERE  TenantId = @tenantId
           AND BranchId = @branchId
           AND ShiftId = @shiftId
           AND NOT(IsDeleted IS NOT NULL
                   AND IsDeleted = 1)
           AND CheckInDate IS NULL
           AND CheckOutDate IS NULL
           AND StartTime >= @comparedDate
    SET @returnValue = @@ROWCOUNT
END

GO

	ALTER PROCEDURE dbo.sp_alterdiagram
	(
		@diagramname 	sysname,
		@owner_id	int	= null,
		@version 	int,
		@definition 	varbinary(max)
	)
	WITH EXECUTE AS 'dbo'
	AS
	BEGIN
		set nocount on

		declare @theId 			int
		declare @retval 		int
		declare @IsDbo 			int

		declare @UIDFound 		int
		declare @DiagId			int
		declare @ShouldChangeUID	int

		if(@diagramname is null)
		begin
			RAISERROR ('Invalid ARG', 16, 1)
			return -1
		end

		execute as caller;
		select @theId = DATABASE_PRINCIPAL_ID();
		select @IsDbo = IS_MEMBER(N'db_owner');
		if(@owner_id is null)
			select @owner_id = @theId;
		revert;

		select @ShouldChangeUID = 0
		select @DiagId = diagram_id, @UIDFound = principal_id from dbo.sysdiagrams where principal_id = @owner_id and name = @diagramname

		if(@DiagId IS NULL or (@IsDbo = 0 and @theId <> @UIDFound))
		begin
			RAISERROR ('Diagram does not exist or you do not have permission.', 16, 1);
			return -3
		end

		if(@IsDbo <> 0)
		begin
			if(@UIDFound is null or USER_NAME(@UIDFound) is null) -- invalid principal_id
			begin
				select @ShouldChangeUID = 1 ;
			end
		end

		-- update dds data
		update dbo.sysdiagrams set definition = @definition where diagram_id = @DiagId ;

		-- change owner
		if(@ShouldChangeUID = 1)
			update dbo.sysdiagrams set principal_id = @theId where diagram_id = @DiagId ;

		-- update dds version
		if(@version is not null)
			update dbo.sysdiagrams set version = @version where diagram_id = @DiagId ;

		return 0
	END


GO

	ALTER PROCEDURE dbo.sp_creatediagram
	(
		@diagramname 	sysname,
		@owner_id		int	= null,
		@version 		int,
		@definition 	varbinary(max)
	)
	WITH EXECUTE AS 'dbo'
	AS
	BEGIN
		set nocount on

		declare @theId int
		declare @retval int
		declare @IsDbo	int
		declare @userName sysname
		if(@version is null or @diagramname is null)
		begin
			RAISERROR (N'E_INVALIDARG', 16, 1);
			return -1
		end

		execute as caller;
		select @theId = DATABASE_PRINCIPAL_ID();
		select @IsDbo = IS_MEMBER(N'db_owner');
		revert;

		if @owner_id is null
		begin
			select @owner_id = @theId;
		end
		else
		begin
			if @theId <> @owner_id
			begin
				if @IsDbo = 0
				begin
					RAISERROR (N'E_INVALIDARG', 16, 1);
					return -1
				end
				select @theId = @owner_id
			end
		end
		-- next 2 line only for test, will be removed after define name unique
		if EXISTS(select diagram_id from dbo.sysdiagrams where principal_id = @theId and name = @diagramname)
		begin
			RAISERROR ('The name is already used.', 16, 1);
			return -2
		end

		insert into dbo.sysdiagrams(name, principal_id , version, definition)
				VALUES(@diagramname, @theId, @version, @definition) ;

		select @retval = @@IDENTITY
		return @retval
	END


GO

	ALTER PROCEDURE dbo.sp_dropdiagram
	(
		@diagramname 	sysname,
		@owner_id	int	= null
	)
	WITH EXECUTE AS 'dbo'
	AS
	BEGIN
		set nocount on
		declare @theId 			int
		declare @IsDbo 			int

		declare @UIDFound 		int
		declare @DiagId			int

		if(@diagramname is null)
		begin
			RAISERROR ('Invalid value', 16, 1);
			return -1
		end

		EXECUTE AS CALLER;
		select @theId = DATABASE_PRINCIPAL_ID();
		select @IsDbo = IS_MEMBER(N'db_owner');
		if(@owner_id is null)
			select @owner_id = @theId;
		REVERT;

		select @DiagId = diagram_id, @UIDFound = principal_id from dbo.sysdiagrams where principal_id = @owner_id and name = @diagramname
		if(@DiagId IS NULL or (@IsDbo = 0 and @UIDFound <> @theId))
		begin
			RAISERROR ('Diagram does not exist or you do not have permission.', 16, 1)
			return -3
		end

		delete from dbo.sysdiagrams where diagram_id = @DiagId;

		return 0;
	END


GO

	ALTER PROCEDURE dbo.sp_helpdiagramdefinition
	(
		@diagramname 	sysname,
		@owner_id	int	= null
	)
	WITH EXECUTE AS N'dbo'
	AS
	BEGIN
		set nocount on

		declare @theId 		int
		declare @IsDbo 		int
		declare @DiagId		int
		declare @UIDFound	int

		if(@diagramname is null)
		begin
			RAISERROR (N'E_INVALIDARG', 16, 1);
			return -1
		end

		execute as caller;
		select @theId = DATABASE_PRINCIPAL_ID();
		select @IsDbo = IS_MEMBER(N'db_owner');
		if(@owner_id is null)
			select @owner_id = @theId;
		revert;

		select @DiagId = diagram_id, @UIDFound = principal_id from dbo.sysdiagrams where principal_id = @owner_id and name = @diagramname;
		if(@DiagId IS NULL or (@IsDbo = 0 and @UIDFound <> @theId ))
		begin
			RAISERROR ('Diagram does not exist or you do not have permission.', 16, 1);
			return -3
		end

		select version, definition FROM dbo.sysdiagrams where diagram_id = @DiagId ;
		return 0
	END


GO

	ALTER PROCEDURE dbo.sp_helpdiagrams
	(
		@diagramname sysname = NULL,
		@owner_id int = NULL
	)
	WITH EXECUTE AS N'dbo'
	AS
	BEGIN
		DECLARE @user sysname
		DECLARE @dboLogin bit
		EXECUTE AS CALLER;
			SET @user = USER_NAME();
			SET @dboLogin = CONVERT(bit,IS_MEMBER('db_owner'));
		REVERT;
		SELECT
			[Database] = DB_NAME(),
			[Name] = name,
			[ID] = diagram_id,
			[Owner] = USER_NAME(principal_id),
			[OwnerID] = principal_id
		FROM
			sysdiagrams
		WHERE
			(@dboLogin = 1 OR USER_NAME(principal_id) = @user) AND
			(@diagramname IS NULL OR name = @diagramname) AND
			(@owner_id IS NULL OR principal_id = @owner_id)
		ORDER BY
			4, 5, 1
	END


GO

-- Helper stored procedure to reduce code duplication
ALTER   PROCEDURE [dbo].[sp_InsertPayslipDetailsForEmployee]
(
    @payslipId BIGINT,
    @tenantId INT,
    @allowanceTemplate NVARCHAR(MAX),
    @deductionTemplate NVARCHAR(MAX),
    @commissionTemplate NVARCHAR(MAX),
    @mainSalaryAmount DECIMAL(18,2),
    @calculatedDays DECIMAL(5,2)
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Insert Allowance Rule
    INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
    SELECT TOP 1 @payslipId, RuleType, RuleValue, @allowanceTemplate, @tenantId
    FROM PayRateTemplateDetail
    WHERE TenantId = @tenantId AND RuleType = 'AllowanceRule'
    ORDER BY Id DESC;

    -- Insert Deduction Rule
    INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
    SELECT TOP 1 @payslipId, RuleType, RuleValue, @deductionTemplate, @tenantId
    FROM PayRateTemplateDetail
    WHERE TenantId = @tenantId AND RuleType = 'DeductionRule'
    ORDER BY Id DESC;

    -- Insert Commission Rule
    INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
    SELECT TOP 1 @payslipId, RuleType, RuleValue, @commissionTemplate, @tenantId
    FROM PayRateTemplateDetail
    WHERE TenantId = @tenantId AND RuleType = 'CommissionSalaryRuleV2'
    ORDER BY Id DESC;

    -- Insert Main Salary Rule
    DECLARE @mainSalaryRuleValue NVARCHAR(MAX) =
        '{"Type":4,"MainSalaryValueDetails":[{"ShiftId":0,"Default":' +
        CAST(@mainSalaryAmount AS VARCHAR(20)) +
        ',"MainSalaryHolidays":[],"Rank":0}]}';

    DECLARE @mainSalaryRuleParam NVARCHAR(MAX) =
        '{"MainSalaryShifts":[{"ShiftId":0,"Salary":' +
        CAST(@mainSalaryAmount AS VARCHAR(20)) +
        ',"CalculatedSalary":' + CAST(@mainSalaryAmount AS VARCHAR(20)) +
        ',"Default":31.0,"CalculatedDefault":' + CAST(@calculatedDays AS VARCHAR(10)) +
        ',"MainSalaryByShiftParamDetails":null,"Type":4}]}';

    INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
    VALUES (@payslipId, 'MainSalaryRule', @mainSalaryRuleValue, @mainSalaryRuleParam, @tenantId);
END

GO

	ALTER PROCEDURE dbo.sp_renamediagram
	(
		@diagramname 		sysname,
		@owner_id		int	= null,
		@new_diagramname	sysname

	)
	WITH EXECUTE AS 'dbo'
	AS
	BEGIN
		set nocount on
		declare @theId 			int
		declare @IsDbo 			int

		declare @UIDFound 		int
		declare @DiagId			int
		declare @DiagIdTarg		int
		declare @u_name			sysname
		if((@diagramname is null) or (@new_diagramname is null))
		begin
			RAISERROR ('Invalid value', 16, 1);
			return -1
		end

		EXECUTE AS CALLER;
		select @theId = DATABASE_PRINCIPAL_ID();
		select @IsDbo = IS_MEMBER(N'db_owner');
		if(@owner_id is null)
			select @owner_id = @theId;
		REVERT;

		select @u_name = USER_NAME(@owner_id)

		select @DiagId = diagram_id, @UIDFound = principal_id from dbo.sysdiagrams where principal_id = @owner_id and name = @diagramname
		if(@DiagId IS NULL or (@IsDbo = 0 and @UIDFound <> @theId))
		begin
			RAISERROR ('Diagram does not exist or you do not have permission.', 16, 1)
			return -3
		end

		-- if((@u_name is not null) and (@new_diagramname = @diagramname))	-- nothing will change
		--	return 0;

		if(@u_name is null)
			select @DiagIdTarg = diagram_id from dbo.sysdiagrams where principal_id = @theId and name = @new_diagramname
		else
			select @DiagIdTarg = diagram_id from dbo.sysdiagrams where principal_id = @owner_id and name = @new_diagramname

		if((@DiagIdTarg is not null) and  @DiagId <> @DiagIdTarg)
		begin
			RAISERROR ('The name is already used.', 16, 1);
			return -2
		end

		if(@u_name is null)
			update dbo.sysdiagrams set [name] = @new_diagramname, principal_id = @theId where diagram_id = @DiagId
		else
			update dbo.sysdiagrams set [name] = @new_diagramname where diagram_id = @DiagId
		return 0
	END


GO

	ALTER PROCEDURE dbo.sp_upgraddiagrams
	AS
	BEGIN
		IF OBJECT_ID(N'dbo.sysdiagrams') IS NOT NULL
			return 0;

		CREATE TABLE dbo.sysdiagrams
		(
			name sysname NOT NULL,
			principal_id int NOT NULL,	-- we may change it to varbinary(85)
			diagram_id int PRIMARY KEY IDENTITY,
			version int,

			definition varbinary(max)
			CONSTRAINT UK_principal_name UNIQUE
			(
				principal_id,
				name
			)
		);

		/* Add this if we need to have some form of extended properties for diagrams */
		/*
		IF OBJECT_ID(N'dbo.sysdiagram_properties') IS NULL
		BEGIN
			CREATE TABLE dbo.sysdiagram_properties
			(
				diagram_id int,
				name sysname,
				value varbinary(max) NOT NULL
			)
		END
		*/

		IF OBJECT_ID(N'dbo.dtproperties') IS NOT NULL
		begin
			insert into dbo.sysdiagrams
			(
				[name],
				[principal_id],
				[version],
				[definition]
			)
			select
				convert(sysname, dgnm.[uvalue]),
				DATABASE_PRINCIPAL_ID(N'dbo'),			-- will change to the sid of sa
				0,							-- zero for old format, dgdef.[version],
				dgdef.[lvalue]
			from dbo.[dtproperties] dgnm
				inner join dbo.[dtproperties] dggd on dggd.[property] = 'DtgSchemaGUID' and dggd.[objectid] = dgnm.[objectid]
				inner join dbo.[dtproperties] dgdef on dgdef.[property] = 'DtgSchemaDATA' and dgdef.[objectid] = dgnm.[objectid]

			where dgnm.[property] = 'DtgSchemaNAME' and dggd.[uvalue] like N'_EA3E6268-D998-11CE-9454-00AA00A3F36E_'
			return 2;
		end
		return 1;
	END


GO

COMMIT;
