* Problem Set 3: Cleaning Pipelines, Panel Checks, and Your First GitHub Repo
* Megan Flores
* 02/19/2026

/////////////////////// Required Task #1: Initialize and begin logging ///////////////////////
* Set your working directory to the problem set folder.
cd "/Users/meganflores/Documents/UTSW/Sweat Programming/pset3_data"

* Start a log file named logs/ps3.log
capture log close
set more off
clear
log using logs/ps3log, replace text

/////////////////////// #2 Part A: Clean and validate people_full.csv ///////////////////////
* Import with stringcols(_all).
import delimited people_full.csv, stringcols(_all) 

* Standardize location and sex strings (trim/case cleanup).
tab location
replace location = strtrim(location)
replace location = strlower(location)
replace location = strproper(location)
tab location

tab sex

* Convert the following columns from strings to numeric and handle "NA" correctly: person_id household_id age height_cm weight_kg systolic_bp diastolic_bp.
foreach v in person_id household_id age height_cm weight_kg systolic_bp diastolic_bp {
	destring `v', replace ignore("NA")
}

* Convert date/time fields by creating visit_date from date_str, visit_time from time_str, and people_year from visit_date.
generate visit_date = date(date_str, "MDY")
format visit_date %td
generate visit_time = time_str
generate people_year = yofd(visit_date)

* Run QA checks:
misstable summarize
* – no missing person_id (use assert !missing(person_id))
count if missing(person_id)
bysort person_id: assert !missing(person_id)

* – unique key person_id people_year (use isid person_id people_year)
isid person_id people_year
duplicates report person_id people_year

* – each non-missing person_id has 5 observations (use bysort person_id: assert_N == 5)
bysort person_id: assert _N == 5

* Create categorical encodings named sex_id and location_id.
encode sex, generate(sex_id)
codebook sex_id
encode location, generate(location_id)
codebook location_id

* Create these grouped variables using bysort:
* – hh_n: number of rows per household_id
bysort household_id: generate hh_n=_N

* – hh_row: within-household row index after sorting by person_id people_year
bysort household_id (person_id people_year): generate hh_index=_n

* – hh_mean_age: household-level mean of age
bysort household_id: egen mean_hh_age = mean(age)

* Export a cleaned file to processed_data/ps3_people_clean.csv.
save "processed_data/ps3_people_clean.csv", replace

/////////////////////// #3 Part A: Clean and validate households.csv ///////////////////////
import delimited households.csv, clear varnames(1)

* Convert household_id year region_id income hh_size from strings to numeric (handle "NA" if present)
foreach v in household_id year region_id income hh_size {
	destring `v', replace
}

* Encode region into region_code and inspect labels.
encode region, generate(region_code)
label list region_code
tab region_code, missing

* Create these grouped variables:
* – year_mean_income: mean of income by year
bysort year: egen year_mean_income = mean(income)

* – region_year_mean_income: mean of income by region_code year
bysort region_code year: egen region_year_mean_income = mean(income)

* – region_year_row: within-region_code index after sorting by year
bysort region_code (year): generate region_year_row=_n

* Run this regression (factor-variable notation): reg income i.region_code c.hh_size##c.year.
regress income i.region_code c.hh_size##c.year

* Export a cleaned file to processed_data/ps3_households_clean.csv.
save "processed_data/ps3_households_clean.csv", replace

/////////////////////// #4 Part A: Clean and validate regions.csv as panel data ///////////////////////
import delimited regions.csv, clear varnames(1)

* Convert numeric variables from strings and handle "NA".
foreach v in region_id year median_income population {
	destring `v', replace ignore("NA")
}

* Drop rows with missing panel keys.
tab region_name
duplicates report region_id year
drop if missing(region_id) | missing(year)

* Verify unique region_id year.
isid region_id year

* Declare panel structure with xtset region_id year.
xtset region_id year

* Generate both:
* yoy_change_median_income = median_income - L.median_income
generate yoy_change_median_income = median_income - L.median_income
 
* median_income_growth_rate = (median_income - L.median_income) / L.median_income
generate median_income_growth_rate = (median_income - L.median_income) / L.median_income

* Run xtdescribe and xtsum median_income population yoy_change_median_income median_income_growth_rate.
xtdescribe 
xtsum median_income population yoy_change_median_income median_income_growth_rate

* Export a cleaned file to processed_data/ps3_regions_clean.csv.
save "processed_data/ps3_regions_clean.csv", replace





