--1
create database IB170059v3

go
create table Klijenti(
KlijentID int identity(1,1) constraint PK_KlijentID primary key,
Ime nvarchar(50) not null,
Prezime nvarchar(50) not null,
Grad nvarchar(50) not null,
Email nvarchar(50) not null,
Telefon nvarchar(50) not null,
)

go
create table Racuni(
RacunID int identity(1,1) constraint PK_RacunID primary key,
KlijentID int foreign key references Klijenti(KlijentID),
DatumOtvaranja date not null,
TipRacuna nvarchar(50) not null,
BrojRacuna nvarchar(16) not null,
Stanje decimal not null,
)
go
create table Transakcije(
TransakcijaID int identity(1,1) constraint PK_TransakcijaID primary key,
RacunID int foreign key references Racuni(RacunID),
Datum date not null,
Primatelj nvarchar(50) not null,
BrojRacunaPrimatelja nvarchar(16) not null,
MjestoPrimatelja nvarchar(50) not null,
AdresaPrimatelja nvarchar(50) null,
Svrha nvarchar(200) null,
Iznos decimal not null
)


--2
go
create unique nonclustered index Index_Klijenti_Mail
on Klijenti(Email)

--3
go
create procedure UnosRacuna(
@KlijentID int,@TipRacuna nvarchar(50),
@BrojRacuna nvarchar(16), @Stanje decimal
)
as begin
	insert into Racuni(KlijentID,DatumOtvaranja,TipRacuna,BrojRacuna,Stanje)
	values (@KlijentID,SYSDATETIME(),@TipRacuna,@BrojRacuna,@Stanje)
end

insert into Klijenti
values ('Enes','Hockic','Mostar','enes.hockic@gmail.com','062-771/404')

select * 
from Transakcije


exec UnosRacuna 1,'commercial','03651461813584',356.15

--4
go
insert Klijenti
select LEFT(ContactName,CHARINDEX(' ',ContactName)),RIGHT(ContactName,LEN(ContactName)-CHARINDEX(' ',ContactName)),City,REPLACE(ContactName,' ','.')+'@northwind.ba',Phone
from NORTHWND.dbo.Customers as C
where CustomerID in (select CustomerID from NORTHWND.dbo.Orders as O where YEAR(OrderDate)=1996)

select *
from Klijenti
go
insert into Racuni
values (166,SYSDATETIME(),'private','025318514861',202.2),
 (170,SYSDATETIME(),'student','ST5318514861',302),
 (171,SYSDATETIME(),'university','ST25312384861',50),
 (170,SYSDATETIME(),'private','0205315362061',0),
 (183,SYSDATETIME(),'private','213103516651',2131.251),
 (162,SYSDATETIME(),'private','02265411203',350),
 (191,SYSDATETIME(),'private','1324246313',123513),
 (162,SYSDATETIME(),'private','1045364211214',32561),
 (162,SYSDATETIME(),'private','04523645237',0),
 (173,SYSDATETIME(),'private','0455623424334',1231)

 select*
 from Racuni

 go
 insert Transakcije
 select top 10 12,O.OrderDate,O.ShipName,convert(nvarchar,O.OrderID)+'00000123456',O.ShipCity,ShipAddress,NULL,(SELECT SUM(UnitPrice*Quantity) from NORTHWND.dbo.[Order Details] as OD where OD.OrderID=O.OrderID)
 from NORTHWND.dbo.Orders as O
 order by newID()

 --5
 go

 update Racuni
 set Stanje+=500
 from Racuni as R inner join Klijenti as K on K.KlijentID=R.KlijentID
 where K.Grad like 'London' and Month(R.DatumOtvaranja)=6


 --6
 go
 create view SpecialViewV1
 as
 select K.Ime+' '+K.Prezime as 'Ime i prezime', K.Grad, K.Email,K.Telefon,R.TipRacuna,R.BrojRacuna,R.Stanje,T.Primatelj,T.BrojRacunaPrimatelja,T.Iznos
 from Klijenti as K left outer join Racuni as R on K.KlijentID=R.KlijentID
	  left outer join Transakcije as T on R.RacunID=T.RacunID

go
select *
from SpecialViewV1

--7
go
create procedure PodaciOVlasnikuRacuna
(
@BrojRacuna nvarchar(15)=NULL
)
as begin
	select [Ime i prezime],Grad,Telefon,ISNULL(BrojRacuna,'N/A'),ISNULL(CONVERT(varchar,Stanje),'N/A'),ISNULL(CONVERT(varchar,SUM(Iznos)),'N/A')as 'Ukupan Iznos'
	from SpecialViewV1
	where BrojRacuna like @BrojRacuna or @BrojRacuna is null
	group by [Ime i prezime],Grad,Telefon,BrojRacuna,Stanje
end

exec PodaciOVlasnikuRacuna '0455623424334'

alter table Transakcije
add constraint FK_Transakcije_Racuni foreign key (RacunID) references Racuni(RacunID)
--8
go
create procedure BrisanjeKlijentaNjegovogRacunaISvihTransakcija
(@KlijentID int )
as begin
	alter table Racuni
	drop constraint FK_Racuni_Klijenti

	alter table Racuni
	add constraint FK_Racuni_Klijenti foreign key (KlijentID) references Klijenti(KlijentID)
	on delete cascade

	alter table Transakcije
	drop constraint FK_Transakcije_Racuni

	alter table Transakcije
	add constraint FK_Transakcije_Racuni foreign key (RacunID) references Racuni(RacunID)
	on delete cascade

	delete Klijenti
	where KlijentID=@KlijentID

	alter table Racuni
	drop constraint FK_Racuni_Klijenti

	alter table Racuni
	add constraint FK_Racuni_Klijenti foreign key (KlijentID) references Klijenti(KlijentID)

	alter table Transakcije
	drop constraint FK_Transakcije_Racuni

	alter table Transakcije
	add constraint FK_Transakcije_Racuni foreign key (RacunID) references Racuni(RacunID)

end
 
 exec BrisanjeKlijentaNjegovogRacunaISvihTransakcija 162


--9
go
create procedure UvecajStanjeRacuna(
@Grad nvarchar(20),@Mjesec int,@UvecanjeIznosa decimal
)
as begin
  update Racuni
  set Stanje+=@UvecanjeIznosa
  from Racuni as R inner join Klijenti as K on K.KlijentID=R.KlijentID
  where K.Grad like @Grad and Month(R.DatumOtvaranja)=@Mjesec
end


exec UvecajStanjeRacuna 'Marseille',6,300

--10
backup database IB170059v3
to disk ='E:\BP2\Backup.bak'

backup database IB170059v3
to disk ='E:\BP2\BackupDIFF.bak'
with differential











