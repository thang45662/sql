BEGIN TRANSACTION;
GO
-- ========================
-- File: pr_Auto_Keeping.sql
-- ========================
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

-- ========================
-- File: pr_Booking_Delete_TrialData.sql
-- ========================
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

-- ========================
-- File: pr_Booking_Delete_TrialData_Allowance.sql
-- ========================
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

-- ========================
-- File: pr_Booking_Delete_TrialData_Clocking.sql
-- ========================
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

-- ========================
-- File: pr_Booking_Delete_TrialData_Deduction.sql
-- ========================
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

-- ========================
-- File: pr_Booking_Delete_TrialData_Employees.sql
-- ========================
ALTER PROCEDURE [dbo].[pr_Booking_Delete_TrialData_Employees]
(
@tenantId INT, -- ID gian hàng
@userId BIGINT -- ID tài khoản admin
)
AS
BEGIN
UPDATE Employee
SET [Code] += '{DEL}', [Name] += '{DEL}', ModifiedBy = @userId, ModifiedDate = GETDATE(), IsDeleted = 1, DeletedBy = @userId, DeletedDate = GETDATE()
WHERE (TenantId = @tenantId) AND (IsDeleted = 0) AND (UserId <> @userId OR UserId IS NULL)
END

GO

-- ========================
-- File: pr_Booking_Delete_TrialData_PayRateTemplate.sql
-- ========================
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

-- ========================
-- File: pr_Booking_Delete_TrialData_Paysheet.sql
-- ========================
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

-- ========================
-- File: pr_Booking_Delete_TrialData_Payslip.sql
-- ========================
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

-- ========================
-- File: pr_Booking_Delete_TrialData_PayslipClocking.sql
-- ========================
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

-- ========================
-- File: pr_Booking_Delete_TrialData_Shifts.sql
-- ========================
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

-- ========================
-- File: pr_Booking_Delete_TrialData_TimeSheet.sql
-- ========================
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

-- ========================
-- File: pr_Booking_Insert_TrialData.sql
-- ========================
ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData]
(
@tenantId INT, -- ID gian hàng
@branchId INT, -- ID chi nhánh
@userIdAdmin BIGINT, -- ID tài khoản admin
@userId1 BIGINT, -- ID tài khoản nhân viên 1
@userId2 BIGINT, -- ID tài khoản nhân viên 2
@commissionId BIGINT -- ID bảng hoa hồng
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

-- Tạo ca làm việc
EXEC [pr_Booking_Insert_TrialData_Shifts] @tenantId, @branchId, @userIdAdmin, @shiftId1 OUTPUT, @shiftId2 OUTPUT

-- Tạo nhân viên
EXEC [pr_Booking_Insert_TrialData_Employees] @tenantId, @branchId, @userIdAdmin, @userId1, @userId2, @employeeId1 OUTPUT, @employeeId2 OUTPUT

-- tạo phụ cấp
EXEC [pr_Booking_Insert_TrialData_Allowance] @tenantId, @userIdAdmin, @allowanceId OUTPUT

-- tạo giảm trừ
EXEC [pr_Booking_Insert_TrialData_Deduction] @tenantId, @userIdAdmin, @deductionId OUTPUT

-- tạo mẫu lương
EXEC [pr_Booking_Insert_TrialData_PayRateTemplate] @tenantId, @branchId, @userIdAdmin, @payRateTemplateId OUTPUT
EXEC [pr_Booking_Insert_TrialData_PayRateTemplateDetail] @tenantId, @userIdAdmin, @payRateTemplateId, @commissionId, @allowanceId, @deductionId

-- tạo thiết lập lương
EXEC [pr_Booking_Insert_TrialData_PayRate] @tenantId, @userIdAdmin, @payRateTemplateId, @employeeId1, @employeeId2, @payRateId1 OUTPUT, @payRateId2 OUTPUT
EXEC [pr_Booking_Insert_TrialData_PayRateDetail] @tenantId, @commissionId, @allowanceId, @deductionId, @payRateId1, @payRateId2, @employeeId1, @employeeId2

-- tạo ca làm việc
DECLARE @startDate DATETIME
DECLARE @endDate DATETIME
SET @startDate = (SELECT DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0))
SET @endDate = (SELECT CAST(CONVERT(CHAR(8), GETDATE() - 1, 112) + ' 23:59:59.00' AS datetime))

EXEC [pr_Booking_Insert_TrialData_TimeSheet] @tenantId, @branchId, @userIdAdmin, @employeeId1, @employeeId2, @startDate, @endDate, @timeSheetId1 OUTPUT, @timeSheetId2 OUTPUT
EXEC [pr_Booking_Insert_TrialData_TimeSheetShift] @shiftId1 , @shiftId2, @timeSheetId1, @timeSheetId2

-- tạo chấm công
EXEC [pr_Booking_Insert_TrialData_Clocking] @tenantId, @branchId, @userIdAdmin, @employeeId1, @employeeId2, @startDate, @endDate, @shiftId1, @shiftId2, @timeSheetId1, @timeSheetId2

