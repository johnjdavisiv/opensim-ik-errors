function plot_marker_errors(error_filename, ik_taskset)
%This function won't work to its full potential with the Rajagopal demo data, because the marker
%names differ from mine, but you should be able to see how you can implement a color-by-name scheme.

%Set taskset to [] if you don't want to print IK weights
import org.opensim.modeling.*
%debug
%error_filename = this_error_file;
%ik_taskset = taskset.safeCopy;


%% Plot marker errors and analyze
[err_data,err_header] = read_mot(error_filename);
marker_names = strip(strsplit(err_header{end}, '\t'));
marker_names = marker_names(2:end);

%Summarize - omit nan because a marker location will be NaN in the .trc error if it is (temporarily)
%missing, e.g. because the marker was briefly obscured
mean_err = mean(err_data(:,2:end), 1, 'omitnan')*100;
max_err = max(err_data(:,2:end), [], 1, 'omitnan')*100;
p99_err = quantile(err_data(:,2:end),0.99,1)*100;

%I usually set toes to NaN because I lock the MTP joint, so it always has large error
%(and I don't weigh the toe marker highly, if at all, in IK)
%ix_toe = matches(marker_names, 'R_toe') | matches(marker_names, 'L_toe');
%mean_err(ix_toe) = NaN;
%max_err(ix_toe) = NaN;
%p99_err(ix_toe) = NaN;

% Plot
figure('units', 'normalized', 'position', [0.05 0.05 0.8 0.85]);
hold on;
patch([2, 4, 4, 2], ...
    [0, 0, length(marker_names)+1, length(marker_names)+1], ...
    'yellow', 'FaceAlpha', 0.2, 'edgecolor', 'none');
patch([0, 2, 2, 0], ...
    [0, 0, length(marker_names)+1, length(marker_names)+1], ...
    'green', 'FaceAlpha', 0.2, 'edgecolor', 'none');

%Maybe modify with for loop with coloring by body locaiton
bmax = barh(max_err, 0.1);
bmean = barh(mean_err);
scatter(p99_err, 1:length(marker_names), 50, 'k', 'filled');

bmean.FaceColor = 'flat';
bmax.FaceColor = 'flat';

%This is set up to my own marker naming scheme...
cm = hsv(8);
back_mk = {'R_acr', 'L_acr', 'back_T', 'back_mid', 'back_B'};
pelvis_mk = {'R_gtroch', 'L_gtroch', 'R_asis','L_asis','R_psis','L_psis','R_ilium','L_ilium'};
R_thigh_mk = {'R_thigh', 'R_kneejoint'};
L_thigh_mk = {'L_thigh', 'L_kneejoint'};
R_shank_mk = {'R_shank','R_fibula', 'R_ankle'};
L_shank_mk = {'L_shank','L_fibula', 'L_ankle'};
R_foot_mk = {'R_heel','R_met', 'R_latfoot'};
L_foot_mk = {'L_heel','L_met', 'L_latfoot'};

for a=1:size(bmean.CData,1)   
    if contains(marker_names{a}, back_mk)
        sel_col = cm(1,:);
    elseif contains(marker_names{a}, pelvis_mk)
        sel_col = cm(2,:);
    elseif contains(marker_names{a}, R_thigh_mk)
        sel_col = cm(3,:);
    elseif contains(marker_names{a}, L_thigh_mk)
        sel_col = cm(4,:);
    elseif contains(marker_names{a}, R_shank_mk)
        sel_col = cm(5,:);
    elseif contains(marker_names{a}, L_shank_mk)
        sel_col = cm(6,:);
    elseif contains(marker_names{a}, R_foot_mk)
        sel_col = cm(7,:);
    elseif contains(marker_names{a}, L_foot_mk)
        sel_col = cm(8,:);
    else
        sel_col = [0.5 0.5 0.5];
    end
    bmean.CData(a,:) = sel_col;
    bmax.CData(a,:) = [0 0 0];
end

xlabel('Marker error (cm)');

set(gca, 'YTick', 1:length(marker_names)+1);
set(gca, 'YTickLabels', marker_names);
set(gca,'TickLabelInterpreter','none');

y_lim = 10; %For y axis limit
ylim([0 length(marker_names)+0.9]);
xlim([0, y_lim]);

t_str = strsplit(error_filename, '\');
t_str = strrep(t_str{end}, '_ik_marker_errors.sto', '');
title(t_str, 'interpreter', 'none');

% If taskset provided, also plot weight
%Little hacky but works ok
if ~isempty(ik_taskset)
    n_tasks = ik_taskset.getSize;
    for a=0:n_tasks-1
        %this_marker = char(ik_taskset.get(a).getName);
        yi = find(matches(marker_names, char(ik_taskset.get(a).getName)));
        if ~isempty(yi)
            if max_err(yi) < y_lim*0.95
                xi = max_err(yi)*1.01;
            elseif isnan(max_err(yi))
                xi = 0.25;
            else
                xi = 6;
            end
            text(xi,yi,sprintf('w=%.2f', ik_taskset.get(a).getWeight()));
        end
    end
end

end

