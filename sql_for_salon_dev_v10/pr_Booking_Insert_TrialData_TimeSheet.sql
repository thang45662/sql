USE [KV_TimeSheet_Booking_Dev2]
GO

/****** Object:  StoredProcedure [dbo].[pr_Booking_Insert_TrialData_TimeSheet]    Script Date: 6/18/2025 10:25:03 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

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

