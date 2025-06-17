USE [KV_TimeSheet_Booking_Dev2]
GO
/****** Object:  StoredProcedure [dbo].[pr_Booking_Insert_TrialData_TimeSheetShift]    Script Date: 6/13/2025 11:34:30 AM ******/
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
	@useNewTimeSheet	BIT
)
AS
BEGIN
	DECLARE @repeatDaysOfWeek1 NVARCHAR(500)
	DECLARE @repeatDaysOfWeek2 NVARCHAR(500)
	SET @repeatDaysOfWeek1 = (SELECT case when @useNewTimeSheet = 1 then '1,2,3,4,5,6' else NULL end)
	SET @repeatDaysOfWeek2 = (SELECT case when @useNewTimeSheet = 1 then '1,3,5' else NULL end)

	INSERT INTO [TimeSheetShift] (TimeSheetId, ShiftIds, RepeatDaysOfWeek)
	VALUES		(@timeSheetId1, @shiftId1, @repeatDaysOfWeek1)

	INSERT INTO [TimeSheetShift] (TimeSheetId, ShiftIds, RepeatDaysOfWeek)
	VALUES      (@timeSheetId2, @shiftId2, @repeatDaysOfWeek2)
END