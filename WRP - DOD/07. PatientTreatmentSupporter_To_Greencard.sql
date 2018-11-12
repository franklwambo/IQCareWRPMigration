--USE [IQCare_WRP]
--GO

/****** Object:  StoredProcedure [dbo].[PatientTreatmentSupporter_To_Greencard]    Script Date: 11/5/2018 8:49:52 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[PatientTreatmentSupporter_To_Greencard]
	-- Add the parameters for the stored procedure here
	@ptn_pk int,
	@PersonId int,
	@PatientTreatmentSupporterID int OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--Insert into Treatment Supporter
	DECLARE @k INT = 1;
	DECLARE @countk INT, @message varchar(max);

	DECLARE @FirstNameT varchar(50), @LastNameT varchar(50), @TreatmentSupportTelNumber varchar(50), 
	@CreateDateT datetime, @UserIDT int, @IDT int;

	--Create Temporary Tables for storing data 
	CREATE TABLE #Tdtl_PatientContacts(Id INT IDENTITY(1,1), FirstNameT varchar(50), LastNameT varchar(50), TreatmentSupportTelNumber varchar(50), CreateDateT datetime, UserIDT int);
		--Insert data to temporary table #Tdtl_PatientContacts 
	INSERT INTO #Tdtl_PatientContacts(FirstNameT, LastNameT, TreatmentSupportTelNumber, CreateDateT, UserIDT)
	SELECT SUBSTRING(TreatmentSupporterName,0,charindex(' ',TreatmentSupporterName))as firstname, SUBSTRING(TreatmentSupporterName,charindex(' ',TreatmentSupporterName) + 1,len(TreatmentSupporterName)+1)as lastname,	TreatmentSupportTelNumber, CreateDate, UserID 
	from dtl_PatientContacts WHERE ptn_pk = @ptn_pk;

	SELECT @countk = COUNT(Id) FROM #Tdtl_PatientContacts 
	BEGIN
	WHILE (@k <= @countk)
		BEGIN
			SELECT @FirstNameT = FirstNameT, @LastNameT = LastNameT, @TreatmentSupportTelNumber = TreatmentSupportTelNumber, @CreateDateT = Isnull(CreateDateT,getdate()), @UserIDT = Isnull(UserIDT,1) FROM #Tdtl_PatientContacts WHERE Id = @k;

			BEGIN TRY
				BEGIN TRANSACTION
					--PRINT ' '  
					--SELECT @message = '----- Treatment Supporter: ' + CAST(@ptn_pk as varchar(50));
					--PRINT @message;

					IF @FirstNameT IS NOT NULL AND @LastNameT IS NOT NULL 
						BEGIN
							Insert into Person(FirstName, MidName, LastName, Sex, Active, DeleteFlag, CreateDate, CreatedBy)
							Values(ENCRYPTBYKEY(KEY_GUID('Key_CTC'),@FirstNameT), NULL, ENCRYPTBYKEY(KEY_GUID('Key_CTC'),@LastNameT), (select TOP 1 ItemId from LookupItemView where MasterName = 'Unknown' and ItemName = 'Unknown'), 1, 0, getdate(), @UserIDT);

							SELECT @IDT = SCOPE_IDENTITY();
							--SELECT @message = 'Created Person Treatment Supporter Id: ' + CAST(@IDT as varchar(50));
							--PRINT @message;

							INSERT INTO PatientTreatmentSupporter(PersonId, [SupporterId], [MobileContact], [DeleteFlag], [CreatedBy], [CreateDate])
							VALUES(@PersonId, @IDT, ENCRYPTBYKEY(KEY_GUID('Key_CTC'),@TreatmentSupportTelNumber), 0, @UserIDT, getdate());

							SET @PatientTreatmentSupporterID = SCOPE_IDENTITY();
							--SET @message = 'Created PatientTreatmentSupporterID Id: ' + CAST(@PatientTreatmentSupporterID as varchar);
							--PRINT @message;
						END
				IF @@TRANCOUNT > 0 COMMIT
				END TRY
				BEGIN CATCH
					Declare @ErrorMessage NVARCHAR(4000),@ErrorSeverity Int,@ErrorState Int;

					Select	@ErrorMessage = Error_message(),@ErrorSeverity = Error_severity(),	@ErrorState = Error_state();

					Raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState  );

					IF @@TRANCOUNT > 0					
						ROLLBACK
				END CATCH

				SELECT @k = @k + 1;

				END
			END
		--Now Drop Temporary Tables
		DROP TABLE #Tdtl_PatientContacts

	SELECT @PatientTreatmentSupporterID;
END

GO


