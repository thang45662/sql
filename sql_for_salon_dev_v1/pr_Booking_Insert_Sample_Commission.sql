USE [KV_TimeSheet_Booking_Dev2]
GO

CREATE OR ALTER PROCEDURE [dbo].[pr_Booking_Insert_Sample_Commission]
(
    @tenantId       INT,            -- ID gian hàng
    @userId         BIGINT,         -- ID tài khoản admin
    @language       NVARCHAR(50),   -- Ngôn ngữ
    @commissionId   BIGINT OUTPUT   -- ID hoa hồng (output)
)
AS
BEGIN
    SET NOCOUNT ON;
    -- Tạo bảng hoa hồng chung
    SET @commissionId = NEXT VALUE FOR CommissionSeq;
    
    -- Tạo bảng hoa hồng
    INSERT INTO Commission (
        Id, Name, IsActive, TenantId, CreatedBy, CreatedDate, 
        IsDeleted, IsAllBranch, IsDefault
    )
    VALUES (
        @commissionId, N'Hoa hồng chung', 1, @tenantId, @userId, GETDATE(), 
        0, 1, 1
    );
    
END
