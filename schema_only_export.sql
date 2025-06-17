
-- Table: backup_ClockingHistory_202402295
CREATE TABLE [backup_ClockingHistory_202402295] (
  [Id] bigint NOT NULL,
  [ClockingId] bigint NOT NULL,
  [CheckedInDate] datetime2 NOT NULL,
  [CheckedOutDate] datetime2 NOT NULL,
  [TimeIsLate] int NOT NULL,
  [OverTimeBeforeShiftWork] int NOT NULL,
  [TimeIsLeaveWorkEarly] int NOT NULL,
  [OverTimeAfterShiftWork] int NOT NULL,
  [TenantId] int NULL,
  [BranchId] int NOT NULL,
  [TimeKeepingType] int NOT NULL,
  [ClockingStatus] int NOT NULL,
  [ModifiedBy] int NULL,
  [ModifiedDate] int NULL,
  [CreatedBy] int NOT NULL,
  [CreatedDate] datetime NOT NULL,
  [ClockingHistoryStatus] int NOT NULL,
  [TimeIsLateAdjustment] int NOT NULL,
  [OverTimeBeforeShiftWorkAdjustment] int NOT NULL,
  [TimeIsLeaveWorkEarlyAdjustment] int NOT NULL,
  [OverTimeAfterShiftWorkAdjustment] int NOT NULL,
  [AbsenceType] int NULL,
  [ShiftId] bigint NOT NULL,
  [ShiftFrom] bigint NOT NULL,
  [ShiftTo] bigint NOT NULL,
  [EmployeeId] bigint NOT NULL,
  [CheckTime] datetime NOT NULL,
  [AutoTimekeepingUid] int NULL
);

-- Table: backup_ClockingHistory_202402296
CREATE TABLE [backup_ClockingHistory_202402296] (
  [Id] bigint NOT NULL,
  [ClockingId] bigint NOT NULL,
  [CheckedInDate] datetime2 NOT NULL,
  [CheckedOutDate] datetime2 NOT NULL,
  [TimeIsLate] int NOT NULL,
  [OverTimeBeforeShiftWork] int NOT NULL,
  [TimeIsLeaveWorkEarly] int NOT NULL,
  [OverTimeAfterShiftWork] int NOT NULL,
  [TenantId] int NULL,
  [BranchId] int NOT NULL,
  [TimeKeepingType] int NOT NULL,
  [ClockingStatus] int NOT NULL,
  [ModifiedBy] int NULL,
  [ModifiedDate] datetime NOT NULL,
  [CreatedBy] int NOT NULL,
  [CreatedDate] datetime NOT NULL,
  [ClockingHistoryStatus] int NOT NULL,
  [TimeIsLateAdjustment] int NOT NULL,
  [OverTimeBeforeShiftWorkAdjustment] int NOT NULL,
  [TimeIsLeaveWorkEarlyAdjustment] int NOT NULL,
  [OverTimeAfterShiftWorkAdjustment] int NOT NULL,
  [AbsenceType] int NULL,
  [ShiftId] bigint NOT NULL,
  [ShiftFrom] bigint NOT NULL,
  [ShiftTo] bigint NOT NULL,
  [EmployeeId] bigint NOT NULL,
  [CheckTime] datetime NOT NULL,
  [AutoTimekeepingUid] int NULL
);

-- Table: Commission1
CREATE TABLE [Commission1] (
  [Id] bigint NOT NULL,
  [Name] nvarchar(255) NOT NULL,
  [IsActive] bit NOT NULL,
  [TenantId] int NOT NULL,
  [CreatedBy] bigint NOT NULL,
  [CreatedDate] datetime2 NOT NULL,
  [ModifiedBy] bigint NULL,
  [ModifiedDate] datetime2 NULL,
  [IsDeleted] bit NOT NULL,
  [DeletedBy] bigint NULL,
  [DeletedDate] datetime2 NULL,
  [IsAllBranch] bit NOT NULL,
  [IsDefault] bit NOT NULL
);

-- Table: ScheduledNotification
CREATE TABLE [ScheduledNotification] (
  [Id] int NOT NULL,
  [KvAppId] int NOT NULL,
  [RetailerId] int NOT NULL,
  [ScheduledDate] datetime NOT NULL,
  [ScheduledDateSince1970] int NOT NULL,
  [ScheduledTimeIndex] int NOT NULL,
  [Type] nvarchar(255) NOT NULL,
  [Message] nvarchar(-1) NOT NULL,
  [ReceiverId] int NULL,
  [GroupKey] nvarchar(255) NULL,
  [CreatedDate] datetime NOT NULL,
  [ModifiedDate] datetime NULL,
  [IsPushed] bit NOT NULL,
  [Data] nvarchar(4000) NULL
);

-- Table: backup_employee_2025_02_07
CREATE TABLE [backup_employee_2025_02_07] (
  [Id] int NOT NULL,
  [TenantId] bigint NULL,
  [EmployeeId] bigint NULL,
  [OldCode] varchar(50) NULL,
  [OldName] nvarchar(255) NULL,
  [NewCode] varchar(50) NULL,
  [NewName] nvarchar(255) NULL,
  [IsDeleted] bit NULL
);

-- Table: backup_timesheet_2025_02_07
CREATE TABLE [backup_timesheet_2025_02_07] (
  [Id] int NOT NULL,
  [TenantId] bigint NULL,
  [EmployeeId] bigint NULL,
  [TimeSheetId] bigint NULL,
  [OldTimeSheetStatus] tinyint NULL,
  [NewTimeSheetStatus] tinyint NULL
);

-- Table: backup_clocking_2025_02_07
CREATE TABLE [backup_clocking_2025_02_07] (
  [Id] int NOT NULL,
  [TenantId] bigint NULL,
  [EmployeeId] bigint NULL,
  [ClockingId] bigint NULL,
  [OldIsDeleted] bit NULL,
  [NewIsDeleted] bit NULL
);

-- Table: backup_clocking_check_in_out_2025_02_07
CREATE TABLE [backup_clocking_check_in_out_2025_02_07] (
  [Id] int NOT NULL,
  [CheckInDate] datetime2 NULL,
  [CheckOutDate] datetime2 NULL,
  [TenantId] bigint NULL,
  [EmployeeId] bigint NULL,
  [ClockingId] bigint NULL
);

-- Table: sysdiagrams
CREATE TABLE [sysdiagrams] (
  [name] nvarchar(128) NOT NULL,
  [principal_id] int NOT NULL,
  [diagram_id] int NOT NULL,
  [version] int NULL,
  [definition] varbinary NULL
);

-- Table: PaysheetDepartment
CREATE TABLE [PaysheetDepartment] (
  [Id] bigint NOT NULL,
  [TenantId] int NOT NULL,
  [PaysheetId] bigint NOT NULL,
  [DepartmentId] bigint NOT NULL
);

-- Table: __EFMigrationsHistory
CREATE TABLE [__EFMigrationsHistory] (
  [MigrationId] nvarchar(150) NOT NULL,
  [ProductVersion] nvarchar(32) NOT NULL
);

-- Table: KvBranch
CREATE TABLE [KvBranch] (
  [AppId] int NOT NULL,
  [TenantId] int NOT NULL,
  [BranchId] int NOT NULL,
  [Name] nvarchar(4000) NULL,
  [BaseUtcOffsetMinute] int NULL,
  [IsActive] bit NOT NULL,
  [IsDeleted] bit NOT NULL,
  [ModifiedDate] datetime2 NULL,
  [CreatedDate] datetime2 NOT NULL,
  [TimeZoneId] nvarchar(500) NULL
);

