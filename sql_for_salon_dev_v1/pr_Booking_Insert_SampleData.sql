ALTER PROCEDURE [dbo].[pr_Booking_Insert_SampleData]
(
    @tenantId			INT,			-- ID gian hàng
	@userIdAdmin		BIGINT,			-- ID tài khoản admin
    @language			NVARCHAR(50)	-- ngôn ngữ (en-US/vi-VN)
)
AS
BEGIN
	DECLARE @allowanceId			BIGINT
	DECLARE @deductionId			BIGINT
	DECLARE @branchId				BIGINT
	DECLARE @payRateTemplateId		BIGINT
	DECLARE @commissionId			BIGINT
	DECLARE @payRateId1				BIGINT
	DECLARE @payRateId2				BIGINT

    SET NOCOUNT ON
	-- tạo phòng ban
	EXEC [pr_Booking_Insert_Sample_Department] @tenantId, @userIdAdmin, @language
	-- tạo chức danh
	EXEC [pr_Booking_Insert_SampleData_JobTitles] @tenantId, @userIdAdmin, @language

END

GO
