ALTER PROCEDURE [dbo].[pr_Booking_Delete_TrialData_PayslipClocking]
(
    @tenantId	INT			-- ID gian hàng
)
AS
BEGIN
	DELETE FROM PayslipClocking
	WHERE        ClockingId IN (SELECT Id FROM Clocking WHERE TenantId = @tenantId)
END;

GO
