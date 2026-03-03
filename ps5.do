* Problem Set 4: Real ACS Data Cleaning with Macros and Git Workflow
* Megan Flores
* 02/27/2026

/////////////////////// Required Task #1: Initialize and begin logging ///////////////////////
* Set your working directory to this PS5 folder
cd "/Users/meganflores/Documents/UTSW/Sweat Programming/lecture_5_pset"

* Start a log file named logs/ps5.log
capture log close
set more off
clear
log using logs/ps5, replace text

/////////////////////// #2 Import the data without forcing all columns to strings ///////////////////////
* Import psam_p50.csv
import delimited "/Users/meganflores/Documents/UTSW/Sweat Programming/lecture_5_pset/psam_p50.csv"

* Verify and display that the dataset has more than 100 variables (using ds)
ds 
assert r(k) > 100

/////////////////////// #3 Use local macros to define numeric and categorical columns ///////////////////////
*  Create a local macro named numeric_vars with this required subset of ACS columns:– AGEP WAGP WKHP SCHL PINCP POVPIP ESR COW MAR SEX RAC1P HISP ADJINC PWGTP
local numeric_vars "agep wagp wkhp schl pincp povpip esr cow mar sex rac1p hisp adjinc pwgtp"

* Create a local macro named categorical_vars with this required subset: – NAICSP SOCP
local categorical_vars "naicsp socp"

* Use a loop over numeric_vars to: – verify each variable exists
local count = 0
foreach var of local numeric_vars {
    local count = `count' + 1
}
display `count'

foreach v of local numeric_vars {
    capture confirm variable `v'
    if _rc == 0 {
        display "`v' exists"
    }
    else {
        display in red "`v' does not exist"
    }
}

* convert to numeric only when needed (handle "NA", ".", and blanks correctly).
foreach v in `numeric_vars' {
	destring `v', replace ignore("NA")
}

* Use a loop over categorical_vars to: – clean string formatting,
tab naicsp 
tab socp

foreach v in `categorical_vars' {
	destring `v', replace ignore("NA")
}

codebook naicsp 
codebook socp

* – encode each variable to a new _id variable.
encode naicsp, generate(naicsp_id)
codebook naicsp_id
encode socp, generate(socp_id)
codebook socp_id

* Display both macro contents in the log.
display "`numeric_vars'"
display "`categorical_vars'"

/////////////////////// #4 Run QA checks and save a cleaned full file ///////////////////////
* Check for missing key fields and verify uniqueness of SERIALNO SPORDER using duplicates report and isid.
misstable summarize
count if missing(serialno)
count if missing(sporder)
isid serialno sporder
duplicates report serialno sporder

* Save processed_data/ps5_cleaned_full.dta.
save processed_data/ps5_cleaned_full.dta, replace

/////////////////////// #5 Build a sample-construction table ///////////////////////
* Use postfile to create a step-by-step sample-construction table with:
* – step name,
* – remaining observations,
* – excluded observations at that step.
tempname sample_post
tempfile sample_steps
postfile `sample_post' str80 step int n_remaining int n_excluded using "`sample_steps'", replace

count 
local n_prev = r(N)
post `sample_post' ("Start: Cleaned observations") (`n_prev') (0)

* Required filtering sequence:
* keep ages 25–64,
keep if inrange(age, 25, 64)
count 
local n_now = r(N)
post `sample_post' ("Inclusion: age 25 to 64") (`n_now') (`n_prev'- `n_now')
local n_prev = `n_now'

* keep WAGP > 0 and WKHP >= 35,
keep if wagp >0 & wkhp >= 35
count
local n_now = r(N)
post `sample_post' ("Inclusion:  WAGP > 0 and WKHP >= 35") (`n_now') (`n_prev'- `n_now')
local n_prev = `n_now'

* keep ESR in employed categories (1 or 2),
keep if inrange(esr, 1, 2)
count
local n_now = r(N)
post `sample_post' ("Inclusion: employed") (`n_now') (`n_prev'- `n_now')
local n_prev = `n_now'

* drop missing values in key model covariates and encoded categorical IDs.
drop if missing(agep, wagp, wkhp, schl, pincp, povpip, esr, cow, mar, sex, rac1p, hisp, adjinc, pwgtp, naicsp_id, socp_id)
count
local n_now=r(N)
post `sample_post' ("Exclusion: missing covariates") (`n_now') (`n_prev'- `n_now')
local n_prev = `n_now'

* Create ln_wage = ln(WAGP).
generate ln_wage = ln(wagp)
label var ln_wage "Log hourly wage"

* Export processed_data/ps5_sample_construction.csv
postclose `sample_post'
preserve
use "`sample_steps'", clear
export delimited using "processed_data/ps5_sample_construction.csv", replace
save "processed_data/ps5_sample_construction.dta", replace
restore

/////////////////////// #6 Use macros for model specification and loops ///////////////////////
* Create locals for:
* outcome
local outcome "ln_wage"

* covariates_demo
local covariates_demo "c.agep c.schl i.mar i.sex i.rac1p i.hisp c.pwgtp"
* age, school, marital status, sex, race, ethnicity, weight

* covariates_humancap
local covariates_humancap "c.wagp c.povpip c.pincp c.adjinc"
* wage, poverty-income ratio, total person's income, adjustment factor for income and earnings dollar amounts

* covariates_labor
local covariates_labor "i.cow i.esr c.wkhp"
* class of worker, employment status, usual hours worked per week

* covariates_occ
local covariates_occ "i.naicsp_id i.socp_id"
* North American Industry Classification System and Standard Occupational Classification

* combined model_covariates
local model_covariates "`covariates_demo' `covariates_humancap' `covariates_geo' `covariates_labor' `covariates_occ'"

* Display your outcome and model_covariates macros.
display "Outcome macro: `outcome'"
display "Model covariates macro: `model_covariates'"

* Use a foreach loop over a qa_vars macro to report means and standard deviations.
local qa_vars "agep wagp wkhp schl pincp povpip esr cow mar sex rac1p hisp adjinc pwgtp"
foreach v of local qa_vars {
	qui: summarize `v'
	display as text "`v': mean = " %9.2f r(mean) " sd = " %9.2f r(sd)
}

* Use a forvalues loop to report counts for WKHP >= cutoff over several cutoffs.
summarize wkhp

forvalues cutoff = 35/40 {
quietly count if wkhp >= `cutoff'
display as txt "Observations with hours >= `cutoff': " %6.0f r(N)
}

* Run and store three regression specifications that build from simple to full covariate blocks.
reg `outcome' `covariates_demo', r

reg `outcome' `covariates_demo' `covariates_humancap', r

reg `outcome' `model_covariates', r

/////////////////////// #7 Required macro-based keep list ///////////////////////
* Create a local macro named keepvars containing all variables required in your final analysis dataset.
local keepvars "ln_wage agep wagp wkhp schl pincp povpip esr cow mar sex rac1p hisp adjinc pwgtp naicsp naicsp_id socp socp_id"

* Use keep `keepvars' (do not hardcode a standalone keep list).
keep `keepvars'

* Verify each kept variable exists using a loop and confirm variable.
* Your keepvars must include the encoded _id variables created from categorical_vars.
local count = 0
foreach var of local keepvars {
    local count = `count' + 1
}
display `count'

foreach v of local keepvars {
    capture confirm variable `v'
    if _rc == 0 {
        display "`v' exists"
    }
    else {
        display in red "`v' does not exist"
    }
}

* Save processed_data/ps5_analysis_data.dta.
save "processed_data/ps5_analysis_data.dta", replace





