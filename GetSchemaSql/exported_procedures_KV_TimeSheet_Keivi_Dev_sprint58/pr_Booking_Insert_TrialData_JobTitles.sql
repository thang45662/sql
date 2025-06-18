ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_JobTitles]
(

    @tenantId	INT,			-- ID gian hàng
	@userId		BIGINT			-- ID tài khoản admin
)
AS
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

GO
