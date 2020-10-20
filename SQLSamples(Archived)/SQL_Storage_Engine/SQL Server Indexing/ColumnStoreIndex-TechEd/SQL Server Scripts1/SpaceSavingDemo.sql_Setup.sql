--- SCRIPT TAKES ABOUT 2 Minutes and 5 Seconds
Use Master
Go
--- Create a Database for the ColumnStore Index Demos
If db_id('ColumnstoreDemos') is null
	Create DATABASE CCI_Spaceusage
GO

Use CCI_Spaceusage
go
/* Procedure for Getting the Space Used */
Create Procedure GetSPaceByTables
As
SELECT TOP 1000
			(row_number() over(order by (a1.reserved + ISNULL(a4.reserved,0)) desc))%2 as l1,
			a3.name AS [schemaname],
			a2.name AS [tablename],
			a1.rows as row_count,
			((a1.reserved + ISNULL(a4.reserved,0))* 8) AS "reserved(In KB)" ,
			(a1.data * 8) AS "data(In KB)" ,
			((CASE WHEN (a1.used + ISNULL(a4.used,0)) > a1.data 
			THEN (a1.used + ISNULL(a4.used,0)) - a1.data ELSE 0 END) * 8) AS "index_size(In KB)" ,
			((CASE WHEN (a1.reserved + ISNULL(a4.reserved,0)) > a1.used THEN 
			(a1.reserved + ISNULL(a4.reserved,0)) - a1.used ELSE 0 END) * 8) AS "unused(In KB)" 
			FROM
			(
			SELECT
			ps.object_id,
			SUM (
			CASE
			WHEN (ps.index_id < 2) THEN row_count
			ELSE 0
			END
			) AS [rows],
			SUM (ps.reserved_page_count) AS reserved,
			SUM (
			CASE
			WHEN (ps.index_id < 2) THEN (ps.in_row_data_page_count + ps.lob_used_page_count + ps.row_overflow_used_page_count)
			ELSE (ps.lob_used_page_count + ps.row_overflow_used_page_count)
			END
			) AS data,
			SUM (ps.used_page_count) AS used
			FROM sys.dm_db_partition_stats ps
			WHERE ps.object_id NOT IN (SELECT object_id FROM sys.tables WHERE is_memory_optimized = 1)
			GROUP BY ps.object_id) AS a1
			LEFT OUTER JOIN
			(SELECT
			it.parent_id,
			SUM(ps.reserved_page_count) AS reserved,
			SUM(ps.used_page_count) AS used
			FROM sys.dm_db_partition_stats ps
			INNER JOIN sys.internal_tables it ON (it.object_id = ps.object_id)
			WHERE it.internal_type IN (202,204)
			GROUP BY it.parent_id) AS a4 ON (a4.parent_id = a1.object_id)
			INNER JOIN sys.all_objects a2  ON ( a1.object_id = a2.object_id )
			INNER JOIN sys.schemas a3 ON (a2.schema_id = a3.schema_id)
			WHERE a2.type <> N'S' and a2.type <> N'IT'
GO

/* Heap Tables */
CREATE TABLE dbo.SalesOrderDetail(
	[SalesOrderID] int ,
	[SalesOrderDetailID] [int] NOT NULL,
	[CarrierTrackingNumber] [nvarchar](25) NULL,
	[OrderQty] [smallint] NOT NULL,
	[ProductID] int ,
	[SpecialOfferID] int ,
	[UnitPrice] [money] NOT NULL,
	[UnitPriceDiscount] [money] NOT NULL,
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[ModifiedDate] [datetime] NOT NULL
) ON [PRIMARY]
GO
Alter Table SalesOrderDetail Rebuild With (Data_Compression = NONE)
Go

CREATE TABLE dbo.SalesOrderDetail_RowCompressed(
	[SalesOrderID] int ,
	[SalesOrderDetailID] [int] NOT NULL,
	[CarrierTrackingNumber] [nvarchar](25) NULL,
	[OrderQty] [smallint] NOT NULL,
	[ProductID] int ,
	[SpecialOfferID] int ,
	[UnitPrice] [money] NOT NULL,
	[UnitPriceDiscount] [money] NOT NULL,
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[ModifiedDate] [datetime] NOT NULL
) ON [PRIMARY]
Go
Alter Table  SalesOrderDetail_RowCompressed Rebuild
	With (Data_Compression = ROW)
Go

CREATE TABLE dbo.SalesOrderDetail_PageCompressed(
	[SalesOrderID] int ,
	[SalesOrderDetailID] [int] NOT NULL,
	[CarrierTrackingNumber] [nvarchar](25) NULL,
	[OrderQty] [smallint] NOT NULL,
	[ProductID] int ,
	[SpecialOfferID] int ,
	[UnitPrice] [money] NOT NULL,
	[UnitPriceDiscount] [money] NOT NULL,
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[ModifiedDate] [datetime] NOT NULL
) ON [PRIMARY]
GO

Alter Table SalesOrderDetail_PageCompressed Rebuild
	With (Data_Compression = PAGE)
Go


/* Heap Table */

--- Insert Data into the Tables 
insert into [dbo].[SalesOrderDetail] (SalesOrderID, SalesOrderDetailID, CarrierTrackingNumber, OrderQty, ProductID, SpecialOfferID, UnitPrice, UnitPriceDiscount, rowguid, ModifiedDate)
	Select SalesOrderID, SalesOrderDetailID, CarrierTrackingNumber, OrderQty, ProductID, SpecialOfferID, UnitPrice, UnitPriceDiscount, rowguid, ModifiedDate from AdventureWorks2012.Sales.SalesOrderDetail
go


insert into [dbo].SalesOrderDetail_PageCompressed (SalesOrderID, SalesOrderDetailID, CarrierTrackingNumber, OrderQty, ProductID, SpecialOfferID, UnitPrice, UnitPriceDiscount, rowguid, ModifiedDate)
	Select SalesOrderID, SalesOrderDetailID, CarrierTrackingNumber, OrderQty, ProductID, SpecialOfferID, UnitPrice, UnitPriceDiscount, rowguid, ModifiedDate from AdventureWorks2012.Sales.SalesOrderDetail
go


insert into  [dbo].SalesOrderDetail_RowCompressed (SalesOrderID, SalesOrderDetailID, CarrierTrackingNumber, OrderQty, ProductID, SpecialOfferID, UnitPrice, UnitPriceDiscount, rowguid, ModifiedDate)
	Select SalesOrderID, SalesOrderDetailID, CarrierTrackingNumber, OrderQty, ProductID, SpecialOfferID, UnitPrice, UnitPriceDiscount, rowguid, ModifiedDate from AdventureWorks2012.Sales.SalesOrderDetail
go 


--- Insert somemore records into the table
declare @count int = 1
while @count <=6
begin

insert into [dbo].[SalesOrderDetail]
	Select * from dbo.[SalesOrderDetail]

insert into [dbo].SalesOrderDetail_PageCompressed
	Select * from dbo.SalesOrderDetail_PageCompressed

insert into  [dbo].SalesOrderDetail_RowCompressed
	Select * from dbo.SalesOrderDetail_RowCompressed

set @count = @count + 1
end



 