-- Table: Allowance
CREATE TABLE [Allowance] (
  [Id] bigint NOT NULL,
  [Name] nvarchar(100) NOT NULL,
  [CreatedBy] bigint NOT NULL,
  [CreatedDate] datetime2 NOT NULL,
  [ModifiedBy] bigint NULL,
  [ModifiedDate] datetime2 NULL,
  [TenantId] int NOT NULL,
  [Code] nvarchar(450) NULL,
  [IsDeleted] bit NOT NULL,
  [DeletedDate] datetime2 NULL,
  [DeletedBy] bigint NULL,
  [Value] float NOT NULL,
  [ValueRatio] float NOT NULL,
  [Type] int NULL,
  [IsChecked] bit NOT NULL,
  [Rank] float NOT NULL,
  [test] float NOT NULL
);

-- Table: AuditProcessFailEvent
CREATE TABLE [AuditProcessFailEvent] (
  [Id] bigint NOT NULL,
  [EventId] uniqueidentifier NOT NULL,
  [EventData] ntext NOT NULL,
  [EventType] nvarchar(500) NOT NULL,
  [ErrorMessage] ntext NOT NULL,
  [State] int NOT NULL,
  [RetryTimes] int NOT NULL,
  [ProcessedTime] datetime2 NULL,
  [CreatedTime] datetime2 NOT NULL
);

-- Table: Test
CREATE TABLE [Test] (
  [Id] bigint NOT NULL,
  [test01] nchar(10) NULL,
  [test02] nchar(10) NULL
);

-- Table: backup_employee_branch_fromUser
CREATE TABLE [backup_employee_branch_fromUser] (
  [BranchId] int NOT NULL,
  [TenantId] int NOT NULL,
  [EmployeeId] bigint NOT NULL
);

-- Table: backup_employee_fromUser
CREATE TABLE [backup_employee_fromUser] (
  [EmployeeId] bigint NOT NULL,
  [Code] bigint NOT NULL,
  [Name] nvarchar(50) NOT NULL,
  [DOB] date NULL,
  [TenantId] int NOT NULL,
  [BranchId] int NOT NULL,
  [isDeleted] bit NULL,
  [MobilePhone] nvarchar(50) NULL,
  [Email] nvarchar(255) NULL,
  [Address] nvarchar(255) NULL,
  [LocationName] nvarchar(100) NULL,
  [WardName] nvarchar(100) NULL,
  [Note] nvarchar(-1) NULL,
  [IsActive] bit NOT NULL,
  [CreatedDate] datetime NOT NULL,
  [CreatedBy] bigint NOT NULL,
  [UserId] bigint NOT NULL,
  [IsUpdated] int NOT NULL
);

-- Table: backup_not_update_tenant_from_Holiday
CREATE TABLE [backup_not_update_tenant_from_Holiday] (
  [TenantId] int NOT NULL
);

-- Table: backup_old_TenantNationalHoliday
CREATE TABLE [backup_old_TenantNationalHoliday] (
  [TenantId] int NOT NULL
);

-- Table: backup_Tenants
CREATE TABLE [backup_Tenants] (
  [TenantId] int NOT NULL,
  [IsUpdated] int NOT NULL
);

-- Table: BranchSetting
CREATE TABLE [BranchSetting] (
  [Id] bigint NOT NULL,
  [BranchId] int NOT NULL,
  [WorkingDays] nvarchar(255) NULL,
  [TenantId] int NOT NULL
);

-- Table: ConfirmClocking
CREATE TABLE [ConfirmClocking] (
  [Id] bigint NOT NULL,
  [TenantId] int NOT NULL,
  [GpsInfoId] bigint NULL,
  [EmployeeId] bigint NOT NULL,
  [CheckTimeStart] datetime2 NOT NULL,
  [CheckTimeEnd] datetime2 NULL,
  [Type] tinyint NOT NULL,
  [Status] tinyint NOT NULL,
  [Note] nvarchar(2000) NULL,
  [IdentityKeyClocking] nvarchar(100) NULL,
  [Extra] nvarchar(4000) NULL,
  [CreatedBy] bigint NOT NULL,
  [CreatedDate] datetime2 NOT NULL,
  [ModifiedBy] bigint NULL,
  [ModifiedDate] datetime2 NULL,
  [IsDeleted] bit NOT NULL,
  [DeletedBy] bigint NULL,
  [DeletedDate] datetime2 NULL,
  [ClockingType] tinyint NOT NULL,
  [BranchId] int NOT NULL,
  [CheckTime] datetime2 NULL
);

-- Table: Clocking
CREATE TABLE [Clocking] (
  [Id] bigint NOT NULL,
  [TimeSheetId] bigint NULL,
  [ShiftId] bigint NOT NULL,
  [EmployeeId] bigint NOT NULL,
  [WorkById] bigint NOT NULL,
  [ClockingStatus] tinyint NOT NULL,
  [StartTime] datetime2 NOT NULL,
  [EndTime] datetime2 NOT NULL,
  [Note] nvarchar(500) NULL,
  [TenantId] int NOT NULL,
  [BranchId] int NOT NULL,
  [CreatedBy] bigint NOT NULL,
  [CreatedDate] datetime2 NOT NULL,
  [ModifiedBy] bigint NULL,
  [ModifiedDate] datetime2 NULL,
  [IsDeleted] bit NOT NULL,
  [DeletedBy] bigint NULL,
  [DeletedDate] datetime2 NULL,
  [CheckInDate] datetime2 NULL,
  [CheckOutDate] datetime2 NULL,
  [TimeIsLate] int NOT NULL,
  [OverTimeBeforeShiftWork] int NOT NULL,
  [TimeIsLeaveWorkEarly] int NOT NULL,
  [OverTimeAfterShiftWork] int NOT NULL,
  [AbsenceType] tinyint NULL,
  [ClockingPaymentStatus] tinyint NOT NULL
);

-- Table: ClockingHistory
CREATE TABLE [ClockingHistory] (
  [Id] bigint NOT NULL,
  [ClockingId] bigint NOT NULL,
  [CheckedInDate] datetime2 NULL,
  [CheckedOutDate] datetime2 NULL,
  [TimeIsLate] int NOT NULL,
  [OverTimeBeforeShiftWork] int NOT NULL,
  [TimeIsLeaveWorkEarly] int NOT NULL,
  [OverTimeAfterShiftWork] int NOT NULL,
  [TenantId] int NOT NULL,
  [BranchId] int NOT NULL,
  [TimeKeepingType] tinyint NOT NULL,
  [ClockingStatus] tinyint NOT NULL,
  [ModifiedBy] bigint NULL,
  [ModifiedDate] datetime2 NULL,
  [CreatedBy] bigint NOT NULL,
  [CreatedDate] datetime2 NOT NULL,
  [ClockingHistoryStatus] tinyint NOT NULL,
  [TimeIsLateAdjustment] int NOT NULL,
  [OverTimeBeforeShiftWorkAdjustment] int NOT NULL,
  [TimeIsLeaveWorkEarlyAdjustment] int NOT NULL,
  [OverTimeAfterShiftWorkAdjustment] int NOT NULL,
  [AbsenceType] tinyint NULL,
  [ShiftId] bigint NULL,
  [ShiftFrom] bigint NULL,
  [ShiftTo] bigint NULL,
  [EmployeeId] bigint NULL,
  [CheckTime] datetime2 NULL,
  [AutoTimekeepingUid] nvarchar(255) NULL
);

