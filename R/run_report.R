
# Use this script to run a single acoustic event summary report
# This allows for metadata settings and unique file names for each glider

# ###### MODIFY THESE #######
# mission name (for report contents)
# mission <- 'sg639_CalCurCEAS_Sep2024'
mission <- 'sg680_CalCurCEAS_Sep2024'
# path to pamguard folder (for building filenames)
path_pg <- 'Q:/CalCurCEAS_fall_2024/analysis/pamguard'
# ###########################

# ###### BUILD PARAMS #######
# path to AcousticStudies RDS files
path_acSt <- file.path(path_pg, 'acoustic_studies')
# name of AcousticStudy file (RDS)
acousticStudy <- paste0('pam20217a_glider_banter_', mission, '_acousticStudy.rds')
# name of filtered AcousticStudy file (RDS)
acousticStudyFiltered <- paste0('pam20217a_glider_banter_', mission, '_acousticStudyFiltered.rds')
# name of Pamguard database file
dbFile <- file.path(path_pg, 'databases', 
                    paste0('pam20217a_glider_banter_', mission, '.sqlite3'))
# path to Pamguard binaries folder
path_binaries <- file.path(path_pg, 'binaries',
                           paste0('pam20217a_glider_banter_', mission))
# output folder for event_summary tables and html report
path_out <- 'Q:/CalCurCEAS_fall_2024/analysis/event_reports'

# use defaults for these
# snrThreshold: 15 # SNR threshold for "good" clicks
# refSpec <- FALSE
# path_to_refSpec <- FALSE # path to reference spectra files, e.g., '//piccrp4nas/grampus/llharp/processingCode/llamp/files/reference_spectra'
# refSpecList <- !r c() # use !r to call r then
# refSpecSp <- !r c() #left it empty on purpose for the moment
# calFile <- FALSE


# ###### RUN THIS ###########
rmarkdown::render(
  "R/event_summary_report_glider_CalCurCEAS_2024.Rmd",
  params = list(
    useParamsFlag = TRUE,
    log = TRUE,
    survey = mission,
    path_acSt = path_acSt,
    acousticStudy = acousticStudy,
    acousticStudyFiltered = acousticStudyFiltered,
    dbFile = dbFile,
    path_binaries = path_binaries,
    path_out = path_out,
    reCalc = TRUE
  ),
  output_file = file.path(path_out, paste0("event_summary_report_glider_", 
                                           mission, '_', Sys.Date(), ".html"))
)



# to monitor the log file in real time (tail)
# In another R session, monitor the log in real-time:
# system(paste0('tail -f "', logFile, '"'))
