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
--my way
SELECT
		SUM(total_claim_count) AS sum_count
	,	NPI
	
FROM prescription
GROUP BY npi
ORDER BY sum_count DESC

--other way
SELECT DISTINCT npi
, SUM(total_claim_count) as total_claims
FROM prescription
GROUP BY npi
ORDER BY total_claims DESC
LIMIT 1;
	
--1    b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

--MY WAY
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



--other way to do 
SELECT nppes_provider_first_name,nppes_provider_last_org_name, 
specialty_description, SUM(total_claim_count) AS 
total_claim_count_over_all_drugs
FROM prescription
INNER JOIN prescriber
ON prescriber.npi=prescription.npi
GROUP BY nppes_provider_first_name,nppes_provider_last_org_name, 
specialty_description
ORDER BY total_claim_count_over_all_drugs DESC

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

--my way
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

--other way
SELECT
p.specialty_description,
SUM(total_claim_count) as total_sum
FROM prescriber as p
INNER JOIN prescription as pr
ON p.npi=PR.npi
INNER JOIN drug as d
ON pr.drug_name=d.drug_name
WHERE d.opioid_drug_flag = 'Y'
GROUP BY 1
ORDER BY total_sum DESC;


--3a. Which drug (generic_name) had the highest total drug cost?

--my answer. Wrong. Dont know why
SELECT 
		ROUND(SUM(p.total_drug_cost),0) ::MONEY AS round_cost
	,	d.generic_name

FROM prescription AS p
	INNER JOIN drug AS d
		ON p.drug_name=d.drug_name
WHERE p.total_drug_cost IS NOT NULL
GROUP BY d.generic_name, p.total_drug_cost
ORDER BY p.total_drug_cost DESC
LIMIT 10;


--correct answer
SELECT drug.generic_name
, SUM(prescription.total_drug_cost) AS total_cost
FROM drug
INNER JOIN prescription
ON drug.drug_name = prescription.drug_name
WHERE prescription.total_drug_cost IS NOT NULL
GROUP BY drug.generic_name
ORDER BY total_cost DESC
LIMIT 10;

--3b. Which drug (generic_name) has the hightest total cost per day? 

SELECT 
		(SUM(p.total_drug_cost)/SUM(p.total_day_supply)) ::MONEY AS day_cost
	,	d.generic_name

FROM prescription AS p
	INNER JOIN drug AS d
		ON p.drug_name=d.drug_name
GROUP BY d.generic_name--, p.total_drug_cost
ORDER BY day_cost DESC;


--correct answer
SELECT drug.generic_name
,
(SUM(prescription.total_drug_cost)/SUM(prescription.total_day_supply)) :: 
MONEY as daily_drug_cost
FROM prescription
INNER JOIN drug
USING (drug_name)
GROUP BY drug.generic_name
ORDER BY daily_drug_cost DESC

--4a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/ 

--drug_name, generic_name, opioid_drug_flag, long_acting_opioid_drug_flag, antibiotic_drug_flag, antipsychotic_drug_flag

--my attempt
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


--other attempt
SELECT
drug_name
, CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
ELSE 'neither'END AS drug_type
FROM drug;