-- Table: ClockingPenalize
CREATE TABLE [ClockingPenalize] (
  [Id] bigint NOT NULL,
  [ClockingId] bigint NOT NULL,
  [EmployeeId] bigint NOT NULL,
  [PenalizeId] bigint NOT NULL,
  [Value] decimal(18, 2) NOT NULL,
  [TimesCount] int NOT NULL,
  [CreatedBy] bigint NOT NULL,
  [CreatedDate] datetime2 NOT NULL,
  [ModifiedBy] bigint NULL,
  [ModifiedDate] datetime2 NULL,
  [TenantId] int NOT NULL,
  [IsDeleted] bit NOT NULL,
  [DeletedDate] datetime2 NULL,
  [DeletedBy] bigint NULL,
  [MoneyType] int NOT NULL,
  [ClockingPaymentStatus] tinyint NOT NULL
);

-- Table: Commission
CREATE TABLE [Commission] (
  [Id] bigint NOT NULL,
  [Name] nvarchar(255) NOT NULL,
  [IsActive] bit NOT NULL,
  [TenantId] int NOT NULL,
  [CreatedBy] bigint NOT NULL,
  [CreatedDate] datetime2 NOT NULL,
  [ModifiedBy] bigint NULL,
  [ModifiedDate] datetime2 NULL,
  [IsDeleted] bit NOT NULL,
  [DeletedBy] bigint NULL,
  [DeletedDate] datetime2 NULL,
  [IsAllBranch] bit NOT NULL,
  [IsDefault] bit NOT NULL
);

-- Table: CommissionBranch
CREATE TABLE [CommissionBranch] (
  [Id] bigint NOT NULL,
  [TenantId] int NOT NULL,
  [BranchId] int NOT NULL,
  [CommissionId] bigint NOT NULL
);

-- Table: backup_Payslip_2024_07_01
CREATE TABLE [backup_Payslip_2024_07_01] (
  [Id] bigint NOT NULL,
  [TenantId] int NOT NULL,
  [OldTotalPayment] money NOT NULL,
  [NewTotalPayment] int NOT NULL
);

-- Table: CommissionDetail
CREATE TABLE [CommissionDetail] (
  [Id] bigint NOT NULL,
  [CommissionId] bigint NOT NULL,
  [Value] decimal(18, 2) NULL,
  [ValueRatio] decimal(18, 2) NULL,
  [TenantId] int NOT NULL,
  [CreatedBy] bigint NOT NULL,
  [CreatedDate] datetime2 NOT NULL,
  [ModifiedBy] bigint NULL,
  [ModifiedDate] datetime2 NULL,
  [DeletedBy] bigint NULL,
  [DeletedDate] datetime2 NULL,
  [IsDeleted] bit NOT NULL,
  [Type] tinyint NOT NULL,
  [ObjectId] bigint NOT NULL,
  [ProductId] bigint NULL
);

-- Table: TrailDataCollection
CREATE TABLE [TrailDataCollection] (
  [Id] int NOT NULL,
  [EmployeeNumber] int NULL,
  [CreatedDate] datetime NULL,
  [CreatedBy] int NULL,
  [RetailerId] int NOT NULL
);

-- Table: OperationEventTest
CREATE TABLE [OperationEventTest] (
  [EventId] uniqueidentifier NOT NULL,
  [TenantId] int NOT NULL,
  [EventType] nvarchar(500) NOT NULL,
  [CreatedTime] datetime2 NOT NULL,
  [Data] nvarchar(-1) NULL
);

-- Table: ConfirmClockingHistory
CREATE TABLE [ConfirmClockingHistory] (
  [Id] bigint NOT NULL,
  [TenantId] int NOT NULL,
  [ConfirmClockingId] bigint NOT NULL,
  [ConfirmBy] bigint NOT NULL,
  [ConfirmDate] datetime2 NOT NULL,
  [StatusOld] tinyint NOT NULL,
  [StatusNew] tinyint NOT NULL,
  [Note] nvarchar(2000) NULL,
  [CreatedBy] bigint NOT NULL,
  [CreatedDate] datetime2 NOT NULL,
  [ModifiedBy] bigint NULL,
  [ModifiedDate] datetime2 NULL,
  [IsDeleted] bit NOT NULL,
  [DeletedBy] bigint NULL,
  [DeletedDate] datetime2 NULL
);

-- Table: OperationEventData
CREATE TABLE [OperationEventData] (
  [EventId] uniqueidentifier NOT NULL,
  [Data] nvarchar(-1) NOT NULL
);

-- Table: TrialData
CREATE TABLE [TrialData] (
  [Id] int NOT NULL,
  [ContactName] nvarchar(255) NULL,
  [ContactPhone] varchar(50) NULL,
  [EmployeeNumber] int NULL,
  [StartTrialDate] datetime NULL,
  [ExpiredDate] datetime NULL,
  [CreatedDate] datetime NULL,
  [CreatedBy] int NULL,
  [RetailerId] int NOT NULL
);

-- Table: CronSchedule
CREATE TABLE [CronSchedule] (
  [Id] bigint NOT NULL,
  [Type] int NOT NULL,
  [Title] nvarchar(250) NULL,
  [TenantCode] varchar(100) NULL,
  [TenantId] int NOT NULL,
  [BranchId] int NULL,
  [Params] nvarchar(2000) NULL,
  [LastSync] datetime NOT NULL,
  [NextRun] datetime NOT NULL,
  [LimitRun] datetime NULL,
  [CreatedDate] datetime NOT NULL,
  [ModifiedDate] datetime NULL,
  [CreatedBy] int NOT NULL,
  [IsActive] bit NOT NULL,
  [Duration] int NOT NULL,
  [IsRunning] bit NOT NULL,
  [Processed] int NOT NULL
);

-- Table: Deduction
CREATE TABLE [Deduction] (
  [Id] bigint NOT NULL,
  [Name] nvarchar(100) NOT NULL,
  [CreatedBy] bigint NOT NULL,
  [CreatedDate] datetime2 NOT NULL,
  [ModifiedBy] bigint NULL,
  [ModifiedDate] datetime2 NULL,
  [TenantId] int NOT NULL,
  [Code] nvarchar(450) NULL,
  [IsDeleted] bit NOT NULL,
  [DeletedDate] datetime2 NULL,
  [DeletedBy] bigint NULL,
  [Value] decimal(18, 2) NULL,
  [ValueRatio] float NULL,
  [ValueType] int NULL,
  [DeductionRuleId] int NOT NULL,
  [DeductionTypeId] int NOT NULL,
  [BlockTypeTimeValue] int NOT NULL,
  [BlockTypeMinuteValue] int NOT NULL
);

-- Table: OperationEvent
CREATE TABLE [OperationEvent] (
  [EventId] uniqueidentifier NOT NULL,
  [TenantId] int NOT NULL,
  [EventType] nvarchar(500) NOT NULL,
  [Data] nvarchar(-1) NOT NULL,
  [CreatedTime] datetime2 NOT NULL,
  [Id] bigint NOT NULL
);

