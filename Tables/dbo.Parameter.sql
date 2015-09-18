CREATE TABLE [dbo].[Parameter]
(
[Item] [varchar] (100) COLLATE Latin1_General_CI_AS NOT NULL,
[NumValue] [int] NULL,
[AlfaValue] [varchar] (200) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Parameter] ADD CONSTRAINT [PK_Parameter] PRIMARY KEY CLUSTERED  ([Item]) ON [PRIMARY]
GO