--another attempt with count
SELECT
drug_name
, COUNT(CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'END) AS 
opioid_count
, COUNT(CASE WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic' 
END) AS antibiotic_count
, COUNT(CASE WHEN opioid_drug_flag <> 'Y' AND 
antibiotic_drug_flag <> 'Y' THEN 'neither' END) AS neither_count
FROM drug
GROUP BY drug_name;

--4b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

--my answer correct 
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
--my answer incorrect
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
--my answer incorrect
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


--correct answer from sabrina
SELECT drug_type, SUM(total_drug_cost)::MONEY AS total_cost
FROM
(SELECT drug.drug_name ,
CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
ELSE 'neither'
END AS drug_type , total_drug_cost
FROM drug AS drug
INNER JOIN prescription
ON drug.drug_name = prescription.drug_name ) AS drug_cost
WHERE drug_type IN ('opioid','antibiotic')
GROUP BY drug_type;

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

--sabrina other answer (is this right? returns only 2 records)
SELECT *
FROM cbsa
WHERE cbsaname iLIKE '%TN%'
AND cbsaname NOT IN(SELECT cbsaname
FROM cbsa AS c
INNER JOIN fips_county AS f
ON c.fipscounty = f.fipscounty
WHERE state LIKE '%TN%')


--5b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

--max(population) FROM population
--min(populattion) FROM population
--cbsa_name from cbsa

--my answer not right
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
--my answer not right
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

--sabrina other answer 
(
SELECT cbsaname, SUM(population) AS total_population, 'largest' as flag
FROM cbsa
INNER JOIN population
USING(fipscounty)
GROUP BY cbsaname
ORDER BY total_population DESC
limit 1
)
UNION
(
SELECT cbsaname, SUM(population) AS total_population, 'smallest' as flag
FROM cbsa
INNER JOIN population
USING(fipscounty)
GROUP BY cbsaname
ORDER BY total_population
limit 1
)
order by total_population desc;


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

--ALT ANS (EXCEPT + Subquery):
SELECT f.county, SUM(p.population) as combined_population
FROM fips_county AS f
INNER JOIN population AS p
ON f.fipscounty = p.fipscounty
WHERE f.fipscounty IN
--Subquery to return TN fipscounty which are not included in CBSA
(SELECT fipscounty FROM fips_county WHERE STATE = 'TN' 
--fips_county table has 96 records for TN
EXCEPT
SELECT fipscounty FROM cbsa) --Total 54 fipscounty are not 
--present in CBSA
GROUP BY f.county
ORDER BY combined_population desc
LIMIT 1

--ALT ANS (2 JOINS):
SELECT fc.county,
   p.population
FROM population  AS p
INNER JOIN fips_county AS fc
ON p.fipscounty = fc.fipscounty
LEFT JOIN cbsa
ON fc.fipscounty = cbsa.fipscounty
WHERE cbsa.cbsa IS NULL
ORDER BY p.population DESc


--6a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT
		drug_name
	,	total_claim_count
FROM prescription
WHERE total_claim_count >=3000


--6b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

--my answer wrong
SELECT
		p.drug_name
	,	p.total_claim_count
	,	(CASE WHEN 'd.opioid_drug_flag'='Y' THEN 'Y' ELSE 'N' END) AS outcome
FROM prescription AS p
		INNER JOIN drug AS d
			ON p.drug_name = d.drug_name
WHERE total_claim_count >=3000

--sabrina answer right
SELECT
p.drug_name
, total_claim_count
, CASE WHEN opioid_drug_flag = 'Y' THEN 'Opioid'
WHEN opioid_drug_flag = 'N' THEN 'Not Opioid'
END AS opioid_filter
FROM prescription AS p
INNER JOIN drug AS d
ON p.drug_name = d.drug_name
WHERE total_claim_count >= 3000;

--6c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

--jon
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

--sabrina
SELECT
p1.drug_name
, total_claim_count
, CONCAT(nppes_provider_first_name, ' ', 
nppes_provider_last_org_name) AS first_lastname
, CASE WHEN opioid_drug_flag = 'Y' THEN 'Opioid'
WHEN opioid_drug_flag = 'N' THEN 'Not Opioid'
END AS opioid_filter
FROM prescription AS p1
INNER JOIN drug AS d
ON p1.drug_name = d.drug_name
INNER JOIN prescriber AS p2
ON p1.npi = p2.npi
WHERE total_claim_count >= 3000;

-----------------------------------------------
--7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--7a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

--notes: specialty_description from presctiber

--Jon answer Wrong
SELECT
		p1.npi
	,	d.drug_name
	,	(CASE WHEN p1.specialty_description = 'Pain Management' THEN 'Y' ELSE 'N' END) AS pain_specialty
	,	(CASE WHEN nppes_provider_city = 'NASHVILLE' THEN 'Y' ELSE 'N' END) AS nash_city
	,	(CASE WHEN opioid_drug_flag = 'Y' THEN 'Y' ELSE 'N' END) AS opioid_flag
FROM prescriber AS p1
	INNER JOIN prescription AS p2
		ON p1.npi = p2.npi
	INNER JOIN drug AS d
		ON p2.drug_name = d.drug_name
WHERE p1.specialty_description='Pain Management'
	AND p1.nppes_provider_city = 'NASHVILLE'
	AND d.opioid_drug_flag = 'Y'

--sabrina answer
SELECT
p.npi
, drug_name
FROM prescriber AS p
CROSS JOIN drug AS d
WHERE opioid_drug_flag = 'Y'
AND nppes_provider_city = 'NASHVILLE'
AND specialty_description = 'Pain Management'
ORDER BY
p.npi
, drug_name;


--7b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).


