SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  FUNCTION [dbo].[fnVersion] (@pProc sysname)
--  ----------------------------------------------------------------------------
--  Name            : SQLHeader.sql
--  Date            : 20150917
--  Author          : Ivo Beek - IBEE1
--  Copyright © yyyy, Glencore Grain B.V., All Rights Reserved
--  ----------------------------------------------------------------------------
--  Purpose         : Introduce a standaard header for .sql scripts
--  Parameters      : -
--  Return          : varchar(10)
--  ----------------------------------------------------------------------------
--  Version    User   Date      change  Comment
--  v00.00.01  IBEE1  20150914          Initial
--  v00.00.02  IBEE1  20150914          Bugfix
--  v00.00.03  IBEE1  20150916          Minor progress
--  v01.00.00  IBEE1  20150917          First major version
--  ----------------------------------------------------------------------------
returns varchar(10)
AS
BEGIN
        DECLARE @yveau TABLE (_sequence INT IDENTITY(1,1), Content VARCHAR(MAX))

        --  This statement is side effecting, and thus not allowed in a function !!!
        --  INSERT INTO @yveau
        --  EXEC sp_helptext @pProc

        DECLARE @lText VARCHAR(MAX)

        SELECT  @lText = text
        FROM    sys.syscomments
        WHERE   1 = 1
        AND     id = OBJECT_ID(@pProc)

        DECLARE @lstart INT = 1
        DECLARE @lstring NCHAR(2) = CHAR(13) + CHAR(10)
        DECLARE @llen INT

        WHILE   @lstart < LEN(@lText)
        BEGIN
                SELECT  @llen = CHARINDEX(@lstring, @lText, @lstart) - @lstart
                INSERT  INTO @yveau
                        ( Content )
                VALUES  ( SUBSTRING(@lText, @lstart, @llen) )
        
                SELECT  @lstart = @lstart + @llen + LEN(@lstring)
        end

        DECLARE @ret varchar(10)

        SELECT  @ret = SUBSTRING(Content, CHARINDEX('--  v', Content) + LEN('--  v'), 8)
        FROM    @Yveau
        WHERE   1 = 1
        AND     Content LIKE '--  v[0-9][0-9].[0-9][0-9].[0-9][0-9]%'
        ORDER   BY SUBSTRING(Content, CHARINDEX('--  v', Content) + LEN('--  v'), 2) ASC
        ,       SUBSTRING(Content, CHARINDEX('--  v', Content) + LEN('--  v') + 3, 2) ASC
        ,       SUBSTRING(Content, CHARINDEX('--  v', Content) + LEN('--  v') + 6, 2) ASC

        RETURN  @ret
END
GO
