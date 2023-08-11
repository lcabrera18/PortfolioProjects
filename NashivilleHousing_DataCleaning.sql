/*

Cleaning Data in SQL Queries

*/

-- 1. Changing the Date Column Format

SELECT SaleDate, DATE_FORMAT(STR_TO_DATE(SaleDate, '%M %e, %Y'), '%Y-%m-%d')
FROM Portfolio_DataCleaning.nashvillehousing;

UPDATE Portfolio_DataCleaning.nashvillehousing
SET SaleDate = DATE_FORMAT(STR_TO_DATE(SaleDate, '%M %e, %Y'), '%Y-%m-%d');


-- 2. Populate Property Address data

SELECT PropertyAddress
FROM Portfolio_DataCleaning.nashvillehousing
WHERE PropertyAddress is null;
-- ORDER BY ParcelID;

-- Doing a self join to find same ParcelIDs but different uniqueIDs 
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, COALESCE(a.PropertyAddress, b.PropertyAddress)
FROM Portfolio_DataCleaning.nashvillehousing a
JOIN Portfolio_DataCleaning.nashvillehousing b
ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

-- For MySQL a subquery is necessary to update the tables. 
UPDATE Portfolio_DataCleaning.nashvillehousing a
JOIN (
  SELECT a.ParcelID, COALESCE(a.PropertyAddress, b.PropertyAddress) AS UpdatedPropertyAddress
  FROM Portfolio_DataCleaning.nashvillehousing a
  JOIN Portfolio_DataCleaning.nashvillehousing b
  ON a.ParcelID = b.ParcelID
  AND a.UniqueID <> b.UniqueID
  WHERE a.PropertyAddress IS NULL
) AS subquery
ON a.ParcelID = subquery.ParcelID
SET a.PropertyAddress = subquery.UpdatedPropertyAddress;


-- 3. Breaking out Address into Individual Columns (Address, City, State)

SELECT 
-- Using LOCATE as CHARINDEX is not supported in MySQL
SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress)-1) as Address,
-- Using SUBSTRING_INDEX instead of SUBSTRING + LENGTH
SUBSTRING_INDEX(PropertyAddress, ',', -1) as City
FROM Portfolio_DataCleaning.nashvillehousing;


-- Creating new columns to populate with new info

ALTER TABLE Portfolio_DataCleaning.nashvillehousing
ADD COLUMN SplitAddress VARCHAR(255),
ADD COLUMN SplitCity VARCHAR(255);

-- Updating table with new columns
UPDATE Portfolio_DataCleaning.nashvillehousing AS nh
JOIN (
  SELECT
  UniqueID,
    SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress)-1) AS Address,
    SUBSTRING_INDEX(PropertyAddress, ',', -1) AS City
  FROM Portfolio_DataCleaning.nashvillehousing
) AS subquery
ON nh.UniqueID = subquery.UniqueID
SET nh.Address = subquery.Address,
    nh.City = subquery.City;

-- Breaking up Owner Address Column for Better Usability

SELECT 
SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'), '.', -1) AS OwnerSate,
TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -2), ',', 1)) AS OwnerCity,
SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'), '.', 1) AS OwnerSplitAddress
FROM Portfolio_DataCleaning.nashvillehousing;

ALTER TABLE Portfolio_DataCleaning.nashvillehousing
    ADD COLUMN OwnerState VARCHAR(255),
    ADD COLUMN OwnerCity VARCHAR(255),
    ADD COLUMN OwnerSplitAddress VARCHAR(255);

UPDATE Portfolio_DataCleaning.nashvillehousing
SET
    OwnerState = SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'), '.', -1),
    OwnerCity = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -2), ',', 1)),
    OwnerSplitAddress = SUBSTRING_INDEX(REPLACE(OwnerAddress, ',', '.'), '.', 1);




-- 4. Replacing Y and N to Yes and No in "Sold as Vacant" field
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM Portfolio_DataCleaning.nashvillehousing
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    END
FROM Portfolio_DataCleaning.nashvillehousing;

UPDATE Portfolio_DataCleaning.nashvillehousing
SET SoldAsVacant =
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    END;
    



-- 5. Deleting Unused Columns (For practice purposes only)
SELECT *
FROM Portfolio_DataCleaning.nashvillehousing;

ALTER TABLE  Portfolio_DataCleaning.nashvillehousing
DROP COLUMN TaxDistrict,
DROP COLUMN LandUse




