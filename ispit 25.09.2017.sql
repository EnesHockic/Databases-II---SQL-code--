create database IB170059v5
use IB170059v5
--1
create table Klijenti(
KlijentID int constraint PK_Klijenti primary key identity(1,1),
Ime nvarchar(50) not null,
Prezime nvarchar(50) not null,
Drzava nvarchar(50) not null,
Grad nvarchar(50) not null,
Email nvarchar(50) not null,
Telefon nvarchar(50) not null,
)
go
create table Izleti(
IzletID int constraint PK_Izleti primary key identity(1,1),
Sifra nvarchar(10) not null,
Naziv nvarchar(100) not null,
DatumPolaska date not null,
DatumPovratka date not null,
Cijena decimal not null,
Opis text
)
go
create table Prijave(
KlijentID int not null,
IzletID int not null,
Constraint PK_Prijave primary key(KlijentID,IzletID),
constraint FK_Pijave_Klijenti foreign key (KlijentID) references Klijenti(KlijentID),
constraint FK_Pijave_izleti foreign key (IzletID) references Izleti(IzletID),
Datum datetime not null,
BrojOdraslih int not null,
BrojDjece int not null
)

--2
insert Klijenti
select P.FirstName, P.LastName,CR.[Name],A.City,EA.EmailAddress,PP.PhoneNumber
from AdventureWorks2014.HumanResources.Employee as E
inner join AdventureWorks2014.Sales.SalesPerson as SP on E.BusinessEntityID=SP.BusinessEntityID
inner join AdventureWorks2014.Person.Person as P on P.BusinessEntityID=E.BusinessEntityID
inner join AdventureWorks2014.Person.BusinessEntityAddress as BEA on BEA.BusinessEntityID=E.BusinessEntityID
inner join AdventureWorks2014.Person.[Address] as A on A.AddressID=BEA.AddressID
inner join AdventureWorks2014.Person.StateProvince as StateP on StateP.StateProvinceID=A.StateProvinceID
inner join AdventureWorks2014.Person.CountryRegion as CR on CR.CountryRegionCode=StateP.CountryRegionCode
inner join AdventureWorks2014.Person.EmailAddress as EA on EA.BusinessEntityID=E.BusinessEntityID
inner join AdventureWorks2014.Person.PersonPhone as PP on PP.BusinessEntityID=E.BusinessEntityID
--U emailu se nalazi samo ime

go
insert into Izleti
values('IZLET0001','Zajedno u prirodu','2019-07-01','2019-07-10',340,'N/A'),
('IZLET0002','Australia tour','2019-09-11','2019-09-22',750,'N/A'),
('IZLET0003','America here we come','2020-01-25','2020-02-10',1100,'N/A')

--3
go
create procedure AddPrijavu(
@KlijentID int,@IzletID int, @BrojOdraslih int, @BrojDjece int
)
as begin
	insert Prijave
	values (@KlijentID,@IzletID,SYSDATETIME(),@BrojOdraslih,@BrojDjece)
end


exec AddPrijavu 3,3,20,5
exec AddPrijavu 3,4,15,15
exec AddPrijavu 4,5,10,20
exec AddPrijavu 1,3,5,30
exec AddPrijavu 17,4,30,0
exec AddPrijavu 15,5,20,25
exec AddPrijavu 15,3,2,20
exec AddPrijavu 13,4,23,0
exec AddPrijavu 10,4,50,50
exec AddPrijavu 6,5,3,50

--4
create unique nonclustered  index IX_Klijent_Email
on Klijenti(Email)

insert into Klijenti
values ('Syed','Abbas','BiH','Sarajevo','syed0@adventure-works.com','1650-035/310')

--5
update Izleti
set Cijena=Cijena*0.9
from Izleti as I
where 3< (select count(P.IzletID) from Prijave as P where P.IzletID=I.IzletID)


--6
go
create view PodaciOIzletu
as
	select I.Sifra,I.Naziv,format(I.DatumPolaska,'dd.MM.yyyy')as [Datum polaska],format(I.DatumPovratka,'dd.MM.yyyy') as [Datum povratka],I.Cijena,(select COUNT(P.IzletID) from Prijave as P where P.IzletID=I.IzletID) as [Broj prijava], 
	(select SUM(P.BrojOdraslih+P.BrojDjece) from Prijave as P where P.IzletID=I.IzletID) as [Ukupan broj putnika],(select SUM(P.BrojOdraslih) from Prijave as P where P.IzletID=I.IzletID) as [Broj odraslih],
	(select SUM(P.BrojDjece) from Prijave as P where P.IzletID=I.IzletID) as [Broj djece]
	from Izleti as I

--7
go
create procedure GetZaradaOdIzleta(
@Sifra nvarchar(10)
)
as begin
	select I.Naziv,SUM(I.Cijena*P.BrojOdraslih) as [Zarada od odraslih],SUM(I.Cijena*P.BrojDjece)*0.5 as [Zarada od djece],SUM(I.Cijena*P.BrojDjece*0.5+I.Cijena*P.BrojOdraslih) as [Ukupna zarada]
	from Izleti as I inner join Prijave as P on I.IzletID=P.IzletID
	where I.Sifra like @Sifra
	group by I.Naziv
end

exec GetZaradaOdIzleta 'IZLET0002'


--8
go
create table IzletiHistorijaCijena(
IHCID int constraint PK_IHC primary key identity(1,1),
IzletID int constraint FK_IHC_Izleti foreign key references Izleti(IzletID),
DatumIzmjene date not null,
StaraCijena decimal not null,
NovaCijena decimal not null
)
go
create trigger update_price_Izlet
on Izleti
After Update
as begin
	Insert into IzletiHistorijaCijena
	select I.IzletID,SYSDATETIME(),d.Cijena,I.Cijena
	from inserted as I inner join deleted as d on d.IzletID=I.IzletID
end

select *
from IzletiHistorijaCijena

go
select I.Naziv,I.DatumPolaska,I.DatumPovratka,I.Cijena, IHC.DatumIzmjene,IHC.StaraCijena,IHC.NovaCijena
from Izleti as I inner join IzletiHistorijaCijena as IHC on I.IzletID=IHC.IzletID


--9
go
delete Klijenti
from Klijenti as K left outer join Prijave as P on P.KlijentID=K.KlijentID
where P.IzletID is null


--10
backup database IB170059v5
to disk = 'E:\Backup\IB170059v5FULL.back'

backup database IB170059v5
to disk = 'E:\Backup\IB170059v5DIFF.back'
with differential
 