-- tạo bảng lương
EXEC [pr_Booking_Insert_TrialData_Paysheet] @tenantId, @branchId, @userIdAdmin, @startDate, @paysheetId OUTPUT

-- tạo phiếu lương
EXEC [pr_Booking_Insert_TrialData_Payslip] @tenantId, @branchId, @userIdAdmin, @employeeId1, @employeeId2, @paysheetId, @payslipId1 OUTPUT, @payslipId2 OUTPUT

--
EXEC [pr_Booking_Insert_TrialData_PayslipClocking] @tenantId, @userIdAdmin, @employeeId1, @employeeId2, @payslipId1, @payslipId2

-- tạo chi tiết phiếu lương
EXEC [pr_Booking_Insert_TrialData_PayslipDetail] @tenantId, @userIdAdmin, @employeeId1, @employeeId2, @payslipId1, @payslipId2, @allowanceId, @deductionId

SELECT * FROM Employee WHERE TenantId = @tenantId AND IsDeleted = 0 AND UserId != @userIdAdmin
END


GO

-- ========================
-- File: pr_Booking_Insert_TrialData_Allowance.sql
-- ========================
ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_Allowance]
(
    @tenantId	INT,			-- ID gian hàng
	@userId		BIGINT,			-- ID tài khoản admin
	@allowanceId	BIGINT OUTPUT
)
AS
BEGIN
	SET @allowanceId = NEXT VALUE FOR AllowanceSeq

	INSERT INTO Allowance (Id, [Name], CreatedBy, CreatedDate, TenantId, Code, IsDeleted, [Value], ValueRatio, [Type], IsChecked, [Rank], test)
	VALUES        (@allowanceId, N'Ăn uống', @userId, GETDATE(), @tenantId, 'PC000001', 0, 50000, 0, 1, 1, 0, 0)
END

GO

