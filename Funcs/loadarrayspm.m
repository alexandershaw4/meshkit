function o = loadarrayspm(in)
% Same as loadarray.m but for spm datafiles.
% Loads a cell array of file names (in) into array of structures (o).
% AS2016 [util]

warning off

try in = {in.name}; end     % in case of input from 'dir'
if ~iscell(in); return; end % nope

for i = 1:size(in,1)
    for j = 1:size(in,2)
        clear t
        t = spm_eeg_load(in{i,j});
        o{i,j} = t;
    end
end