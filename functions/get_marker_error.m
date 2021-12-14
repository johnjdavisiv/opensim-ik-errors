function [marker_errors, marker_names] = get_marker_error(ik_marker_data,...
    ik_marker_header, mocap_marker_data, mocap_marker_header)
%Compute absolute error for each marker

%Input validation
if size(ik_marker_data,1) ~= size(mocap_marker_data,1)
    error('Different number of frames in IK and mocap data!');
end

%First column is time so forget that one
if mod(size(ik_marker_data,2)-1,3) ~= 0
    error('Marker columns not a multiple of three!');
end

%First column is Frame# and second is Time
if mod(size(mocap_marker_data,2)-2,3) ~= 0
    error('Marker columns not a multiple of three!');
end

%Parse headers differently bc different file types (trc vs mot/sto?)
mocap_cols = get_trc_columns(mocap_marker_data,mocap_marker_header);
ik_cols = strip(strsplit(ik_marker_header{end}, '\t'));

%Clever regexprep to get a list of the markers on the model
ik_markers = unique(regexprep(ik_cols(2:end), '_t[xyz]', '')); %exclude "time" col
marker_names = ik_markers;
n_ik_markers = length(ik_markers);
marker_errors = NaN(size(ik_marker_data,1), n_ik_markers); %Marker error will be NaN if missing in experimental data

for a=1:n_ik_markers
    %Directly index into ik columns
    xi_ik = matches(ik_cols, [ik_markers{a}, '_tx']);
    yi_ik = matches(ik_cols, [ik_markers{a}, '_ty']);
    zi_ik = matches(ik_cols, [ik_markers{a}, '_tz']);

    %...and into mocap columsn
    xi_m = matches(mocap_cols, [ik_markers{a}, 'X']);
    yi_m = matches(mocap_cols, [ik_markers{a}, 'Y']);
    zi_m = matches(mocap_cols, [ik_markers{a}, 'Z']);

    %Get vector representations of this marker
    v_ik = [ik_marker_data(:,xi_ik), ...
        ik_marker_data(:,yi_ik), ...
        ik_marker_data(:,zi_ik)]; % already in meters
    
    v_m = [mocap_marker_data(:,xi_m), ...
        mocap_marker_data(:,yi_m),...
        mocap_marker_data(:,zi_m)]/1000; %mm to meters! 
    
    %Get distance
    dv = v_ik - v_m;
    d_err = sqrt(dv(:,1).^2 + dv(:,2).^2 + dv(:,3).^2);
    marker_errors(:,a) = d_err;
    
    %This is mean absolute error
    fprintf('Error: %.2f cm (%.2f in) for %s\n', ...
        mean(d_err, 'omitnan')*100, ...
        mean(d_err, 'omitnan')*100/2.54, ...
        ik_markers{a});
end