-- ========================
-- File: pr_Booking_Insert_TrialData_Clocking.sql
-- ========================
ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_Clocking]
(
    @tenantId	INT,			-- ID gian hàng
	@branchId	INT,			-- ID chi nhánh
	@userId	BIGINT,				-- ID tài khoản admin
	@employeeId1	BIGINT,		-- ID nhân viên 1
	@employeeId2	BIGINT,		-- ID nhân viên 2
	@startDate	DATETIME,		-- Ngày bắt đầu
	@endDate	DATETIME,		-- Ngày kết thúc
	@shiftId1	BIGINT,			-- ID ca 1
	@shiftId2	BIGINT,			-- ID ca 2
	@timeSheetId1	BIGINT,		-- ID lịch làm việc ca 1
	@timeSheetId2	BIGINT		-- ID lịch làm việc ca 2
)
AS
BEGIN
	DECLARE @startDateCaSang DATETIME
	DECLARE @startDateCaSangDiTre DATETIME
	DECLARE @startDateCaChieu DATETIME
	DECLARE @startDateCaChieuDiTre DATETIME
	DECLARE @endDateCaSang DATETIME
	DECLARE @endDateCaChieu DATETIME
	DECLARE @clockingId BIGINT
	DECLARE @clockingHistoryId BIGINT

	DECLARE @dateNumber INT
	SET @dateNumber = (SELECT DATEDIFF(DAY, StartDate, EndDate) + 1 FROM TimeSheet WHERE TenantId = @tenantId AND EmployeeId = @employeeId1)

	-- Insert đi trễ ca sáng lần 1
	SET @clockingId = NEXT VALUE FOR ClockingSeq
	SET @startDateCaSang = (SELECT CAST(CONVERT(CHAR(8), @startDate, 112) + ' 09:00:00' AS datetime))
	SET @startDateCaSangDiTre = (SELECT CAST(CONVERT(CHAR(8), @startDate, 112) + ' 09:15:00' AS datetime))
	SET @endDateCaSang = (SELECT CAST(CONVERT(CHAR(8), @startDate, 112) + ' 15:00:00' AS datetime))
	INSERT INTO Clocking (Id, TimeSheetId, ShiftId, EmployeeId, WorkById, ClockingStatus, StartTime, EndTime, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted, CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork,  ClockingPaymentStatus)
	VALUES        (@clockingId, @timeSheetId1, @shiftId1, @employeeId1, @employeeId1, 3, @startDateCaSang, @endDateCaSang, @tenantId, @branchId, @userId, GETDATE(), 0, @startDateCaSangDiTre, @endDateCaSang, 15, 0, 0, 0, 0)

	SET @clockingHistoryId = NEXT VALUE FOR ClockingHistorySeq
	INSERT INTO ClockingHistory (Id, ClockingId, CheckedInDate, CheckedOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, TenantId, BranchId, TimeKeepingType, ClockingStatus, CreatedBy, CreatedDate, ClockingHistoryStatus, TimeIsLateAdjustment, OverTimeBeforeShiftWorkAdjustment, TimeIsLeaveWorkEarlyAdjustment, OverTimeAfterShiftWorkAdjustment, ShiftId, ShiftFrom, ShiftTo,
                         EmployeeId, CheckTime)
	VALUES        (@clockingHistoryId, @clockingId, @startDateCaSangDiTre, @endDateCaSang, 15, 0, 0, 0, @tenantId, @branchId, 1, 3, @userId, GETDATE(), 1, 0, 0, 0, 0, @shiftId1, 540, 900, @employeeId1, GETDATE())

	-- Insert đi trễ ca chiều lần 1
	SET @startDateCaChieu = (SELECT CAST(CONVERT(CHAR(8), @startDate, 112) + ' 15:00:00' AS datetime))
	SET @startDateCaChieuDiTre = (SELECT CAST(CONVERT(CHAR(8), @startDate, 112) + ' 15:15:00' AS datetime))
	SET @endDateCaChieu = (SELECT CAST(CONVERT(CHAR(8), @startDate, 112) + ' 22:30:00' AS datetime))
	SET @clockingId = NEXT VALUE FOR ClockingSeq
	INSERT INTO Clocking (Id, TimeSheetId, ShiftId, EmployeeId, WorkById, ClockingStatus, StartTime, EndTime, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted, CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork,  ClockingPaymentStatus)
	VALUES        (@clockingId, @timeSheetId2, @shiftId2, @employeeId2, @employeeId2, 3, @startDateCaChieu, @endDateCaChieu, @tenantId, @branchId, @userId, GETDATE(), 0, @startDateCaChieuDiTre, @endDateCaChieu, 15, 0, 0, 0, 0)

	SET @clockingHistoryId = NEXT VALUE FOR ClockingHistorySeq
	INSERT INTO ClockingHistory (Id, ClockingId, CheckedInDate, CheckedOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, TenantId, BranchId, TimeKeepingType, ClockingStatus, CreatedBy, CreatedDate, ClockingHistoryStatus, TimeIsLateAdjustment, OverTimeBeforeShiftWorkAdjustment, TimeIsLeaveWorkEarlyAdjustment, OverTimeAfterShiftWorkAdjustment, ShiftId, ShiftFrom, ShiftTo,
                         EmployeeId, CheckTime)
	VALUES        (@clockingHistoryId, @clockingId, @startDateCaChieuDiTre, @endDateCaChieu, 15, 0, 0, 0, @tenantId, @branchId, 1, 3, @userId, GETDATE(), 1, 0, 0, 0, 0, @shiftId2, 900, 1350, @employeeId1, GETDATE())

	-- Insert đi trễ ca sáng lần 2
	SET @startDate = DATEADD(DAY, 1, @startDate)
	SET @startDateCaSang = (SELECT CAST(CONVERT(CHAR(8), @startDate, 112) + ' 09:00:00' AS datetime))
	SET @startDateCaSangDiTre = (SELECT CAST(CONVERT(CHAR(8), @startDate, 112) + ' 09:15:00' AS datetime))
	SET @endDateCaSang = (SELECT CAST(CONVERT(CHAR(8), @startDate, 112) + ' 15:00:00' AS datetime))
	SET @clockingId = NEXT VALUE FOR ClockingSeq
	INSERT INTO Clocking (Id, TimeSheetId, ShiftId, EmployeeId, WorkById, ClockingStatus, StartTime, EndTime, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted, CheckInDate, CheckOutDate,
								TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork,  ClockingPaymentStatus)
	VALUES        (@clockingId, @timeSheetId1, @shiftId1, @employeeId1, @employeeId1, 3, @startDateCaSang, @endDateCaSang, @tenantId, @branchId, @userId, GETDATE(), 0, @startDateCaSangDiTre, @endDateCaSang, 15, 0, 0, 0, 0)

	SET @clockingHistoryId = NEXT VALUE FOR ClockingHistorySeq
	INSERT INTO ClockingHistory (Id, ClockingId, CheckedInDate, CheckedOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, TenantId, BranchId, TimeKeepingType, ClockingStatus, CreatedBy, CreatedDate, ClockingHistoryStatus, TimeIsLateAdjustment, OverTimeBeforeShiftWorkAdjustment, TimeIsLeaveWorkEarlyAdjustment, OverTimeAfterShiftWorkAdjustment, ShiftId, ShiftFrom, ShiftTo, EmployeeId, CheckTime)
	VALUES        (@clockingHistoryId, @clockingId, @startDateCaSangDiTre, @endDateCaSang, 15, 0, 0, 0, @tenantId, @branchId, 1, 3, @userId, GETDATE(), 1, 0, 0, 0, 0, @shiftId1, 540, 900, @employeeId1, GETDATE())

	-- Insert đi trễ ca chiều lần 2
	SET @startDateCaChieu = (SELECT CAST(CONVERT(CHAR(8), @startDate, 112) + ' 15:00:00' AS datetime))
	SET @startDateCaChieuDiTre = (SELECT CAST(CONVERT(CHAR(8), @startDate, 112) + ' 15:15:00' AS datetime))
	SET @endDateCaChieu = (SELECT CAST(CONVERT(CHAR(8), @startDate, 112) + ' 22:30:00' AS datetime))
	SET @clockingId = NEXT VALUE FOR ClockingSeq
	INSERT INTO Clocking (Id, TimeSheetId, ShiftId, EmployeeId, WorkById, ClockingStatus, StartTime, EndTime, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted, CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork,  ClockingPaymentStatus)
	VALUES        (@clockingId, @timeSheetId2, @shiftId2, @employeeId2, @employeeId2, 3, @startDateCaChieu, @endDateCaChieu, @tenantId, @branchId, @userId, GETDATE(), 0, @startDateCaChieuDiTre, @endDateCaChieu, 15, 0, 0, 0, 0)

	SET @clockingHistoryId = NEXT VALUE FOR ClockingHistorySeq
	INSERT INTO ClockingHistory (Id, ClockingId, CheckedInDate, CheckedOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, TenantId, BranchId, TimeKeepingType, ClockingStatus, CreatedBy, CreatedDate, ClockingHistoryStatus, TimeIsLateAdjustment, OverTimeBeforeShiftWorkAdjustment, TimeIsLeaveWorkEarlyAdjustment, OverTimeAfterShiftWorkAdjustment, ShiftId, ShiftFrom, ShiftTo,
                         EmployeeId, CheckTime)
	VALUES        (@clockingHistoryId, @clockingId, @startDateCaChieuDiTre, @endDateCaChieu, 15, 0, 0, 0, @tenantId, @branchId, 1, 3, @userId, GETDATE(), 1, 0, 0, 0, 0, @shiftId2, 900, 1350, @employeeId1, GETDATE())

	DECLARE @Number INT = 1
	WHILE @Number <= @dateNumber - 2
	BEGIN
		-- Insert ca sáng
		SET @startDate = DATEADD(DAY, 1, @startDate)
		SET @startDateCaSang = (SELECT CAST(CONVERT(CHAR(8), @startDate, 112) + ' 09:00:00' AS datetime))
		SET @endDateCaSang = (SELECT CAST(CONVERT(CHAR(8), @startDate, 112) + ' 15:00:00' AS datetime))
		SET @clockingId = NEXT VALUE FOR ClockingSeq
		INSERT INTO Clocking (Id, TimeSheetId, ShiftId, EmployeeId, WorkById, ClockingStatus, StartTime, EndTime, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted, CheckInDate, CheckOutDate,
								TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork,  ClockingPaymentStatus)
		VALUES        (@clockingId, @timeSheetId1, @shiftId1, @employeeId1, @employeeId1, 3, @startDateCaSang, @endDateCaSang, @tenantId, @branchId, @userId, GETDATE(), 0, @startDateCaSang, @endDateCaSang, 0, 0, 0, 0, 0)

		SET @clockingHistoryId = NEXT VALUE FOR ClockingHistorySeq
		INSERT INTO ClockingHistory (Id, ClockingId, CheckedInDate, CheckedOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, TenantId, BranchId, TimeKeepingType, ClockingStatus, CreatedBy, CreatedDate, ClockingHistoryStatus, TimeIsLateAdjustment, OverTimeBeforeShiftWorkAdjustment, TimeIsLeaveWorkEarlyAdjustment, OverTimeAfterShiftWorkAdjustment, ShiftId, ShiftFrom, ShiftTo,
							 EmployeeId, CheckTime)
		VALUES        (@clockingHistoryId, @clockingId, @startDateCaSang, @endDateCaSang, 0, 0, 0, 0, @tenantId, @branchId, 1, 3, @userId, GETDATE(), 1, 0, 0, 0, 0, @shiftId1, 540, 900, @employeeId1, GETDATE())

		-- Insert ca chiều
		SET @startDateCaChieu = (SELECT CAST(CONVERT(CHAR(8), @startDate, 112) + ' 15:00:00' AS datetime))
		SET @endDateCaChieu = (SELECT CAST(CONVERT(CHAR(8), @startDate, 112) + ' 22:30:00' AS datetime))
		SET @clockingId = NEXT VALUE FOR ClockingSeq
		INSERT INTO Clocking (Id, TimeSheetId, ShiftId, EmployeeId, WorkById, ClockingStatus, StartTime, EndTime, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted,  CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork,  ClockingPaymentStatus)
		VALUES        (@clockingId, @timeSheetId2, @shiftId2, @employeeId2, @employeeId2, 3, @startDateCaChieu, @endDateCaChieu, @tenantId, @branchId, @userId, GETDATE(), 0, @startDateCaChieu, @endDateCaChieu, 0, 0, 0, 0, 0)

		SET @clockingHistoryId = NEXT VALUE FOR ClockingHistorySeq
		INSERT INTO ClockingHistory (Id, ClockingId, CheckedInDate, CheckedOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, TenantId, BranchId, TimeKeepingType, ClockingStatus, CreatedBy, CreatedDate, ClockingHistoryStatus, TimeIsLateAdjustment, OverTimeBeforeShiftWorkAdjustment, TimeIsLeaveWorkEarlyAdjustment, OverTimeAfterShiftWorkAdjustment, ShiftId, ShiftFrom, ShiftTo,
							 EmployeeId, CheckTime)
		VALUES        (@clockingHistoryId, @clockingId, @startDateCaChieu, @endDateCaChieu, 0, 0, 0, 0, @tenantId, @branchId, 1, 3, @userId, GETDATE(), 1, 0, 0, 0, 0, @shiftId2, 900, 1350, @employeeId1, GETDATE())

		SET @Number = @Number + 1
	END
