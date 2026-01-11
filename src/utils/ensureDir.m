function ensureDir(folderPath)
% ENSUREDIR Create folder if it does not exist.
if ~exist(folderPath, "dir")
    mkdir(folderPath);
end
end
