/*--ETL
--Extraction
--- Importing Data using OPENROWSET and BULK INSERT	
sp_configure 'show advanced options', 1;
RECONFIGURE;
GO
sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
GO


--USE PortfolioProject 

GO 
EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1 
GO 
EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1 
GO 


---- Using BULK INSERT

--USE PortfolioProject;
GO
Drop Table if exists nashvilleHousing
CREATE TABLE nashvilleHousing
(UniqueID INT,
ParcelID INT,
LandUse NVARCHAR(40),
PropertyAddress NVARCHAR(255),
SaleDate Date,
SalePrice INT,
LegalReference NVARCHAR(255),
SoldAsVacant NVARCHAR(255),
OwnerName NVARCHAR(255),
OwnerAddress NVARCHAR(255),
Acreage float,
TaxDistrict NVARCHAR(255),
LandValue INT,
BuildingValue INT,
TotalValue INT,
YearBuilt INT,
Bedrooms INT,
FullBath INT,
HalfBath INT,
)
GO
GO
bulk
	insert nashvilleHousing
		from 'C:\Users\yuqi5\OneDrive\Desktop\COVID DEATH PROJECT\Data Cleaning\Nashville Housing Data for Data Cleaning.csv'
		with
			(
			ROWTERMINATOR = '0x0a',
			FIELDTERMINATOR = ',',
			firstrow=2,
			FORMAT = 'CSV',
			DATAFILETYPE = 'widechar'
			)
GO

---- Using OPENROWSET
--USE PortfolioProject;
--GO
--SELECT * INTO nashvilleHousing
--FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
--    'Excel 12.0; Database=C:\Users\yuqi5\OneDrive\Desktop\COVID DEATH PROJECT\Data Cleaning\Nashville Housing Data for Data Cleaning.csv', [Sheet1$]);
--GO
*/



-----------------------------------
/*
Cleaning Data in SQL Queries
*/

select * 
from PortfdforlioProject..NashvilleHousing

---------------------------------------------
-- Standardize Data Format
-- Removing the time 00:00:00 from each dates since they don't make any sense here
-- Create a new column called SalesDate1 for the converted dates 
select SalesDate, CONVERT(Date, SaleDate)
from PortfdforlioProject..NashvilleHousing

Alter Table PortfdforlioProject..NashvilleHousing
ADD SalesDate1 Date;

Update PortfdforlioProject..NashvilleHousing
SET SalesDate1 = CONVERT(Date, SaleDate)

--------------------------------------
--Populate Property Address data
-- First look at NULL values
select *
from PortfdforlioProject..NashvilleHousing
where PropertyAddress is null

select *
from PortfdforlioProject..NashvilleHousing
order by ParcelID

--By observing the ParcelID, same ParcelId holds the same PropertyAddress
--Idea: Let's populate null propertyAddress with other address who has the same ParcelID

select tb1.ParcelID, tb1.PropertyAddress, tb2.ParcelID, tb2.PropertyAddress, ISNULL(tb1.PropertyAddress, tb2.PropertyAddress)
from PortfdforlioProject..NashvilleHousing as tb1
join PortfdforlioProject..NashvilleHousing as tb2
	on tb1.ParcelID = tb2.ParcelID
	AND tb1.[UniqueID ] <> tb2.[UniqueID ]
where tb1.PropertyAddress is null

update tb1
SET PropertyAddress =  ISNULL(tb1.PropertyAddress, tb2.PropertyAddress)
from PortfdforlioProject..NashvilleHousing as tb1
join PortfdforlioProject..NashvilleHousing as tb2
	on tb1.ParcelID = tb2.ParcelID
	AND tb1.[UniqueID ] <> tb2.[UniqueID ]
where tb1.PropertyAddress is null

---------------------------------------------------
--Breaking out Address Into Indivdual Columns (Address, City, State)
--Observe Address -> dlimiter is a comma
select PropertyAddress
from PortfdforlioProject..NashvilleHousing
--where PropertyAddress is null

Select
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) as City
from PortfdforlioProject..NashvilleHousing
--where PropertyAddress like ','  -- test if all comma is removed 

Alter Table PortfdforlioProject..NashvilleHousing
ADD PropertySplitedAddress Nvarchar(255);

update NashvilleHousing
SET PropertySplitedAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

Alter Table PortfdforlioProject..NashvilleHousing
ADD PropertySplitedCity Nvarchar(255);

update NashvilleHousing
SET PropertySplitedCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))


select *
from PortfdforlioProject..NashvilleHousing

-- Breaking out OwnerAddress
-- observe data -> more complicated than PropertyAddress
select OwnerAddress
from PortfdforlioProject..NashvilleHousing

select
PARSENAME(REPLACE(OwnerAddress, ',','.'),3),
PARSENAME(REPLACE(OwnerAddress, ',','.'),2),
PARSENAME(REPLACE(OwnerAddress, ',','.'),1)
from PortfdforlioProject..NashvilleHousing

Alter Table PortfdforlioProject..NashvilleHousing
ADD OwnerSplitedAddress Nvarchar(255);

update NashvilleHousing
SET OwnerSplitedAddress = PARSENAME(REPLACE(OwnerAddress, ',','.'),3)

Alter Table PortfdforlioProject..NashvilleHousing
ADD OwnerSplitedCity Nvarchar(255);

update NashvilleHousing
SET OwnerSplitedCity = PARSENAME(REPLACE(OwnerAddress, ',','.'),2)

Alter Table PortfdforlioProject..NashvilleHousing
ADD OwnerSplitedStates Nvarchar(255);

update NashvilleHousing
SET OwnerSplitedStates = PARSENAME(REPLACE(OwnerAddress, ',','.'),1)

--------------------------------------------
--Change Y and N to Yes and No in 'Sold as Vacant' Field
-- Yes and No are the majority so transform 'Y' AND 'N'
Select Distinct SoldAsVacant, COUNT(SoldAsVacant)
from PortfdforlioProject..NashvilleHousing
group by SoldAsVacant
order by 2


Select SoldAsVacant,
Case when SoldAsVacant = 'Y' THEN 'Yes'
	 when SoldAsVacant = 'N' THEN 'No'
	 else SoldAsVacant
	 END
from PortfdforlioProject..NashvilleHousing

update NashvilleHousing
SET SoldAsVacant = Case when SoldAsVacant = 'Y' THEN 'Yes'
	 when SoldAsVacant = 'N' THEN 'No'
	 else SoldAsVacant
	 END

--------------------------------------------------------------------------
-- Remove Duplicates
WITH ROWNUMCTE AS(
select *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID) row_num
from PortfdforlioProject..NashvilleHousing
)
DELETE
from ROWNUMCTE
where row_num >1

--test
WITH ROWNUMCTE AS(
select *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID) row_num
from PortfdforlioProject..NashvilleHousing
)
select *
from ROWNUMCTE
where row_num >1

----------------------------------------------------------------
--Delete Unused Columns

select *
from PortfdforlioProject..NashvilleHousing

ALTER TABLE PortfdforlioProject..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate


ALTER TABLE PortfdforlioProject..NashvilleHousing
DROP COLUMN SaleDate