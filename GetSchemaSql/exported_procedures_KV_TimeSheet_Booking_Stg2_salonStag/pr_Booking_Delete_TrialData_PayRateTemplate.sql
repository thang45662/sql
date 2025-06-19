----
ALTER PROCEDURE [dbo].[pr_Booking_Delete_TrialData_PayRateTemplate]
(
    @tenantId	INT,		-- ID gian hàng
	@userId		BIGINT		-- ID tài khoản admin
)
AS
BEGIN
	UPDATE       PayRateTemplate
	SET                [Name] += '{DEL}', ModifiedBy = @userId, ModifiedDate = GETDATE(), [Status] = 1
	WHERE        (TenantId = @tenantId)
END

GO
