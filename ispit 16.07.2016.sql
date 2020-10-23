--1
create database IB170059v8




go
create table Proizvodi(
ProizvodID int constraint PK_Proizvodi primary key identity(1,1),
Sifra nvarchar(10) not null constraint UQ_Sifra unique,
Naziv nvarchar(50) not null,
Cijena decimal(18,2) not null
)
go
create table Skladista(
SkladisteID int constraint PK_Skladista primary key identity(1,1),
Naziv nvarchar(50) not null,
Oznaka nvarchar(10) not null constraint UQ_Oznaka unique,
Lokacija nvarchar(50) not null
)
go
create table SkladisteProizvodi(
SkladisteID int not null constraint FK_SkladisteProizvodi_Skladista foreign key references Skladista(SkladisteID),
ProizvodID int not null constraint FK_SkladisteProizvodi_Proizvodi foreign key references Proizvodi(ProizvodID),
constraint PK_SkladisteProizvodi primary key (SkladisteID,ProizvodID),
Stanje decimal(18,2) not null
)
--2
go
insert into Skladista
values ('Big Warehouse', 'BW','Mostar'),
	   ('Medium Warehouse', 'MW','Sarajevo'),
	   ('Small Warehouse', 'SW','Zenica')
		
go
insert Proizvodi
select top 10 P.ProductNumber,P.[Name],P.ListPrice
from AdventureWorks2014.Production.Product as P
	inner join AdventureWorks2014.Production.ProductSubcategory as PS on P.ProductSubcategoryID=PS.ProductSubcategoryID
	inner join AdventureWorks2014.Sales.SalesOrderDetail as SOD on P.ProductID=SOD.ProductID
where PS.[Name] like '%Bikes%'
group by P.ProductNumber,P.[Name],P.ListPrice
order by COUNT(P.ProductNumber) desc

go
insert SkladisteProizvodi
select 3,P.ProizvodID,100
from Proizvodi as P 

--3
go
create procedure PovecajStanjeProizvoda(
@ProizvodID int, @SkladiteID int, @Stanje decimal(18,2)
)
as begin
	update SkladisteProizvodi
	set Stanje+=@Stanje
	where @ProizvodID=ProizvodID and @SkladiteID=SkladisteID	 
end

exec PovecajStanjeProizvoda 5,2,10.52

--4
go
create nonclustered index IX_Proizvodi_SifraNaziv_Cijena
on Proizvodi (Sifra, Naziv) include (Cijena)

go
select Sifra,Naziv,Cijena
from Proizvodi

go
alter index IX_Proizvodi_SifraNaziv_Cijena on Proizvodi
disable

--5
go
create view View_Proizvod_StanjeNaSkladistu
as 
	select P.Sifra,P.Naziv,P.Cijena,S.Oznaka,S.Naziv as 'Naziv skladista',S.Lokacija,SP.Stanje
	from Proizvodi as P inner join SkladisteProizvodi as SP on P.ProizvodID=SP.ProizvodID
		 inner join Skladista as S on S.SkladisteID=SP.SkladisteID


--6
go
create Procedure StanjeProizvodaNaSvimSkladistima
( @Sifra nvarchar(10)
)
as begin
	select Sifra,Naziv, Cijena, SUM(Stanje)
	from View_Proizvod_StanjeNaSkladistu
	where Sifra =@Sifra
	group by Sifra,Naziv, Cijena
end

exec StanjeProizvodaNaSvimSkladistima 'BK-M68S-46'

--7
go
create procedure UpisProizvodaStanje0(
@Sifra nvarchar(10), @Naziv nvarchar(50), @Cijena decimal(18,2)
)
as begin
	insert Proizvodi
	values (@Sifra,@Naziv,@Cijena)

	insert SkladisteProizvodi
	select S.SkladisteID, (select ProizvodID from Proizvodi where @Sifra=Sifra),0
	from Skladista as S
end

exec UpisProizvodaStanje0 'M1LK@','Milka',1.60 

--8
go
create procedure DeleteProizvodBySifra
(
@Sifra nvarchar(10)
)
as begin
	alter table SkladisteProizvodi
	drop constraint [FK_SkladisteProizvodi_Proizvodi]

	alter table SkladisteProizvodi
	add constraint FK_SkladisteProizvodi_Proizvodi foreign key (ProizvodID) references Proizvodi(ProizvodID)
	on delete cascade

	delete Proizvodi
	where @Sifra=Sifra

	alter table SkladisteProizvodi
	drop constraint [FK_SkladisteProizvodi_Proizvodi]

	alter table SkladisteProizvodi
	add constraint FK_SkladisteProizvodi_Proizvodi foreign key (ProizvodID) references Proizvodi(ProizvodID)

end
exec DeleteProizvodBySifra 'M1LK@'

--9
go
create procedure ViewProizvodSkladisteStanje
(
@Sifra nvarchar(10)=NULL, @Oznaka nvarchar(10)=NULL,
@Lokacija nvarchar(50)=NULL
)
as begin
	select *
	from View_Proizvod_StanjeNaSkladistu
	where (Sifra=@Sifra or @Sifra is null) and
		  (Oznaka=@Oznaka or @Oznaka is null) and
		  (Lokacija =@Lokacija or @Lokacija is null)
end

exec ViewProizvodSkladisteStanje @Sifra='BK-M68B-42',@Lokacija='Sarajevo'

--10
backup database IB170059v8
to disk = 'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\IB170059v8FULL.bak'

backup database IB170059v8
to disk = 'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\IB170059v8diff.bak'
with differential