END

GO

-- ========================
-- File: pr_Booking_Insert_TrialData_Deduction.sql
-- ========================
ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_Deduction]
(
    @tenantId	INT,			-- ID gian hàng
	@userId		BIGINT,			-- ID tài khoản admin
	@deductionId BIGINT OUTPUT
)
AS
BEGIN
	SET @deductionId = NEXT VALUE FOR DeductionSeq

	INSERT INTO Deduction (Id, [Name], CreatedBy, CreatedDate, TenantId, Code, IsDeleted, [Value], ValueType, DeductionRuleId, DeductionTypeId, BlockTypeTimeValue, BlockTypeMinuteValue)
	VALUES        (@deductionId, N'Đi trễ', @userId, GETDATE(), @tenantId, 'GT000001', 0, 10000, 1, 1, 1, 1, 10)
END

GO

-- ========================
-- File: pr_Booking_Insert_TrialData_Employees.sql
-- ========================
ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_Employees]
(
    @tenantId	INT,			-- ID gian hàng
    @branchId	INT,			-- ID chi nhánh
	@userId		BIGINT,			-- ID tài khoản admin
	@taikhoan1		BIGINT,     -- ID tài khoản nhân viên 1
	@taikhoan2		BIGINT,		-- ID tài khoản nhân viên 2
	@employeeId1	BIGINT OUTPUT,
	@employeeId2	BIGINT OUTPUT
)
AS
BEGIN
	DECLARE @employeeBranch BIGINT
	SET @employeeId1 = NEXT VALUE FOR EmployeeSeq;
	INSERT INTO Employee (Id, Code, [Name], IsActive, UserId, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted)
	VALUES        (@employeeId1, 'NV000002', N'Hoàng Long', 1, @taikhoan1, @tenantId, @branchId, @userId, GETDATE(), 0)

	SET @employeeBranch = NEXT VALUE FOR EmployeeBranchSeq
	INSERT INTO EmployeeBranch (Id, TenantId, BranchId, EmployeeId)
	VALUES        (@employeeBranch, @tenantId, @branchId, @employeeId1)

	SET @employeeId2 = NEXT VALUE FOR EmployeeSeq
	INSERT INTO Employee (Id, Code, [Name], IsActive, UserId, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted)
	VALUES        (@employeeId2, 'NV000003', N'Mai Hương', 1, @taikhoan2, @tenantId, @branchId, @userId, GETDATE(), 0)

	SET @employeeBranch = NEXT VALUE FOR EmployeeBranchSeq
	INSERT INTO EmployeeBranch (Id, TenantId, BranchId, EmployeeId)
	VALUES        (@employeeBranch, @tenantId, @branchId, @employeeId2)
