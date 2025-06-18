ALTER PROCEDURE [dbo].[pr_Booking_Delete_TrialData_TimeSheet]
(
    @tenantId	INT,			-- ID gian hàng
	@userId	BIGINT				-- ID tài khoản admin
)
AS
BEGIN
	UPDATE       TimeSheet
	SET                ModifiedBy = @userId, ModifiedDate = GETDATE(), IsDeleted = 1, DeletedBy = @userId, DeletedDate = GETDATE(), TimeSheetStatus = 0
	WHERE        (TenantId = @tenantId)
END;

GO
