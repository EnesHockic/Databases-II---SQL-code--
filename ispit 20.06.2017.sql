--1
create database IB1700591 on primary
(
	name='IB1700591',
	filename='E:\BP2\IB1700591.mdf',
	size=5mb,
	maxsize=unlimited,
	filegrowth=10%
)
log on
(
	name='IB1700591_log',
	filename='E:\BP2\IB1700591_log.ldf',
	size=2mb,
	maxsize=unlimited,
	filegrowth=10%
)
--2
use IB1700591
go
create table Proizvodi(
ProizvodID int constraint PK_Proizvodi primary key,
Sifra nvarchar(25)not null unique,
Naziv nvarchar(50) not null,
Kategorija nvarchar(50) not null,
Cijena decimal not null
)
go
create table Narudzbe(
NarudzbaID int constraint PK_Narudzbe primary key,
BrojNarudzbe nvarchar(50) not null constraint Unq_BrojNarudzbe unique,
Datum date not null,
Ukupno decimal not null
)
go
create table StavkeNarudzbe(
ProizvodID int,
NarudzbaID int,
Kolicina int not null,
Cijena decimal not null,
Popust decimal not null,
Iznos decimal not null
constraint PK_StavkeNarudzbe primary key(ProizvodID,NarudzbaID),
constraint FK_Proizvod foreign key(ProizvodID) references Proizvodi(ProizvodID),
constraint FK_Narudzba foreign key(NarudzbaID) references Narudzbe(NarudzbaID)
)
--3
insert Proizvodi(ProizvodID,Sifra,Naziv,Kategorija,Cijena)
select distinct P.ProductID,P.ProductNumber,P.[Name],(select PC.[Name] from AdventureWorks2014.Production.ProductCategory as PC where PS.ProductCategoryID=PC.ProductCategoryID),P.ListPrice
from AdventureWorks2014.Production.Product as P inner join
	AdventureWorks2014.Production.ProductSubcategory as PS on P.ProductSubcategoryID=PS.ProductSubcategoryID
	inner join AdventureWorks2014.Sales.SalesOrderDetail as SOD on P.ProductID=SOD.ProductID
	inner join AdventureWorks2014.Sales.SalesOrderHeader as SOH on SOD.SalesOrderID=SOH.SalesOrderID
where YEAR(SOH.OrderDate)=2014

go
insert Narudzbe(NarudzbaID,BrojNarudzbe,Datum,Ukupno)
select SOH.SalesOrderID,SOH.SalesOrderNumber,SOH.OrderDate,SOH.TotalDue
from AdventureWorks2014.Sales.SalesOrderHeader as SOH
where YEAR(SOH.OrderDate)=2014

go
insert StavkeNarudzbe(ProizvodID,NarudzbaID,Kolicina,Cijena,Popust,Iznos)
select SOD.ProductID,SOD.SalesOrderID,SOD.OrderQty,SOD.UnitPrice,SOD.UnitPriceDiscount,SOD.LineTotal
from AdventureWorks2014.Sales.SalesOrderDetail as SOD 
where SOD.SalesOrderID in (select SOH.SalesOrderID from AdventureWorks2014.Sales.SalesOrderHeader as SOH
						   where SOH.SalesOrderID=SOD.SalesOrderID and YEAR(SOH.OrderDate)=2014)
--4
go
create table Skladista(
SkladisteID smallint constraint PK_Skladiste primary key,
Naziv nvarchar(50) not null
)
create table ProizvodSkladiste(
ProizvodID int,
SkladisteID smallint,
Kolicina int not null
constraint PK_ProizvodSkladiste primary key(ProizvodID,SkladisteID),
constraint FK_ProizvodSkladiste_Proizvod foreign key (ProizvodID) references Proizvodi(ProizvodID),
constraint FK_ProizvodSkladiste_Skladiste foreign key (SkladisteID) references Skladista(SkladisteID)
)

--5
insert Skladista(SkladisteID,Naziv)
select top 3 L.LocationID,L.[Name]
from AdventureWorks2014.Production.[Location] as L
order by NEWID()

go
insert ProizvodSkladiste
select PL.ProductID,PL.LocationID,0 
from AdventureWorks2014.Production.ProductInventory as PL
where PL.LocationID =(select S.SkladisteID from Skladista as S where S.SkladisteID=PL.LocationID)and
	  PL.ProductID =(SELect P.ProizvodID from Proizvodi as P where P.ProizvodID=PL.ProductID)
--6
go
create procedure changeProductQuantity(
	@Proizvod int,@Skladiste smallint ,@Kolicina int
)
as begin

	update ProizvodSkladiste
	set Kolicina=@Kolicina
	where ProizvodID=@Proizvod and SkladisteID=@Skladiste

end

exec changeProductQuantity 747,40,120

--7
create nonclustered index Proizvodi_Sifra_Naziv
on Proizvodi (Sifra,Naziv)

select Sifra,Naziv
from Proizvodi
where Naziv like 'A%' 
--9
go
create view dbo.UkupnaZaradaOdProizvoda
as
select Sifra,Naziv,SN.Cijena,SUM(SN.Kolicina)as [Ukupna prodana kolicina],SUM(SN.Iznos) [Ukupna zarada]
from Proizvodi as P inner join StavkeNarudzbe as SN on P.ProizvodID=SN.ProizvodID
group by Sifra,Naziv,SN.Cijena

select *
from UkupnaZaradaOdProizvoda


--10
go
create procedure viewProducts(
	@Sifra int =null
)
as begin
	if(@Sifra is null)
	(select *
	from UkupnaZaradaOdProizvoda );
	else
	(select *
	from UkupnaZaradaOdProizvoda
	where @Sifra=Sifra);

end


exec viewProducts 'BK-M68S-46'


SELECT SCHEMA_NAME(schema_id) AS SchemaName,
 Name AS ProcedureName FROM sys.procedures


select * 
from ProizvodSkladiste






























