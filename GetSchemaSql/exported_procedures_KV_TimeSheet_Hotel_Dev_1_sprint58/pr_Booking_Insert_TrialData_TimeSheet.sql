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
