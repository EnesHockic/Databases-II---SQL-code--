--1
go 
create database IB170059v4


go
create table Otkupljivaci( 
OtkupljivacID int constraint PK_Otkupljivaci primary key ,
Ime nvarchar(50) not null,
Prezime nvarchar(50) not null,
DatumRodjenja date not null default SYSDATETIME(),
JMBG nvarchar(13) not null,
Spol nvarchar(1) not null,
Grad nvarchar(50) not null,
Adresa nvarchar(100) not null,
Email nvarchar(100) not null constraint UQ_Email unique,
Aktivan bit not null default 1
)
go
create table Proizvodi(
ProizvodID int constraint PK_Proizvodi primary key ,
Naziv nvarchar(50) not null,
Sorta nvarchar(50) not null,
OtkupnaCijena decimal not null,
Opis text
)
go
create table OtkupProizvoda(
OtkupljivacID int not null,
ProizvodID int not null,
Datum date not null default SYSDATETIME(),
constraint PK_OtkupProizvoda primary key(OtkupljivacID,ProizvodID,Datum),
constraint FK_Otkup_Otkupljivac foreign key (OtkupljivacID) references Otkupljivaci(OtkupljivacID),
constraint FK_Otkup_Proizvod foreign key (ProizvodID) references Proizvodi(ProizvodID),
Kolicina decimal not null,
BrojGajbica int not null
)
delete Otkupljivaci
--2
insert Otkupljivaci(OtkupljivacID,Ime,Prezime,JMBG,Spol,Grad,Adresa,Email,Aktivan)
select Top 5  E.EmployeeID,E.FirstName,E.LastName,convert(nvarchar,REVERSE(YEAR(E.BirthDate)))+convert(nvarchar,DAY(E.BirthDate))+convert(nvarchar,MONTH(E.BirthDate))+convert(nvarchar,RIGHT(E.HomePhone,4)),CAST(case when E.TitleOfCourtesy like 'Ms.' or  E.TitleOfCourtesy like 'Mrs.' then 'Z' else 'M' end as nvarchar),
E.City,REPLACE(E.[Address],' ','_'),E.FirstName+'_'+E.LastName+'@edu.fit.ba',1
from NORTHWND.dbo.Employees as E
where E.EmployeeID != 10
order by E.BirthDate desc

go
insert Proizvodi
select P.ProductID, P.ProductName,(select C.CategoryName from NORTHWND.dbo.Categories as C where P.CategoryID=C.CategoryID),P.UnitPrice,(select C.[Description] from NORTHWND.dbo.Categories as C where P.CategoryID=C.CategoryID)
from NORTHWND.dbo.Products as P

select *
from NORTHWND.dbo.Employees

SELECT * FROM OtkupProizvoda

go
insert OtkupProizvoda
select top 100 O.EmployeeID,OD.ProductID,O.OrderDate,OD.Quantity*8,OD.Quantity
from NORTHWND.dbo.[Order Details] as OD inner join NORTHWND.dbo.Orders as O on OD.OrderID=O.OrderID
where O.EmployeeID in (select OtkupljivacID from Otkupljivaci) and 0= (select count(OP.OtkupljivacID) from OtkupProizvoda as OP where O.EmployeeID=OP.OtkupljivacID and OD.ProductID=OP.ProizvodID and O.OrderDate=OP.Datum)

select O.EmployeeID,OD.ProductID,O.OrderDate,count(OD.ProductID)
from NORTHWND.dbo.[Order Details] as OD inner join NORTHWND.dbo.Orders as O on OD.OrderID=O.OrderID
where O.EmployeeID in (select OtkupljivacID from Otkupljivaci)
group by O.EmployeeID,OD.ProductID,O.OrderDate

select O.EmployeeID,OD.ProductID,O.OrderDate,OD.Quantity*8,OD.Quantity
from NORTHWND.dbo.[Order Details] as OD inner join NORTHWND.dbo.Orders as O on OD.OrderID=O.OrderID
where O.EmployeeID in (select OtkupljivacID from Otkupljivaci) and (select count(OD2.ProductID) from NORTHWND.dbo.[Order Details] as OD2 inner join NORTHWND.dbo.Orders as O2 on OD2.OrderID=O2.OrderID where O.EmployeeID=O2.EmployeeID AND OD.ProductID=OD2.ProductID and O.OrderDate=O2.OrderDate) >1
--3
alter table Otkupljivaci
alter column Adresa nvarchar(100)

go
alter table Proizvodi
add TipProizvoda nvarchar(50)

go
update Proizvodi
set TipProizvoda ='Voće'
where ProizvodID%2=0

--4
go
update Otkupljivaci
set Aktivan =0
where Grad not like 'London' and YEAR(DatumRodjenja)>=1960

--5
go
update Proizvodi
set OtkupnaCijena +=5.45
where Sorta like '%/%'

--6
go
select O.Ime+' '+O.Prezime as [Ime i prezime], P.Naziv as'Naziv proizvoda', SUM(OP.Kolicina) as 'Ukupna kolicina',SUM(OP.BrojGajbica) as 'Ukupno gajbica'
from Otkupljivaci as O inner join OtkupProizvoda as OP on O.OtkupljivacID=OP.OtkupljivacID
inner join Proizvodi as P on OP.ProizvodID=P.ProizvodID
group by O.Ime,O.Prezime, P.Naziv
order by P.Naziv ASC,[Ukupna kolicina] DESC

--7
go
select top 10 P.Naziv,FORMAT(ROUND(SUM(OP.Kolicina*P.OtkupnaCijena),2),'C','ba-BA') as 'Zarada',SUM(OP.Kolicina) as 'Kolicina'
from Proizvodi as P inner join OtkupProizvoda as OP on P.ProizvodID=OP.ProizvodID
where OP.Datum between '1996-12-24' and '1997-08-16'
group by P.Naziv
having SUM(OP.Kolicina)>1000
order by SUM(OP.Kolicina*P.OtkupnaCijena) desc

DECLARE @d DATETIME = GETDATE();  
SELECT FORMAT( @d, 'dd/MM/yyyy', 'en-US' ) AS 'DateTime Result'  
       ,FORMAT(123456789,'###-##-####') AS 'Custom Number Result'
select*
from Proizvodi
where Sorta like '%/%'


create table Sorta(
Naziv nvarchar(50) constraint PK_Sorta primary key,
Opis text
)
insert into Sorta
select P.Sorta, P.Opis
from Proizvodi as P
where not exists (select 1 from Sorta as S where S.Naziv like P.Sorta)