--jon answer wrong
SELECT
		p1.npi
	,	d.drug_name
	,	(CASE WHEN p1.specialty_description = 'Pain Management' THEN 'Y' ELSE 'N' END) AS pain_specialty
	,	(CASE WHEN nppes_provider_city = 'NASHVILLE' THEN 'Y' ELSE 'N' END) AS nash_city
	,	(CASE WHEN opioid_drug_flag = 'Y' THEN 'Y' ELSE 'N' END) AS opioid_flag
	,	(CASE WHEN p2.total_claim_count IS NULL THEN 0 ELSE p2.total_claim_count END) AS total_claim_count
FROM prescriber AS p1
	LEFT JOIN prescription AS p2
		ON p1.npi = p2.npi
	LEFT JOIN drug AS d
		ON p2.drug_name = d.drug_name
WHERE p1.specialty_description='Pain Management'
	AND p1.nppes_provider_city = 'NASHVILLE'
	AND d.opioid_drug_flag = 'Y'

--sabrina answer right

SELECT prescriber.npi
, drug.drug_name
, SUM(prescription.total_claim_count) AS sum_total_claims
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
USING (drug_name)
WHERE prescriber.specialty_description = 'Pain Management'
AND prescriber.nppes_provider_city = 'NASHVILLE'
AND drug.opioid_drug_flag = 'Y'
GROUP BY prescriber.npi
, drug.drug_name
ORDER BY prescriber.npi;



    
--7c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

SELECT
		COALESCE(p2.total_claim_count, 0) AS total_claim_count
	,	p1.npi
	,	d.drug_name
	,	(CASE WHEN p1.specialty_description = 'Pain Management' THEN 'Y' ELSE 'N' END) AS pain_specialty
	,	(CASE WHEN nppes_provider_city = 'NASHVILLE' THEN 'Y' ELSE 'N' END) AS nash_city
	,	(CASE WHEN opioid_drug_flag = 'Y' THEN 'Y' ELSE 'N' END) AS opioid_flag
FROM prescriber AS p1
	LEFT JOIN prescription AS p2
		ON p1.npi = p2.npi
	LEFT JOIN drug AS d
		ON p2.drug_name = d.drug_name
WHERE p1.specialty_description='Pain Management'
	AND p1.nppes_provider_city = 'NASHVILLE'
	AND d.opioid_drug_flag = 'Y'

--correct answer
SELECT prescriber.npi
, drug.drug_name
, COALESCE(SUM(prescription.total_claim_count), 0) AS 
sum_total_claims
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
USING (drug_name)
WHERE prescriber.specialty_description = 'Pain Management'
AND prescriber.nppes_provider_city = 'NASHVILLE'
AND drug.opioid_drug_flag = 'Y'
GROUP BY prescriber.npi
, drug.drug_name
ORDER BY prescriber.npi;



