ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_Department]
(
    @tenantId	INT,			-- ID gian hàng
	@userId		BIGINT			-- ID tài khoản admin
)
AS
BEGIN
    INSERT INTO Department(
        Id, [Name], Description, IsActive, TenantId, CreatedBy, CreatedDate,
        ModifiedBy, ModifiedDate, IsDeleted, DeletedBy, DeletedDate
    )
    VALUES
        (NEXT VALUE FOR DepartmentSeq, N'Kinh doanh','', 1, @tenantId,@userId, GETDATE(), NULL, NULL, 0, NULL, NULL),
        (NEXT VALUE FOR DepartmentSeq, N'Kế toán','', 1, @tenantId,@userId, GETDATE(), NULL, NULL, 0, NULL, NULL),
        (NEXT VALUE FOR DepartmentSeq, N'Thu ngân ','', 1, @tenantId,@userId, GETDATE(), NULL, NULL, 0, NULL, NULL),
        (NEXT VALUE FOR DepartmentSeq, N'Quản lý','', 1, @tenantId,@userId, GETDATE(), NULL, NULL, 0, NULL, NULL)
END

GO
