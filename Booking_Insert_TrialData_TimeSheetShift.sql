USE [KV_TimeSheet_Booking_Dev2]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[pr_Booking_Insert_TrialData_TimeSheetShift]
(
	@shiftId1			VARCHAR(50),
	@shiftId2			VARCHAR(50),
	@timeSheetId1		BIGINT,
	@timeSheetId2		BIGINT,
	@prevTimeSheetId1	BIGINT, -- lịch làm việc tháng trước nhân viên 1
	@prevTimeSheetId2	BIGINT, -- lịch làm việc tháng trước nhân viên 2
	@useNewTimeSheet	BIT
)
AS
BEGIN
    SET NOCOUNT ON;

	DECLARE @repeatDaysOfWeek1 NVARCHAR(500)
	DECLARE @repeatDaysOfWeek2 NVARCHAR(500)

	-- Nếu dùng lịch làm việc 2.0 thì gán ngày cụ thể
	IF @useNewTimeSheet = 1
	BEGIN
		SET @repeatDaysOfWeek1 = '1,2,3,4,5,6' -- Nhân viên 1 làm từ thứ 2 đến thứ 7
		SET @repeatDaysOfWeek2 = '1,3,5'       -- Nhân viên 2 làm thứ 2, 4, 6
	END
	ELSE
	BEGIN
		SET @repeatDaysOfWeek1 = NULL
		SET @repeatDaysOfWeek2 = NULL
	END

	-- Gán ca cho lịch làm việc hiện tại
	INSERT INTO [TimeSheetShift] (TimeSheetId, ShiftIds, RepeatDaysOfWeek)
	VALUES		(@timeSheetId1, @shiftId1, @repeatDaysOfWeek1)

	INSERT INTO [TimeSheetShift] (TimeSheetId, ShiftIds, RepeatDaysOfWeek)
	VALUES      (@timeSheetId2, @shiftId2, @repeatDaysOfWeek2)

	-- Gán ca cho lịch làm việc tháng trước
	INSERT INTO [TimeSheetShift] (TimeSheetId, ShiftIds, RepeatDaysOfWeek)
	VALUES		(@prevTimeSheetId1, @shiftId1, @repeatDaysOfWeek1)

	INSERT INTO [TimeSheetShift] (TimeSheetId, ShiftIds, RepeatDaysOfWeek)
	VALUES      (@prevTimeSheetId2, @shiftId2, @repeatDaysOfWeek2)
END
