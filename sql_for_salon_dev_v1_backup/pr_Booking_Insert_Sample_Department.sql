ALTER PROCEDURE [dbo].[pr_Booking_Insert_Sample_Department]
(
    @tenantId	INT,			-- ID gian hàng
	@userId		BIGINT,			-- ID tài khoản admin
    @language	NVARCHAR(50)	-- ngôn ngữ (en-US/vi-VN)
)
AS
BEGIN
    IF @language = 'en-US'
    BEGIN
        INSERT INTO Department(
            Id, [Name], Description, IsActive, TenantId, CreatedBy, CreatedDate,
            ModifiedBy, ModifiedDate, IsDeleted, DeletedBy, DeletedDate
        )
        VALUES
        (NEXT VALUE FOR DepartmentSeq, N'Business','', 1, @tenantId,@userId, GETDATE(), NULL, NULL, 0, NULL, NULL),
            (NEXT VALUE FOR DepartmentSeq, N'Accounting','', 1, @tenantId,@userId, GETDATE(), NULL, NULL, 0, NULL, NULL),
            (NEXT VALUE FOR DepartmentSeq, N'Cashier','', 1, @tenantId,@userId, GETDATE(), NULL, NULL, 0, NULL, NULL),
            (NEXT VALUE FOR DepartmentSeq, N'Management','', 1, @tenantId,@userId, GETDATE(), NULL, NULL, 0, NULL, NULL)
    END
    ELSE
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
END

GO
