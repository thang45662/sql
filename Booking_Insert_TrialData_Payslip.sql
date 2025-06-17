USE [KV_TimeSheet_Booking_Dev2]
GO
/****** Object:  StoredProcedure [dbo].[pr_Booking_Insert_TrialData_Payslip]    Script Date: 6/13/2025 11:31:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

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

