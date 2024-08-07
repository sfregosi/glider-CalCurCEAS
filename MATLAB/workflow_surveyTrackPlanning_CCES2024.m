% WORKFLOW_SURVEYTRACKPLANNING for OR-CCES 2024 Glider Missions
%	Planned mission path kmls to targets file and pretty map
%
%	Description:
%       This script takes survey tracks created in Google Earth and saved
%       as .kml files and:
%       (1) creates properly formatted 'targets' files to be loaded onto
%       the gliders
%       (2) adds them to a publication-ready planned survey map figure
%       (3) creates a plot of the bathymetry profile along the targets
%       track 
%       (4) exports .csv of 5-km spaced waypoints and estimated arrival
%       dates/times to send to the Navy as a courtesy
%       (5) calculates full planned track distance and distance to end from
%       each waypoint for mission duration estimation
%       
%       This requires access to bathymetric basemaps for plotting and
%       requires manual creation of the track in Google Earth. Track must
%       be saved as a kml containing just a single track/path. More
%       information on creating a path in Google Earth can be found at 
%       https://sfregosi.github.io/agate-public/survey-planning.html#create-planned-track-using-google-earth-pro
%
%	See also
%
%	Authors:
%		S. Fregosi <selene.fregosi@gmail.com> <https://github.com/sfregosi>
%
%	FirstVersion: 	05 April 2023
%	Updated:        07 August 2024
%
%	Created with MATLAB ver.: 9.13.0.2166757 (R2022b) Update 4
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
path_repo = 'C:\Users\Selene.Fregosi\Documents\GitHub\glider-CCES';

col_sg639 = [1 1 0];
col_sg679 = [1 0.4 0];
col_sg680 = [1 0 0];

% specify expected avg glider speed in km/day
avgSpd = 18; % km/day

%% SG639 - Track A - Nearshore
CONFIG = agate(fullfile(path_repo, 'MATLAB', 'agate_config_sg639_CCES_Aug2024.cnf'));

% (1) Generate targets file from Google Earth path saved as .kmml
kmlFile = fullfile(path_repo, 'survey_planning', 'A_Nearshore_2024-08-06.kml');
radius = 2000;

% create targets file, use prefix-based naming
prefix = 'AN'; % Any two letters make easy to reference and read options
targetsFile = makeTargetsFile(CONFIG, kmlFile, prefix, radius);
[targets, ~] = readTargetsFile(CONFIG, targetsFile); 
[~, targetsName, ~] = fileparts(targetsFile);

% (2) Create basemap and plot it 
% create masemap plot
bathyOn = 1; contourOn = 1;
[baseFig] = createBasemap(CONFIG, bathyOn, contourOn, 20);
mapFigPosition = [2000   300    900    650];
baseFig.Position = mapFigPosition;

% plot planned track
plotm(targets.lat, targets.lon, 'Marker', 'o', 'MarkerSize', 4, ...
	'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', [0 0 0], 'Color', [0 0 0], ...
	'HandleVisibility', 'off')
textm(targets.lat+0.1, targets.lon-0.1, targets.name, 'FontSize', 10)

h(1) = linem(targets.lat, targets.lon, 'LineWidth', 2, 'Color', col_sg639,...
    'DisplayName', targetsName);

% (3) Plot bathymetry profile of targets file
plotTrackBathyProfile(CONFIG, targetsFile)
% change title
title(['Targets Bathymetry Profile: ' targetsName])

% save as .png
exportgraphics(gcf, fullfile(path_repo, 'survey_planning', ...
	 ['targetsBathymetryProfile_' targetsName, '.png']), ...
    'Resolution', 300)

% (4) Export approx 5 km spacing
% this will make points between 5 and 6 km apart along each segment
interpTrack = interpolatePlannedTrack(CONFIG, targetsFile, 5);
writetable(interpTrack, fullfile(path_repo, 'survey_planning', ...
	['trackPoints_', targetsName, '.csv']));
% have to manually add time information based on estimated glider speed

% (5) Summarize distance
for f = 1:height(targets) - 1
    [targets.distToNext_km(f), ~] = lldistkm([targets.lat(f+1) targets.lon(f+1)], ...
        [targets.lat(f) targets.lon(f)]);
end
fprintf(1, 'Total tracklength for %s: %.0f km\n', targetsName, ...
	sum(targets.distToNext_km));
fprintf(1, 'Estimated mission duration, at %i km/day: %.1f days\n', avgSpd, ...
	sum(targets.distToNext_km)/avgSpd);

%% SG679 - Track B - Nearshore
CONFIG = agate(fullfile(path_repo, 'MATLAB', 'agate_config_sg679_CCES_Aug2024.cnf'));

% (1) Generate targets file from Google Earth path saved as .kmml
kmlFile = fullfile(path_repo, 'survey_planning', 'B_Nearshore_2024-08-06.kml');
radius = 2000;

