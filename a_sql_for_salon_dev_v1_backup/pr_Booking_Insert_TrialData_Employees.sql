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
