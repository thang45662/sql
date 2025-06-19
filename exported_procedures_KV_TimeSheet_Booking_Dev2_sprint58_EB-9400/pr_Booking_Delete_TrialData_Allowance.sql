ALTER PROCEDURE [dbo].[pr_Booking_Delete_TrialData_Allowance]
(
    @tenantId	INT,			-- ID gian hàng
	@userId		BIGINT			-- ID tài khoản admin
)
AS
BEGIN
	UPDATE       Allowance
	SET                [Name] += '{DEL}', ModifiedBy = @userId, ModifiedDate = GETDATE(), Code += '{DEL}', IsDeleted = 1, DeletedDate = GETDATE(), DeletedBy = @userId
	WHERE        (TenantId = @tenantId) AND (IsDeleted = 0)
END

GO