% create targets file, use prefix-based naming
prefix = 'BN'; % Any two letters make easy to reference and read options
targetsFile = makeTargetsFile(CONFIG, kmlFile, prefix, radius);
[targets, ~] = readTargetsFile(CONFIG, targetsFile); 
[~, targetsName, ~] = fileparts(targetsFile);

% (2) Add to map
set(0, 'currentfigure', baseFig);
plotm(targets.lat, targets.lon, 'Marker', 'o', 'MarkerSize', 4, ...
	'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', [0 0 0], 'Color', [0 0 0], ...
	'HandleVisibility', 'off')
textm(targets.lat+0.1, targets.lon-0.1, targets.name, 'FontSize', 10)

h(2) = linem(targets.lat, targets.lon, 'LineWidth', 2, 'Color', col_sg679,...
    'DisplayName', targetsName);

% (3) Plot bathymetry profile of targets file
plotTrackBathyProfile(CONFIG, targetsFile)
% change title
title(['Targets Bathymetry Profile: ' targetsName])

% save as .png
exportgraphics(gcf, fullfile(path_repo, 'survey_planning', ...
	 ['targetsBathymetryProfile_' targetsName, '.png']), ...
    'Resolution', 300)

% (4) Export approx 5 km spacing
% this will make points between 5 and 6 km apart along each segment
interpTrack = interpolatePlannedTrack(CONFIG, targetsFile, 5);
writetable(interpTrack, fullfile(path_repo, 'survey_planning', ...
	['trackPoints_', targetsName, '.csv']));
% have to manually add time information based on estimated glider speed

% (5) Summarize distance
for f = 1:height(targets) - 1
    [targets.distToNext_km(f), ~] = lldistkm([targets.lat(f+1) targets.lon(f+1)], ...
        [targets.lat(f) targets.lon(f)]);
end
fprintf(1, 'Total tracklength for %s: %.0f km\n', targetsName, ...
	sum(targets.distToNext_km));
fprintf(1, 'Estimated mission duration, at %i km/day: %.1f days\n', avgSpd, ...
	sum(targets.distToNext_km)/avgSpd);

%% SG680 - Track C - Offshore
CONFIG = agate(fullfile(path_repo, 'MATLAB', 'agate_config_sg680_CCES_Aug2024.cnf'));

% (1) Generate targets file from Google Earth path saved as .kmml
kmlFile = fullfile(path_repo, 'survey_planning', 'C_Offshore_2024-08-06.kml');
radius = 2000;

% create targets file, use prefix-based naming
prefix = 'CO'; % Any two letters make easy to reference and read options
targetsFile = makeTargetsFile(CONFIG, kmlFile, prefix, radius);
[targets, ~] = readTargetsFile(CONFIG, targetsFile); 
[~, targetsName, ~] = fileparts(targetsFile);

% (2) Add to map
set(0, 'currentfigure', baseFig);
plotm(targets.lat, targets.lon, 'Marker', 'o', 'MarkerSize', 4, ...
	'MarkerEdgeColor', [0 0 0], 'MarkerFaceColor', [0 0 0], 'Color', [0 0 0], ...
	'HandleVisibility', 'off')
textm(targets.lat+0.1, targets.lon-0.1, targets.name, 'FontSize', 10)

h(3) = linem(targets.lat, targets.lon, 'LineWidth', 2, 'Color', col_sg680,...
    'DisplayName', targetsName);

% (3) Plot bathymetry profile of targets file
plotTrackBathyProfile(CONFIG, targetsFile)
% change title
title(['Targets Bathymetry Profile: ' targetsName])

% save as .png
exportgraphics(gcf, fullfile(path_repo, 'survey_planning', ...
	 ['targetsBathymetryProfile_' targetsName, '.png']), ...
    'Resolution', 300)

% (4) Export approx 5 km spacing
% this will make points between 5 and 6 km apart along each segment
interpTrack = interpolatePlannedTrack(CONFIG, targetsFile, 5);
writetable(interpTrack, fullfile(path_repo, 'survey_planning', ...
	['trackPoints_', targetsName, '.csv']));
% have to manually add time information based on estimated glider speed

% (5) Summarize distance
for f = 1:height(targets) - 1
    [targets.distToNext_km(f), ~] = lldistkm([targets.lat(f+1) targets.lon(f+1)], ...
        [targets.lat(f) targets.lon(f)]);
end
fprintf(1, 'Total tracklength for %s: %.0f km\n', targetsName, ...
	sum(targets.distToNext_km));
fprintf(1, 'Estimated mission duration, at %i km/day: %.1f days\n', avgSpd, ...
	sum(targets.distToNext_km)/avgSpd);

%% Finalize figure
set(0, 'currentfigure', baseFig);

% add legend, title
legend(h(1:3), 'Interpreter', 'none', 'Location', 'southwest', 'FontSize', 12)
title('Planned CCES 2024 Glider Tracks')

% save as .png
exportgraphics(gcf, fullfile(path_repo, 'survey_planning', ...
	'option6_three_gliders.png'), 'Resolution', 300)

