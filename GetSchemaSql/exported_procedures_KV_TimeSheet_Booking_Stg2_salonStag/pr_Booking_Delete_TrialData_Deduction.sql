----
ALTER PROCEDURE [dbo].[pr_Booking_Delete_TrialData_Deduction]
(
    @tenantId	INT,			-- ID gian hàng
	@userId		BIGINT			-- ID tài khoản admin
)
AS
BEGIN
	UPDATE       Deduction
	SET                [Name] += '{DEL}', ModifiedBy = @userId, ModifiedDate = GETDATE(), Code += '{DEL}', IsDeleted = 1, DeletedDate = GETDATE(), DeletedBy = @userId
	WHERE        (TenantId = @tenantId) AND (IsDeleted = 0)
END

GO
