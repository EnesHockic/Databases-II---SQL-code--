--1
create database IB1700592

go
create table Klijenti(
KlijentID int constraint PK_KlijentID primary key identity(1,1),
Ime nvarchar(30) not null,
Prezime nvarchar(30) not null,
Telefon nvarchar(20) not null,
Mail nvarchar(50) not null constraint UQ_Mail unique,
BrojRacuna nvarchar(15) not null,
KorisnickoIme nvarchar(20) not null,
Lozinka nvarchar(20) not null,
)
go
create Table Transakcije(
TransakcijeID int constraint PK_TransakcijeID primary key identity(1,1),
Datum datetime not null,
TipTransakcije nvarchar(30) not null,
PosiljalacID int not null constraint FK_Posiljalac_Klijenti foreign key references Klijenti(KlijentID),
PrimalacID int not null constraint FK_Primalac_Klijenti foreign key references Klijenti(KlijentID),
Svrha nvarchar(50) not null,
Iznos decimal not null
)
--2
insert Klijenti(Ime,Prezime,Telefon,BrojRacuna,KorisnickoIme,Lozinka,Mail)
select top 10 P.FirstName,P.LastName,PP.PhoneNumber,C.AccountNumber,P.FirstName+'.'+P.LastName,RIGHT(Pass.PasswordHash,8),EA.EmailAddress
from AdventureWorks2014.Sales.Customer as C inner join AdventureWorks2014.Person.Person as P on C.PersonID=P.BusinessEntityID 
	inner join AdventureWorks2014.Person.PersonPhone as PP on PP.BusinessEntityID=P.BusinessEntityID
	inner join AdventureWorks2014.Person.Password as Pass on Pass.BusinessEntityID=P.BusinessEntityID
	inner join AdventureWorks2014.Person.EmailAddress as EA on EA.BusinessEntityID=P.BusinessEntityID
order by NEWID()

go
INSERT INTO Transakcije
VALUES ('2016-01-01','TIP I',122,122,'Svrha 1',400),
       ('2016-02-02','TIP I',122,123,'Svrha 2',300),
	   ('2016-03-03','TIP II',123,122,'Svrha 3',200),
	   ('2015-04-04','TIP I',122,125,'Svrha 4',100),
	   ('2015-01-05','TIP II',123,124,'Svrha 5',500),
	   ('2015-05-06','TIP I',126,122,'Svrha 6',600),
	   ('2016-06-07','TIP I',127,123,'Svrha 7',700),
       ('2015-04-08','TIP II',125,122,'Svrha 8',800),
	   ('2017-03-09','TIP I',132,123,'Svrha 9',400),
	   ('2017-02-10','TIP II',131,125,'Svrha 10',300),
	   ('2017-01-11','TIP I',130,127,'Svrha 11',400),
	   ('2017-07-12','TIP II',129,122,'Svrha 12',800)
GO

select*
from Klijenti
--3
create nonclustered index IndeksImePrezime
on Klijenti(Ime,Prezime) include (BrojRacuna)

go

select Ime,Prezime,BrojRacuna
from Klijenti
where Ime like 'A%'

go
Alter index IndeksImePrezime on Klijenti
disable 

--4
go
create procedure UpisKlijenta(
@Ime nvarchar(30),@Prezime nvarchar(30),
@Telefon nvarchar(20),@Mail nvarchar(50),
@BrojRacuna nvarchar(15), @KorisnickoIme nvarchar(20),
@Lozinka nvarchar(20)
)
as begin
insert Klijenti(Ime,Prezime,Telefon,Mail,BrojRacuna,KorisnickoIme,Lozinka)
values (@Ime,@Prezime,@Telefon,@Mail,@BrojRacuna,@KorisnickoIme,
		@Lozinka)
end

go
exec UpisKlijenta Enes,Hockic,'062751698','enes.hockic@gmail.com','40617652135','enes.hockic','askmadasd123'

select*
from Klijenti


--5
go
create view DetaljanPrikazTransakcija
as
select T.Datum,T.TipTransakcije,Posiljaoc.Ime+' '+Posiljaoc.Prezime as 'Ime i Prezime Posiljaoca',Posiljaoc.BrojRacuna as 'Broj racuna Posiljaoca',
	   Primalac.Ime+' '+Primalac.Prezime as 'Ime i Prezime Primaoca',Primalac.BrojRacuna as 'Broj racuna primaoca',T.Svrha,T.Iznos
from Transakcije as T inner join Klijenti as Posiljaoc on T.PosiljalacID=Posiljaoc.KlijentID
     inner join Klijenti as Primalac on Primalac.KlijentID=T.PrimalacID
	 
go
select *
from DetaljanPrikazTransakcija

--6
go
create procedure TransakcijeProvedeneSaRacuna(
@BrojRacunaPosiljaoca nvarchar(15)
)
as
begin
	select*
	from DetaljanPrikazTransakcija as D
	where D.[Broj racuna Posiljaoca] like @BrojRacunaPosiljaoca
end

go

exec TransakcijeProvedeneSaRacuna AW00020632

--7
select YEAR(Datum),SUM(Iznos)
from Transakcije
group by YEAR(Datum)
order by YEAR(Datum)

--8
go
create procedure BrisanjeKlijenta(
@Ime nvarchar(20),@Prezime nvarchar(30)
)
as
begin
	delete
	from Transakcije 
	where PosiljalacID =(select K.KlijentID from Klijenti as K where Ime like @Ime and @Prezime like Prezime)
	or	PrimalacID =(select K.KlijentID from Klijenti as K where Ime like @Ime and @Prezime like Prezime)

	delete 
	from Klijenti
	where Ime like @Ime and Prezime like @Prezime


end
go
exec BrisanjeKlijenta 'Marcus', 'Stewart'

--9
go
create procedure PretragaVIEWAPoRacunu(
@BrojRacunaPosiljaoca nvarchar(15)=NULL,
@PrezimePosiljaoca nvarchar(30)=NULL
)
as begin
	if(@BrojRacunaPosiljaoca IS NULL AND @PrezimePosiljaoca is null)
	(select *
	from DetaljanPrikazTransakcija)
	else
	(select *
	from DetaljanPrikazTransakcija
	where @BrojRacunaPosiljaoca like [Broj racuna Posiljaoca]
	or @PrezimePosiljaoca like SUBSTRING([Ime i Prezime Posiljaoca],CHARINDEX(' ',[Ime i Prezime Posiljaoca])+1,51)
	)
end

select*
from DetaljanPrikazTransakcija

exec PretragaVIEWAPoRacunu 
exec PretragaVIEWAPoRacunu 'AW00024957'
exec PretragaVIEWAPoRacunu @PrezimePosiljaoca='Hockic'
exec PretragaVIEWAPoRacunu 'AW00024957','Hockic'
exec PretragaVIEWAPoRacunu '40617652135','Hockic'

--10
backup database IB1700592
to disk = 'E:\Backup\IB1700592.bak'
go

backup database IB1700592
to disk = 'E:\Backup\IB1700592DIFF.bak'
with differential









