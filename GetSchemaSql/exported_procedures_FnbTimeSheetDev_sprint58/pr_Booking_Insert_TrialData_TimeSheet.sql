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
    @timeSheetId2		BIGINT OUTPUT
)
AS
BEGIN
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

GO
