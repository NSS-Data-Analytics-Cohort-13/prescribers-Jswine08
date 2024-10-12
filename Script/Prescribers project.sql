SELECT *
FROM cbsa

SELECT *
FROM drug

SELECT *
FROM fips_county

SELECT *
FROM overdose_deaths

SELECT *
FROM population

SELECT *
FROM prescriber

SELECT *
FROM prescription

SELECT*
FROM zip_flps


--1a notes
--npi from prescriber table
--total_claim_count from prescription table
--USING(npi)top match tables

--1. 
--    a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

SELECT
		SUM(total_claim_count) AS sum_count
	,	NPI
	
FROM prescription
GROUP BY npi
ORDER BY sum_count DESC
	
--1    b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT
		SUM(total_claim_count) AS sum_count
	,	p1.NPI
	,	CONCAT(p2.nppes_provider_first_name, ' ', p2.nppes_provider_last_org_name) AS name
	,	p2.specialty_description
	
FROM prescription AS p1
	INNER JOIN prescriber AS p2
		USING(npi)
GROUP BY npi, name, p2.specialty_description
ORDER BY sum_count DESC
LIMIT 1;


--2a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT 
		SUM(p1.total_claim_count) AS sum_count
	,	p2.specialty_description
FROM prescription AS p1
	INNER JOIN prescriber AS p2
		ON p1.npi = p2.npi
GROUP BY p2.specialty_description
ORDER BY sum_count DESC;



--2b.   b. Which specialty had the most total number of claims for opioids?
--prescribers specialty_description
--total_claim_count from prescription
--opioid_drug_flag from drug

SELECT 
		SUM(p1.total_claim_count) AS sum_count
	,	p2.specialty_description
	,	d.opioid_drug_flag
FROM prescription AS p1
	INNER JOIN prescriber AS p2
		ON p1.npi = p2.npi
	INNER JOIN drug AS d
		ON p1.drug_name=d.drug_name
WHERE d.opioid_drug_flag='Y'
GROUP BY p2.specialty_description, d.opioid_drug_flag
ORDER BY sum_count DESC;

--3a. Which drug (generic_name) had the highest total drug cost?

SELECT 
		ROUND(SUM(p.total_drug_cost),0) ::MONEY AS round_cost
	,	d.generic_name

FROM prescription AS p
	INNER JOIN drug AS d
		ON p.drug_name=d.drug_name
GROUP BY d.generic_name, p.total_drug_cost
ORDER BY p.total_drug_cost DESC;


--3b. Which drug (generic_name) has the hightest total cost per day? 

SELECT 
		ROUND(SUM(p.total_drug_cost/p.total_day_supply),0) ::MONEY AS day_cost
	,	d.generic_name

FROM prescription AS p
	INNER JOIN drug AS d
		ON p.drug_name=d.drug_name
GROUP BY d.generic_name, p.total_drug_cost
ORDER BY day_cost DESC;


--4a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/ 

--drug_name, generic_name, opioid_drug_flag, long_acting_opioid_drug_flag, antibiotic_drug_flag, antipsychotic_drug_flag

SELECT 
		drug_name
	, 	generic_name
	,   opioid_drug_flag
	, 	long_acting_opioid_drug_flag
	, 	antibiotic_drug_flag	

	,	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type
FROM drug



--4b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

WITH drug AS (SELECT
		drug_name
	 ,	generic_name
	 ,  opioid_drug_flag
	, 	long_acting_opioid_drug_flag
	, 	antibiotic_drug_flag	

	,	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type
		FROM drug)
	SELECT drug_type,
	ROUND(SUM(p.total_drug_cost),0) ::MONEY AS total_cost
	FROM drug
INNER JOIN prescription AS p
		ON drug.drug_name=p.drug_name
GROUP BY drug_type
ORDER BY total_cost DESC


------------------------------------------------------------
SELECT 
		d.drug_name
	, 	d.generic_name
	,   d.opioid_drug_flag
	, 	d.long_acting_opioid_drug_flag
	, 	d.antibiotic_drug_flag	

	,	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type
	, ROUND(SUM(p.total_drug_cost),0) ::MONEY AS total_cost
