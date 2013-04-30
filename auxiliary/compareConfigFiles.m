% compareConfigFiles (COSIVINA toolbox)
%   Compare two Simulator configuration files in JSON format.
%
% compareConfigFiles(filenameA, filenameB) attempts to open the two files
%   and read in the configuration struct using LOADJSON. It then prints any
%   differences found between the two structs (added/removed elements,
%   changes in element classes, parameters, or inputs). The function
%   assumes that both files are valid configuration files for a COSIVINA
%   Simulator object.

function compareConfigFiles(filenameA, filenameB)

filenames = {filenameA, filenameB};
jsonStructs = cell(2, 1);
filesReadable = true;

for i = 1 : 2
  fid = fopen(filenames{i}, 'r');
  if fid == -1
    filesReadable = false;
  else
    str = fscanf(fid, '%c');
    jsonStructs{i} = loadjson(str);
    fclose(fid);
  end
end

if ~filesReadable
  error('compareConfigFiles:fileReadError', 'Could not read files.');
end

simA = jsonStructs{1}.simulator;
simB = jsonStructs{2}.simulator;

if ~iscell(simA.elements) % for compatibility with both JSONlab 0.9.1
  simA.elements = num2cell(simA.elements);
end
if ~iscell(simB.elements) % for compatibility with both JSONlab 0.9.1
  simB.elements = num2cell(simB.elements);
end

for iA = 1 : simA.nElements
  if ~iscell(simA.elements{iA}.input)
    simA.elements{iA}.input = num2cell(simA.elements{iA}.input);
  end
end
for iB = 1 : simB.nElements
  if ~iscell(simB.elements{iB}.input)
    simB.elements{iB}.input = num2cell(simB.elements{iB}.input);
  end
end



missingInA = true(1, simB.nElements);

fprintf('Comparing configuration files:\n%s \t|\t %s\n\n', filenameA, filenameB);

for iA = 1 : simA.nElements
  iB = find(strcmp(simA.elementLabels{iA}, simB.elementLabels), 1);
  
  if isempty(iB)
    fprintf('Element missing in second file: ''%s'' (%s)\n', simA.elementLabels{iA}, simA.elements{iA}.class);
  else
    missingInA(iB) = false;
    if ~strcmp(simA.elements{iA}.class, simB.elements{iB}.class)
      fprintf(['Class changed for element ''%s'':\n\tfile A: %s \t file B: %s\n' ...
        '\t(parameter changes for this element are not reported)\n'], ...
        simA.elementLabels{iA}, simA.elements{iA}.class, simB.elements{iB}.class);
    else
      parameterNames = fieldnames(simA.elements{iA}.param);
      nParameters = numel(parameterNames);
      parameterMismatch = false(1, nParameters);
      for iP = 1 : nParameters
        parameterMismatch(iP) =  ...
          any(simA.elements{iA}.param.(parameterNames{iP}) ~= simB.elements{iB}.param.(parameterNames{iP}));
      end
      if any(parameterMismatch)
        fprintf('Parameters changed for element ''%s'':\n', simA.elementLabels{iA});
        for iP = find(parameterMismatch)
          fprintf('\t%s: \t%s \t|\t %s\n', ...
            parameterNames{iP}, ...
            num2str(simA.elements{iA}.param.(parameterNames{iP})), ...
            num2str(simB.elements{iB}.param.(parameterNames{iP})));
        end
      end
    end
    
    nInputsA = simA.elements{iA}.nInputs;
    nInputsB = simB.elements{iB}.nInputs;
    inputMissingInA = true(1, nInputsA);
    inputMissingInB = true(1, nInputsB);
    for iIA = 1 : nInputsA
      for iIB = 1 : nInputsB
        if strcmp(simA.elements{iA}.input{iIA}.label, simB.elements{iB}.input{iIB}.label) ...
            && strcmp(simA.elements{iA}.input{iIA}.component, simB.elements{iB}.input{iIB}.component)
          inputMissingInA(iIA) = false;
          inputMissingInB(iIB) = false;
          break;
        end
      end
    end
    
    if any(inputMissingInA) || any(inputMissingInB)
      fprintf('Inputs changed for element ''%s'':\n', simA.elementLabels{iA});
      for iIA = find(inputMissingInA)
        fprintf('\tInput missing in first file: element ''%s'', component %s\n', ...
          simA.elements{iA}.input{iIA}.label, simA.elements{iA}.input(iIA).component);
      end
      for iIB = find(inputMissingInB)
        fprintf('\tInput missing in second file: element ''%s'', component %s\n', ...
          simB.elements{iB}.input{iIB}.label, simB.elements{iB}.input(iIB).component);
      end
    end
  end
end


for iB = find(missingInA)
  fprintf('Element missing in first file: ''%s'' (%s)\n', simB.elementLabels{iB}, simB.elements{iB}.class);
end