-- Table: backup_employee_2025_04_14
CREATE TABLE [backup_employee_2025_04_14] (
  [TenantId] bigint NULL,
  [EmployeeId] bigint NULL,
  [OldCode] nvarchar(100) NULL,
  [OldName] nvarchar(255) NULL,
  [NewCode] nvarchar(100) NULL,
  [NewName] nvarchar(255) NULL,
  [IsDeleted] bit NULL
);

-- Table: Department
CREATE TABLE [Department] (
  [Id] bigint NOT NULL,
  [Name] nvarchar(50) NOT NULL,
  [Description] nvarchar(500) NULL,
  [IsActive] bit NOT NULL,
  [TenantId] int NOT NULL,
  [CreatedBy] bigint NOT NULL,
  [CreatedDate] datetime2 NOT NULL,
  [ModifiedBy] bigint NULL,
  [ModifiedDate] datetime2 NULL,
  [IsDeleted] bit NOT NULL,
  [DeletedBy] bigint NULL,
  [DeletedDate] datetime2 NULL
);

-- Table: backup_timesheet_2025_04_14
CREATE TABLE [backup_timesheet_2025_04_14] (
  [TenantId] bigint NULL,
  [EmployeeId] bigint NULL,
  [TimeSheetId] bigint NULL,
  [OldTimeSheetStatus] int NULL,
  [NewTimeSheetStatus] int NULL
);

-- Table: backup_Payslip_2024_07_22
CREATE TABLE [backup_Payslip_2024_07_22] (
  [Id] bigint NOT NULL,
  [TenantId] int NOT NULL,
  [OldTotalPayment] money NOT NULL,
  [NewTotalPayment] int NOT NULL
);

-- Table: backup_clocking_2025_04_14
CREATE TABLE [backup_clocking_2025_04_14] (
  [TenantId] bigint NULL,
  [EmployeeId] bigint NULL,
  [ClockingId] bigint NULL,
  [OldIsDeleted] bit NULL,
  [NewIsDeleted] bit NULL
);

-- Table: Employee
CREATE TABLE [Employee] (
  [Id] bigint NOT NULL,
  [Code] nvarchar(255) NOT NULL,
  [NickName] nvarchar(255) NULL,
  [Name] nvarchar(255) NOT NULL,
  [DOB] datetime2 NULL,
  [Gender] bit NULL,
  [IsActive] bit NOT NULL,
  [IdentityNumber] nvarchar(255) NULL,
  [MobilePhone] nvarchar(255) NULL,
  [Email] nvarchar(255) NULL,
  [Facebook] nvarchar(255) NULL,
  [Address] nvarchar(255) NULL,
  [LocationName] nvarchar(255) NULL,
  [WardName] nvarchar(255) NULL,
  [Note] nvarchar(500) NULL,
  [UserId] bigint NULL,
  [DepartmentId] bigint NULL,
  [JobTitleId] bigint NULL,
  [IdentityKeyClocking] nvarchar(100) NULL,
  [AccountSecretKey] nvarchar(100) NULL,
  [TenantId] int NOT NULL,
  [BranchId] int NOT NULL,
  [CreatedBy] bigint NOT NULL,
  [CreatedDate] datetime2 NOT NULL,
  [ModifiedBy] bigint NULL,
  [ModifiedDate] datetime2 NULL,
  [IsDeleted] bit NOT NULL,
  [DeletedBy] bigint NULL,
  [DeletedDate] datetime2 NULL,
  [SecretKeyTakenUserId] bigint NULL,
  [StandardizedMobilePhone] nvarchar(255) NULL,
  [StartWorkingDate] datetime2 NULL,
  [ModelDeviceClocking] nvarchar(100) NULL,
  [IsRecoverable] bit NOT NULL,
  [ReturnToWorkDate] datetime2 NULL
);

-- Table: employee_existed_fromUser
CREATE TABLE [employee_existed_fromUser] (
  [Id] bigint NOT NULL
);

-- Table: EmployeeBranch
CREATE TABLE [EmployeeBranch] (
  [Id] bigint NOT NULL,
  [TenantId] int NOT NULL,
  [BranchId] int NOT NULL,
  [EmployeeId] bigint NOT NULL
);

-- Table: ImportExportFile
CREATE TABLE [ImportExportFile] (
  [Id] bigint NOT NULL,
  [RetailerId] int NOT NULL,
  [KvSessionId] nvarchar(255) NOT NULL,
  [IsImport] bit NULL,
  [FileName] nvarchar(255) NOT NULL,
  [FilePath] nvarchar(255) NULL,
  [EventType] nvarchar(50) NULL,
  [Status] tinyint NOT NULL,
  [Message] nvarchar(-1) NULL,
  [Revision] timestamp NOT NULL,
  [CreatedBy] bigint NOT NULL,
  [ModifiedBy] bigint NULL,
  [CreatedDate] datetime NOT NULL,
  [ModifiedDate] datetime NULL
);

-- Table: EmployeeProfilePicture
CREATE TABLE [EmployeeProfilePicture] (
  [Id] bigint NOT NULL,
  [ImageUrl] nvarchar(4000) NOT NULL,
  [IsMainImage] bit NOT NULL,
  [EmployeeId] bigint NOT NULL,
  [TenantId] int NOT NULL
);

-- Table: backup_employee_2024_08_15
CREATE TABLE [backup_employee_2024_08_15] (
  [Id] int NOT NULL,
  [TenantId] bigint NULL,
  [EmployeeId] bigint NULL,
  [OldCode] varchar(50) NULL,
  [OldName] nvarchar(255) NULL,
  [NewCode] varchar(50) NULL,
  [NewName] nvarchar(255) NULL,
  [IsDeleted] bit NULL
);

-- Table: backup_timesheet_2024_08_15
CREATE TABLE [backup_timesheet_2024_08_15] (
  [Id] int NOT NULL,
  [TenantId] bigint NULL,
  [EmployeeId] bigint NULL,
  [TimeSheetId] bigint NULL,
  [OldTimeSheetStatus] tinyint NULL,
  [NewTimeSheetStatus] tinyint NULL
);

-- Table: FingerMachine
CREATE TABLE [FingerMachine] (
  [Id] bigint NOT NULL,
  [TenantId] int NOT NULL,
  [BranchId] int NOT NULL,
  [MachineName] nvarchar(50) NOT NULL,
  [MachineId] nvarchar(255) NOT NULL,
  [Vendor] nvarchar(255) NOT NULL,
  [Status] int NOT NULL,
  [CreatedDate] datetime2 NOT NULL,
  [CreatedBy] bigint NOT NULL,
  [ModifiedDate] datetime2 NULL,
  [ModifiedBy] bigint NULL,
  [Note] nvarchar(255) NULL,
  [IpAddress] varchar(100) NULL,
  [Commpass] int NULL,
  [Port] int NULL,
  [ConnectionType] int NULL
);

-- Table: backup_clocking_2024_08_15
CREATE TABLE [backup_clocking_2024_08_15] (
  [Id] int NOT NULL,
  [TenantId] bigint NULL,
  [EmployeeId] bigint NULL,
  [ClockingId] bigint NULL,
  [OldIsDeleted] bit NULL,
  [NewIsDeleted] bit NULL
);

-- Table: FingerPrint
CREATE TABLE [FingerPrint] (
  [Id] bigint NOT NULL,
  [TenantId] int NOT NULL,
  [BranchId] int NOT NULL,
  [FingerCode] nvarchar(255) NOT NULL,
  [EmployeeId] bigint NOT NULL,
  [FingerName] nvarchar(255) NULL,
  [FingerNo] int NOT NULL,
  [CreatedDate] datetime2 NOT NULL,
  [CreatedBy] bigint NOT NULL,
  [ModifiedDate] datetime2 NULL,
  [ModifiedBy] bigint NULL
);

