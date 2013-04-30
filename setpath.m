function setpath

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