END

GO

-- ========================
-- File: pr_Booking_Insert_TrialData_PayRate.sql
-- ========================
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

-- ========================
-- File: pr_Booking_Insert_TrialData_PayRateDetail.sql
-- ========================
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

-- ========================
-- File: pr_Booking_Insert_TrialData_PayRateTemplate.sql
-- ========================
ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_PayRateTemplate]
(
    @tenantId	INT,		-- ID gian hàng
    @branchId	INT,		-- ID chi nhánh
	@userId		BIGINT,		-- ID tài khoản admin
	@payRateTemplateId BIGINT OUTPUT
)
AS
BEGIN
	SET @payRateTemplateId = NEXT VALUE FOR PayRateTemplateSeq

	INSERT INTO PayRateTemplate (Id, TenantId, [Name], SalaryPeriod, BranchId, CreatedDate, CreatedBy, [Status])
	VALUES        (@payRateTemplateId, @tenantId, N'Nhân viên dịch vụ - tư vấn', 1, @branchId, GETDATE(), @userId, 0)
END

GO

-- ========================
-- File: pr_Booking_Insert_TrialData_PayRateTemplateDetail.sql
-- ========================
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
    @tenantId	INT,			-- ID gian hàng
	@branchId	INT,			-- ID chi nhánh
	@userId	BIGINT,				-- ID tài khoản admin
	@startDate	DATETIME,		-- Ngày bắt đầu
    @paysheetId BIGINT OUTPUT
)
AS
BEGIN
	DECLARE @paysheetPeriodName VARCHAR(50)
	DECLARE @endDate DATETIME
	SET @endDate = DATEADD(DAY, - 1, DATEADD(MONTH, 1, @startDate))
	SET @paysheetPeriodName = CONVERT(VARCHAR, @startDate, 103) + ' - ' + CONVERT(VARCHAR, @endDate, 103)
	SET @paysheetId = NEXT VALUE FOR PaysheetSeq

	INSERT INTO Paysheet (Id, Code, TenantId, BranchId, IsDeleted, CreatedBy, CreatedDate, [Name], SalaryPeriod, StartTime, EndTime, PaysheetStatus, Note, WorkingDayNumber, PaysheetPeriodName, CreatorBy, PaysheetCreatedDate, [Version], IsDraft, TimeOfStandardWorkingDay)
	VALUES        (@paysheetId, 'BL000001', @tenantId, @branchId, 0, @userId, GETDATE(), N'Bảng lương ' + @paysheetPeriodName, 1, @startDate, CAST(CONVERT(char(8), @endDate, 112) + ' 23:59:59.000' AS datetime2), 1, '', DATEDIFF(DAY, @startDate, @endDate) + 1, @paysheetPeriodName, @userId, GETDATE(), 0, 0, 8)
