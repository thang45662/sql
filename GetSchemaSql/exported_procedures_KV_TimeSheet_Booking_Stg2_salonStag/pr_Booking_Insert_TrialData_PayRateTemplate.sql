----
ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_PayRateTemplate]
(
    @tenantId	INT,		-- ID gian hàng
    @branchId	INT,		-- ID chi nhánh
	@userId		BIGINT,		-- ID tài khoản admin
	@payRateTemplateId BIGINT OUTPUT
)
AS
BEGIN
	SET @payRateTemplateId = NEXT VALUE FOR PayRateTemplateSeq

	INSERT INTO PayRateTemplate (Id, TenantId, [Name], SalaryPeriod, BranchId, CreatedDate, CreatedBy, [Status])
	VALUES        (@payRateTemplateId, @tenantId, N'Nhân viên dịch vụ - tư vấn', 1, @branchId, GETDATE(), @userId, 0)
END

GO
