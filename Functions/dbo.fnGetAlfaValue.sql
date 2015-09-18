SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--  ----------------------------------------------------------------------------
--  2a. Create Functions

create function [dbo].[fnGetAlfaValue] (@pItem varchar(100), @pDatabase sysname) 
returns varchar(200)
as
begin
		declare @lResult varchar(200)

		select  @lResult = AlfaValue
		from	dbo.Parameter
		where   Item = @pItem + ' ' + @pDatabase
		if (@lResult is NULL)
		begin
				select  @lResult = AlfaValue
				from	dbo.Parameter
				where   Item = 'Default ' + @pItem
		end

		return @lResult
end
GO
