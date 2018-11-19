--USE [IQCare_WRP]
--GO

/****** Object:  StoredProcedure [dbo].[PatientIdentifiers_To_Greencard]    Script Date: 11/5/2018 8:49:04 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[PatientIdentifiers_To_Greencard]
	-- Add the parameters for the stored procedure here
	@CCCNumber varchar(20),
	@PersonId int,
	@ModuleId int,
	@StartDate datetime,
	@PatientId int,
	@EnrollmentId int,
	@UserID int,
	@CreateDate datetime,
	@ReferredFrom int,
	@entryPoint int,	
	@MaritalStatus int,
	@MaritalStatusId int,
	@ServiceEntryPointId int OUTPUT,
	@PatientIdentifierId int OUTPUT,
	@PatientMaritalStatusID int OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @message varchar(max);

	IF @CCCNumber IS NOT NULL --AND @ModuleId = 5
		BEGIN
			-- Patient Identifier

			IF NOT EXISTS(SELECT * FROM PatientIdentifier m WHERE m.patientid=@PatientId)  and @EnrollmentId is not null
					INSERT INTO [dbo].[PatientIdentifier] ([PatientId], [PatientEnrollmentId], [IdentifierTypeId], [IdentifierValue] ,[DeleteFlag] ,[CreatedBy] ,[CreateDate] ,[Active] ,[AuditData])
			VALUES (@PatientId , @EnrollmentId ,(select top 1 Id from Identifiers where Code='CCCNumber') ,@CCCNumber ,0 ,@UserID ,@CreateDate ,0 ,NULL);

			SET @PatientIdentifierId = SCOPE_IDENTITY();
			--SET @message = 'Created PatientIdentifier Id: ' + CAST(@PatientIdentifierId as varchar);
			--PRINT @message;
		END

	--Insert into ServiceEntryPoint
	IF @ReferredFrom > 0 bEGIN
		SET @entryPoint = (select TOP 1 ItemId from [dbo].[LookupItemView] where ItemName like '%' + (SELECT top 1 Name FROM mst_Decode WHERE ID=@ReferredFrom AND CodeID=17) + '%');
		IF @entryPoint IS NULL
			BEGIN
				SET @entryPoint = (select top 1 ItemId from LookupItemView where MasterName = 'Unknown' and ItemName = 'Unknown');
			END
	END
	ELSE
		SET @entryPoint = (select top 1 ItemId from LookupItemView where MasterName = 'Unknown' and ItemName = 'Unknown');

	IF NOT EXISTS(SELECT * FROM ServiceEntryPoint m WHERE m.patientid=@PatientId)
	INSERT INTO ServiceEntryPoint([PatientId], [ServiceAreaId], [EntryPointId], [DeleteFlag], [CreatedBy], [CreateDate], [Active])
	VALUES(@PatientId, 1, @entryPoint, 0 , @UserID, @CreateDate, 0);

	SET @ServiceEntryPointId = SCOPE_IDENTITY();
	--SET @message = 'Created ServiceEntryPoint Id: ' + CAST(@ServiceEntryPointId as varchar);
	--PRINT @message;
	
	--Insert into MaritalStatus
	IF @MaritalStatus > 0
		BEGIN
			IF EXISTS (select TOP 1 ItemId from [dbo].[LookupItemView] where ItemName like '%' + (select Name from mst_Decode where ID = @MaritalStatus and CodeID = 12) + '%')
				SET @MaritalStatusId = (select TOP 1 ItemId from [dbo].[LookupItemView] where ItemName like '%' + (select TOP 1 Name from mst_Decode where ID = @MaritalStatus and CodeID = 12) + '%');
			ELSE
				SET @MaritalStatusId = (select TOP 1 ItemId from LookupItemView where MasterName = 'Unknown' and ItemName = 'Unknown');
		END
	ELSE
		SET @MaritalStatusId = (select TOP 1 ItemId from LookupItemView where MasterName = 'Unknown' and ItemName = 'Unknown');

	INSERT INTO PatientMaritalStatus(PersonId, MaritalStatusId, Active, DeleteFlag, CreatedBy, CreateDate)
	VALUES(@PersonId, @MaritalStatusId, 1, 0, @UserID, @CreateDate);

	SET @PatientMaritalStatusID = SCOPE_IDENTITY();
	--SET @message = 'Created PatientMaritalStatus Id: ' + CAST(@PatientMaritalStatusID as varchar);
	--PRINT @message;

	--SELECT @PatientIdentifierId, @ServiceEntryPointId, @PatientMaritalStatusID
END

GO


