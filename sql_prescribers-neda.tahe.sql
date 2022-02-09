
--1. a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.


select npi, sum(total_claim_count) as total_claims, nppes_provider_first_name, nppes_provider_last_org_name
from prescription 
inner join prescriber 
USING (npi)
group by npi, nppes_provider_first_name, nppes_provider_last_org_name, specialty_description
order by total_claims desc
limit 1
   -- b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
select nppes_provider_first_name, 
	nppes_provider_last_org_name, 
	specialty_description, 
	npi, 
	sum(total_claim_count) as total_claims
from prescription 
inner join prescriber 
USING (npi)
group by npi, nppes_provider_first_name, nppes_provider_last_org_name, specialty_description --whatever left in select that is not aggregated on, needs to be on group by
order by total_claims desc
limit 1

--2. a. Which specialty had the most total number of claims (totaled over all drugs)?
select specialty_description, sum(total_claim_count) as claim_sum
from prescriber 
inner join prescription
using (npi)
group by specialty_description
order by claim_sum desc



   -- b. Which specialty had the most total number of claims for opioids?

select specialty_description, sum(total_claim_count) as claim_sum
from prescriber 
inner join prescription
using (npi)
inner join drug
using (drug_name)
where opioid_drug_flag = 'Y'
group by specialty_description
order by claim_sum desc


    --c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

SELECT DISTINCT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber
FULL JOIN prescription
ON prescriber.npi = prescription.npi --or: using(npi)
GROUP BY specialty_description
HAVING (SUM(total_claim_count) IS NULL)
ORDER BY total_claims;





   -- d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

--3. a. Which drug (generic_name) had the highest total drug cost?
select generic_name, sum(total_drug_cost)::money
from drug
inner join prescription
using (drug_name)
group by generic_name
order by sum(total_drug_cost) desc
limit 1




   -- b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.
select generic_name, round(sum(total_drug_cost/total_day_supply), 2)::money as cost_per_day
from drug
inner join prescription
using (drug_name)
group by generic_name
order by cost_per_day desc

			   

--4. a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

select drug_name,
case 
when opioid_drug_flag = 'Y' then 'opioid'
when antibiotic_drug_flag = 'Y' then 'antibiotic'
else 'neither'
end as drug_type
from drug
order by drug_type asc



   -- b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.



SELECT drug_type, SUM(total_drug_cost)::MONEY
FROM prescription as p 
FULL JOIN (
	SELECT drug_name, 
	CASE 
		WHEN opioid_drug_flag = 'Y' THEN 'opioid' -- Second case 
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic' -- Else clause + end 
		ELSE 'neither' 
	END AS drug_type FROM drug) AS flags 
USING (drug_name) 
WHERE drug_type = 'opioid' 
OR drug_type = 'antibiotic'
GROUP BY drug_type 
order by SUM(total_drug_cost:: MONEY) desc;


--5. a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.


select count(distinct cbsa)
from cbsa
join fips_county
using (fipscounty)
where state = 'TN'



    --b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.



select distinct cbsaname, sum(population) as pop
from cbsa 
inner join fips_county
using (fipscounty)
inner join population
using (fipscounty)
where state = 'TN'
or cbsaname like '%TN%'
group by cbsaname
order by pop desc


   -- c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

select county, population, state, cbsa
from population
left join fips_county
using (fipscounty)
left join cbsa
using (fipscounty)
where state = 'TN'
and cbsa.cbsa is null
order by population desc
limit 1


select county, population, state, cbsa
from population
left join fips_county
using (fipscounty)
left join cbsa
using (fipscounty)
where state = 'TN'
and cbsa.cbsa is null
order by population 
limit 1

--6. 

   -- a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
select  drug_name, sum(total_claim_count)
from prescription
where total_claim_count >= 3000 --first gets the claims that are bigger than 3000 then sums them up
group by drug_name
order by drug_name

  --  b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
select  drug_name, sum(total_claim_count) as s, opioid_drug_flag
from prescription
left join drug
using (drug_name)
where total_claim_count >= 3000
group by drug_name, opioid_drug_flag
order by s desc


   -- c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

select  drug_name,
sum(total_claim_count) as s,
opioid_drug_flag, 
nppes_provider_first_name, 
nppes_provider_last_org_name
from prescription
left join drug
using (drug_name)
left join prescriber
using (npi)
where total_claim_count >= 3000
group by drug_name, opioid_drug_flag, nppes_provider_first_name, 
nppes_provider_last_org_name
order by s desc


--7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid.
   -- a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will likely only need to use the prescriber and drug tables.
SELECT npi, drug_name 
FROM prescriber
CROSS JOIN drug--cross join does not need matching column name
WHERE specialty_description = 'Pain Management' 
AND nppes_provider_city = 'NASHVILLE'
AND opioid_drug_flag = 'Y';


  --  b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
    
   -- c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

