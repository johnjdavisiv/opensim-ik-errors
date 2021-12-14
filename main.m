% Demo of how to get marker errors from IK
% John Davis
% IU Biomechanics Lab
% john@johnjdavis.io

% This script sets up IK, runs it on data from Rajagopal 2015, and analyzes the error for each
% marker. It also prints and plots a summary of the results.
addpath('./functions');
import org.opensim.modeling.*

%Important note: At least on Windows, if these are not in the working folder, you must provide
%ABSOLUTE paths (C:/users/john/...), not relative paths ('./data/subject_01/...')
scaled_model_file = 'subject_scaled_run.osim';
trc_file = 'motion_capture_run.trc';
ik_template = 'ik_setup_run.xml';
results_dir = 'ik_results';

%For naming results
[~, trial_name] = fileparts(trc_file);
ik_result_file = [results_dir, '/', trial_name, '_ik.mot'];

ik_tool = InverseKinematicsTool(ik_template);
ik_tool.set_model_file(scaled_model_file);

%To output marker locations, must change this setting!
ik_tool.set_report_marker_locations(true);

% Get trc data to determine time range
marker_data = MarkerData(trc_file);
initial_time = marker_data.getStartFrameTime();
final_time = marker_data.getLastFrameTime();

% Setup the ikTool for this trial
ik_tool.setName(trial_name);
ik_tool.setMarkerDataFileName(trc_file);
ik_tool.setStartTime(initial_time);
ik_tool.setEndTime(final_time);
ik_tool.setOutputMotionFileName(ik_result_file);
ik_tool.setResultsDir(results_dir)
ik_tool.set_report_errors(false); %Only reports total errors, not individual markers!

% Save the settings in a setup file
trial_ik_config_file = [results_dir, '/', trial_name, '_ik_setup.xml'];
ik_tool.print(trial_ik_config_file);

fprintf('Running IK...\n');
ik_tool.run();
fprintf('IK analysis complete\n');

%% ------- Marker error ---------

%IK marker locations are saved as [trial_name, '_model_marker_locations.sto']
% (AFAIK the user has no ability to change this filename)
ik_marker_file = strrep(ik_result_file, '.mot', '_model_marker_locations.sto');

%Note: My 'read_mot' function actually works on .mot and .sto
[ik_marker_data, ik_marker_header] = read_mot(ik_marker_file);
[mocap_marker_data, mocap_marker_header] = read_trc(trc_file);

%Farm out to our error function
[marker_errors, marker_names] = get_marker_error(ik_marker_data,...
    ik_marker_header, mocap_marker_data, mocap_marker_header);

%Repackage into a sto with time column and save
error_filename = [results_dir, '/', trial_name, '_ik_marker_errors.sto'];
write_sto([ik_marker_data(:,1), marker_errors],...
    [{'time'}, marker_names], ...
    error_filename, 'IK model marker errors vs experimental data');

%% Show off cool plotting utility!

%Interpreting this plot: 
% 1) Bar goes out to the mean error
% 2) Dot is at the 99th percentile
% 3) End of the line is at the maximum

plot_marker_errors(error_filename, ik_tool.getIKTaskSet);
%Taskset is needed only if you want to annotate the plot with each marker's IK weight

