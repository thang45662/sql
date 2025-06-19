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
