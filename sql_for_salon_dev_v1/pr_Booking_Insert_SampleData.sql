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
	DECLARE @branchId				BIGINT --- lấy ở đâu bây h 
	DECLARE @payRateTemplateId		BIGINT
	DECLARE @commissionId			BIGINT
	DECLARE @payRateId1				BIGINT
	DECLARE @payRateId2				BIGINT
    SET NOCOUNT ON
	-- tạo phòng ban

	EXEC [pr_Booking_Insert_Sample_Department] @tenantId, @userIdAdmin, @language
	-- tạo chức danh
	EXEC [pr_Booking_Insert_SampleData_JobTitles] @tenantId, @userIdAdmin, @language

	-- tạo phụ cấp
	EXEC [pr_Booking_Insert_Sample_Allowance] @tenantId, @userIdAdmin, @language, @allowanceId OUTPUT

	-- tạo giảm trừ
	EXEC [pr_Booking_Insert_Sample_Deduction] @tenantId, @userIdAdmin, @language, @deductionId OUTPUT
	--Tạo hoa hồng
	 EXEC [pr_Booking_Insert_Sample_Commission] @tenantId, @userIdAdmin, @language, @commissionId OUTPUT
	-- tạo mẫu lương
	EXEC [pr_Booking_Insert_Sample_PayRateTemplate] @tenantId, @branchId, @userIdAdmin, @language, @payRateTemplateId OUTPUT
	EXEC [pr_Booking_Insert_Sample_PayRateTemplateDetail] @tenantId, @userIdAdmin, @payRateTemplateId, @commissionId, @allowanceId, @deductionId
	
END

GO

-- ko bốc được tiết lập lương sang 