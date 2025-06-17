USE [KV_TimeSheet_Booking_Dev2]
GO
/****** Object:  StoredProcedure [dbo].[pr_Booking_Insert_TrialData_Clocking]    Script Date: 6/17/2025 4:17:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_Clocking]
(
    @tenantId			INT,				-- ID gian hàng
	@branchId			INT,				-- ID chi nhánh
	@userId				BIGINT,				-- ID tài khoản admin
	@employeeId1		BIGINT,				-- ID nhân viên 1
	@employeeId2		BIGINT,				-- ID nhân viên 2
	@startDate			DATETIME,			-- Ngày bắt đầu
	@endDate			DATETIME,			-- Ngày kết thúc
	@shiftId1			BIGINT,				-- ID ca 1
	@shiftId2			BIGINT,				-- ID ca 2
	@timeSheetId1		BIGINT,				-- ID lịch làm việc ca 1
	@timeSheetId2		BIGINT,				-- ID lịch làm việc ca 2
	@useNewTimeSheet	BIT,				-- Gian hàng dùng Lịch làm việc 1.0/2.0
	@monday				DATETIME,			-- Thứ 2 của tuần hiện tại
	@sunday				DATETIME			-- Chủ nhật của tuần hiện tại
)
AS
BEGIN
	DECLARE @clockingStartDate DATETIME
	DECLARE @clockingEndDate DATETIME
	SET @clockingStartDate = (SELECT case when @useNewTimeSheet = 1 then @monday else @startDate end)
	SET @clockingEndDate = (SELECT case when @useNewTimeSheet = 1 then @sunday else @endDate end)

	DECLARE @startDateCaSang DATETIME
	DECLARE @startDateCaSangDiTre DATETIME
	DECLARE @startDateCaChieu DATETIME
	DECLARE @startDateCaChieuDiTre DATETIME
	DECLARE @endDateCaSang DATETIME
	DECLARE @endDateCaChieu DATETIME
	DECLARE @clockingId BIGINT
	DECLARE @clockingHistoryId BIGINT

	DECLARE @dateNumber INT
	SET @dateNumber = (SELECT DATEDIFF(DAY, StartDate, EndDate) FROM TimeSheet WHERE TenantId = @tenantId AND EmployeeId = @employeeId1) + (case when @useNewTimeSheet = 1 then 0 else 1 end)

	-- Insert đi trễ ca sáng lần 1
	SET @clockingId = NEXT VALUE FOR ClockingSeq
	SET @startDateCaSang = (SELECT CAST(CONVERT(CHAR(8), @clockingStartDate, 112) + ' 09:00:00' AS datetime))
	SET @startDateCaSangDiTre = (SELECT CAST(CONVERT(CHAR(8), @clockingStartDate, 112) + ' 09:15:00' AS datetime))
	SET @endDateCaSang = (SELECT CAST(CONVERT(CHAR(8), @clockingStartDate, 112) + ' 15:00:00' AS datetime))
	INSERT INTO Clocking (Id, TimeSheetId, ShiftId, EmployeeId, WorkById, ClockingStatus, StartTime, EndTime, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted, CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork,  ClockingPaymentStatus)
	VALUES        (@clockingId, @timeSheetId1, @shiftId1, @employeeId1, @employeeId1, 3, @startDateCaSang, @endDateCaSang, @tenantId, @branchId, @userId, GETDATE(), 0, @startDateCaSangDiTre, @endDateCaSang, 15, 0, 0, 0, 0)

	SET @clockingHistoryId = NEXT VALUE FOR ClockingHistorySeq
	INSERT INTO ClockingHistory (Id, ClockingId, CheckedInDate, CheckedOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, TenantId, BranchId, TimeKeepingType, ClockingStatus, CreatedBy, CreatedDate, ClockingHistoryStatus, TimeIsLateAdjustment, OverTimeBeforeShiftWorkAdjustment, TimeIsLeaveWorkEarlyAdjustment, OverTimeAfterShiftWorkAdjustment, ShiftId, ShiftFrom, ShiftTo, 
                         EmployeeId, CheckTime)
	VALUES        (@clockingHistoryId, @clockingId, @startDateCaSangDiTre, @endDateCaSang, 15, 0, 0, 0, @tenantId, @branchId, 1, 3, @userId, GETDATE(), 1, 0, 0, 0, 0, @shiftId1, 540, 900, @employeeId1, GETDATE())
	
	-- Insert đi trễ ca chiều lần 1
	SET @startDateCaChieu = (SELECT CAST(CONVERT(CHAR(8), @clockingStartDate, 112) + ' 15:00:00' AS datetime))
	SET @startDateCaChieuDiTre = (SELECT CAST(CONVERT(CHAR(8), @clockingStartDate, 112) + ' 15:15:00' AS datetime))
	SET @endDateCaChieu = (SELECT CAST(CONVERT(CHAR(8), @clockingStartDate, 112) + ' 22:30:00' AS datetime))
	SET @clockingId = NEXT VALUE FOR ClockingSeq
	INSERT INTO Clocking (Id, TimeSheetId, ShiftId, EmployeeId, WorkById, ClockingStatus, StartTime, EndTime, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted, CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork,  ClockingPaymentStatus)
	VALUES        (@clockingId, @timeSheetId2, @shiftId2, @employeeId2, @employeeId2, 3, @startDateCaChieu, @endDateCaChieu, @tenantId, @branchId, @userId, GETDATE(), 0, @startDateCaChieuDiTre, @endDateCaChieu, 15, 0, 0, 0, 0)

	SET @clockingHistoryId = NEXT VALUE FOR ClockingHistorySeq
	INSERT INTO ClockingHistory (Id, ClockingId, CheckedInDate, CheckedOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, TenantId, BranchId, TimeKeepingType, ClockingStatus, CreatedBy, CreatedDate, ClockingHistoryStatus, TimeIsLateAdjustment, OverTimeBeforeShiftWorkAdjustment, TimeIsLeaveWorkEarlyAdjustment, OverTimeAfterShiftWorkAdjustment, ShiftId, ShiftFrom, ShiftTo, 
                         EmployeeId, CheckTime)
	VALUES        (@clockingHistoryId, @clockingId, @startDateCaChieuDiTre, @endDateCaChieu, 15, 0, 0, 0, @tenantId, @branchId, 1, 3, @userId, GETDATE(), 1, 0, 0, 0, 0, @shiftId2, 900, 1350, @employeeId1, GETDATE())

	-- Insert đi trễ ca sáng lần 2
	SET @clockingStartDate = DATEADD(DAY, 1, @clockingStartDate)
	SET @startDateCaSang = (SELECT CAST(CONVERT(CHAR(8), @clockingStartDate, 112) + ' 09:00:00' AS datetime))
	SET @startDateCaSangDiTre = (SELECT CAST(CONVERT(CHAR(8), @clockingStartDate, 112) + ' 09:15:00' AS datetime))
	SET @endDateCaSang = (SELECT CAST(CONVERT(CHAR(8), @clockingStartDate, 112) + ' 15:00:00' AS datetime))
	SET @clockingId = NEXT VALUE FOR ClockingSeq
	INSERT INTO Clocking (Id, TimeSheetId, ShiftId, EmployeeId, WorkById, ClockingStatus, StartTime, EndTime, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted, CheckInDate, CheckOutDate, 
								TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork,  ClockingPaymentStatus)
	VALUES        (@clockingId, @timeSheetId1, @shiftId1, @employeeId1, @employeeId1, 3, @startDateCaSang, @endDateCaSang, @tenantId, @branchId, @userId, GETDATE(), 0, @startDateCaSangDiTre, @endDateCaSang, 15, 0, 0, 0, 0)

	SET @clockingHistoryId = NEXT VALUE FOR ClockingHistorySeq
	INSERT INTO ClockingHistory (Id, ClockingId, CheckedInDate, CheckedOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, TenantId, BranchId, TimeKeepingType, ClockingStatus, CreatedBy, CreatedDate, ClockingHistoryStatus, TimeIsLateAdjustment, OverTimeBeforeShiftWorkAdjustment, TimeIsLeaveWorkEarlyAdjustment, OverTimeAfterShiftWorkAdjustment, ShiftId, ShiftFrom, ShiftTo, EmployeeId, CheckTime)
	VALUES        (@clockingHistoryId, @clockingId, @startDateCaSangDiTre, @endDateCaSang, 15, 0, 0, 0, @tenantId, @branchId, 1, 3, @userId, GETDATE(), 1, 0, 0, 0, 0, @shiftId1, 540, 900, @employeeId1, GETDATE())
	
	IF @useNewTimeSheet = 0
		BEGIN
			-- Insert đi trễ ca chiều lần 2
			SET @startDateCaChieu = (SELECT CAST(CONVERT(CHAR(8), @clockingStartDate, 112) + ' 15:00:00' AS datetime))
			SET @startDateCaChieuDiTre = (SELECT CAST(CONVERT(CHAR(8), @clockingStartDate, 112) + ' 15:15:00' AS datetime))
			SET @endDateCaChieu = (SELECT CAST(CONVERT(CHAR(8), @clockingStartDate, 112) + ' 22:30:00' AS datetime))
			SET @clockingId = NEXT VALUE FOR ClockingSeq
			INSERT INTO Clocking (Id, TimeSheetId, ShiftId, EmployeeId, WorkById, ClockingStatus, StartTime, EndTime, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted, CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork,  ClockingPaymentStatus)
			VALUES        (@clockingId, @timeSheetId2, @shiftId2, @employeeId2, @employeeId2, 3, @startDateCaChieu, @endDateCaChieu, @tenantId, @branchId, @userId, GETDATE(), 0, @startDateCaChieuDiTre, @endDateCaChieu, 15, 0, 0, 0, 0)

			SET @clockingHistoryId = NEXT VALUE FOR ClockingHistorySeq
			INSERT INTO ClockingHistory (Id, ClockingId, CheckedInDate, CheckedOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, TenantId, BranchId, TimeKeepingType, ClockingStatus, CreatedBy, CreatedDate, ClockingHistoryStatus, TimeIsLateAdjustment, OverTimeBeforeShiftWorkAdjustment, TimeIsLeaveWorkEarlyAdjustment, OverTimeAfterShiftWorkAdjustment, ShiftId, ShiftFrom, ShiftTo, 
								 EmployeeId, CheckTime)
			VALUES        (@clockingHistoryId, @clockingId, @startDateCaChieuDiTre, @endDateCaChieu, 15, 0, 0, 0, @tenantId, @branchId, 1, 3, @userId, GETDATE(), 1, 0, 0, 0, 0, @shiftId2, 900, 1350, @employeeId1, GETDATE())
		END

	DECLARE @Number INT = 1
	WHILE @Number <= @dateNumber - 2
	BEGIN
		-- Insert ca sáng
		SET @clockingStartDate = DATEADD(DAY, 1, @clockingStartDate)
		SET @startDateCaSang = (SELECT CAST(CONVERT(CHAR(8), @clockingStartDate, 112) + ' 09:00:00' AS datetime))
		SET @endDateCaSang = (SELECT CAST(CONVERT(CHAR(8), @clockingStartDate, 112) + ' 15:00:00' AS datetime))
		SET @clockingId = NEXT VALUE FOR ClockingSeq
		INSERT INTO Clocking (Id, TimeSheetId, ShiftId, EmployeeId, WorkById, ClockingStatus, StartTime, EndTime, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted, CheckInDate, CheckOutDate, 
								TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork,  ClockingPaymentStatus)
		VALUES        (@clockingId, @timeSheetId1, @shiftId1, @employeeId1, @employeeId1, 3, @startDateCaSang, @endDateCaSang, @tenantId, @branchId, @userId, GETDATE(), 0, @startDateCaSang, @endDateCaSang, 0, 0, 0, 0, 0)
	
		SET @clockingHistoryId = NEXT VALUE FOR ClockingHistorySeq
		INSERT INTO ClockingHistory (Id, ClockingId, CheckedInDate, CheckedOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, TenantId, BranchId, TimeKeepingType, ClockingStatus, CreatedBy, CreatedDate, ClockingHistoryStatus, TimeIsLateAdjustment, OverTimeBeforeShiftWorkAdjustment, TimeIsLeaveWorkEarlyAdjustment, OverTimeAfterShiftWorkAdjustment, ShiftId, ShiftFrom, ShiftTo, 
							 EmployeeId, CheckTime)
		VALUES        (@clockingHistoryId, @clockingId, @startDateCaSang, @endDateCaSang, 0, 0, 0, 0, @tenantId, @branchId, 1, 3, @userId, GETDATE(), 1, 0, 0, 0, 0, @shiftId1, 540, 900, @employeeId1, GETDATE())
		
		-- Insert ca chiều
		IF (@useNewTimeSheet = 0 or (@useNewTimeSheet = 1 and @Number % 2 = 1))
			BEGIN
				SET @startDateCaChieu = (SELECT CAST(CONVERT(CHAR(8), @clockingStartDate, 112) + ' 15:00:00' AS datetime))
				SET @endDateCaChieu = (SELECT CAST(CONVERT(CHAR(8), @clockingStartDate, 112) + ' 22:30:00' AS datetime))
				SET @clockingId = NEXT VALUE FOR ClockingSeq
				INSERT INTO Clocking (Id, TimeSheetId, ShiftId, EmployeeId, WorkById, ClockingStatus, StartTime, EndTime, TenantId, BranchId, CreatedBy, CreatedDate, IsDeleted,  CheckInDate, CheckOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork,  ClockingPaymentStatus)
				VALUES        (@clockingId, @timeSheetId2, @shiftId2, @employeeId2, @employeeId2, 3, @startDateCaChieu, @endDateCaChieu, @tenantId, @branchId, @userId, GETDATE(), 0, @startDateCaChieu, @endDateCaChieu, 0, 0, 0, 0, 0)
		
				SET @clockingHistoryId = NEXT VALUE FOR ClockingHistorySeq
				INSERT INTO ClockingHistory (Id, ClockingId, CheckedInDate, CheckedOutDate, TimeIsLate, OverTimeBeforeShiftWork, TimeIsLeaveWorkEarly, OverTimeAfterShiftWork, TenantId, BranchId, TimeKeepingType, ClockingStatus, CreatedBy, CreatedDate, ClockingHistoryStatus, TimeIsLateAdjustment, OverTimeBeforeShiftWorkAdjustment, TimeIsLeaveWorkEarlyAdjustment, OverTimeAfterShiftWorkAdjustment, ShiftId, ShiftFrom, ShiftTo, 
									 EmployeeId, CheckTime)
				VALUES        (@clockingHistoryId, @clockingId, @startDateCaChieu, @endDateCaChieu, 0, 0, 0, 0, @tenantId, @branchId, 1, 3, @userId, GETDATE(), 1, 0, 0, 0, 0, @shiftId2, 900, 1350, @employeeId1, GETDATE())
			END

		SET @Number = @Number + 1
	END
END