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
	SET @workingDay = (SELECT TOP 1 WorkingDayNumber from Paysheet WHERE TenantId = @tenantId AND PaysheetStatus = 1)

	SET @payslipId1 = NEXT VALUE FOR PayslipSeq
	INSERT INTO Payslip (Id, Code, PaysheetId, TenantId, IsDeleted, PayslipStatus, EmployeeId, CreatedDate, CreatedBy, ModifiedBy, ModifiedDate, MainSalary, CommissionSalary, OvertimeSalary, Allowance, Deduction,
							 Bonus, NetSalary, GrossSalary, TotalPayment, IsDraft, PayslipCreatedDate, PayslipCreatedBy)
	VALUES        (@payslipId1, 'PL000001', @paysheetId, @tenantId, 0, 1, @employeeId1, GETDATE(), @userId, @userId, GETDATE(), 10000000, 0, 0, 50000 * @workingDay, 30000, 0, 10000000 + (50000 * @workingDay) - 30000, 10000000 + (50000 * @workingDay), 0, 0, GETDATE(), @userId)

	SET @payslipId2 = NEXT VALUE FOR PayslipSeq
	INSERT INTO Payslip (Id, Code, PaysheetId, TenantId, IsDeleted, PayslipStatus, EmployeeId, CreatedDate, CreatedBy, ModifiedBy, ModifiedDate, MainSalary, CommissionSalary, OvertimeSalary, Allowance, Deduction,
							 Bonus, NetSalary, GrossSalary, TotalPayment, IsDraft, PayslipCreatedDate, PayslipCreatedBy)
	VALUES        (@payslipId2, 'PL000002', @paysheetId, @tenantId, 0, 1, @employeeId2, GETDATE(), @userId, @userId, GETDATE(), 7000000, 0, 0, 50000 * @workingDay, 30000, 0, 7000000 + (50000 * @workingDay) - 30000, 7000000 + (50000 * @workingDay), 0, 0, GETDATE(), @userId)
END


GO