END


GO

-- ========================
-- File: pr_Booking_Insert_TrialData_Payslip.sql
-- ========================
ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_Payslip]
(
    @tenantId	INT,			-- ID gian hàng
	@branchId	INT,			-- ID chi nhánh
	@userId	BIGINT,				-- ID tài khoản admin
	@employeeId1 BIGINT,		-- ID nhân viên 1
	@employeeId2 BIGINT,		-- ID nhân viên 2
    @paysheetId BIGINT,			-- ID bảng lương
    @payslipId1 BIGINT OUTPUT,	-- ID phiếu lương 1
    @payslipId2 BIGINT OUTPUT	-- ID phiếu lương 2
)
AS
BEGIN
	DECLARE @workingDay INT
	DECLARE @code1 nvarchar(255)
	DECLARE @code2 nvarchar(255)
	SET @workingDay = (SELECT TOP 1 WorkingDayNumber from Paysheet WHERE TenantId = @tenantId AND PaysheetStatus = 1)

	SET @payslipId1 = NEXT VALUE FOR PayslipSeq
	INSERT INTO Payslip (Id, Code, PaysheetId, TenantId, IsDeleted, PayslipStatus, EmployeeId, CreatedDate, CreatedBy, ModifiedBy, ModifiedDate, MainSalary, CommissionSalary, OvertimeSalary, Allowance, Deduction,
							 Bonus, NetSalary, GrossSalary, TotalPayment, IsDraft, PayslipCreatedDate, PayslipCreatedBy)
	VALUES        (@payslipId1, dbo.[GenerateCodePayslip] (@tenantId), @paysheetId, @tenantId, 0, 1, @employeeId1, GETDATE(), @userId, @userId, GETDATE(), 10000000, 0, 0, 50000 * @workingDay, 30000, 0, 10000000 + (50000 * @workingDay) - 30000, 10000000 + (50000 * @workingDay), 0, 0, GETDATE(), @userId)

	SET @payslipId2 = NEXT VALUE FOR PayslipSeq
	INSERT INTO Payslip (Id, Code, PaysheetId, TenantId, IsDeleted, PayslipStatus, EmployeeId, CreatedDate, CreatedBy, ModifiedBy, ModifiedDate, MainSalary, CommissionSalary, OvertimeSalary, Allowance, Deduction,
							 Bonus, NetSalary, GrossSalary, TotalPayment, IsDraft, PayslipCreatedDate, PayslipCreatedBy)
	VALUES        (@payslipId2, dbo.[GenerateCodePayslip] (@tenantId), @paysheetId, @tenantId, 0, 1, @employeeId2, GETDATE(), @userId, @userId, GETDATE(), 7000000, 0, 0, 50000 * @workingDay, 30000, 0, 7000000 + (50000 * @workingDay) - 30000, 7000000 + (50000 * @workingDay), 0, 0, GETDATE(), @userId)
END


GO

