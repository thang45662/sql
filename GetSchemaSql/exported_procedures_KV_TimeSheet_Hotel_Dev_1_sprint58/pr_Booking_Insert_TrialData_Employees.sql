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