-- how many npi numbers appear in the prescriber table but not in the prescription table?

SELECT COUNT(DISTINCT npi)
FROM prescriber
WHERE npi NOT IN 
(
	SELECT DISTINCT npi
	FROM prescription
)

--find the top five drugs (generic name) prescribed by the prescribers with the specialty of family practice, what about cardiology?
SELECT generic_name, SUM(total_claim_count)
FROM prescription
LEFT JOIN prescriber
USING (npi)
LEFT JOIN drug
USING(drug_name)
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY 2 DESC
LIMIT 5;

SELECT generic_name, SUM(total_claim_count)
FROM prescription
LEFT JOIN prescriber
USING (npi)
LEFT JOIN drug
USING(drug_name)
WHERE specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY 2 DESC
LIMIT 5;

-- Which drugs appear in the top five prescribed for both Family Practice prescribers and Cardiologists?
--Combine what you did for parts a and b into a single query to answer this question.
WITH family_drugs AS (
	SELECT 
		d.generic_name, 
		SUM(p2.total_claim_count) AS total_perscribed
	FROM prescriber AS p1
	INNER JOIN prescription AS p2
	USING (npi)
	INNER JOIN drug AS d
	USING (drug_name)
	WHERE specialty_description = 'Family Practice'
	GROUP BY d.generic_name
	ORDER BY 2 DESC
	LIMIT 5), -- end of first one
cardiology_drugs AS (
	SELECT 
		d.generic_name, 
		SUM(p2.total_claim_count) AS total_perscribed
	FROM prescriber AS p1
	INNER JOIN prescription AS p2
	USING (npi)
	INNER JOIN drug AS d
	USING (drug_name)
	WHERE specialty_description = 'Cardiology' 
	GROUP BY d.generic_name
	ORDER BY 2 DESC
	LIMIT 5) ----end of second one
SELECT generic_name
FROM family_drugs
INTERSECT -- rows in both
SELECT generic_name
FROM cardiology_drugs;


--3. Your goal in this question is to generate a list of the top prescribers in each of the major 
--metropolitan areas of Tennessee.

    --a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.

   -- b. Now, report the same for Memphis.

   -- c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.
SELECT 
    npi,
    SUM(total_claim_count) AS total_claim_count,
    nppes_provider_city
FROM prescriber
INNER JOIN prescription
USING(npi)
WHERE nppes_provider_city = 'NASHVILLE'
GROUP BY npi, nppes_provider_city
ORDER BY total_claim_count DESC
LIMIT 5;


--
(SELECT 
	npi,
	nppes_provider_city,
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING (npi)
WHERE nppes_provider_city = 'NASHVILLE'
GROUP BY npi, nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5)
UNION
(SELECT 
	npi,
	nppes_provider_city,
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING (npi)
WHERE nppes_provider_city = 'MEMPHIS'
GROUP BY npi, nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5)
UNION
(SELECT 
	npi,
	nppes_provider_city,
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING (npi)
WHERE nppes_provider_city = 'KNOXVILLE'
GROUP BY npi, nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5)
UNION
(SELECT 
	npi,
	nppes_provider_city,
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING (npi)
WHERE nppes_provider_city = 'CHATTANOOGA'
GROUP BY npi, nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5) -- end of last query
ORDER BY nppes_provider_city, total_claims DESC;


--44. Find all counties which had an above-average (for the state) number of overdose
--deaths in 2017. Report the county name and number of overdose deaths.
SELECT COUNTY,
	OVERDOSE_DEATHS
FROM FIPS_COUNTY
INNER JOIN OVERDOSE_DEATHS 
USING (FIPSCOUNTY)
WHERE YEAR = 2017
	AND OVERDOSE_DEATHS >
		(SELECT AVG(OVERDOSE_DEATHS)
			FROM OVERDOSE_DEATHS
			WHERE YEAR = 2017)
ORDER BY OVERDOSE_DEATHS DESC;


--5.

   -- a. Write a query that finds the total population of Tennessee.

   -- b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.
 
 WITH state_pop AS 
(
SELECT SUM(population) AS state_population
FROM population
), -- this gives the total population

county_pop AS 
(
SELECT county, SUM(population) AS county_population
FROM population
INNER JOIN fips_county
USING (fipscounty)
GROUP BY county
)

SELECT county, county_population,
	ROUND(county_population * 100.00/ (SELECT state_population FROM state_pop), 2) AS percentage
	FROM county_pop
	
 --or:
 SELECT county, population, round(100 * population / (SELECT sum(population) 
	FROM population
	INNER JOIN fips_county
	USING (fipscounty)), 2) AS percent_population
FROM population
INNER JOIN fips_county
USING (fipscounty)
   
