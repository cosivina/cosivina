% setpath (COSIVINA toolbox)
%   Adds the cosivina subfolders and, if found, the jsonlab folder to the 
%   Matlab path in order to allow full use of the cosivina framework.
%   
%   setpath(false) does not save the path for later sessions (default)
%   setpath(true) saves the path to pathdef.m file for latter sessions

function setpath(permanent)

if nargin < 1
  permanent = false;
end

release = version('-release');
releaseNum = str2double(release(1:4));
if isnan(releaseNum)
  fprintf(['Matlab version could not be determined. See the documentation for further \n' ...
    'information on compatibility if you encounter any problems. \n']);
elseif releaseNum < 2011
  fprintf(['Full functionality of the framework is only supported for Matlab R2011a \n'...
    'and later. Method ''copy'' will not be supported for Element and \n' ...
    'Simulator class. Class definition in file Element.m must be adjusted for \n' ...
    'compatibility with this Matlab version (see documentation for further \n', ...
    'details).\n']);
end

pbase = fileparts(mfilename('fullpath'));
p = {fullfile(pbase, 'base', ''), fullfile(pbase, 'controls', ''), fullfile(pbase, 'elements', ''), ...
  fullfile(pbase, 'mathTools', ''), fullfile(pbase, 'examples', ''), fullfile(pbase, 'visualizations', ''), ...
  fullfile(pbase, 'auxiliary', '')};

allfound = true;
for i = 1 : length(p)
  if isdir(p{i})
    addpath(p{i});
  else
    fprintf('Directory ''%s'' not found.\n', p{i});
    allfound = false;
  end
end
if allfound
  disp('All required directories added to path.');
end

jfound = false;

if exist('loadjson', 'file') == 2 && exist('savejson', 'file') == 2
  disp('JSONlab found in path.');
  jfound = true;
end

if ~jfound
  pj = fullfile(pbase, 'jsonlab', '');
  if isdir(pj)
    addpath(pj);
    fprintf('Directory ''%s'' added for JSONlab support.\n', pj);
    jfound = true;
  end
end

if ~jfound
  n = find(pbase == filesep, 1, 'last');
  if isempty(n)
    pbase = '';
  else
    pbase = fullfile(pbase(1:n), '');
  end
  pj = fullfile(pbase, 'jsonlab', '');
  if isdir(pj)
    addpath(pj);
    fprintf('Directory ''%s'' added for JSONlab support.\n', pj);
    jfound = true;
  end
end

if ~jfound
  disp('No directory found for JSONlab support. Saving and loading of configuration files may not be possible.');
end

if permanent
  saved = savepath;
  if saved == 0
    disp('Path saved successfully.');
  else
    disp('Path could not be saved for later sessions. You may not have write permission for pathdef.m file.');
  end
end

