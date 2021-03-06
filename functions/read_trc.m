function [trc_data,trc_header] = read_trc(file_path)
%Read OpenSim-compatible .trc file

if ~contains(file_path, '.trc')
    error('File is not a TRC file!');
end

%Read header
fid = fopen(file_path);
trc_header = cell(6,1);  
f_line = 1;


while f_line < 7
    trc_header{f_line} = fgets(fid);
    f_line = f_line+1;
end
fclose(fid);

%Read data - replace readmatrix() with dlmread() if you have a MATLAB version lower than R2019a  
trc_data = readmatrix(file_path, 'FileType', 'text', ...
    'NumheaderLines', 6, 'delimiter', '\t');

end
