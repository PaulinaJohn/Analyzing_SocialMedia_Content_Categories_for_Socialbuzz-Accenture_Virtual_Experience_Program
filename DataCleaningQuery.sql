-- Social buzz Data cleaning and merging script.
-- I used MSSQL for this task.


-- The first task is strictly about cleaning each of the three datasets provided.
-- Creating Schema
CREATE  SCHEMA socialbuzz;

/*Although I wrote a query to create the schema for this task, 
going forward, I will approach the task like I am a junior Data Analyst who has been restricted from using most DDL and DML languages when working with this database, 
but I have been asked to fetch a cleaned subset of each of the three datasets that will be needed to execute the requirements from Socialbuzz anyways. 
Oftentimes, intern and junior analysts are restricted from such administrator privileges and only allowed to use mainly query language and commands to get tasks done,
so, it helps to get used to how to achieve what's required without being held back by the restriction.
This is one way I demonstrate my problem-solving skill and analytical mindset.

There are usually a number of ways to solve these problems.
However, a SELECT statement using a number of commands to mop up dirty data issues, coupled with a WHERE clause where necessary, works in this case. 
I can save the cleaned dataset as a view and export it as a csv file.
*/

-- Previewing the datasets after importing them. Note that MSSQL is not case-sensitive

SELECT * FROM socialbuzz.Content;
SELECT * FROM socialbuzz.Reactions;
SELECT * FROM socialbuzz.ReactionTypes;

-- Let's check for duplicates
SELECT DISTINCT * FROM socialbuzz.Content;
SELECT DISTINCT * FROM socialbuzz.Reactions;
SELECT DISTINCT * FROM socialbuzz.ReactionTypes;

--Each of the datasets return the same number of rows with or without the DISTINCT command so, no duplicate rows in the datasets

--Cleaning the datasets
/* From these datasets, we need to
- remove rows that have null values
- remove columns that are outrightly redundant- like column1 in all the datasets. The header for this column was auto-generated from a user-defined index in the csv file during import into the database.
and was not initially named in the orginal dataset.
-Collect out columns relevant to the task from each dataset.

Datatypes were correctly infered at import so, all the columns are in the right datatype.

To avoid creating more than one resulting output and having to query the result again to achieve the final cleaned dataset, 
I will work towards achieving all the aforelisted cleaning steps in one query for each of the datasets.
*/

/* Cleaning the Content table

I am going to remove the null values without using the 'DELETE' statement- No DDLs and DMLs, remember. I will only use the CREATE statement to create the final views.
Then, since I am also going to subset the data for only those columns relevant to the project,
I will just leave out column1 with the other irrelevant columns as I do this.
I will also do some data transformation, like renaming some columns to make them more descriptive, where needed.

The columns I need from the content dataset are content ID, category, content type.
*/
-- From inspecting table description, only the URL column is not constrained to 'NOT NULL' and it is the only column with null values.
-- I don't need the column anyways so we'll just exclude it from my final result instead of using it in a WHERE clause to get rid of rows with null values.

-- I checked for distinct values in the Category column. So I can address all dirty data issues at once.
SELECT DISTINCT Category
FROM socialbuzz.Content

-- There is value inconsistency in the column. Some of the categories have multiple variants due to some values starting and ending with double quotes.
-- Also, there is inconsitency in case for some values. All these, I'll address when subseting the final, cleaned dataset.

-- I also checked the 'Type' columnn
SELECT DISTINCT TYPE
FROM socialbuzz.Content
-- No value inconsistency in this column

-- Now, getting the cleaned dataset.

CREATE VIEW socialbuzz.CleanedContent AS

SELECT Content_ID,  LOWER(REPLACE(Category,'"', '')) AS Category, Type AS Content_Type -- I used the 'REPLACE' function to get rid of the double quotes. 
--Note that REPLACE is not a DML as it doesn't get rid of the value inconsistency issue in the original dataset. The changes only reflect in the cleaned dataset.
FROM
socialbuzz.Content

-- I used 'Script table as' to see the table description, so as to identify columns not constrained as 'Not Null' as these are the columns that could have null values.
-- Only the URL column contains null values and we don't need the column itself so, no need to add a WHERE clause to filter for non-null rows.
-- In a case where there are many columns, use 'Design Query in Editor' to get a list of all the columns, then relevant columns can be copied into the query.