-- Table: PreloadedProductRevenue
CREATE TABLE [PreloadedProductRevenue] (
  [Id] int NOT NULL,
  [AppId] int NOT NULL,
  [TenantId] int NOT NULL,
  [EmployeeId] bigint NOT NULL,
  [BillCode] nvarchar(100) NULL,
  [ProductId] bigint NOT NULL,
  [UserId] int NULL,
  [BranchId] int NOT NULL,
  [MasterId] int NULL,
  [CategoryIds] nvarchar(4000) NULL,
  [TotalCommission] decimal(18, 2) NOT NULL,
  [Quantity] float NOT NULL,
  [ReturnCode] nvarchar(100) NULL,
  [DateOfPayment] datetime2 NOT NULL,
  [TotalEmployee] int NOT NULL,
  [CommissionRatio] float NOT NULL,
  [CommissionValue] decimal(18, 2) NOT NULL,
  [CommissionType] int NOT NULL,
  [CustomerId] bigint NULL,
  [UniqueId] nvarchar(100) NOT NULL,
  [IsByCounselor] bit NOT NULL,
  [CommissionSetting] int NULL,
  [RevenueTypeSetting] int NULL,
  [DiscountSetting] int NULL,
  [DiscountSettingCounselor] int NULL,
  [LastSyncedTotal] int NOT NULL,
  [LastSyncedTransactionTotal] int NOT NULL,
  [LastSyncedTransactionId] uniqueidentifier NOT NULL,
  [FirstSyncedTime] datetime2 NOT NULL,
  [LastSyncedTime] datetime2 NOT NULL,
  [Uid] nvarchar(267) NULL,
  [Hash] bigint NOT NULL
);

-- Table: GpsInfo
CREATE TABLE [GpsInfo] (
  [Id] bigint NOT NULL,
  [TenantId] int NOT NULL,
  [BranchId] int NOT NULL,
  [Coordinate] nvarchar(2000) NULL,
  [Address] nvarchar(100) NULL,
  [LocationName] nvarchar(100) NULL,
  [WardName] nvarchar(100) NULL,
  [Province] nvarchar(100) NULL,
  [District] nvarchar(100) NULL,
  [Status] tinyint NOT NULL,
  [QrKey] nvarchar(100) NOT NULL,
  [RadiusLimit] int NOT NULL,
  [CreatedBy] bigint NOT NULL,
  [CreatedDate] datetime2 NOT NULL,
  [ModifiedBy] bigint NULL,
  [ModifiedDate] datetime2 NULL,
  [IsDeleted] bit NOT NULL,
  [DeletedBy] bigint NULL,
  [DeletedDate] datetime2 NULL
);

-- Table: Holiday
CREATE TABLE [Holiday] (
  [Id] bigint NOT NULL,
  [Name] nvarchar(255) NOT NULL,
  [From] datetime2 NOT NULL,
  [To] datetime2 NOT NULL,
  [TenantId] int NOT NULL,
  [CreatedBy] bigint NOT NULL,
  [CreatedDate] datetime2 NOT NULL,
  [ModifiedBy] bigint NULL,
  [ModifiedDate] datetime2 NULL,
  [IsDeleted] bit NOT NULL,
  [DeletedDate] datetime2 NULL,
  [DeletedBy] bigint NULL,
  [Bonus] decimal(18, 2) NULL,
  [IsBonusApplied] bit NOT NULL
);

-- Table: IntegrationEventLogEntry
CREATE TABLE [IntegrationEventLogEntry] (
  [EventId] uniqueidentifier NOT NULL,
  [TransactionId] uniqueidentifier NOT NULL,
  [EventType] nvarchar(-1) NOT NULL,
  [Data] nvarchar(-1) NOT NULL,
  [CreatedTime] datetime2 NOT NULL,
  [State] int NOT NULL,
  [ProcessedTime] datetime2 NULL,
  [TimeSent] int NOT NULL
);

-- Table: JobTitle
CREATE TABLE [JobTitle] (
  [Id] bigint NOT NULL,
  [Name] nvarchar(50) NOT NULL,
  [Description] nvarchar(500) NULL,
  [IsActive] bit NOT NULL,
  [TenantId] int NOT NULL,
  [CreatedBy] bigint NOT NULL,
  [CreatedDate] datetime2 NOT NULL,
  [ModifiedBy] bigint NULL,
  [ModifiedDate] datetime2 NULL,
  [IsDeleted] bit NOT NULL,
  [DeletedBy] bigint NULL,
  [DeletedDate] datetime2 NULL
);

-- Table: NationalHoliday
CREATE TABLE [NationalHoliday] (
  [Id] int NOT NULL,
  [Name] nvarchar(250) NOT NULL,
  [StartDay] tinyint NOT NULL,
  [EndDay] tinyint NOT NULL,
  [StartMonth] tinyint NOT NULL,
  [EndMonth] tinyint NOT NULL,
  [IsLunarCalendar] bit NOT NULL
);

-- Table: PayRate
CREATE TABLE [PayRate] (
  [Id] bigint NOT NULL,
  [EmployeeId] bigint NOT NULL,
  [PayRateTemplateId] bigint NULL,
  [TenantId] int NOT NULL,
  [CreatedDate] datetime2 NOT NULL,
  [CreatedBy] bigint NOT NULL,
  [ModifiedBy] bigint NULL,
  [ModifiedDate] datetime2 NULL,
  [SalaryPeriod] tinyint NOT NULL,
  [ApplyDate] datetime2 NULL,
  [IsDeleted] bit NOT NULL,
  [DeletedDate] datetime2 NULL,
  [DeletedBy] bigint NULL
);

-- Table: OnboardingExperience
CREATE TABLE [OnboardingExperience] (
  [TenantId] int NOT NULL,
  [LastShownAt] datetime2 NULL,
  [ShownCountInMonth] int NULL,
  [CreatedDate] datetime2 NOT NULL,
  [ModifiedDate] datetime2 NULL,
  [DeletedBy] bigint NULL,
  [DeletedDate] datetime2 NULL,
  [IsDeleted] bit NOT NULL
);

-- Table: PayRateDetail
CREATE TABLE [PayRateDetail] (
  [Id] bigint NOT NULL,
  [PayRateId] bigint NOT NULL,
  [RuleType] nvarchar(255) NOT NULL,
  [RuleValue] nvarchar(-1) NULL,
  [TenantId] int NOT NULL
);

-- Table: PayRateTemplate
CREATE TABLE [PayRateTemplate] (
  [Id] bigint NOT NULL,
  [TenantId] int NOT NULL,
  [Name] nvarchar(250) NOT NULL,
  [SalaryPeriod] tinyint NOT NULL,
  [BranchId] int NOT NULL,
  [CreatedDate] datetime2 NOT NULL,
  [CreatedBy] bigint NOT NULL,
  [ModifiedBy] bigint NULL,
  [ModifiedDate] datetime2 NULL,
  [Status] int NOT NULL
);

-- Table: backup_employee_2024_08_28
CREATE TABLE [backup_employee_2024_08_28] (
  [Id] int NOT NULL,
  [TenantId] bigint NULL,
  [EmployeeId] bigint NULL,
  [OldCode] varchar(50) NULL,
  [OldName] nvarchar(255) NULL,
  [NewCode] varchar(50) NULL,
  [NewName] nvarchar(255) NULL,
  [IsDeleted] bit NULL
);

