ALTER PROCEDURE [dbo].[pr_Booking_Delete_TrialData_Shifts]
(
    @tenantId	INT,		-- ID gian hàng
	@userId		BIGINT		-- ID tài khoản admin
)
AS
BEGIN
	UPDATE       [Shift]
	SET                IsDeleted = 1, DeletedBy = @userId, DeletedDate = GETDATE(), ModifiedBy = @userId, ModifiedDate = GETDATE()
	WHERE        (TenantId = @tenantId) AND (IsDeleted = 0)
END

GO
