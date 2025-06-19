ALTER PROCEDURE [dbo].[pr_Booking_Insert_SampleData]
(
    @tenantId			INT,			-- ID gian hàng
	@userIdAdmin		BIGINT,			-- ID tài khoản admin
    @language			NVARCHAR(50)	-- ngôn ngữ (en-US/vi-VN)
)
AS
BEGIN
    SET NOCOUNT ON
	-- tạo phòng ban
	EXEC [pr_Booking_Insert_Sample_Department] @tenantId, @userIdAdmin, @language
	-- tạo chức danh
	EXEC [pr_Booking_Insert_SampleData_JobTitles] @tenantId, @userIdAdmin, @language
END

GO
