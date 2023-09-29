/*
Cleaning Data in SQL Queries

This SQL script is intended to clean and transform data in the table 'fifa21Raw' in the 'cleaningDataSQL' database. The script performs the following tasks:

1. Checks the existing data in the table.

2. Changes the unit of 'Height' from inches to centimeters and 'Weight' from pounds to kilograms.

3. Creates new columns 'inch' and 'feet' to store the separated inch and feet values from the 'Height' column, converts them to centimeters, and updates the 'Height' column accordingly.

4. Adds commas for players with multiple positions in the 'Positions' column.

5. Cleans and transforms the 'Value,' 'Wage,' and 'Release_Clause' columns into integer values, considering the currency symbols ('€') and units ('K' for thousands, 'M' for millions).

6. Renames the columns to reflect the currency (€) and units.

*/

-- Switch to the 'cleaningDataSQL' database.
USE cleaningDataSQL

-- Check the existing data in the 'fifa21Raw' table.
SELECT * 
FROM cleaningDataSQL.dbo.fifa21Raw

-- Change unit of 'Height' and 'Weight' columns.
UPDATE cleaningDataSQL.dbo.fifa21Raw
SET Weight = REPLACE(Weight, 'lbs', '');

-- Rename the 'Weight' column and change its data type.
EXEC sp_rename 'cleaningDataSQL.dbo.fifa21Raw.Weight', 'Weight(Kg)', 'COLUMN';
ALTER TABLE cleaningDataSQL.dbo.fifa21Raw
ALTER COLUMN "Weight(Kg)" FLOAT;

-- Convert 'Weight(Kg)' from pounds to kilograms.
UPDATE cleaningDataSQL.dbo.fifa21Raw
SET "Weight(Kg)" = ROUND("Weight(Kg)" * 0.45359237, 0)

-- Remove double quotes from 'Height' column.
UPDATE cleaningDataSQL.dbo.fifa21Raw
SET Height = REPLACE(Height, '"', '');

-- Create new columns 'inch' and 'feet' to store separated values.
ALTER TABLE cleaningDataSQL.dbo.fifa21Raw
ADD inch FLOAT, feet FLOAT 

-- Update 'inch' and 'feet' columns with converted values.
DECLARE @delimiter NVARCHAR(1) = '''';

UPDATE cleaningDataSQL.dbo.fifa21Raw
SET inch = SUBSTRING(Height, CHARINDEX(@delimiter, Height) + 1, LEN(Height) - CHARINDEX(@delimiter, Height)),
    feet = SUBSTRING(Height, 1, CHARINDEX(@delimiter, Height) - 1)

UPDATE cleaningDataSQL.dbo.fifa21Raw
SET inch = inch * 2.54,
    feet = feet * 30.48

-- Update 'Height' column with the combined value in centimeters.
UPDATE cleaningDataSQL.dbo.fifa21Raw
SET Height = ROUND(inch + feet, 0);

-- Rename the 'Height' column.
EXEC sp_rename 'cleaningDataSQL.dbo.fifa21Raw.Height', 'Height(Cm)', 'COLUMN';

-- Add commas for players with multiple positions in the 'Positions' column.
UPDATE cleaningDataSQL.dbo.fifa21Raw
SET Positions = REPLACE(Positions, ' ', ', ')

-- Clean and transform the 'Value,' 'Wage,' and 'Release_Clause' columns.
-- Check data
SELECT Value, Wage, Release_Clause
FROM cleaningDataSQL.dbo.fifa21Raw

-- Add temporary columns for value, wage, and release_clause conversion.
ALTER TABLE cleaningDataSQL.dbo.fifa21Raw
ADD tmpValue INT, tmpWage INT, tmpRe INT

-- Drop the temporary column (there's a typo, should be 'tmpValue,' 'tmpWage,' and 'tmpRe').
ALTER TABLE cleaningDataSQL.dbo.fifa21Raw
DROP COLUMN tmp

-- Remove currency symbols and units from 'Value,' 'Wage,' and 'Release_Clause' columns.
UPDATE cleaningDataSQL.dbo.fifa21Raw
SET Value = REPLACE(Value, '€', ''),
    Wage = REPLACE(Wage, '€', ''),
    Release_Clause = REPLACE(Release_Clause, '€', '')

-- Populate the temporary columns with conversion factors based on the unit.
UPDATE cleaningDataSQL.dbo.fifa21Raw
SET tmpValue =
    CASE
        WHEN CHARINDEX('M', Value) > 0 THEN 1000000 
        WHEN CHARINDEX('K', Value) > 0 THEN 1000
        ELSE 1
    END,
    tmpWage =
    CASE
        WHEN CHARINDEX('M', Wage) > 0 THEN 1000000
        WHEN CHARINDEX('K', Wage) > 0 THEN 1000
        ELSE 1
    END,
    tmpRe =
    CASE
        WHEN CHARINDEX('M', Release_Clause) > 0 THEN 1000000
        WHEN CHARINDEX('K', Release_Clause) > 0 THEN 1000
        ELSE 1
    END

-- Remove currency symbols and units from 'Value,' 'Wage,' and 'Release_Clause' columns.
UPDATE cleaningDataSQL.dbo.fifa21Raw
SET Value = REPLACE(Value, 'M', ''),
    Wage = REPLACE(Wage, 'M', ''),
    Release_Clause = REPLACE(Release_Clause, 'M', '')

UPDATE cleaningDataSQL.dbo.fifa21Raw
SET Value = REPLACE(Value, 'K', ''),
    Wage = REPLACE(Wage, 'K', ''),
    Release_Clause = REPLACE(Release_Clause, 'K', '')

-- Change the data types of 'Value,' 'Wage,' and 'Release_Clause' columns to FLOAT.
ALTER TABLE cleaningDataSQL.dbo.fifa21Raw
ALTER COLUMN "Value" FLOAT
ALTER TABLE cleaningDataSQL.dbo.fifa21Raw
ALTER COLUMN "Wage" FLOAT
ALTER TABLE cleaningDataSQL.dbo.fifa21Raw
ALTER COLUMN "Release_Clause" FLOAT;

-- Multiply 'Value,' 'Wage,' and 'Release_Clause' columns by the corresponding conversion factor.
UPDATE cleaningDataSQL.dbo.fifa21Raw
SET Value = Value * tmpValue,
    Wage = Wage * tmpWage,
    Release_Clause = Release_Clause * tmpRe

-- Rename columns to reflect the currency.
EXEC sp_rename 'cleaningDataSQL.dbo.fifa21Raw.Value', 'Value(€)', 'COLUMN';
EXEC sp_rename 'cleaningDataSQL.dbo.fifa21Raw.Wage', 'Wage(€)', 'COLUMN';
EXEC sp_rename 'cleaningDataSQL.dbo.fifa21Raw.Release_Clause', 'Release_Clause(€)', 'COLUMN';