-- Table: backup_timesheet_2024_08_28
CREATE TABLE [backup_timesheet_2024_08_28] (
  [Id] int NOT NULL,
  [TenantId] bigint NULL,
  [EmployeeId] bigint NULL,
  [TimeSheetId] bigint NULL,
  [OldTimeSheetStatus] tinyint NULL,
  [NewTimeSheetStatus] tinyint NULL
);

-- Table: PayRateTemplateDetail
CREATE TABLE [PayRateTemplateDetail] (
  [Id] bigint NOT NULL,
  [TenantId] int NOT NULL,
  [PayRateTemplateId] bigint NOT NULL,
  [RuleType] nvarchar(255) NOT NULL,
  [RuleValue] ntext NOT NULL,
  [CreatedBy] bigint NOT NULL,
  [CreatedDate] datetime2 NOT NULL,
  [ModifiedBy] bigint NULL,
  [ModifiedDate] datetime2 NULL
);

-- Table: backup_clocking_2024_08_28
CREATE TABLE [backup_clocking_2024_08_28] (
  [Id] int NOT NULL,
  [TenantId] bigint NULL,
  [EmployeeId] bigint NULL,
  [ClockingId] bigint NULL,
  [OldIsDeleted] bit NULL,
  [NewIsDeleted] bit NULL
);

-- Table: Paysheet
CREATE TABLE [Paysheet] (
  [Id] bigint NOT NULL,
  [Code] nvarchar(255) NOT NULL,
  [TenantId] int NOT NULL,
  [BranchId] int NOT NULL,
  [IsDeleted] bit NOT NULL,
  [DeletedBy] bigint NULL,
  [DeletedDate] datetime2 NULL,
  [CreatedBy] bigint NOT NULL,
  [CreatedDate] datetime2 NOT NULL,
  [Name] nvarchar(-1) NULL,
  [SalaryPeriod] tinyint NOT NULL,
  [StartTime] datetime2 NOT NULL,
  [EndTime] datetime2 NOT NULL,
  [PaysheetStatus] tinyint NOT NULL,
  [Note] nvarchar(2000) NULL,
  [WorkingDayNumber] float NOT NULL,
  [ModifiedBy] bigint NULL,
  [ModifiedDate] datetime2 NULL,
  [PaysheetPeriodName] nvarchar(255) NOT NULL,
  [CreatorBy] bigint NOT NULL,
  [PaysheetCreatedDate] datetime2 NULL,
  [Version] bigint NOT NULL,
  [IsDraft] bit NOT NULL,
  [TimeOfStandardWorkingDay] float NULL,
  [ErrorStatus] int NULL,
  [PreviousWorkingDayNumber] float NULL,
  [RevisionStatus] tinyint NOT NULL,
  [PaysheetOption] tinyint NULL,
  [ApprovedBy] bigint NULL,
  [ApprovedDate] datetime2 NULL
);

-- Table: backup_employee_2025_05_30
CREATE TABLE [backup_employee_2025_05_30] (
  [TenantId] bigint NULL,
  [EmployeeId] bigint NULL,
  [OldCode] nvarchar(50) NULL,
  [OldName] nvarchar(255) NULL,
  [NewCode] nvarchar(50) NULL,
  [NewName] nvarchar(255) NULL,
  [IsDeleted] bit NULL
);

-- Table: backup_Payslip_2024_08_29
CREATE TABLE [backup_Payslip_2024_08_29] (
  [Id] bigint NOT NULL,
  [TenantId] int NOT NULL,
  [OldTotalPayment] money NOT NULL,
  [NewTotalPayment] money NULL
);

-- Table: backup_timesheet_2025_05_30
CREATE TABLE [backup_timesheet_2025_05_30] (
  [TenantId] bigint NULL,
  [EmployeeId] bigint NULL,
  [TimeSheetId] bigint NULL,
  [OldTimeSheetStatus] int NULL,
  [NewTimeSheetStatus] int NULL
);

-- Table: Payslip
CREATE TABLE [Payslip] (
  [Id] bigint NOT NULL,
  [Code] nvarchar(255) NOT NULL,
  [PaysheetId] bigint NOT NULL,
  [TenantId] int NOT NULL,
  [IsDeleted] bit NOT NULL,
  [DeletedBy] bigint NULL,
  [DeletedDate] datetime2 NULL,
  [Note] nvarchar(2000) NULL,
  [PayslipStatus] tinyint NOT NULL,
  [EmployeeId] bigint NOT NULL,
  [CreatedDate] datetime2 NOT NULL,
  [CreatedBy] bigint NOT NULL,
  [ModifiedBy] bigint NULL,
  [ModifiedDate] datetime2 NULL,
  [MainSalary] money NOT NULL,
  [CommissionSalary] money NOT NULL,
  [OvertimeSalary] money NOT NULL,
  [Allowance] money NOT NULL,
  [Deduction] money NOT NULL,
  [Bonus] money NOT NULL,
  [NetSalary] money NOT NULL,
  [GrossSalary] money NOT NULL,
  [TotalPayment] money NOT NULL,
  [IsDraft] bit NOT NULL,
  [PayslipCreatedDate] datetime2 NULL,
  [PayslipCreatedBy] bigint NULL
);

-- Table: backup_clocking_2025_05_30
CREATE TABLE [backup_clocking_2025_05_30] (
  [TenantId] bigint NULL,
  [EmployeeId] bigint NULL,
  [ClockingId] bigint NULL,
  [OldIsDeleted] bit NULL,
  [NewIsDeleted] bit NULL
);

-- Table: backup_timesheet_2024_09_01
CREATE TABLE [backup_timesheet_2024_09_01] (
  [Id] int NOT NULL,
  [TenantId] bigint NULL,
  [EmployeeId] bigint NULL,
  [TimeSheetId] bigint NULL,
  [OldTimeSheetStatus] tinyint NULL,
  [NewTimeSheetStatus] tinyint NULL
);

-- Table: backup_clocking_2024_09_01
CREATE TABLE [backup_clocking_2024_09_01] (
  [Id] int NOT NULL,
  [TenantId] bigint NULL,
  [EmployeeId] bigint NULL,
  [ClockingId] bigint NULL,
  [OldIsDeleted] bit NULL,
  [NewIsDeleted] bit NULL,
  [DeletedDate] date NULL
);

-- Table: PayslipClocking
CREATE TABLE [PayslipClocking] (
  [Id] bigint NOT NULL,
  [PayslipId] bigint NOT NULL,
  [ClockingId] bigint NOT NULL,
  [CheckInDate] datetime2 NULL,
  [CheckOutDate] datetime2 NULL,
  [TimeIsLate] int NOT NULL,
  [OverTimeBeforeShiftWork] int NOT NULL,
  [TimeIsLeaveWorkEarly] int NOT NULL,
  [OverTimeAfterShiftWork] int NOT NULL,
  [AbsenceType] tinyint NULL,
  [ClockingStatus] tinyint NOT NULL,
  [StartTime] datetime2 NOT NULL,
  [EndTime] datetime2 NOT NULL,
  [ShiftId] bigint NOT NULL
);