-- ========================
-- File: pr_Booking_Insert_TrialData_PayslipClocking.sql
-- ========================
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
    @tenantId	INT,			-- ID gian hàng
	@userId	BIGINT,				-- ID tài khoản admin
	@employeeId1 BIGINT,		-- ID nhân viên 1
	@employeeId2 BIGINT,		-- ID nhân viên 2
    @payslipId1 BIGINT,			-- ID phiếu lương 1
    @payslipId2 BIGINT,			-- ID phiếu lương 2
	@allowanceId BIGINT,
	@deductionId BIGINT
)
AS
BEGIN
	DECLARE @numberWorkingDay INT
	SET @numberWorkingDay = DAY(EOMONTH(DATEADD(MONTH, -1, GETDATE())))

	-- Chi tiết phiếu lương 1
	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipId1, RuleType, RuleValue, '{"Allowances":[{"AllowanceId":' +  CAST(@allowanceId AS VARCHAR(50)) + ',"Value":50000.0,"ValueRatio":null,"Name":null,"CalculatedValue":50000.0,"CalculatedValueRatio":null,"NumberWorkingDay":' +  CAST(@numberWorkingDay AS VARCHAR(2)) + ',"SelectedItem":null,"Type":1,"StandardWorkingDayNumber":' +  CAST(@numberWorkingDay AS VARCHAR(2)) + ',"IsChecked":true}]}', @tenantId
	FROM PayRateTemplateDetail
	WHERE TenantId = @tenantId AND RuleType = 'AllowanceRule'
	ORDER BY Id DESC

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipId1, RuleType, RuleValue, '{"Deductions":[{"DeductionId":' +  CAST(@deductionId AS VARCHAR(50)) + ',"Value":30000.0,"ValueRatio":null,"Name":null,"CalculatedValue":30000.0,"CalculatedValueRatio":null,"SelectedItem":null,"Type":1}]}', @tenantId
	FROM PayRateTemplateDetail
	WHERE TenantId = @tenantId AND RuleType = 'DeductionRule'

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipId1, RuleType, RuleValue, '{"Type":1,"TotalRevenue":0.0,"TotalCounselorRevenue":0.0,"TotalGrossProfit":0.0,"CommissionSalary":null,"CommissionSalaryOrigin":0.0,"CommissionParams":[{"CommissionType":1,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"ValueOrigin":null,"ValueRatioOrigin":null,"IsDirty":null,"ProductRevenues":[],"CommissionTable":null,"CommissionSetting":0},{"CommissionType":2,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"ValueOrigin":null,"ValueRatioOrigin":null,"IsDirty":null,"ProductRevenues":[],"CommissionTable":null,"CommissionSetting":0}]}', @tenantId
	FROM PayRateTemplateDetail
	WHERE TenantId = @tenantId AND RuleType = 'CommissionSalaryRuleV2'
	ORDER BY Id DESC

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	VALUES        (@payslipId1, 'MainSalaryRule', '{"Type":4,"MainSalaryValueDetails":[{"ShiftId":0,"Default":10000000.0,"MainSalaryHolidays":[],"Rank":0}]}', '{"MainSalaryShifts":[{"ShiftId":0,"Salary":10000000.0,"CalculatedSalary":10000000.0,"Default":31.0,"CalculatedDefault":31.0,"MainSalaryByShiftParamDetails":null,"Type":4}]}', @tenantId)

	-- Chi tiết phiếu lương 2
	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipId2, RuleType, RuleValue, '{"Allowances":[{"AllowanceId":' +  CAST(@allowanceId AS VARCHAR(50)) + ',"Value":50000.0,"ValueRatio":null,"Name":null,"CalculatedValue":50000.0,"CalculatedValueRatio":null,"NumberWorkingDay":' +  CAST(@numberWorkingDay AS VARCHAR(2)) + ',"SelectedItem":null,"Type":1,"StandardWorkingDayNumber":' +  CAST(@numberWorkingDay AS VARCHAR(2)) + ',"IsChecked":true}]}', @tenantId
	FROM PayRateTemplateDetail
	WHERE TenantId = @tenantId AND RuleType = 'AllowanceRule'
	ORDER BY Id DESC

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipId2, RuleType, RuleValue, '{"Deductions":[{"DeductionId":' +  CAST(@deductionId AS VARCHAR(50)) + ',"Value":30000.0,"ValueRatio":null,"Name":null,"CalculatedValue":30000.0,"CalculatedValueRatio":null,"SelectedItem":null,"Type":1}]}', @tenantId
	FROM PayRateTemplateDetail
	WHERE TenantId = @tenantId AND RuleType = 'DeductionRule'
	ORDER BY Id DESC

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	SELECT TOP 1 @payslipId2, RuleType, RuleValue, '{"Type":1,"TotalRevenue":0.0,"TotalCounselorRevenue":0.0,"TotalGrossProfit":0.0,"CommissionSalary":null,"CommissionSalaryOrigin":0.0,"CommissionParams":[{"CommissionType":1,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"ValueOrigin":null,"ValueRatioOrigin":null,"IsDirty":null,"ProductRevenues":[],"CommissionTable":null,"CommissionSetting":0},{"CommissionType":2,"CommissionLevel":0.0,"Value":null,"ValueRatio":null,"ValueOrigin":null,"ValueRatioOrigin":null,"IsDirty":null,"ProductRevenues":[],"CommissionTable":null,"CommissionSetting":0}]}', @tenantId
	FROM PayRateTemplateDetail
	WHERE TenantId = @tenantId AND RuleType = 'CommissionSalaryRuleV2'
	ORDER BY Id DESC

	INSERT INTO PayslipDetail (PayslipId, RuleType, RuleValue, RuleParam, TenantId)
	VALUES        (@payslipId2, 'MainSalaryRule', '{"Type":4,"MainSalaryValueDetails":[{"ShiftId":0,"Default":7000000.0,"MainSalaryHolidays":[],"Rank":0}]}', '{"MainSalaryShifts":[{"ShiftId":0,"Salary":7000000.0,"CalculatedSalary":7000000.0,"Default":31.0,"CalculatedDefault":31.0,"MainSalaryByShiftParamDetails":null,"Type":4}]}', @tenantId)
