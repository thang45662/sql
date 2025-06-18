ALTER PROCEDURE [dbo].[pr_Booking_Insert_SampleData_JobTitles]
(
    @tenantId   INT,            -- ID gian hàng
    @userId     BIGINT,         -- ID tài khoản admin
    @language   NVARCHAR(50)    -- ngôn ngữ (en-US/vi-VN)
)
AS
BEGIN
    IF @language = 'en-US'
    BEGIN
        INSERT INTO JobTitle (
            Id, [Name], Description, IsActive, TenantId, CreatedBy, CreatedDate,
            ModifiedBy, ModifiedDate, IsDeleted, DeletedBy, DeletedDate
        )
        VALUES
            (NEXT VALUE FOR JobTitleSeq, N'Sales Staff','', 1, @tenantId, @userId, GETDATE(), NULL, NULL, 0, NULL, NULL),
            (NEXT VALUE FOR JobTitleSeq, N'Service Staff','', 1, @tenantId, @userId, GETDATE(), NULL, NULL, 0, NULL, NULL),
            (NEXT VALUE FOR JobTitleSeq, N'Accountant','', 1, @tenantId, @userId, GETDATE(), NULL, NULL, 0, NULL, NULL),
            (NEXT VALUE FOR JobTitleSeq, N'Cashier','', 1, @tenantId, @userId, GETDATE(), NULL, NULL, 0, NULL, NULL),
            (NEXT VALUE FOR JobTitleSeq, N'Manager','', 1, @tenantId, @userId, GETDATE(), NULL, NULL, 0, NULL, NULL)
    END
    ELSE
    BEGIN
        INSERT INTO JobTitle (
            Id, [Name], Description, IsActive, TenantId, CreatedBy, CreatedDate,
            ModifiedBy, ModifiedDate, IsDeleted, DeletedBy, DeletedDate
        )
        VALUES
            (NEXT VALUE FOR JobTitleSeq, N'Nhân viên bán hàng','', 1, @tenantId, @userId, GETDATE(), NULL, NULL, 0, NULL, NULL),
            (NEXT VALUE FOR JobTitleSeq, N'Nhân viên làm dịch vụ','', 1, @tenantId, @userId, GETDATE(), NULL, NULL, 0, NULL, NULL),
            (NEXT VALUE FOR JobTitleSeq, N'Kế toán','', 1, @tenantId, @userId, GETDATE(), NULL, NULL, 0, NULL, NULL),
            (NEXT VALUE FOR JobTitleSeq, N'Thu ngân','', 1, @tenantId, @userId, GETDATE(), NULL, NULL, 0, NULL, NULL),
            (NEXT VALUE FOR JobTitleSeq, N'Quản lý','', 1, @tenantId, @userId, GETDATE(), NULL, NULL, 0, NULL, NULL)
    END
END

GO
