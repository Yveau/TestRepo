SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*  ----------------------------------------------------------------------------

--  20150824  IBee1  @Max time adjusted with half the backup frequency to avoid early deletion of backup files.
--
*/

CREATE  procedure [dbo].[csBackupCleanup]
        @pDatabase sysname
as
begin
        declare @Retention int 
        declare @RetentionHist int 
        declare @Path varchar(200)
        declare @BackupDate datetime
        declare @ServerName sysname
        DECLARE @JobName sysname

        select  @Retention = dbo.fnGetNumValue ('Backup Retention', @pDatabase)
		,		@RetentionHist = dbo.fnGetNumValue ('BackupHistory Retention', @pDatabase)
		,		@Path = dbo.fnGetAlfaValue ('Backup location', @pDatabase)
        ,       @JobName = 'DBAInfo Backup ' + @pDatabase

        IF NOT EXISTS
                (   select  DB.name
                ,       ARS.role_desc
                from    sys.databases DB
                inner   join    sys.dm_hadr_availability_replica_states ARS on DB.replica_id = ARS.replica_id
                where   DB.name = @pDatabase)
                begin
                        -- No HADR configuration
                        select  @ServerName = cast(SERVERPROPERTY('servername') as sysname)
                end
                else
                begin
                        -- HADR configuration
                        select  @ServerName = cluster_name
                        from sys.dm_hadr_cluster
                end

        set     @Path = @Path 
        +       @ServerName + '\'
		+       case isnull(SERVERPROPERTY('instancename'), '-')
				when '-' then 'MSSQLSERVER\'
				else ''
				end
        +		@pDatabase

		DECLARE @RetentionDate DATETIME
        ,       @RetentionHistDate DATETIME
		,		@MaxFull DATETIME
		,		@MaxDiff DATETIME
		,		@maxLog DATETIME
		SELECT  @RetentionDate = DATEADD(HOUR, @Retention * -24, GETDATE())
        ,       @RetentionHistDate = DATEADD(HOUR, @RetentionHist * -24, GETDATE())

		SELECT  @MAXFull = MAX(BS.backup_start_date)
		FROM    msdb.dbo.backupset BS
		WHERE   1 = 1
		AND     BS.backup_start_date < @RetentionDate
		AND     BS.database_name = @pDatabase
		AND     BS.is_snapshot = 0
		AND     BS.type = 'D'
		
		SELECT  @MAXDiff = MAX(BS.backup_start_date)
		FROM    msdb.dbo.backupset BS
		WHERE   1 = 1
		AND     BS.backup_start_date < @RetentionDate
		AND		BS.backup_start_date > @MaxFull
		AND     BS.database_name = @pDatabase
		AND     BS.is_snapshot = 0
		AND     BS.type = 'I'
		
		SELECT  @MaxDiff = ISNULL(@MaxDiff, @MaxFull)
		
		SELECT  @MAXLog = MIN(BS.backup_start_date)
		FROM    msdb.dbo.backupset BS
		WHERE   1 = 1
		AND     BS.backup_start_date < @RetentionDate
		AND		BS.backup_start_date > @MaxDiff
		AND     BS.database_name = @pDatabase
		AND     BS.is_snapshot = 0
		AND     BS.type = 'L'
		
        -- clean up system tables with backup history
		EXECUTE msdb.dbo.sp_delete_backuphistory @RetentionHistDate
        EXECUTE msdb.dbo.sp_purge_jobhistory  @job_name = @JobName, @oldest_date= @RetentionHistDate

        -- subtract half the Interval from @Max times to make sure the backups are not deleted too soon.
        SELECT  @MaxFull = DATEADD(MINUTE, -1 * DBAInfo.dbo.fnGetNumValue('Backup Frequency', @pDatabase), @MaxFull)
        ,       @MaxDiff = DATEADD(MINUTE, -1 * DBAInfo.dbo.fnGetNumValue('Backup Frequency', @pDatabase), @MaxDiff)
        ,       @maxLog = DATEADD(MINUTE, -1 * DBAInfo.dbo.fnGetNumValue('Backup Frequency', @pDatabase), @maxLog)

        -- clean up file system with backup files
        EXECUTE master.dbo.xp_delete_file 0,@Path,N'TRN',@MaxLog,1
        EXECUTE master.dbo.xp_delete_file 0,@Path,N'DIF',@MaxDiff,1
        EXECUTE master.dbo.xp_delete_file 0,@Path,N'BAK',@MaxFull,1
END
GO