-- Table: PayslipClockingPenalize
CREATE TABLE [PayslipClockingPenalize] (
  [Id] bigint NOT NULL,
  [PayslipId] bigint NOT NULL,
  [ClockingId] bigint NOT NULL,
  [PenalizeId] bigint NOT NULL,
  [PenalizeName] nvarchar(255) NULL,
  [Value] decimal(18, 2) NOT NULL,
  [TimesCount] int NOT NULL,
  [MoneyType] int NOT NULL,
  [ClockingPenalizeCreated] datetime2 NOT NULL,
  [CreatedBy] bigint NOT NULL,
  [CreatedDate] datetime2 NOT NULL,
  [ModifiedBy] bigint NULL,
  [ModifiedDate] datetime2 NULL,
  [IsDeleted] bit NOT NULL,
  [DeletedDate] datetime2 NULL,
  [DeletedBy] bigint NULL,
  [ShiftId] bigint NULL
);

-- Table: PayslipDetail
CREATE TABLE [PayslipDetail] (
  [Id] bigint NOT NULL,
  [PayslipId] bigint NOT NULL,
  [RuleType] nvarchar(255) NOT NULL,
  [RuleValue] ntext NOT NULL,
  [RuleParam] ntext NOT NULL,
  [TenantId] int NOT NULL
);

-- Table: PayslipPenalize
CREATE TABLE [PayslipPenalize] (
  [Id] bigint NOT NULL,
  [PayslipId] bigint NOT NULL,
  [PenalizeId] bigint NOT NULL,
  [PenalizeName] nvarchar(255) NULL,
  [Value] decimal(18, 2) NOT NULL,
  [TimesCount] int NOT NULL,
  [MoneyType] int NOT NULL,
  [CreatedBy] bigint NOT NULL,
  [CreatedDate] datetime2 NOT NULL,
  [ModifiedBy] bigint NULL,
  [ModifiedDate] datetime2 NULL,
  [IsDeleted] bit NOT NULL,
  [DeletedDate] datetime2 NULL,
  [DeletedBy] bigint NULL,
  [IsActive] bit NOT NULL
);

-- Table: backup_Settings_2010
CREATE TABLE [backup_Settings_2010] (
  [Id] bigint NOT NULL,
  [TenantId] int NOT NULL,
  [Name] nvarchar(250) NULL,
  [OldValue] nvarchar(500) NULL,
  [NewValue] nvarchar(500) NULL,
  [IsActive] bit NOT NULL,
  [CreatedDate] datetime2 NOT NULL
);

-- Table: Penalize
CREATE TABLE [Penalize] (
  [Id] bigint NOT NULL,
  [Code] nvarchar(450) NULL,
  [Name] nvarchar(255) NOT NULL,
  [Value] decimal(18, 2) NOT NULL,
  [CreatedBy] bigint NOT NULL,
  [CreatedDate] datetime2 NOT NULL,
  [ModifiedBy] bigint NULL,
  [ModifiedDate] datetime2 NULL,
  [TenantId] int NOT NULL,
  [IsDeleted] bit NOT NULL,
  [DeletedDate] datetime2 NULL,
  [DeletedBy] bigint NULL,
  [Type] tinyint NOT NULL
);

-- Table: Settings
CREATE TABLE [Settings] (
  [Id] bigint NOT NULL,
  [TenantId] int NOT NULL,
  [Name] nvarchar(250) NULL,
  [Value] nvarchar(500) NULL,
  [IsActive] bit NOT NULL,
  [CreatedDate] datetime2 NOT NULL
);

-- Table: backup_employee_2024_09_26
CREATE TABLE [backup_employee_2024_09_26] (
  [Id] int NOT NULL,
  [TenantId] bigint NULL,
  [EmployeeId] bigint NULL,
  [OldCode] varchar(50) NULL,
  [OldName] nvarchar(255) NULL,
  [NewCode] varchar(50) NULL,
  [NewName] nvarchar(255) NULL,
  [IsDeleted] bit NULL
);

-- Table: backup_timesheet_2024_09_26
CREATE TABLE [backup_timesheet_2024_09_26] (
  [Id] int NOT NULL,
  [TenantId] bigint NULL,
  [EmployeeId] bigint NULL,
  [TimeSheetId] bigint NULL,
  [OldTimeSheetStatus] tinyint NULL,
  [NewTimeSheetStatus] tinyint NULL
);

-- Table: Shift
CREATE TABLE [Shift] (
  [Id] bigint NOT NULL,
  [Name] nvarchar(250) NOT NULL,
  [From] bigint NOT NULL,
  [To] bigint NOT NULL,
  [IsActive] bit NOT NULL,
  [IsDeleted] bit NOT NULL,
  [BranchId] int NOT NULL,
  [CheckInBefore] bigint NULL,
  [CheckOutAfter] bigint NULL,
  [TenantId] int NOT NULL,
  [DeletedBy] bigint NULL,
  [DeletedDate] datetime2 NULL,
  [CreatedBy] bigint NOT NULL,
  [CreatedDate] datetime2 NOT NULL,
  [ModifiedBy] bigint NULL,
  [ModifiedDate] datetime2 NULL
);

-- Table: backup_clocking_2024_09_26
CREATE TABLE [backup_clocking_2024_09_26] (
  [Id] int NOT NULL,
  [TenantId] bigint NULL,
  [EmployeeId] bigint NULL,
  [ClockingId] bigint NULL,
  [OldIsDeleted] bit NULL,
  [NewIsDeleted] bit NULL
);

-- Table: TenantNationalHoliday
CREATE TABLE [TenantNationalHoliday] (
  [Id] bigint NOT NULL,
  [TenantId] int NOT NULL,
  [LastCreatedYear] int NOT NULL
);

-- Table: backup_employee_2024_09_17
CREATE TABLE [backup_employee_2024_09_17] (
  [Id] int NOT NULL,
  [TenantId] bigint NULL,
  [EmployeeId] bigint NULL,
  [OldCode] varchar(50) NULL,
  [OldName] nvarchar(255) NULL,
  [NewCode] varchar(50) NULL,
  [NewName] nvarchar(255) NULL,
  [IsDeleted] bit NULL
);

-- Table: backup_timesheet_2024_09_17
CREATE TABLE [backup_timesheet_2024_09_17] (
  [Id] int NOT NULL,
  [TenantId] bigint NULL,
  [EmployeeId] bigint NULL,
  [TimeSheetId] bigint NULL,
  [OldTimeSheetStatus] tinyint NULL,
  [NewTimeSheetStatus] tinyint NULL
);

-- Table: TimeSheet
CREATE TABLE [TimeSheet] (
  [Id] bigint NOT NULL,
  [EmployeeId] bigint NOT NULL,
  [StartDate] datetime2 NOT NULL,
  [EndDate] datetime2 NOT NULL,
  [IsRepeat] bit NULL,
  [RepeatType] tinyint NULL,
  [RepeatEachDay] tinyint NULL,
  [BranchId] int NOT NULL,
  [TenantId] int NOT NULL,
  [CreatedBy] bigint NOT NULL,
  [CreatedDate] datetime2 NOT NULL,
  [ModifiedBy] bigint NULL,
  [ModifiedDate] datetime2 NULL,
  [IsDeleted] bit NOT NULL,
  [DeletedBy] bigint NULL,
  [DeletedDate] datetime2 NULL,
  [TimeSheetStatus] tinyint NOT NULL,
  [SaveOnDaysOffOfBranch] bit NOT NULL,
  [SaveOnHoliday] bit NOT NULL,
  [Note] nvarchar(250) NULL,
  [AutoGenerateClockingStatus] tinyint NOT NULL,
  [IsAppliedForNextWeeks] bit NULL,
  [ParentTimeSheetId] bigint NULL,
  [TimeSheetTrackingType] tinyint NULL
);

