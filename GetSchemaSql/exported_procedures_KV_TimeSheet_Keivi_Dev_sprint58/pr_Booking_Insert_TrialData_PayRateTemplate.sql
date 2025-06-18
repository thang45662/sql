ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_PayRateTemplate]
(
    @tenantId	INT,		-- ID gian hàng
    @branchId	INT,		-- ID chi nhánh
	@userId		BIGINT,		-- ID tài khoản admin
    @language	NVARCHAR(50),	-- Ngôn ngữ
	@payRateTemplateId BIGINT OUTPUT
)
AS
BEGIN
	IF (@language = 'en-US')
	BEGIN
		SET @payRateTemplateId = NEXT VALUE FOR PayRateTemplateSeq

		INSERT INTO PayRateTemplate (Id, TenantId, [Name], SalaryPeriod, BranchId, CreatedDate, CreatedBy, [Status])
		VALUES        (@payRateTemplateId, @tenantId, N'Service & Sales Employee', 1, @branchId, GETDATE(), @userId, 0)
	END
	ELSE
	BEGIN
		SET @payRateTemplateId = NEXT VALUE FOR PayRateTemplateSeq

		INSERT INTO PayRateTemplate (Id, TenantId, [Name], SalaryPeriod, BranchId, CreatedDate, CreatedBy, [Status])
		VALUES        (@payRateTemplateId, @tenantId, N'Nhân viên dịch vụ - tư vấn', 1, @branchId, GETDATE(), @userId, 0)
	END
END

GO
