## Workflow for generating PAMpal AcousticStudy objects for glider data
# 
# Requires manually marked cetacean events (from Triton and simplified into an 
# a csv - agate has tools to do this)
#
# Creates several output .rds files:
#   'pamVer_***_params.rds': parameters (pps) input for PAMpal 
#   'pamVer_***_acSt.rds': 'acSt' AcousticStudy with all all detection feature 
#                           measurements by event
#
# Entire Process Overview
# 1a. Manually identify start/end times of possible odontocete events in Triton 
#     and clean up/reformat into a csv using agate's log clean up tools
# 1b. Run Pamguard click, WM, cepstrum detector
# 2. [THIS SCRIPT] Generate AcousticStudy - define params, calc features, apply
#    filter, output 'acSt' and 'acStFilt'
# OPTIONS for next steps
# - Generate acoustic event summary reports for manual review
# - Predict species with BANTER and save to events table


# ------ install/update necessary packages --------------------------------

# # Installation of CRAN versions - only have to run once
# install.packages('banter')
# install.packages('PAMpal')

# # OPTIONAL: install developmental versions of the packages
# make sure you have Rtools installed
# install.packages('crputils', repos=c('https://pifsc-protected-species-division.r-universe.dev','https://cloud.r-project.org'))
# pak::pak('taikisan21/PAMpal')

# library(here)
library(future)
library(PAMpal)
library(tidyverse)
library(crputils)

# turn on warnings
# options(warn = 1)
# options(warn = 2)


# ------ Set up parallel processing ---------------------------------------

# check current processing mode (sequential = normal processing)
plan() 

#check available cores
availableCores(logical = FALSE)

# set a multisession (parallel processing) plan with cores =< than avail
# TURN ON PARALLEL PROCESSING
#plan(multisession(workers=4))
plan()

# now, proceed as normal
#NOTE progress bars don't work - it will be stuck at 0 and that is OK. 

# ------ USER DEFINED INPUTS ----------------------------------------------
# define glider mission and PG version
# mission <- 'sg639_CalCurCEAS_Sep2024'
mission <- 'sg680_CalCurCEAS_Sep2024'
pgVer <- '20217a'

# define transfer function
calFile <- 0 # 'C:/path/cal.csv'; to skip calibration set to 0

# define paths
# This "analysis" folder must contain a subdirectory "pamguard" which then 
# contains the subdirectories "databases" and "binaries"
# OPTIONALLY, if you'd rather set each of those manually, they can be manually
# entered in the next section
# Generated AcousticStudies will be saved in an "acoustic_studies" folder in 
# the "pamguard" folder
path_analysis <- 'Q:/CalCurCEAS_fall_2024/analysis'

# Path to the event (triton) logs to be used for grouping 
path_log <- 'C:/Users/pam_user/Documents/GitHub/glider-CalCurCEAS/cetaceans/triton_log_derived'

# path_pg <- 'T:/glider_MHI_analysis/pamguard'
# path_out <- 'T:/glider_MHI_analysis/classification'

# ### configurable PAMpal settings - typically DO NOT change ###
# below is typical for the fkw/UO pipeline. Would need mods for bw, Kogia, etc.
sr_hz          <- 'auto'
filterfrom_khz <- 2
filterto_khz   <- NULL
winLen_sec     <- 0.0025


# ------ >>generated some variables from user inputs ----------------------
# these typically will not change but file names may need slight modifications
pgVerPrfx <- paste0('pam', pgVer)
# fnStr <- paste0('pam', pgVer, '_', mission)

# some paths
path_pg <- file.path(path_analysis, 'pamguard')

# some file paths
path_binaries <- file.path(path_pg, 'binaries', paste0(pgVerPrfx, '_glider_banter_', 
                                                mission))
dbFile <- file.path(path_pg, 'databases', paste0(pgVerPrfx, '_glider_banter_', 
                                                 mission, '.sqlite3'))
# merged triton log file
# logFile <- file.path(path_log, 
#                      paste0(mission, '_Pm_mw_sfReview_collapsed_forPAMpal.csv'))
logFile <- file.path(path_log,
                     paste0(mission, '_Pm_mw_collapsed_forPAMpal.csv'))

# files to be created
paramFile <- file.path(path_analysis, 'pamguard', 'acoustic_studies', 
                       paste0(pgVerPrfx, '_glider_banter_', mission, '_params.rds'))
acStFile <- file.path(path_analysis, 'pamguard', 'acoustic_studies',
                      paste0(pgVerPrfx, '_glider_banter_', mission, 
                             '_acousticStudy.rds'))
acStFiltFile <- file.path(path_analysis, 'pamguard', 'acoustic_studies',
                          paste0(pgVerPrfx, '_glider_banter_', mission, 
                                 '_acousticStudyFiltered.rds'))

# ------ PAMpal steps -----------------------------------------------------


# ------ >>define parameters ----------------------------------------------
# (database, binaries, default settings)

if (!file.exists(paramFile)){
  pps <- PAMpalSettings(db = dbFile, binaries = path_binaries, 
                        sr_hz = sr_hz, winLen_sec = winLen_sec,
                        filterfrom_khz = filterfrom_khz, 
                        filterto_khz = filterto_khz)
  # add calibration file
  # fkwPps <- addCalibration(fkwPps, calFile = calFile, units = 2, all = TRUE)
  # enter '16' when prompted for bit rate of data
  saveRDS(pps, file = paramFile)
} else if (file.exists(paramFile)){
  pps <- readRDS(paramFile)
  cat('Loaded existing paramFile:', paramFile, '\n')
}


# ------ >>process all events ---------------------------------------------
# pamguard detections into an acoustics study object
# (slow so only run if doesn't exist already)

if (!file.exists(acStFile)){
  acSt <- processPgDetections(pps, mode = 'time', id = mission,
                              grouping = logFile, 
                              format = '%m/%d/%Y %H:%M:%S')
  # format = '%m/%d/%Y %H:%M:%S')
  # the time format may need to be modified depending on how the csv was made
  saveRDS(acSt, file = acStFile)
  cat(length(names(events(acSt))), 'events processed and saved\n')
}else if (file.exists(acStFile)){
  acSt <- readRDS(acStFile)
  cat('Loaded existing acStFile:', acStFile, '\n')
  cat('AcousticStudy contains', length(names(events(acSt))), 'events\n')
}

# ------ Revert processing mode -------------------------------------------

# go back to sequential for regular life
plan(sequential)


# ------ >>filter out bad clicks ------------------------------------------
# apply 'standard' banter filter/clean up steps

# filters out:
# clicks with bandwidth at 10dB < 5 kHz, peak below 5 or above 80 kHz, duration 
# less than 2 ms or greater than 1000 ms AND cleans up within each detector by 
# peak (Click_Detector_1 peak > 2 & < 15, Click_Detector_2 peak > 15 & < 30, 
# Click_Detector_3 peak > 30 & < 50, Click_Detector_4 peak > 30 & < 50, 
# Click_Detector_5 peak > 50 & < 80

# 
if (!file.exists(acStFiltFile)){
  acStFilt <- crputils::er_filterClicks(acSt)
  
  # save filtered acSt
  saveRDS(acStFilt, file = acStFiltFile)
  # number of events may change after filtering (all clicks may be filtered out)
  cat(length(names(events(acStFilt))), 'events after filtering\n')
  
} else if (file.exists(acStFiltFile)){
  acStFilt <- readRDS(acStFiltFile)
  cat('Loaded existing acSFilttFile:', acStFiltFile, '\n')
  cat('Filtered AcousticStudy contains', length(names(events(acStFilt))), 'events\n')
}