-- Table: backup_clocking_2024_09_17
CREATE TABLE [backup_clocking_2024_09_17] (
  [Id] int NOT NULL,
  [TenantId] bigint NULL,
  [EmployeeId] bigint NULL,
  [ClockingId] bigint NULL,
  [OldIsDeleted] bit NULL,
  [NewIsDeleted] bit NULL
);

-- Table: TimeSheetShift
CREATE TABLE [TimeSheetShift] (
  [Id] bigint NOT NULL,
  [TimeSheetId] bigint NOT NULL,
  [ShiftIds] nvarchar(1000) NOT NULL,
  [RepeatDaysOfWeek] nvarchar(500) NULL,
  [DayOfWeek] ntext NOT NULL
);

-- Table: backup_ClockingHistory_20240229
CREATE TABLE [backup_ClockingHistory_20240229] (
  [Id] bigint NOT NULL,
  [ClockingId] bigint NOT NULL,
  [CheckedInDate] datetime2 NOT NULL,
  [CheckedOutDate] datetime2 NOT NULL,
  [TimeIsLate] int NOT NULL,
  [OverTimeBeforeShiftWork] int NOT NULL,
  [TimeIsLeaveWorkEarly] int NOT NULL,
  [OverTimeAfterShiftWork] int NOT NULL,
  [TenantId] int NULL,
  [BranchId] int NOT NULL,
  [TimeKeepingType] int NOT NULL,
  [ClockingStatus] int NOT NULL,
  [ModifiedBy] int NULL,
  [ModifiedDate] int NULL,
  [CreatedBy] int NOT NULL,
  [CreatedDate] datetime NOT NULL,
  [ClockingHistoryStatus] int NOT NULL,
  [TimeIsLateAdjustment] int NOT NULL,
  [OverTimeBeforeShiftWorkAdjustment] int NOT NULL,
  [TimeIsLeaveWorkEarlyAdjustment] int NOT NULL,
  [OverTimeAfterShiftWorkAdjustment] int NOT NULL,
  [AbsenceType] int NULL,
  [ShiftId] bigint NOT NULL,
  [ShiftFrom] bigint NOT NULL,
  [ShiftTo] bigint NOT NULL,
  [EmployeeId] bigint NOT NULL,
  [CheckTime] datetime NOT NULL,
  [AutoTimekeepingUid] int NULL
);

-- Table: backup_ClockingHistory_20240229_1
CREATE TABLE [backup_ClockingHistory_20240229_1] (
  [Id] bigint NOT NULL,
  [ClockingId] bigint NOT NULL,
  [CheckedInDate] datetime2 NOT NULL,
  [CheckedOutDate] datetime2 NOT NULL,
  [TimeIsLate] int NOT NULL,
  [OverTimeBeforeShiftWork] int NOT NULL,
  [TimeIsLeaveWorkEarly] int NOT NULL,
  [OverTimeAfterShiftWork] int NOT NULL,
  [TenantId] int NULL,
  [BranchId] int NOT NULL,
  [TimeKeepingType] int NOT NULL,
  [ClockingStatus] int NOT NULL,
  [ModifiedBy] int NULL,
  [ModifiedDate] int NULL,
  [CreatedBy] int NOT NULL,
  [CreatedDate] datetime NOT NULL,
  [ClockingHistoryStatus] int NOT NULL,
  [TimeIsLateAdjustment] int NOT NULL,
  [OverTimeBeforeShiftWorkAdjustment] int NOT NULL,
  [TimeIsLeaveWorkEarlyAdjustment] int NOT NULL,
  [OverTimeAfterShiftWorkAdjustment] int NOT NULL,
  [AbsenceType] int NULL,
  [ShiftId] bigint NOT NULL,
  [ShiftFrom] bigint NOT NULL,
  [ShiftTo] bigint NOT NULL,
  [EmployeeId] bigint NOT NULL,
  [CheckTime] datetime NOT NULL,
  [AutoTimekeepingUid] int NULL
);

-- Table: backup_ClockingHistory_202402293
CREATE TABLE [backup_ClockingHistory_202402293] (
  [Id] bigint NOT NULL,
  [ClockingId] bigint NOT NULL,
  [CheckedInDate] datetime2 NOT NULL,
  [CheckedOutDate] datetime2 NOT NULL,
  [TimeIsLate] int NOT NULL,
  [OverTimeBeforeShiftWork] int NOT NULL,
  [TimeIsLeaveWorkEarly] int NOT NULL,
  [OverTimeAfterShiftWork] int NOT NULL,
  [TenantId] int NULL,
  [BranchId] int NOT NULL,
  [TimeKeepingType] int NOT NULL,
  [ClockingStatus] int NOT NULL,
  [ModifiedBy] int NULL,
  [ModifiedDate] int NULL,
  [CreatedBy] int NOT NULL,
  [CreatedDate] datetime NOT NULL,
  [ClockingHistoryStatus] int NOT NULL,
  [TimeIsLateAdjustment] int NOT NULL,
  [OverTimeBeforeShiftWorkAdjustment] int NOT NULL,
  [TimeIsLeaveWorkEarlyAdjustment] int NOT NULL,
  [OverTimeAfterShiftWorkAdjustment] int NOT NULL,
  [AbsenceType] int NULL,
  [ShiftId] bigint NOT NULL,
  [ShiftFrom] bigint NOT NULL,
  [ShiftTo] bigint NOT NULL,
  [EmployeeId] bigint NOT NULL,
  [CheckTime] datetime NOT NULL,
  [AutoTimekeepingUid] int NULL
);

-- Table: backup_ClockingHistory_202402294
CREATE TABLE [backup_ClockingHistory_202402294] (
  [Id] bigint NOT NULL,
  [ClockingId] bigint NOT NULL,
  [CheckedInDate] datetime2 NOT NULL,
  [CheckedOutDate] datetime2 NOT NULL,
  [TimeIsLate] int NOT NULL,
  [OverTimeBeforeShiftWork] int NOT NULL,
  [TimeIsLeaveWorkEarly] int NOT NULL,
  [OverTimeAfterShiftWork] int NOT NULL,
  [TenantId] int NULL,
  [BranchId] int NOT NULL,
  [TimeKeepingType] int NOT NULL,
  [ClockingStatus] int NOT NULL,
  [ModifiedBy] int NULL,
  [ModifiedDate] int NULL,
  [CreatedBy] int NOT NULL,
  [CreatedDate] datetime NOT NULL,
  [ClockingHistoryStatus] int NOT NULL,
  [TimeIsLateAdjustment] int NOT NULL,
  [OverTimeBeforeShiftWorkAdjustment] int NOT NULL,
  [TimeIsLeaveWorkEarlyAdjustment] int NOT NULL,
  [OverTimeAfterShiftWorkAdjustment] int NOT NULL,
  [AbsenceType] int NULL,
  [ShiftId] bigint NOT NULL,
  [ShiftFrom] bigint NOT NULL,
  [ShiftTo] bigint NOT NULL,
  [EmployeeId] bigint NOT NULL,
  [CheckTime] datetime NOT NULL,
  [AutoTimekeepingUid] int NULL
);
