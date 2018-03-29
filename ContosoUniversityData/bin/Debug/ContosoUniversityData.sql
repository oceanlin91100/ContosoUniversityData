/*
ContosoUniversityData 的部署指令碼

這段程式碼由工具產生。
變更這個檔案可能導致不正確的行為，而且如果重新產生程式碼，
變更將會遺失。
*/

GO
SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, ARITHABORT, CONCAT_NULL_YIELDS_NULL, QUOTED_IDENTIFIER ON;

SET NUMERIC_ROUNDABORT OFF;


GO
:setvar DatabaseName "ContosoUniversityData"
:setvar DefaultFilePrefix "ContosoUniversityData"
:setvar DefaultDataPath "C:\Users\ocean\AppData\Local\Microsoft\VisualStudio\SSDT\ContosoUniversityData"
:setvar DefaultLogPath "C:\Users\ocean\AppData\Local\Microsoft\VisualStudio\SSDT\ContosoUniversityData"

GO
:on error exit
GO
/*
偵測 SQLCMD 模式，如果不支援 SQLCMD 模式，則停用指令碼執行。
若要在啟用 SQLCMD 模式後重新啟用指令碼，請執行以下:
SET NOEXEC OFF; 
*/
:setvar __IsSqlCmdEnabled "True"
GO
IF N'$(__IsSqlCmdEnabled)' NOT LIKE N'True'
    BEGIN
        PRINT N'必須啟用 SQLCMD 模式才能成功執行此指令碼。';
        SET NOEXEC ON;
    END


GO
USE [$(DatabaseName)];


GO
PRINT N'正在卸除 [dbo].[FK_dbo.Enrollment_dbo.Student_StudentID]...';


GO
ALTER TABLE [dbo].[Enrollment] DROP CONSTRAINT [FK_dbo.Enrollment_dbo.Student_StudentID];


GO
PRINT N'開始重建資料表 [dbo].[Student]...';


GO
BEGIN TRANSACTION;

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SET XACT_ABORT ON;

CREATE TABLE [dbo].[tmp_ms_xx_Student] (
    [StudentID]      INT           IDENTITY (1, 1) NOT NULL,
    [LastName]       NVARCHAR (50) NULL,
    [FirstName]      NVARCHAR (50) NULL,
    [MiddleName]     NVARCHAR (50) NULL,
    [EnrollmentDate] DATETIME      NULL,
    PRIMARY KEY CLUSTERED ([StudentID] ASC)
);

IF EXISTS (SELECT TOP 1 1 
           FROM   [dbo].[Student])
    BEGIN
        SET IDENTITY_INSERT [dbo].[tmp_ms_xx_Student] ON;
        INSERT INTO [dbo].[tmp_ms_xx_Student] ([StudentID], [LastName], [FirstName], [EnrollmentDate])
        SELECT   [StudentID],
                 [LastName],
                 [FirstName],
                 [EnrollmentDate]
        FROM     [dbo].[Student]
        ORDER BY [StudentID] ASC;
        SET IDENTITY_INSERT [dbo].[tmp_ms_xx_Student] OFF;
    END

DROP TABLE [dbo].[Student];

EXECUTE sp_rename N'[dbo].[tmp_ms_xx_Student]', N'Student';

COMMIT TRANSACTION;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;


GO
PRINT N'正在建立 [dbo].[FK_dbo.Enrollment_dbo.Student_StudentID]...';


GO
ALTER TABLE [dbo].[Enrollment] WITH NOCHECK
    ADD CONSTRAINT [FK_dbo.Enrollment_dbo.Student_StudentID] FOREIGN KEY ([StudentID]) REFERENCES [dbo].[Student] ([StudentID]) ON DELETE CASCADE;


GO
PRINT N'正在針對新建立的條件約束檢查現有資料';


GO
USE [$(DatabaseName)];


GO
ALTER TABLE [dbo].[Enrollment] WITH CHECK CHECK CONSTRAINT [FK_dbo.Enrollment_dbo.Student_StudentID];


GO
PRINT N'更新完成。';


GO