FROM drug as d
	INNER JOIN prescription AS p
		ON d.drug_name = p.drug_name
WHERE CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		END IS NOT NULL
	GROUP BY d.drug_name, d.generic_name
	,   d.opioid_drug_flag
	, 	d.long_acting_opioid_drug_flag
	, 	d.antibiotic_drug_flag
	,	p.total_drug_cost
ORDER BY p.total_drug_cost desc

------------------------------------------------------------
SELECT
	d.drug_name
,	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		END AS drug_type
,	p.total_drug_cost::MONEY
FROM drug AS d
	INNER JOIN prescription AS p
		ON d.drug_name = p.drug_name
WHERE CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		END IS NOT NULL
ORDER BY p.total_drug_cost DESC;



--5a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
--SUM(cbsa) from cbsa
--state FROM fibs_county (where state='TN')

SELECT
		COUNT(c.cbsa)

	--,	f.state

FROM cbsa AS c
	INNER JOIN fips_county AS f
		ON c.fipscounty = f.fipscounty
		WHERE f.state='TN'



--5b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

--max(population) FROM population
--min(populattion) FROM population
--cbsa_name from cbsa

(SELECT 
		MAX(p.population) AS max_pop
	,	c.cbsaname
FROM population AS p
	INNER JOIN cbsa AS c
		ON p.fipscounty = c.fipscounty
		GROUP BY c.cbsaname, p.population
ORDER BY max_pop DESC
LIMIT 1)
UNION
(SELECT 
		MIN(p.population) AS min_pop
	,	c.cbsaname
FROM population AS p
	INNER JOIN cbsa AS c
		ON p.fipscounty = c.fipscounty
		GROUP BY c.cbsaname, p.population
ORDER BY min_pop ASC
LIMIT 1);
----------------------------------------------------------

SELECT
		MAX(p.population) AS max_pop
	,	(SELECT cbsaname
		FROM cbsa AS c
		INNER JOIN population AS p
			ON c.fipscounty = p.fipscounty
		ORDER BY p.population DESC
		LIMIT 1) AS max_cbsa_name
	,
		MIN(p.population) AS min_pop
	,	(SELECT cbsaname
		FROM cbsa AS c
		INNER JOIN population AS p
		ON c.fipscounty = p.fipscounty
		ORDER BY p.population ASC
		LIMIT 1) AS min_cbsa_name
FROM population AS p;




--5c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population

SELECT
		p.fipscounty
	,	MAX(p.population) AS max_pop

	,	f.county

FROM population AS p
		INNER JOIN fips_county AS f
			ON p.fipscounty = f.fipscounty
		LEFT JOIN cbsa AS c
			ON p.fipscounty = c.fipscounty
WHERE c.fipscounty IS NULL
GROUP BY p.fipscounty, f.county
ORDER BY max_pop desc
LIMIT 1


--6a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT
		drug_name
	,	total_claim_count
FROM prescription
WHERE total_claim_count >=3000


--6b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT
		p.drug_name
	,	p.total_claim_count
	,	(CASE WHEN 'd.opioid_drug_flag'='Y' THEN 'Y' ELSE 'N' END) AS outcome
FROM prescription AS p
		INNER JOIN drug AS d
			ON p.drug_name = d.drug_name
WHERE total_claim_count >=3000


--6c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT
		p.drug_name
	,	p.total_claim_count
	,	CONCAT(p2.nppes_provider_first_name, ' ', p2.nppes_provider_last_org_name) AS name
	,	(CASE WHEN 'd.opioid_drug_flag'='Y' THEN 'Y' ELSE 'N' END) AS outcome
FROM prescription AS p
		INNER JOIN drug AS d
			ON p.drug_name = d.drug_name
		INNER JOIN prescriber AS p2
		ON p.NPI = p2.npi
WHERE total_claim_count >=3000

-----------------------------------------------
--7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--7a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

0







--7b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).







    
--7c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.







