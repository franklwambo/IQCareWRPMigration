--USE [IQCare_WRP]
--GO

/****** Object:  StoredProcedure [dbo].[PatientContact_To_Greencard]    Script Date: 11/5/2018 8:50:22 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[PatientContact_To_Greencard]
	-- Add the parameters for the stored procedure here
	@Address varbinary(max),
	@Phone varbinary(max),
	@PersonId int,
	@Status bit,
	@UserID int,
	@CreateDate datetime,
	@PersonContactID int OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @message varchar(max);

	--Insert into Person Contact
	IF @Address IS NOT NULL AND @Phone IS NOT NULL
		BEGIN
			INSERT INTO PersonContact(PersonId, [PhysicalAddress], [MobileNumber], [AlternativeNumber], [EmailAddress], [Active], [DeleteFlag], [CreatedBy], [CreateDate])
			VALUES(@PersonId, @Address, @Phone, null, null, @Status, 0, @UserID, @CreateDate);

			SET @PersonContactID = SCOPE_IDENTITY();
			--SET @message = 'Created PersonContact Id: ' + CAST(@PersonContactID as varchar);
			--PRINT @message;
		END

		--SELECT @PersonContactID;
END

GO


