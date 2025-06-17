USE [KV_TimeSheet_Booking_Dev2]
GO
/****** Object:  StoredProcedure [dbo].[pr_Booking_Insert_TrialData_TimeSheet]    Script Date: 6/17/2025 10:57:16 AM ******/
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

	-- Output: TimeSheet ID tháng trước
    @prevTimeSheetId1	BIGINT OUTPUT,
    @prevTimeSheetId2	BIGINT OUTPUT
)
AS
BEGIN
	---TẠO LỊCH THÁNG TRƯỚC ----
	 DECLARE @firstDayPrevMonth DATE, @lastDayPrevMonth DATE;
    IF MONTH(@startDate) = 1
        SET @firstDayPrevMonth = DATEFROMPARTS(YEAR(@startDate) - 1, 12, 1);
    ELSE
        SET @firstDayPrevMonth = DATEFROMPARTS(YEAR(@startDate), MONTH(@startDate) - 1, 1);

    SET @lastDayPrevMonth = EOMONTH(@startDate, -1);
	SET @prevTimeSheetId1 = NEXT VALUE FOR TimeSheetSeq
	INSERT INTO TimeSheet (Id, EmployeeId, StartDate, EndDate, IsRepeat, RepeatType, RepeatEachDay,BranchId, TenantId, CreatedBy, CreatedDate, IsDeleted, TimeSheetStatus,
						   SaveOnDaysOffOfBranch, SaveOnHoliday, AutoGenerateClockingStatus)
	VALUES (@prevTimeSheetId1, @employeeId1, @firstDayPrevMonth, @lastDayPrevMonth, 1, 2, 1,
			@branchId, @tenantId, @userId, GETDATE(), 0, 1, 0, 0, 0)

	-- ==== Tạo TimeSheet cho nhân viên 2 - tháng trước ====
	SET @prevTimeSheetId2 = NEXT VALUE FOR TimeSheetSeq
	INSERT INTO TimeSheet (Id, EmployeeId, StartDate, EndDate, IsRepeat, RepeatType, RepeatEachDay,
						   BranchId, TenantId, CreatedBy, CreatedDate, IsDeleted, TimeSheetStatus,
						   SaveOnDaysOffOfBranch, SaveOnHoliday, AutoGenerateClockingStatus)
	VALUES (@prevTimeSheetId2, @employeeId2, @firstDayPrevMonth, @lastDayPrevMonth, 1, 2, 1,
			@branchId, @tenantId, @userId, GETDATE(), 0, 1, 0, 0, 0)

	---TẠO LỊCH THÁNG HIỆN TẠI ----
	DECLARE @timeSheetStartDate DATETIME
	DECLARE @timeSheetEndDate DATETIME
	SET @timeSheetStartDate = (SELECT case when @useNewTimeSheet = 1 then @monday else @startDate end)
	SET @timeSheetEndDate = (SELECT case when @useNewTimeSheet = 1 then @sunday else @endDate end)

	DECLARE @timeSheetRepeatType TINYINT
	SET @timeSheetRepeatType = (SELECT case when @useNewTimeSheet = 1 then 2 else 1 end)

	SET @timeSheetId1 = NEXT VALUE FOR TimeSheetSeq
	INSERT INTO TimeSheet (Id, EmployeeId, StartDate, EndDate, IsRepeat, RepeatType, RepeatEachDay, BranchId, TenantId, CreatedBy, CreatedDate, IsDeleted, TimeSheetStatus, SaveOnDaysOffOfBranch, SaveOnHoliday, AutoGenerateClockingStatus)
	VALUES				(@timeSheetId1, @employeeId1, @timeSheetStartDate, @timeSheetEndDate, 1, @timeSheetRepeatType, 1, @branchId, @tenantId, @userId, GETDATE(), 0, 1, 0, 0, 0)
	
	SET @timeSheetId2 = NEXT VALUE FOR TimeSheetSeq
	INSERT INTO TimeSheet (Id, EmployeeId, StartDate, EndDate, IsRepeat, RepeatType, RepeatEachDay, BranchId, TenantId, CreatedBy, CreatedDate, IsDeleted, TimeSheetStatus, SaveOnDaysOffOfBranch, SaveOnHoliday, AutoGenerateClockingStatus)
	VALUES				(@timeSheetId2, @employeeId2, @timeSheetStartDate, @timeSheetEndDate, 1, @timeSheetRepeatType, 1, @branchId, @tenantId, @userId, GETDATE(), 0, 1, 0, 0, 0)
END