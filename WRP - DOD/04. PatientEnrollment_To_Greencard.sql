--USE [IQCare_WRP]
--GO

/****** Object:  StoredProcedure [dbo].[PatientEnrollment_To_Greencard]    Script Date: 11/5/2018 8:48:09 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[PatientEnrollment_To_Greencard]
	-- Add the parameters for the stored procedure here
	@ptn_pk int,
	@transferIn int,
	@PatientId int,
	@Status bit,
	@EnrollmentId int OUTPUT,
	@ModuleId int OUTPUT,
	@StartDate datetime OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--Insert into Enrollment Table
	DECLARE @message varchar(max);
	DECLARE @j INT = 1;
	DECLARE @countj INT;
	--Create Temporary Tables for storing data 
	CREATE TABLE #TLnk_PatientProgramStart (Id INT IDENTITY(1,1), ModuleId int, [StartDate] datetime, [UserID] int, [CreateDate] datetime);

	INSERT INTO #TLnk_PatientProgramStart(ModuleId, [StartDate], [UserID], [CreateDate])
	SELECT ModuleId, [StartDate], Isnull([UserID],1) , Isnull([CreateDate],getdate()) FROM Lnk_PatientProgramStart WHERE Ptn_pk=@ptn_pk And  ModuleId = 5;

	DECLARE @UserID_Enrollment int, @CreateDate_Enrollment datetime;

	SELECT @countj = COUNT(Id) FROM #TLnk_PatientProgramStart 

	BEGIN
		WHILE (@j <= @countj)
			BEGIN
				SELECT @ModuleId = ModuleId, @StartDate = [StartDate], @UserID_Enrollment = isnull([UserID],1), @CreateDate_Enrollment = isnull([CreateDate],getdate())
				 FROM #TLnk_PatientProgramStart WHERE Id = @j AND ModuleId = 5;

				BEGIN TRY
					BEGIN TRANSACTION

							--PRINT ' ';
							--SET @message = '----- Enrollment Start Date: ' + CAST(@StartDate as varchar(50));
							--PRINT @message;

								IF @ModuleId = 5
								BEGIN
									--PRINT ' ';
									--SET @message = '----- Transfer In is (1), New (0) : ' + CAST(@transferIn as varchar(50));
									--PRINT @message;

									DECLARE @DateEnrolledInCare DATETIME;
									IF @transferIn = 1
										BEGIN
											SET @DateEnrolledInCare = (SELECT TOP 1 dbo.dtl_PatientHivPrevCareEnrollment.DateEnrolledInCare
																		FROM dbo.dtl_PatientHivPrevCareEnrollment INNER JOIN
																			dbo.ord_Visit ON dbo.dtl_PatientHivPrevCareEnrollment.ptn_pk = dbo.ord_Visit.Ptn_Pk 
																			AND dbo.dtl_PatientHivPrevCareEnrollment.Visit_pk = dbo.ord_Visit.Visit_Id INNER JOIN
																			dbo.mst_VisitType ON dbo.ord_Visit.VisitType = dbo.mst_VisitType.VisitTypeID
																			WHERE (dbo.mst_VisitType.VisitName = 'ART History') AND dbo.dtl_PatientHivPrevCareEnrollment.ptn_pk = @ptn_pk);

											IF @DateEnrolledInCare IS NOT NULL
												BEGIN
													SET @StartDate = @DateEnrolledInCare 
												END;
										END;

									--PRINT ' ';
									--SET @message = '----- Start Date Patient enrollment: ' + CAST(@StartDate as varchar(50));
									--PRINT @message;


									INSERT INTO [dbo].[PatientEnrollment] ([PatientId] ,[ServiceAreaId] ,[EnrollmentDate] ,[EnrollmentStatusId] ,[TransferIn] ,[CareEnded] ,[DeleteFlag] ,[CreatedBy] ,[CreateDate] ,[AuditData])
									VALUES (@PatientId,1, @StartDate,0, @transferIn, @Status ,0 ,@UserID_Enrollment ,@CreateDate_Enrollment ,NULL);

									SET @EnrollmentId = SCOPE_IDENTITY();
									--SET @message = 'Created PatientEnrollment Id: ' + CAST(@EnrollmentId as varchar);
									--PRINT @message;
								END
					IF @@TRANCOUNT > 0 
						COMMIT
				END TRY
				BEGIN CATCH
					Declare @ErrorMessage NVARCHAR(4000),@ErrorSeverity Int,@ErrorState Int;

					Select	@ErrorMessage = Error_message(),@ErrorSeverity = Error_severity(),	@ErrorState = Error_state();

					Raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState  );

					IF @@TRANCOUNT > 0					
						ROLLBACK
				END CATCH

				SELECT @j = @j + 1;

			END
		END
	--Now Drop Temporary Tables
	DROP TABLE #TLnk_PatientProgramStart

	SELECT @EnrollmentId, @ModuleId, @StartDate;
END

GO


