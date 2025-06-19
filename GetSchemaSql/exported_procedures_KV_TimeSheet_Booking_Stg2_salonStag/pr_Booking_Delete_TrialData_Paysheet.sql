----
ALTER PROCEDURE [dbo].[pr_Booking_Delete_TrialData_Paysheet]
(
    @tenantId	INT,			-- ID gian hàng
	@userId	BIGINT				-- ID tài khoản admin
)
AS
BEGIN
	UPDATE       Paysheet
	SET                PaysheetStatus = 0, ModifiedBy = @userId, ModifiedDate = GETDATE()
	WHERE        (TenantId = @tenantId) AND PaysheetStatus != 0
END

GO
