--1
go
create database IB170059v6
go
use IB170059v6

go
create table Zaposlenici(
ZaposlenikID int constraint PK_Zaposlenici primary key,
Ime nvarchar(30) not null,
Prezime nvarchar(30) not null,
Spol nvarchar(10) not null,
JMBG nvarchar(13) not null,
DatumRodjenja date not null default sysdatetime(),
Adresa nvarchar(100) not null,
Email nvarchar(100) not null constraint UQ_Email unique,
KorisnickoIme nvarchar(60) not null,
Lozinka nvarchar(30) not null,
)
go
create table Artikli(
ArtikalID int constraint PK_Artikli primary key,
Naziv nvarchar(50) not null,
Cijena decimal not null,
StanjeNaSkladistu int not null
)
go
create table Prodaja(
ZaposlenikID int not null constraint FK_Prodaja_Zaposlenici foreign key references Zaposlenici(ZaposlenikID),
ArtikalID int not null constraint FK_Prodaja_Artikli foreign key references Artikli(ArtikalID),
Datum date not null default sysdatetime(),
constraint PK_Prodaja primary key(ZaposlenikID,ArtikalID,Datum),
Kolicina decimal not null
)

--2
go
insert Zaposlenici
select E.EmployeeID,E.FirstName,E.LastName,IIF(E.TitleOfCourtesy like 'Ms.' or E.TitleOfCourtesy like 'Mrs.','Zensko','Musko'),
FORMAT(E.BirthDate,'ddMMyyyy'),E.BirthDate,E.Country+', '+E.City+', '+E.[Address],
LOWER(E.FirstName+right(convert(nvarchar,Year(E.BirthDate)),2) +'@poslovna.ba'),
UPPER(E.FirstName+'.'+E.LastName),REVERSE( REPLACE(SUBSTRING(E.Notes,16,6)+left(E.Extension,2)+' '+convert(nvarchar,DATEDIFF(day,E.BirthDate,E.HireDate)),' ','#'))
from NORTHWND.dbo.Employees as E
where DATEDIFF(year,E.BirthDate,SYSDATETIME()) >60

go
insert Artikli
select P.ProductID,P.ProductName,P.UnitPrice,P.UnitsInStock
from NORTHWND.dbo.Products as P
where P.ProductID in (select distinct OD.ProductID
					  from NORTHWND.dbo.[Order Details] as OD inner join 
						   NORTHWND.dbo.Orders as O on OD.OrderID=O.OrderID
					  where O.OrderDate between '1997-08-01' and '1997-09-30')
order by P.ProductName 


go
insert Prodaja
select O.EmployeeID,OD.ProductID,O.OrderDate,OD.Quantity
from NORTHWND.dbo.[Order Details] as OD inner join NORTHWND.dbo.Orders as O on OD.OrderID=O.OrderID
where O.OrderDate between '1997-08-01' and '1997-09-30' and
	  O.EmployeeID in (select Z.ZaposlenikID from Zaposlenici as Z where Z.ZaposlenikID=O.EmployeeID)

--3
go
alter table Zaposlenici
alter column Adresa nvarchar(100) 

go
alter table Artikli
add Kategorija nvarchar(50)

go
update Artikli
set Kategorija='Hrana'
from Artikli
where ArtikalID%3=0

go
update Zaposlenici
set DatumRodjenja=DATEADD(year,2,DatumRodjenja)
from Zaposlenici 
where Spol like 'Zensko'

--4
update Zaposlenici
set KorisnickoIme = Lower(Ime)+'_'+substring(CONVERT(nvarchar,YEAR(DatumRodjenja)),2,2) +'_'+lower(Prezime)

--5
select A.Naziv,A.StanjeNaSkladistu,SUM(P.Kolicina) as[Narucena kolicina],
SUM(P.Kolicina) -A.StanjeNaSkladistu as [Potrebno naruciti]
from Artikli as A inner join Prodaja as P on A.ArtikalID=P.ArtikalID
group by A.Naziv,A.StanjeNaSkladistu
having SUM(P.Kolicina) -A.StanjeNaSkladistu >0

--6
go
select Z.Ime+' '+ Z.Prezime as 'Ime Prezime',A.Naziv as [Naziv artikla],ISNULL(A.Kategorija,'N/A') as 'Kategorija artikla',
CONVERT(nvarchar,ROUND(SUM(P.Kolicina),2))+' kom'as'Prodana kolicina', format(ROUND(SUM(P.Kolicina*A.Cijena),2),'C','ba-BA') as'Zarada od prodaje'
from Zaposlenici as Z inner join Prodaja as P on Z.ZaposlenikID=P.ZaposlenikID
inner join Artikli as A on P.ArtikalID=A.ArtikalID
where LEFT(Z.Adresa,3) like 'USA'
group by Z.Ime, Z.Prezime,A.Naziv,A.Kategorija

--7
go
select Z.Ime+' '+ Z.Prezime as 'Ime Prezime',A.Naziv as [Naziv artikla],ISNULL(A.Kategorija,'N/A') as 'Kategorija artikla',
CONVERT(nvarchar,ROUND(SUM(P.Kolicina),2))+' kom'as'Prodana kolicina', format(ROUND(SUM(P.Kolicina*A.Cijena),2),'C','ba-BA') as'Zarada od prodaje',
P.Datum
from Zaposlenici as Z inner join Prodaja as P on Z.ZaposlenikID=P.ZaposlenikID
inner join Artikli as A on P.ArtikalID=A.ArtikalID
where Z.Spol like 'Zensko' and (A.Naziv LIKE 'C%' or A.Naziv like 'G%') and A.Kategorija is null and
	P.Datum in ('1997-08-22','1997-09-22')  
group by Z.Ime, Z.Prezime,A.Naziv,A.Kategorija,P.Datum

--8
select Z.Ime+' '+ Z.Prezime as 'Ime Prezime',FORMAT(Z.DatumRodjenja,'dd.MM.yyyy'),Spol,COUNT(Z.ZaposlenikID) as 'Broj prodaja'
from Zaposlenici as Z inner join Prodaja as P on Z.ZaposlenikID=P.ZaposlenikID
where P.Datum between '1997-08-01' and '1997-08-31'
group by Z.Ime,Z.Prezime,Z.DatumRodjenja,Spol
order by [Broj prodaja] desc

--9
alter table Prodaja
drop constraint FK_Prodaja_Zaposlenici

alter table Prodaja 
add constraint FK_Prodaja_Zaposlenici foreign key (ZaposlenikID)
references Zaposlenici(ZaposlenikID)
ON DELETE CASCADE 

delete Zaposlenici
where Adresa like '%London%'

alter table Prodaja
drop constraint FK_Prodaja_Zaposlenici

alter table Prodaja 
add constraint FK_Prodaja_Zaposlenici foreign key (ZaposlenikID)
references Zaposlenici(ZaposlenikID)

select *
from Prodaja






