Create PROCEDURE [dbo].[pr_Booking_Insert_SampleData]
(
@tenantId INT, -- ID gian hàng
@userIdAdmin BIGINT -- ID tài khoản admin
)
AS
BEGIN
SET NOCOUNT ON
-- tạo phòng ban
EXEC [pr_Booking_Insert_SampleData_Department] @tenantId, @userIdAdmin
-- tạo chức danh
EXEC [pr_Booking_Insert_SampleData_JobTitles] @tenantId, @userIdAdmin
END

GO
