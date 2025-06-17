-- =====================================================
-- 3. TIMESHEETSHIFT - SỬA LOGIC TÍNH WORKING DAYS
-- =====================================================
USE [KV_TimeSheet_Booking_Dev2]
GO
ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_TimeSheetShift]
(
	@shiftId1			VARCHAR(50),
	@shiftId2			VARCHAR(50),
	@timeSheetId1		BIGINT,
	@timeSheetId2		BIGINT,
	@prevTimeSheetId1	BIGINT,
	@prevTimeSheetId2	BIGINT,
	@useNewTimeSheet	BIT,
	@workingDays1		INT OUTPUT,		-- Số ngày công tháng hiện tại nhân viên 1
	@workingDays2		INT OUTPUT,		-- Số ngày công tháng hiện tại nhân viên 2
	@workingDaysPrev1	INT OUTPUT,		-- Số ngày công tháng trước nhân viên 1
	@workingDaysPrev2	INT OUTPUT		-- Số ngày công tháng trước nhân viên 2
)
AS
BEGIN
	DECLARE @repeatDaysOfWeek1 NVARCHAR(500)
	DECLARE @repeatDaysOfWeek2 NVARCHAR(500)
	
	-- ✅ SỬA: Thiết lập RepeatDaysOfWeek chính xác
	IF @useNewTimeSheet = 1
	BEGIN
		-- TimeSheet 2.0: Sử dụng RepeatDaysOfWeek
		SET @repeatDaysOfWeek1 = '1,2,3,4,5,6'  -- Thứ 2-7 (6 ngày)
		SET @repeatDaysOfWeek2 = '1,3,5'        -- Thứ 2,4,6 (3 ngày)
	END
	ELSE
	BEGIN
		-- TimeSheet 1.0: Không sử dụng RepeatDaysOfWeek
		SET @repeatDaysOfWeek1 = NULL
		SET @repeatDaysOfWeek2 = NULL
	END

	-- Tạo TimeSheetShift cho tháng hiện tại
	INSERT INTO [TimeSheetShift] (TimeSheetId, ShiftIds, RepeatDaysOfWeek)
	VALUES (@timeSheetId1, @shiftId1, @repeatDaysOfWeek1)

	INSERT INTO [TimeSheetShift] (TimeSheetId, ShiftIds, RepeatDaysOfWeek)
	VALUES (@timeSheetId2, @shiftId2, @repeatDaysOfWeek2)

	-- Tạo TimeSheetShift cho tháng trước
	IF @useNewTimeSheet = 1
	BEGIN
		-- Tìm tất cả TimeSheet của tháng trước
		DECLARE @employeeId1 BIGINT = (SELECT EmployeeId FROM TimeSheet WHERE Id = @timeSheetId1)
		DECLARE @employeeId2 BIGINT = (SELECT EmployeeId FROM TimeSheet WHERE Id = @timeSheetId2)
		DECLARE @prevMonth DATETIME = DATEADD(MONTH, -1, GETDATE())
		
		-- Tạo cho tất cả TimeSheet tháng trước
		INSERT INTO [TimeSheetShift] (TimeSheetId, ShiftIds, RepeatDaysOfWeek)
		SELECT Id, @shiftId1, @repeatDaysOfWeek1
		FROM TimeSheet 
		WHERE EmployeeId = @employeeId1 
		  AND MONTH(CreatedDate) = MONTH(@prevMonth)
		  AND YEAR(CreatedDate) = YEAR(@prevMonth)
		  AND Id != @timeSheetId1
		
		INSERT INTO [TimeSheetShift] (TimeSheetId, ShiftIds, RepeatDaysOfWeek)
		SELECT Id, @shiftId2, @repeatDaysOfWeek2
		FROM TimeSheet 
		WHERE EmployeeId = @employeeId2 
		  AND MONTH(CreatedDate) = MONTH(@prevMonth)
		  AND YEAR(CreatedDate) = YEAR(@prevMonth)
		  AND Id != @timeSheetId2
	END
	ELSE
	BEGIN
		-- TimeSheet 1.0
		INSERT INTO [TimeSheetShift] (TimeSheetId, ShiftIds, RepeatDaysOfWeek)
		VALUES (@prevTimeSheetId1, @shiftId1, @repeatDaysOfWeek1)

		INSERT INTO [TimeSheetShift] (TimeSheetId, ShiftIds, RepeatDaysOfWeek)
		VALUES (@prevTimeSheetId2, @shiftId2, @repeatDaysOfWeek2)
	END

	-- ✅ SỬA: Logic tính số ngày làm việc CHÍNH XÁC
	IF @useNewTimeSheet = 1
	BEGIN
		-- TimeSheet 2.0: Dựa trên RepeatDaysOfWeek
		DECLARE @weeklyDays1 INT
		DECLARE @weeklyDays2 INT
		
		-- Đếm số ngày trong tuần từ RepeatDaysOfWeek
		-- '1,2,3,4,5,6' = 6 ngày
		-- '1,3,5' = 3 ngày
		SET @weeklyDays1 = (LEN(@repeatDaysOfWeek1) - LEN(REPLACE(@repeatDaysOfWeek1, ',', '')) + 1)
		SET @weeklyDays2 = (LEN(@repeatDaysOfWeek2) - LEN(REPLACE(@repeatDaysOfWeek2, ',', '')) + 1)
		
		-- Tháng hiện tại: 1 tuần
		SET @workingDays1 = @weeklyDays1      -- 6 ngày
		SET @workingDays2 = @weeklyDays2      -- 3 ngày
		
		-- Tháng trước: 4 tuần
		SET @workingDaysPrev1 = @weeklyDays1 * 4  -- 24 ngày
		SET @workingDaysPrev2 = @weeklyDays2 * 4  -- 12 ngày
	END
	ELSE
	BEGIN
		-- TimeSheet 1.0: Dựa trên số ngày trong tháng
		DECLARE @currentMonthDays INT = DAY(EOMONTH(GETDATE()))
		DECLARE @prevMonthDays INT = DAY(EOMONTH(DATEADD(MONTH, -1, GETDATE())))
		
		-- Giả sử làm việc tất cả các ngày trong tháng
		SET @workingDays1 = @currentMonthDays
		SET @workingDays2 = @currentMonthDays
		SET @workingDaysPrev1 = @prevMonthDays
		SET @workingDaysPrev2 = @prevMonthDays
	END
	
	-- ✅ THÊM: Debug log để kiểm tra
	PRINT 'useNewTimeSheet: ' + CAST(@useNewTimeSheet AS VARCHAR(10))
	PRINT 'workingDays1: ' + CAST(@workingDays1 AS VARCHAR(10))
	PRINT 'workingDays2: ' + CAST(@workingDays2 AS VARCHAR(10))
	PRINT 'workingDaysPrev1: ' + CAST(@workingDaysPrev1 AS VARCHAR(10))
	PRINT 'workingDaysPrev2: ' + CAST(@workingDaysPrev2 AS VARCHAR(10))
END