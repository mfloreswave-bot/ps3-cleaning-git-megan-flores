* Problem Set 5: Linear Regression Workflow, Margins, Table Export, Nonlinear Terms, and Prediction
* Megan Flores
* 03/08/2026

/////////////////////// Required Task #1: Initialize and begin logging ///////////////////////
* Set your working directory to this PS5 folder
cd "/Users/meganflores/Documents/UTSW/Sweat Programming/lecture_5_pset"

* Start a log file named logs/ps5.log
capture log close
set more off
clear
log using logs/ps5, replace text

/////////////////////// #2 Load data and verify required variables///////////////////////
* Load data/ps5_data.dta.
use "/Users/meganflores/Documents/UTSW/Sweat Programming/lecture_5_pset/ps5_data.dta"

* Define local required_vars as:
local required_vars "SERIALNO SPORDER ln_wage WAGP AGEP SCHL WKHP PINCP POVPIP ESR COW MAR SEX RAC1P HISP PWGTP NAICSP SOCP NAICSP_id SOCP_id"

* Verify this required variable set exists: SERIALNO SPORDER ln_wage WAGP AGEP SCHL WKHP PINCP POVPIP ESR COW MAR SEX RAC1P HISP PWGTP NAICSP SOCP NAICSP_id SOCP_id
display "`required_vars'"

* Use a loop with confirm variable for the checks.
local count = 0
foreach var of local required_vars {
    local count = `count' + 1
}
display `count'

foreach v of local required_vars {
    capture confirm variable `v'
    if _rc == 0 {
        display "`v' exists"
    }
    else {
        display in red "`v' does not exist"
    }
}

/////////////////////// #3 Short warm-up: univariate and bivariate checks//////////////////////
* Run summarize and tabstat for: – ln_wage WAGP AGEP SCHL WKHP PINCP POVPIP
summarize ln_wage WAGP AGEP SCHL WKHP PINCP POVPIP
tabstat ln_wage WAGP AGEP SCHL WKHP PINCP POVPIP

* Run pwcorr with significance at level 0.05 for: ln_wage AGEP SCHL WKHP PINCP POVPIP
pwcorr ln_wage AGEP SCHL WKHP PINCP POVPIP, sig star(0.05)

* Create and export one bivariate plot: – ln_wage vs. AGEP with lfit
twoway lfit ln_wage AGEP

* Export to processed_data/ps5_ln_wage_agep_plot.png
graph export "/Users/meganflores/Documents/UTSW/Sweat Programming/lecture_5_pset/processed_data/ps5_ln_wage_agep_plot.png", as(png) name("Graph") replace

/////////////////////// #4 Macro-driven linear regressions //////////////////////
* Define locals for:
* outcome = "ln_wage"
local outcome "ln_wage"

* covariates_demo = "c.AGEP i.SEX i.RAC1P i.HISP i.MAR"
local covariates_demo "c.AGEP i.SEX i.RAC1P i.HISP i.MAR"

* covariates_humancap = "c.SCHL c.PINCP c.POVPIP"
local covariates_humancap "c.SCHL c.PINCP c.POVPIP"

* covariates_labor = "c.WKHP i.ESR i.COW"
local covariates_labor "c.WKHP i.ESR i.COW"

* covariates_occ = "i.NAICSP_id i.SOCP_id"
local covariates_occ "i.NAICSP_id i.SOCP_id"

* combined model_covariates includes covariates_demo, covariates_humancap, covariates_labor, and covariates_occ
local model_covariates "`covariates_demo' `covariates_humancap' `covariates_labor' `covariates_occ'"

* Display outcome and model_covariates in the log.
display "Outcome macro: `outcome'"
display "Model covariates macro: `model_covariates'"

* Run and store three models with vce(robust):
* m1: demo only
reg `outcome' `covariates_demo', vce(robust)
estimates store m1

* m2: demo + human capital
reg `outcome' `covariates_demo' `covariates_humancap', vce(robust)
estimates store m2

* m3: full baseline model
reg `outcome' `model_covariates', vce(robust)
estimates store m3

/////////////////////// #5 Transformations and nonlinear terms ////////////////////// 
* Create ln_hours = ln(WKHP).
generate ln_hours = ln(WKHP)

* Estimate and store m4 using:
* a quadratic age term via c.AGEP##c.AGEP
* a quadratic income term via c.PINCP##c.PINCP
* c.ln_hours
reg `outcome' ///
c.AGEP##c.AGEP ///
c.PINCP##c.PINCP ///
c.ln_hours ///
`model_covariates', vce(robust)
estimates store m4

/////////////////////// #6 Interpret nonlinear terms with margins and marginsplot ////////////////
* After estimating m4, run:
* margins, at(AGEP = (25(5)64))
margins, at(AGEP = (25(5)64))

* Plot and export the margins profile:
* use marginsplot
marginsplot

* export to processed_data/ps5_margins_age_m4.png
graph export "/Users/meganflores/Documents/UTSW/Sweat Programming/lecture_5_pset/processed_data/ps5_margins_age_m4.png", as(png) name("Graph") replace

/////////////////////// #7 Export a regression table with etable ////////////////
* Create one table with m1 m2 m3 m4.
* Include coefficients and standard errors.
* Include model statistics for N and R2
* Export to processed_data/ps5_regression_table.docx
etable, estimates(m1 m2 m3 m4) mstat(N) mstat(r2) export("processed_data/ps5_regression_table.docx", replace)

/////////////////////// #8 Basic prediction block ////////////////
* After m4, generate:
* ln_wage_hat from predict ..., xb
predict ln_wage_hat, xb

* resid from predict ..., residuals
predict resid, residuals

* wage_hat = exp(ln_wage_hat)
generate wage_hat = exp(ln_wage_hat)

* Report summary statistics for residuals and absolute prediction error.
gen abs_error = abs(WAGP - wage_hat)

summarize resid abs_error

* Report correlation between WAGP and wage_hat.
corr WAGP wage_hat

* Export a prediction file to processed_data/ps5_prediction_output.csv.
save "processed_data/ps5_prediction_output.csv", replace

/////////////////////// #9 Required macro-based keep list ////////////////
* Create local keepvars with variables needed in your final PS5 analysis file, including prediction outputs.
* Define:
* prediction_vars = "ln_hours in_m4_sample ln_wage_hat wage_hat resid abs_error"
local prediction_vars "ln_hours ln_wage_hat wage_hat resid abs_error"

* keepvars = "`required_vars' `prediction_vars'"
local keepvars "`required_vars' `prediction_vars'"

* Use keep `keepvars' (no hardcoded standalone keep command).
keep `keepvars'

* Verify all kept variables exist using a loop and confirm variable.
display "`keepvars'"

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

* Save processed_data/ps5_analysis_with_predictions.dta.
save "processed_data/ps5_analysis_with_predictions", replace

* Close the log
log close