END

GO

-- ========================
-- File: pr_Booking_Insert_TrialData_Shifts.sql
-- ========================
ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_Shifts]
(
    @tenantId	INT,		-- ID gian hàng
    @branchId	INT,		-- ID chi nhánh
	@userId		BIGINT,		-- ID tài khoản admin
	@shiftId1	BIGINT OUTPUT,
	@shiftId2	BIGINT OUTPUT
)
AS
BEGIN
	SET @shiftId1 = NEXT VALUE FOR ShiftSeq;
	INSERT INTO [Shift] ([Id], [Name], [From], [To], IsActive, IsDeleted, BranchId, CheckInBefore, CheckOutAfter, TenantId, CreatedBy, CreatedDate)
	VALUES        (@shiftId1, N'Ca sáng', 540, 900, 1, 0, @branchId, 360, 1080, @tenantId, @userId, GETDATE())

	SET @shiftId2 = NEXT VALUE FOR ShiftSeq;
	INSERT INTO [Shift] ([Id], [Name], [From], [To], IsActive, IsDeleted, BranchId, CheckInBefore, CheckOutAfter, TenantId, CreatedBy, CreatedDate)
	VALUES        (@shiftId2, N'Ca chiều - tối', 900, 1350, 1, 0, @branchId, 720, 90, @tenantId, @userId, GETDATE())
END

GO

-- ========================
-- File: pr_Booking_Insert_TrialData_TimeSheet.sql
-- ========================
ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_TimeSheet]
(
    @tenantId	INT,			-- ID gian hàng
	@branchId	INT,			-- ID chi nhánh
	@userId	BIGINT,				-- ID tài khoản admin
	@employeeId1	BIGINT,		-- ID nhân viên 1
	@employeeId2	BIGINT,		-- ID nhân viên 2
	@startDate	DATETIME,		-- Ngày bắt đầu
	@endDate	DATETIME,		-- Ngày kết thúc
    @timeSheetId1 BIGINT OUTPUT,
    @timeSheetId2 BIGINT OUTPUT
)
AS
BEGIN
	SET @timeSheetId1 = NEXT VALUE FOR TimeSheetSeq
	INSERT INTO TimeSheet (Id, EmployeeId, StartDate, EndDate, IsRepeat, RepeatType, RepeatEachDay, BranchId, TenantId, CreatedBy, CreatedDate, IsDeleted, TimeSheetStatus, SaveOnDaysOffOfBranch, SaveOnHoliday, AutoGenerateClockingStatus)
	VALUES        (@timeSheetId1, @employeeId1, @startDate, @endDate, 1, 1, 1, @branchId, @tenantId, @userId, GETDATE(), 0, 1, 0, 0, 0)

	SET @timeSheetId2 = NEXT VALUE FOR TimeSheetSeq
	INSERT INTO TimeSheet (Id, EmployeeId, StartDate, EndDate, IsRepeat, RepeatType, RepeatEachDay, BranchId, TenantId, CreatedBy, CreatedDate, IsDeleted, TimeSheetStatus, SaveOnDaysOffOfBranch, SaveOnHoliday, AutoGenerateClockingStatus)
	VALUES        (@timeSheetId2, @employeeId2, @startDate, @endDate, 1, 1, 1, @branchId, @tenantId, @userId, GETDATE(), 0, 1, 0, 0, 0)
END

GO

-- ========================
-- File: pr_Booking_Insert_TrialData_TimeSheetShift.sql
-- ========================
ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_TimeSheetShift]
(
@shiftId1 VARCHAR(50),
@shiftId2 VARCHAR(50),
@timeSheetId1 BIGINT,
@timeSheetId2 BIGINT
)
AS
BEGIN
INSERT INTO [TimeSheetShift] (TimeSheetId, ShiftIds)
VALUES (@timeSheetId1, @shiftId1)

INSERT INTO [TimeSheetShift] (TimeSheetId, ShiftIds)
VALUES (@timeSheetId2, @shiftId2)
END

GO

-- ========================
-- File: pr_GetNextEmployeeCode.sql
-- ========================
CREATE PROC [dbo].[pr_GetNextEmployeeCode]
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

-- ========================
-- File: pr_Update_Clocking_Time.sql
-- ========================
ALTER PROCEDURE [dbo].[pr_Update_Clocking_Time]
(
@tenantId INT,
@branchId INT,
@shiftId BIGINT,
@shiftFrom BIGINT,
@shiftTo BIGINT,
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
SET StartTime = DATEADD(minute, @shiftFrom, CONVERT(DATETIME2, CONVERT(DATE, StartTime))),
EndTime = DATEADD(minute, @shiftTo, CONVERT(DATETIME2, CONVERT(DATE, DATEADD(day, @increment, StartTime))))
WHERE TenantId = @tenantId
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

COMMIT;
