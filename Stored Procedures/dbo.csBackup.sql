SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--  modification for csBackup
CREATE  procedure [dbo].[csBackup]
        @pDatabase      sysname
,       @pType          varchar(4) = NULL
as
begin
        declare @Path nvarchar(200)
        declare @File nvarchar(200)
        declare @Desc varchar(100)
        declare @Type varchar(4)
        declare @TS char(14)
        declare @TS2 char(19)
        declare @Ext char(3)
        declare @Hour char(2)
        declare @Min char(2)
        declare @Day int
        declare @RecType varchar(11)
        declare @cmd varchar(1000)
        declare @BackupDate datetime
		declare @Freq int
        declare @ServerName sysname

        if      @pDatabase in 
        (       select  name
                from    master.sys.databases
                where   state_desc = 'ONLINE')
        and
        (       sys.fn_hadr_backup_is_preferred_replica(@pDatabase) = 1)
        begin
                select  @TS2 = convert(char(19),getdate(),120)
                select  @TS = replace(replace(replace(@TS2,' ',''),'-',''),':','')

                select  @Path = dbo.fnGetAlfaValue ('Backup location', @pDatabase)
				,       @Hour = substring(dbo.fnGetAlfaValue ('Backup Time', @pDatabase), 1, 2)
				,		@Min = substring(dbo.fnGetAlfaValue ('Backup Time', @pDatabase), 4, 2)
				,		@Day = dbo.fnGetNumValue ('Backup day', @pDatabase)
				,		@Freq = dbo.fnGetNumValue ('Backup Frequency', @pDatabase)

                select  @RecType = recovery_model_desc from master.sys.databases where name = @pDatabase

                if      @pType is NULL
                and     datediff(MINUTE,(cast(@Hour + ':' + @Min as time)), cast(getdate() as time)) BETWEEN 0 AND @Freq-1
                begin
                        if      charindex(cast(datepart(dw,getdate()) as char(1)),cast(@Day as varchar(7))) <> 0
                        begin
                                select  @Type = 'Full'
                        end
                        else
                        begin
                                select  @Type = 'Diff'
                        end
                end
                else
                begin
                        select  @Type = IsNull(@pType,'Log')
                end

                select  @Ext = case @Type
                        when    'Full' then 'BAK'
                        when    'Diff' then 'DIF'
                        when    'Log' then 'TRN'
                        else    'ERR'
                end

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

                select  @Path = @Path
				+       @ServerName + '\'
				+       case isnull(SERVERPROPERTY('instancename'), '-')
						when '-' then 'MSSQLSERVER\'
						else ''
						end
                +       @pDatabase + '\'
                ,       @Desc = cast(SERVERPROPERTY('servername') as sysname)+' - '+
                +       @pDatabase+' - '
                +       @Type+' - ' + @TS2
                select  @File = @Path  + @pDatabase + '-' + @TS + '.' + @Ext

                -- Create folder
                select  @cmd = 'mkdir ' + @Path
                execute master..xp_cmdshell @cmd

                --  When scheduled job triggers a non-log backup, first run a log backup as well.
                IF (@pType IS NULL) AND @Type IN ('FULL','DIFF')
                BEGIN
                        EXECUTE DBAInfo.dbo.csBackup @pDatabase = @pDatabase, @pType = 'Log'
                END

                if      @Type = 'Full'
                begin
                        BACKUP  DATABASE @pDatabase 
                        TO DISK = @File 
                        WITH    NOFORMAT
                        ,       NOINIT
                        ,       NAME = @Desc
                        ,       SKIP
                        ,       NOREWIND
                        ,       NOUNLOAD
                        ,       STATS = 10
                        ,       COMPRESSION

                        --IF @pType IS NULL
                        --BEGIN
                        --        EXECUTE DBAInfo.dbo.csBackup @pDatabase = @pDatabase, @pType = 'Log'
                        --END
                end
                ELSE IF @RecType <> 'SIMPLE'
                begin
                        if @Type = 'Diff'
                        begin
                                BACKUP  DATABASE @pDatabase 
                                TO DISK = @File
                                WITH    DIFFERENTIAL 
                                ,       NOFORMAT
                                ,       NOINIT
                                ,       NAME = @Desc
                                ,       SKIP
                                ,       NOREWIND
                                ,       NOUNLOAD
                                ,       STATS = 10
                                ,       COMPRESSION
                        end
                        else if @Type = 'Log'
                        begin
                                BACKUP  LOG @pDatabase 
                                TO DISK = @File
                                WITH    NOFORMAT
                                ,       NOINIT
                                ,       NAME = @Desc
                                ,       SKIP
                                ,       NOREWIND
                                ,       NOUNLOAD
                                ,       STATS = 10
                                ,       COMPRESSION

--                                select  @cmd = 'use ['+@pDatabase+'];'
--                                +       'declare @FID int select  @FID = fileid from dbo.sysfiles where groupid = 0 '
--                                +       'DBCC SHRINKFILE (@FID,512)'
--                                execute (@cmd)
                        end
                END
        END
END


GO