-- Next, working on the 'Reactions' data.
-- The columns we need from this data are 'Content_ID' and reaction type and Date- to see if there is a trend in content popularity

-- I checked for value inconsistency in the 'Type'(In this case, reaction type) column.
SELECT DISTINCT Type
FROM socialbuzz.Reactions

-- No value inconsistency but there are null values, which I will address in the query that gets me the cleaned dataset.

-- Geting the cleaned dataset.
CREATE VIEW socialbuzz.CleanedReactions AS

SELECT Content_ID, Type as Reaction_Type, CAST(Datetime AS Date) AS Date
FROM socialbuzz.Reactions
WHERE Type IS NOT NULL-- This is the only column needed that has null values so, I used it in my WHERE clause.

-- Lastly, working on the 'ReactionTypes' data.
-- I'll only take out Column1 from this dataset. I'll keep every other column then, rename 'Type' as 'Reaction_Type' and 'Score' as 'Reaction_Score'

-- Let's check for value inconstency in the 'Sentiment' and 'Type' columns.
SELECT DISTINCT Sentiment
FROM socialbuzz.ReactionTypes

SELECT DISTINCT Type
FROM socialbuzz.ReactionTypes

--No Value inconsistency in both columns. Also, none of the columns in this dataset has null values.

-- Getting the cleaned dataset.
CREATE VIEW socialbuzz.CleanedReactionTypes AS

SELECT Type AS Reaction_Type, Sentiment, Score AS Reaction_Score
FROM socialbuzz.ReactionTypes


--PS: For the export process, you may want to have a csv file already created and should be empty.
--Exporting a table or view in the MSSQL database used meant appending new rows to existing rows in a csv file 
--and did not overide existing rows. I hope to investigate this and find a high-level solution soon. 
--But for now, my low-level solution is to ensure I already have a csv file I am exporting into and it is empty.
-- You can open the csv file in notepad, for example, clear out existing data, if necessary, and save.

/*
Next Task.
The goal of this task is to merge all three datasets into a final dataset that has only the columns that will be used in our analysis.
The main aim of the project is; 
"An Analysis of Socialbuzz's content categories showing the top 5 categories with the largest popularity".*/

--So, I will do this using 2 Joins, a subquery, a CTE, and save the entire result as a view
--The final columns we need are content ID, category, content type, reaction type, sentiment, reaction score and Date
-- I will query the views earlier created to achieve this.

SELECT * FROM socialbuzz.CleanedContent;
SELECT * FROM socialbuzz.CleanedReactions;
SELECT * FROM socialbuzz.CleanedReactionTypes;

CREATE VIEW socialbuzz.merged_socialbuzz_data_data AS -- the view
WITH final_cte AS -- the Common table expression - CTE
(SELECT r.Content_ID, c.Category, c.Content_Type, r.Reaction_Type,  r.Date -- I am listing the columns because I want them to be arranged in a particular order
FROM socialbuzz.CleanedReactions AS r						--) the subquery
JOIN socialbuzz.CleanedContent AS c -- Inner Join  
ON r.Content_ID = c.Content_ID) 

SELECT f.Content_ID, f.Category, f.Content_Type, f.Reaction_Type, t.Sentiment, t.Reaction_Score, f.Date -- The new query-- Listing the columns for same reason here. I could as well just say * for final_cte, but doesn't give me the order I want.
FROM final_cte AS f
JOIN socialbuzz.CleanedReactionTypes AS t  -- Inner Join  
ON f.Reaction_Type = t.Reaction_Type

/*
Now that we have a final, merged dataset, the next task is to get the top 5 most popular content categories. 
To achieve this, I need to perform an aggregation of total reaction score by content category, i.e, get the total reaction score for each category. 
This can be done here in MSSQL using a simple SELECT statement plus the GROUPBY command.
but I'll like to do this in a Spreadsheet. This is just to demonstrate my ability to work with different technologies (Microsoft Excel or Google Sheet can be used. I'll be using Google Sheets)
So, I will end here by exporting my view into a CSV file in preparation for analysis in a Spreadsheet.

Thank you
*/
