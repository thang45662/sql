-- ========================
-- File: pr_Booking_Insert_TrialData_Clocking.sql
-- ========================
ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_Clocking]
(
    @tenantId			INT,				-- ID gian hàng
	@branchId			INT,				-- ID chi nhánh
	@userId				BIGINT,				-- ID tài khoản admin
	@employeeId1		BIGINT,				-- ID nhân viên 1
	@employeeId2		BIGINT,				-- ID nhân viên 2
	@startDate			DATETIME,			-- Ngày bắt đầu tháng hiện tại (ví dụ: 2024-12-01)
	@endDate			DATETIME,			-- Ngày kết thúc tháng hiện tại (ví dụ: 2024-12-17)
	@shiftId1			BIGINT,				-- ID ca 1
	@shiftId2			BIGINT,				-- ID ca 2
	@timeSheetId1		BIGINT,				-- ID lịch làm việc tháng hiện tại ca 1
	@timeSheetId2		BIGINT,				-- ID lịch làm việc tháng hiện tại ca 2
	@useNewTimeSheet	BIT,				-- Gian hàng dùng Lịch làm việc 1.0/2.0
	@monday				DATETIME,			-- Thứ 2 của tuần hiện tại
	@sunday				DATETIME,			-- Chủ nhật của tuần hiện tại
	@prevTimeSheetId1	BIGINT,				-- ID lịch làm việc tháng trước ca 1 (tuần đầu tiên nếu là 2.0)
	@prevTimeSheetId2	BIGINT				-- ID lịch làm việc tháng trước ca 2 (tuần đầu tiên nếu là 2.0)
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @clockingStartDate DATETIME
	DECLARE @clockingEndDate DATETIME
	DECLARE @startDateCaSang DATETIME
	DECLARE @startDateCaSangDiTre DATETIME
	DECLARE @startDateCaChieu DATETIME
	DECLARE @startDateCaChieuDiTre DATETIME
	DECLARE @endDateCaSang DATETIME
	DECLARE @endDateCaChieu DATETIME
	DECLARE @clockingId BIGINT
	DECLARE @clockingHistoryId BIGINT

	-- Xác định khoảng thời gian cho tháng hiện tại
	IF @useNewTimeSheet = 1
	BEGIN
		SET @clockingStartDate = @monday
		SET @clockingEndDate = @sunday
	END
	ELSE
	BEGIN
		SET @clockingStartDate = @startDate
		SET @clockingEndDate = @endDate
	END

	-- Tính tổng số ngày trong khoảng thời gian hiện tại để lặp
	DECLARE @totalDaysCurrentPeriod INT = DATEDIFF(DAY, @clockingStartDate, @clockingEndDate) + 1;
	DECLARE @currentLoopDate DATETIME = @clockingStartDate;
	DECLARE @dayCounter INT = 0;

	-- =====================================================
	-- 1. TẠO CLOCKING CHO THÁNG HIỆN TẠI
	-- =====================================================

	-- Insert đi trễ ca sáng lần 1 (Ngày đầu tiên của khoảng hiện tại)
	SET @clockingId = NEXT VALUE FOR ClockingSeq
	SET @startDateCaSang = (SELECT CAST(CONVERT(CHAR(8), @currentLoopDate, 112) + ' 09:00:00' AS datetime))
	SET @startDateCaSangDiTre = (SELECT CAST(CONVERT(CHAR(8), @currentLoopDate, 112) + ' 09:15:00' AS datetime))
	SET @endDateCaSang = (SELECT CAST(CONVERT(CHAR(8), @currentLoopDate, 112) + ' 15:00:00' AS datetime))
	INSERT INTO Clocking (Id, TimeSheetId, ShiftId, EmployeeId, WorkById, ClockingStatus, StartTime, EndTime, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted, CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork,  ClockingPaymentStatus)
	VALUES        (@clockingId, @timeSheetId1, @shiftId1, @employeeId1, @employeeId1, 3, @startDateCaSang, @endDateCaSang, @tenantId, @branchId, @userId, GETDATE(), 0, @startDateCaSangDiTre, @endDateCaSang, 15, 0, 0, 0, 0)

	SET @clockingHistoryId = NEXT VALUE FOR ClockingHistorySeq
	INSERT INTO ClockingHistory (Id, ClockingId, CheckedInDate, CheckedOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, TenantId, BranchId, TimeKeepingType, ClockingStatus, CreatedBy, CreatedDate, ClockingHistoryStatus, TimeIsLateAdjustment, OverTimeBeforeShiftWorkAdjustment, TimeIsLeaveWorkEarlyAdjustment, OverTimeAfterShiftWorkAdjustment, ShiftId, ShiftFrom, ShiftTo, EmployeeId, CheckTime)
	VALUES        (@clockingHistoryId, @clockingId, @startDateCaSangDiTre, @endDateCaSang, 15, 0, 0, 0, @tenantId, @branchId, 1, 3, @userId, GETDATE(), 1, 0, 0, 0, 0, @shiftId1, 540, 900, @employeeId1, GETDATE())

	-- Insert đi trễ ca chiều lần 1 (Ngày đầu tiên của khoảng hiện tại)
	SET @startDateCaChieu = (SELECT CAST(CONVERT(CHAR(8), @currentLoopDate, 112) + ' 15:00:00' AS datetime))
	SET @startDateCaChieuDiTre = (SELECT CAST(CONVERT(CHAR(8), @currentLoopDate, 112) + ' 15:15:00' AS datetime))
	SET @endDateCaChieu = (SELECT CAST(CONVERT(CHAR(8), @currentLoopDate, 112) + ' 22:30:00' AS datetime))
	SET @clockingId = NEXT VALUE FOR ClockingSeq
	INSERT INTO Clocking (Id, TimeSheetId, ShiftId, EmployeeId, WorkById, ClockingStatus, StartTime, EndTime, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted, CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork,  ClockingPaymentStatus)
	VALUES        (@clockingId, @timeSheetId2, @shiftId2, @employeeId2, @employeeId2, 3, @startDateCaChieu, @endDateCaChieu, @tenantId, @branchId, @userId, GETDATE(), 0, @startDateCaChieuDiTre, @endDateCaChieu, 15, 0, 0, 0, 0)

	SET @clockingHistoryId = NEXT VALUE FOR ClockingHistorySeq
	INSERT INTO ClockingHistory (Id, ClockingId, CheckedInDate, CheckedOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, TenantId, BranchId, TimeKeepingType, ClockingStatus, CreatedBy, CreatedDate, ClockingHistoryStatus, TimeIsLateAdjustment, OverTimeBeforeShiftWorkAdjustment, TimeIsLeaveWorkEarlyAdjustment, OverTimeAfterShiftWorkAdjustment, ShiftId, ShiftFrom, ShiftTo, EmployeeId, CheckTime)
	VALUES        (@clockingHistoryId, @clockingId, @startDateCaChieuDiTre, @endDateCaChieu, 15, 0, 0, 0, @tenantId, @branchId, 1, 3, @userId, GETDATE(), 1, 0, 0, 0, 0, @shiftId2, 900, 1350, @employeeId2, GETDATE()) -- ✅ SỬA: employeeId2

	SET @currentLoopDate = DATEADD(DAY, 1, @currentLoopDate); -- Chuyển sang ngày thứ 2
	SET @dayCounter = @dayCounter + 1;

	-- Insert đi trễ ca sáng lần 2 (Ngày thứ 2 của khoảng hiện tại)
	SET @clockingId = NEXT VALUE FOR ClockingSeq
	SET @startDateCaSang = (SELECT CAST(CONVERT(CHAR(8), @currentLoopDate, 112) + ' 09:00:00' AS datetime))
	SET @startDateCaSangDiTre = (SELECT CAST(CONVERT(CHAR(8), @currentLoopDate, 112) + ' 09:15:00' AS datetime))
	SET @endDateCaSang = (SELECT CAST(CONVERT(CHAR(8), @currentLoopDate, 112) + ' 15:00:00' AS datetime))
	INSERT INTO Clocking (Id, TimeSheetId, ShiftId, EmployeeId, WorkById, ClockingStatus, StartTime, EndTime, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted, CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork,  ClockingPaymentStatus)
	VALUES        (@clockingId, @timeSheetId1, @shiftId1, @employeeId1, @employeeId1, 3, @startDateCaSang, @endDateCaSang, @tenantId, @branchId, @userId, GETDATE(), 0, @startDateCaSangDiTre, @endDateCaSang, 15, 0, 0, 0, 0)

	SET @clockingHistoryId = NEXT VALUE FOR ClockingHistorySeq
	INSERT INTO ClockingHistory (Id, ClockingId, CheckedInDate, CheckedOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, TenantId, BranchId, TimeKeepingType, ClockingStatus, CreatedBy, CreatedDate, ClockingHistoryStatus, TimeIsLateAdjustment, OverTimeBeforeShiftWorkAdjustment, TimeIsLeaveWorkEarlyAdjustment, OverTimeAfterShiftWorkAdjustment, ShiftId, ShiftFrom, ShiftTo, EmployeeId, CheckTime)
	VALUES        (@clockingHistoryId, @clockingId, @startDateCaSangDiTre, @endDateCaSang, 15, 0, 0, 0, @tenantId, @branchId, 1, 3, @userId, GETDATE(), 1, 0, 0, 0, 0, @shiftId1, 540, 900, @employeeId1, GETDATE())

	IF @useNewTimeSheet = 0 -- Logic cũ cho TimeSheet 1.0
	BEGIN
		-- Insert đi trễ ca chiều lần 2 (Ngày thứ 2 của khoảng hiện tại)
		SET @startDateCaChieu = (SELECT CAST(CONVERT(CHAR(8), @currentLoopDate, 112) + ' 15:00:00' AS datetime))
		SET @startDateCaChieuDiTre = (SELECT CAST(CONVERT(CHAR(8), @currentLoopDate, 112) + ' 15:15:00' AS datetime))
		SET @endDateCaChieu = (SELECT CAST(CONVERT(CHAR(8), @currentLoopDate, 112) + ' 22:30:00' AS datetime))
		SET @clockingId = NEXT VALUE FOR ClockingSeq
		INSERT INTO Clocking (Id, TimeSheetId, ShiftId, EmployeeId, WorkById, ClockingStatus, StartTime, EndTime, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted, CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork,  ClockingPaymentStatus)
		VALUES        (@clockingId, @timeSheetId2, @shiftId2, @employeeId2, @employeeId2, 3, @startDateCaChieu, @endDateCaChieu, @tenantId, @branchId, @userId, GETDATE(), 0, @startDateCaChieuDiTre, @endDateCaChieu, 15, 0, 0, 0, 0)

		SET @clockingHistoryId = NEXT VALUE FOR ClockingHistorySeq
		INSERT INTO ClockingHistory (Id, ClockingId, CheckedInDate, CheckedOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, TenantId, BranchId, TimeKeepingType, ClockingStatus, CreatedBy, CreatedDate, ClockingHistoryStatus, TimeIsLateAdjustment, OverTimeBeforeShiftWorkAdjustment, TimeIsLeaveWorkEarlyAdjustment, OverTimeAfterShiftWorkAdjustment, ShiftId, ShiftFrom, ShiftTo, EmployeeId, CheckTime)
		VALUES        (@clockingHistoryId, @clockingId, @startDateCaChieuDiTre, @endDateCaChieu, 15, 0, 0, 0, @tenantId, @branchId, 1, 3, @userId, GETDATE(), 1, 0, 0, 0, 0, @shiftId2, 900, 1350, @employeeId2, GETDATE()) -- ✅ SỬA: employeeId2
	END

	SET @currentLoopDate = DATEADD(DAY, 1, @currentLoopDate); -- Chuyển sang ngày thứ 3
	SET @dayCounter = @dayCounter + 1;

	-- Loop cho các ngày còn lại của tháng hiện tại (từ ngày thứ 3 trở đi)
	WHILE @dayCounter < @totalDaysCurrentPeriod
	BEGIN
		-- Insert ca sáng (nhân viên 1)
		SET @startDateCaSang = (SELECT CAST(CONVERT(CHAR(8), @currentLoopDate, 112) + ' 09:00:00' AS datetime))
		SET @endDateCaSang = (SELECT CAST(CONVERT(CHAR(8), @currentLoopDate, 112) + ' 15:00:00' AS datetime))
		SET @clockingId = NEXT VALUE FOR ClockingSeq
		INSERT INTO Clocking (Id, TimeSheetId, ShiftId, EmployeeId, WorkById, ClockingStatus, StartTime, EndTime, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted, CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork,  ClockingPaymentStatus)
		VALUES        (@clockingId, @timeSheetId1, @shiftId1, @employeeId1, @employeeId1, 3, @startDateCaSang, @endDateCaSang, @tenantId, @branchId, @userId, GETDATE(), 0, @startDateCaSang, @endDateCaSang, 0, 0, 0, 0, 0)

		SET @clockingHistoryId = NEXT VALUE FOR ClockingHistorySeq
		INSERT INTO ClockingHistory (Id, ClockingId, CheckedInDate, CheckedOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, TenantId, BranchId, TimeKeepingType, ClockingStatus, CreatedBy, CreatedDate, ClockingHistoryStatus, TimeIsLateAdjustment, OverTimeBeforeShiftWorkAdjustment, TimeIsLeaveWorkEarlyAdjustment, OverTimeAfterShiftWorkAdjustment, ShiftId, ShiftFrom, ShiftTo, EmployeeId, CheckTime)
		VALUES        (@clockingHistoryId, @clockingId, @startDateCaSang, @endDateCaSang, 0, 0, 0, 0, @tenantId, @branchId, 1, 3, @userId, GETDATE(), 1, 0, 0, 0, 0, @shiftId1, 540, 900, @employeeId1, GETDATE())

		-- Insert ca chiều (nhân viên 2)
		IF (@useNewTimeSheet = 0 OR (@useNewTimeSheet = 1 AND @dayCounter % 2 = 1)) --Cho TimeSheet 1.0 hoặc ngày lẻ cho 2.0
		BEGIN
			SET @startDateCaChieu = (SELECT CAST(CONVERT(CHAR(8), @currentLoopDate, 112) + ' 15:00:00' AS datetime))
			SET @endDateCaChieu = (SELECT CAST(CONVERT(CHAR(8), @currentLoopDate, 112) + ' 22:30:00' AS datetime))
			SET @clockingId = NEXT VALUE FOR ClockingSeq
			INSERT INTO Clocking (Id, TimeSheetId, ShiftId, EmployeeId, WorkById, ClockingStatus, StartTime, EndTime, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted,  CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork,  ClockingPaymentStatus)
			VALUES        (@clockingId, @timeSheetId2, @shiftId2, @employeeId2, @employeeId2, 3, @startDateCaChieu, @endDateCaChieu, @tenantId, @branchId, @userId, GETDATE(), 0, @startDateCaChieu, @endDateCaChieu, 0, 0, 0, 0, 0)

			SET @clockingHistoryId = NEXT VALUE FOR ClockingHistorySeq
			INSERT INTO ClockingHistory (Id, ClockingId, CheckedInDate, CheckedOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, TenantId, BranchId, TimeKeepingType, ClockingStatus, CreatedBy, CreatedDate, ClockingHistoryStatus, TimeIsLateAdjustment, OverTimeBeforeShiftWorkAdjustment, TimeIsLeaveWorkEarlyAdjustment, OverTimeAfterShiftWorkAdjustment, ShiftId, ShiftFrom, ShiftTo, EmployeeId, CheckTime)
			VALUES        (@clockingHistoryId, @clockingId, @startDateCaChieu, @endDateCaChieu, 0, 0, 0, 0, @tenantId, @branchId, 1, 3, @userId, GETDATE(), 1, 0, 0, 0, 0, @shiftId2, 900, 1350, @employeeId2, GETDATE()) -- ✅ SỬA: employeeId2
		END

		SET @currentLoopDate = DATEADD(DAY, 1, @currentLoopDate)
		SET @dayCounter = @dayCounter + 1
	END

	-- =====================================================
	-- 2. TẠO CLOCKING CHO THÁNG TRƯỚC (FULL THÁNG THEO CA LÀM VIỆC)
	-- =====================================================
	DECLARE @prevMonthStartDate DATETIME = DATEADD(MONTH, -1, DATEADD(DAY, 1 - DAY(GETDATE()), GETDATE())); -- Ngày đầu tiên của tháng trước
	DECLARE @prevMonthEndDate DATETIME = EOMONTH(DATEADD(MONTH, -1, GETDATE())); -- Ngày cuối cùng của tháng trước

	-- Lấy RepeatDaysOfWeek từ TimeSheetShift cho ca 1 và ca 2 (tháng trước)
	-- TimeSheetShift cho tháng trước đã được tạo và có RepeatDaysOfWeek tương ứng
	DECLARE @repeatDaysOfWeek1_Prev NVARCHAR(500);
	DECLARE @repeatDaysOfWeek2_Prev NVARCHAR(500);

	-- Lấy RepeatDaysOfWeek cho NV1 (ca 1) từ TimeSheetShift của tháng trước
	SELECT TOP 1 @repeatDaysOfWeek1_Prev = RepeatDaysOfWeek
	FROM TimeSheetShift
	WHERE TimeSheetId = @prevTimeSheetId1 AND ShiftIds = @shiftId1;

	-- Lấy RepeatDaysOfWeek cho NV2 (ca 2) từ TimeSheetShift của tháng trước
	SELECT TOP 1 @repeatDaysOfWeek2_Prev = RepeatDaysOfWeek
	FROM TimeSheetShift
	WHERE TimeSheetId = @prevTimeSheetId2 AND ShiftIds = @shiftId2;

	-- Nếu không tìm thấy, dùng giá trị mặc định (hoặc giá trị từ tháng hiện tại nếu hợp lý)
	IF @repeatDaysOfWeek1_Prev IS NULL AND @useNewTimeSheet = 1 SET @repeatDaysOfWeek1_Prev = '1,2,3,4,5,6';
	IF @repeatDaysOfWeek2_Prev IS NULL AND @useNewTimeSheet = 1 SET @repeatDaysOfWeek2_Prev = '1,3,5';

	-- Nếu là TimeSheet 1.0, RepeatDaysOfWeek sẽ là NULL, cần logic khác
	IF @useNewTimeSheet = 0
	BEGIN
		-- TimeSheet 1.0: Giả định NV1 làm tất cả các ngày, NV2 làm ngày lẻ
		-- Logic này sẽ tạo clocking cho tất cả các ngày trong tháng trước
		DECLARE @prevLoopDate DATETIME = @prevMonthStartDate;
		DECLARE @prevDayCounter INT = 0;
		WHILE @prevLoopDate <= @prevMonthEndDate
		BEGIN
			-- Insert ca sáng cho NV1
			SET @startDateCaSang = (SELECT CAST(CONVERT(CHAR(8), @prevLoopDate, 112) + ' 09:00:00' AS datetime))
			SET @endDateCaSang = (SELECT CAST(CONVERT(CHAR(8), @prevLoopDate, 112) + ' 15:00:00' AS datetime))
			SET @clockingId = NEXT VALUE FOR ClockingSeq
			INSERT INTO Clocking (Id, TimeSheetId, ShiftId, EmployeeId, WorkById, ClockingStatus, StartTime, EndTime, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted, CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork,  ClockingPaymentStatus)
			VALUES        (@clockingId, @prevTimeSheetId1, @shiftId1, @employeeId1, @employeeId1, 3, @startDateCaSang, @endDateCaSang, @tenantId, @branchId, @userId, GETDATE(), 0, @startDateCaSang, @endDateCaSang, 0, 0, 0, 0, 0)

			SET @clockingHistoryId = NEXT VALUE FOR ClockingHistorySeq
			INSERT INTO ClockingHistory (Id, ClockingId, CheckedInDate, CheckedOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, TenantId, BranchId, TimeKeepingType, ClockingStatus, CreatedBy, CreatedDate, ClockingHistoryStatus, TimeIsLateAdjustment, OverTimeBeforeShiftWorkAdjustment, TimeIsLeaveWorkEarlyAdjustment, OverTimeAfterShiftWorkAdjustment, ShiftId, ShiftFrom, ShiftTo, EmployeeId, CheckTime)
			VALUES        (@clockingHistoryId, @clockingId, @startDateCaSang, @endDateCaSang, 0, 0, 0, 0, @tenantId, @branchId, 1, 3, @userId, GETDATE(), 1, 0, 0, 0, 0, @shiftId1, 540, 900, @employeeId1, GETDATE())

			-- Insert ca chiều cho NV2 (ngày lẻ)
			IF @prevDayCounter % 2 = 0 -- Ngày đầu tiên là 0, ngày thứ 2 là 1, v.v.
			BEGIN
				SET @startDateCaChieu = (SELECT CAST(CONVERT(CHAR(8), @prevLoopDate, 112) + ' 15:00:00' AS datetime))
				SET @endDateCaChieu = (SELECT CAST(CONVERT(CHAR(8), @prevLoopDate, 112) + ' 22:30:00' AS datetime))
				SET @clockingId = NEXT VALUE FOR ClockingSeq
				INSERT INTO Clocking (Id, TimeSheetId, ShiftId, EmployeeId, WorkById, ClockingStatus, StartTime, EndTime, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted,  CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork,  ClockingPaymentStatus)
				VALUES        (@clockingId, @prevTimeSheetId2, @shiftId2, @employeeId2, @employeeId2, 3, @startDateCaChieu, @endDateCaChieu, @tenantId, @branchId, @userId, GETDATE(), 0, @startDateCaChieu, @endDateCaChieu, 0, 0, 0, 0, 0)

				SET @clockingHistoryId = NEXT VALUE FOR ClockingHistorySeq
				INSERT INTO ClockingHistory (Id, ClockingId, CheckedInDate, CheckedOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, TenantId, BranchId, TimeKeepingType, ClockingStatus, CreatedBy, CreatedDate, ClockingHistoryStatus, TimeIsLateAdjustment, OverTimeBeforeShiftWorkAdjustment, TimeIsLeaveWorkEarlyAdjustment, OverTimeAfterShiftWorkAdjustment, ShiftId, ShiftFrom, ShiftTo, EmployeeId, CheckTime)
				VALUES        (@clockingHistoryId, @clockingId, @startDateCaChieu, @endDateCaChieu, 0, 0, 0, 0, @tenantId, @branchId, 1, 3, @userId, GETDATE(), 1, 0, 0, 0, 0, @shiftId2, 900, 1350, @employeeId2, GETDATE())
			END
			SET @prevLoopDate = DATEADD(DAY, 1, @prevLoopDate);
			SET @prevDayCounter = @prevDayCounter + 1;
		END
	END
	ELSE -- @useNewTimeSheet = 1 (TimeSheet 2.0)
	BEGIN
		-- TimeSheet 2.0: Lặp qua từng ngày của tháng trước, kiểm tra RepeatDaysOfWeek
		DECLARE @prevLoopDate_20 DATETIME = @prevMonthStartDate;
		WHILE @prevLoopDate_20 <= @prevMonthEndDate
		BEGIN
			DECLARE @dayOfWeek INT = DATEPART(dw, @prevLoopDate_20); -- 1=Monday, 7=Sunday (assuming @@DATEFIRST = 1)
			-- Adjust for @@DATEFIRST if needed. The TimeSheet procedure uses (@@DATEFIRST + 5 + DATEPART(dw, GETDATE())) % 7, which makes Monday=1.
			-- So, if @@DATEFIRST is 7 (Sunday), DATEPART(dw) for Monday is 2. We need to convert it to 1.
			-- If @@DATEFIRST is 1 (Monday), DATEPART(dw) for Monday is 1. No conversion needed.
			-- Let's assume @@DATEFIRST is 1 for consistency with '1,2,3,4,5,6'
			-- Or, safer:
			SET @dayOfWeek = (DATEPART(dw, @prevLoopDate_20) + @@DATEFIRST - 1) % 7;
			IF @dayOfWeek = 0 SET @dayOfWeek = 7; -- Make Sunday 7, not 0.

			-- Check if employee 1 works on this day
			IF CHARINDEX(CAST(@dayOfWeek AS VARCHAR(1)), @repeatDaysOfWeek1_Prev) > 0
			BEGIN
				SET @startDateCaSang = (SELECT CAST(CONVERT(CHAR(8), @prevLoopDate_20, 112) + ' 09:00:00' AS datetime))
				SET @endDateCaSang = (SELECT CAST(CONVERT(CHAR(8), @prevLoopDate_20, 112) + ' 15:00:00' AS datetime))
				SET @clockingId = NEXT VALUE FOR ClockingSeq
				INSERT INTO Clocking (Id, TimeSheetId, ShiftId, EmployeeId, WorkById, ClockingStatus, StartTime, EndTime, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted, CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork,  ClockingPaymentStatus)
				VALUES        (@clockingId, @prevTimeSheetId1, @shiftId1, @employeeId1, @employeeId1, 3, @startDateCaSang, @endDateCaSang, @tenantId, @branchId, @userId, GETDATE(), 0, @startDateCaSang, @endDateCaSang, 0, 0, 0, 0, 0)

				SET @clockingHistoryId = NEXT VALUE FOR ClockingHistorySeq
				INSERT INTO ClockingHistory (Id, ClockingId, CheckedInDate, CheckedOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, TenantId, BranchId, TimeKeepingType, ClockingStatus, CreatedBy, CreatedDate, ClockingHistoryStatus, TimeIsLateAdjustment, OverTimeBeforeShiftWorkAdjustment, TimeIsLeaveWorkEarlyAdjustment, OverTimeAfterShiftWorkAdjustment, ShiftId, ShiftFrom, ShiftTo, EmployeeId, CheckTime)
				VALUES        (@clockingHistoryId, @clockingId, @startDateCaSang, @endDateCaSang, 0, 0, 0, 0, @tenantId, @branchId, 1, 3, @userId, GETDATE(), 1, 0, 0, 0, 0, @shiftId1, 540, 900, @employeeId1, GETDATE())
			END

			-- Check if employee 2 works on this day
			IF CHARINDEX(CAST(@dayOfWeek AS VARCHAR(1)), @repeatDaysOfWeek2_Prev) > 0
			BEGIN
				SET @startDateCaChieu = (SELECT CAST(CONVERT(CHAR(8), @prevLoopDate_20, 112) + ' 15:00:00' AS datetime))
				SET @endDateCaChieu = (SELECT CAST(CONVERT(CHAR(8), @prevLoopDate_20, 112) + ' 22:30:00' AS datetime))
				SET @clockingId = NEXT VALUE FOR ClockingSeq
				INSERT INTO Clocking (Id, TimeSheetId, ShiftId, EmployeeId, WorkById, ClockingStatus, StartTime, EndTime, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted,  CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork,  ClockingPaymentStatus)
				VALUES        (@clockingId, @prevTimeSheetId2, @shiftId2, @employeeId2, @employeeId2, 3, @startDateCaChieu, @endDateCaChieu, @tenantId, @branchId, @userId, GETDATE(), 0, @startDateCaChieu, @endDateCaChieu, 0, 0, 0, 0, 0)

				SET @clockingHistoryId = NEXT VALUE FOR ClockingHistorySeq
				INSERT INTO ClockingHistory (Id, ClockingId, CheckedInDate, CheckedOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, TenantId, BranchId, TimeKeepingType, ClockingStatus, CreatedBy, CreatedDate, ClockingHistoryStatus, TimeIsLateAdjustment, OverTimeBeforeShiftWorkAdjustment, TimeIsLeaveWorkEarlyAdjustment, OverTimeAfterShiftWorkAdjustment, ShiftId, ShiftFrom, ShiftTo, EmployeeId, CheckTime)
				VALUES        (@clockingHistoryId, @clockingId, @startDateCaChieu, @endDateCaChieu, 0, 0, 0, 0, @tenantId, @branchId, 1, 3, @userId, GETDATE(), 1, 0, 0, 0, 0, @shiftId2, 900, 1350, @employeeId2, GETDATE())
			END
			SET @prevLoopDate_20 = DATEADD(DAY, 1, @prevLoopDate_20);
		END
	END
END

GO
