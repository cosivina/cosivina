% Simulator (COSIVINA toolbox)
%   Core class to create a neurodynamic architecture and simulate evolution
%   of activation distributions over time.
%
% Constructor call:
% Simulator()
%   creates a simulator with default settings
% Simulator(propertyName1, value1, ..., propertyNameN, valueN)
%   specifies additional settings; each propertyName must be one of the
%   following strings:
%   deltaT - specifies the time difference for every simulation step
%   tZero - specifies the simulation time on initialization
%   struct - load simulator from struct (given by the following value)
%   file - load simulator from parameter file (file name given by value)
%
% Methods for creating architectures:
% addElement(element, inputLabels, inputComponents, targetLabels, 
%   componentsForTargets) - adds a new element to the architecture, which
%   receives inputs specified by inputLabels and inputComponents, and
%   provides outputs specified by componentsForTargets to elements
%   specified by targetLabels; the parameter 'element' is an element handle
%   (obtained by calling an element constructor), the other parameters are
%   all strings or cell arrays of strings
% addConnection(inputLabels, inputComponents, targetLabel) - adds new
%   connections from one or more existing elements, specified by
%   inputLabels and inputComponents, to the element specified by
%   targetLabel; arguments inputLabels and inputComponents can be strings
%   or cell arrays of strings, targetLabel must be a single string
%
% Methods for running simulations:
% init() - initializes the simulator
% step() - performs one simulation step
% close() - closes all elements (only needed when elements create connection
%   to external devices or programs)
% run(tMax, initialize, closeWhenFinished) - runs the simulator until
%   simulation time reaches tMax; initializes and closes the simulator when
%   optional arguments are set to true
%
% Methods for debugging:
% tryInit() - like init, but with additional information if errors occur
% tryStep() - like step, but with additional information if errors occur
%
% Methods for accessing elements:
% isElements(label) - checks whether a string is an existing element label
% getElement(elementLabel) - return handle to element specified by
%   elementLabel
% getComponent(elementLabel, componentName) - returns the specified
%   component (typically a numeric matrix) of the element identified by
%   elementLabel (both arguments must be strings)
% getElementParameter(elementLabel, parameterName) - returns the specified
%   parameter of the element identified by elementLabel (both arguments
%   must be strings)
% setElementParameters(elementLabels, parameterNames, newValues) - sets one
%   or more parameter values of one or more elements, re-initializes and
%   calls step function of element if necessary for changes to take effect;
%   arguments elementLabels and parameterNames must be strings or cell
%   arrays of strings, newValues must be variable of appropriate type
%   for the specified parameter, or cell array of such variables
%
% Other methods:
% copy() - create copy of the simulator object and all its elements
% saveSettings(filename) - saves architecture settings to file in JSON
%   format
% loadSettings(filename, parameters) - load parameter settings from file in 
%   JSON format; optional argument parameters can be either 'all' (overwrite 
%   all parameters; default) or 'changeable' (overwrite only parameters that 
%   can be changed in GUI)


classdef Simulator < handle
  
  properties (SetAccess = protected)
    nElements = 0;
    elements = {};
    elementLabels = {};
    
    initialized = false;
  end
  
  properties (SetAccess = public)
    deltaT = 1;
    tZero = 0;
    t = 0;
  end
  
  methods
    % constructor (supports loading from file or from struct)
    function obj = Simulator(varargin)
      validParamNames = {'deltaT', 'tZero', 'struct', 'file'};
      if mod(length(varargin), 2) ~= 0
        error('Simulator:Constructor:invalidArgumentNumber', 'Arguments must be list of parameter name / value pairs.');
      end
      nParams = length(varargin)/2;
      params = varargin(1:2:2*nParams);
      values = varargin(2:2:2*nParams);
      
      for i = 1 : nParams
        if ~any(strcmp(params{i}, validParamNames))
          error('Simulator:Constructor:invalidArgument', ...
            'Argument ''%s'' is not a valid parameter name for a Simulator object.', params{i});
        end
      end
      
      iStruct = find(strcmp('struct', params), 1);
      iFile = find(strcmp('file', params), 1);
      iDeltaT = find(strcmp('deltaT', params), 1);
      iTZero = find(strcmp('tZero', params), 1);
      
      if ~isempty(iFile)
        fid = fopen(values{iFile}, 'r');
        if fid == -1
          warning('Simulator:Constructor:cannotReadFile', ...
            'File ''%s'' cannot be opened for reading simulator settings. Simulator object will be empty.', ...
            values{iFile});
        else
          str = fscanf(fid, '%c');
          jsonStruct = loadjson(str);
          obj.fromStruct(jsonStruct.simulator);
          fclose(fid);
        end
      elseif ~isempty(iStruct)
        obj.fromStruct(values{iStruct});
      end
      
      if ~isempty(iDeltaT)
        obj.deltaT = values{iDeltaT};
      end
      if ~isempty(iTZero)
        obj.tZero = values{iTZero};
      end
    end
    
    
    % destructor
    function delete(obj)
      obj.elements = {};
    end
    
    
    % copy simulator (copies all elements)
    function clonedSimulator = copy(obj)
      clonedSimulator = Simulator('deltaT', obj.deltaT, 'tZero', obj.tZero);
      clonedSimulator.t = obj.t;
      clonedSimulator.initialized = obj.initialized;
      
      clonedSimulator.nElements = obj.nElements;
      clonedSimulator.elementLabels = obj.elementLabels;
      clonedSimulator.elements = cell(size(obj.elements));
      for i = 1 : obj.nElements
        clonedSimulator.elements{i} = copy(obj.elements{i});
      end
      % rewire inputs
      for i = 1 : obj.nElements
        for j = 1 : obj.elements{i}.nInputs
          k = find(strcmp(obj.elementLabels, obj.elements{i}.inputElements{j}.label), 1);
          clonedSimulator.elements{i}.inputElements{j} = clonedSimulator.elements{k};
        end
      end
    end
    
    
    % initialization
    function obj = init(obj)
      obj.t = obj.tZero;
      for i = 1 : obj.nElements
        init(obj.elements{i});
      end
      obj.initialized = true;
    end
    
    
    % perform one step of the simulation
    function obj = step(obj)
      obj.t = obj.t + obj.deltaT;
      
      % access to properties slow, faster to copy into tmp variables
      tmpElements = obj.elements;
      tmpT = obj.t;
      tmpDeltaT = obj.deltaT;
      
      for i = 1 : obj.nElements
        step(tmpElements{i}, tmpT, tmpDeltaT);
      end
    end
    
    
    % close all elements
    function obj = close(obj)
      for i = 1 : obj.nElements
        close(obj.elements{i});
      end
    end
    
    
    % run the simulation (current t to tMax)
    function obj = run(obj, tMax, initialize, closeWhenFinished)
      if ~obj.initialized || nargin >= 3 && initialize
        init(obj);
      end

      while obj.t < tMax
        step(obj);
      end
      
      if nargin >= 4 && closeWhenFinished
        close(obj);
      end
    end
    
    
    % step function with time measurement
    function runTimes = stepWithTimer(obj)
      obj.t = obj.t + obj.deltaT;
      
      % access to properties slow, faster to copy into tmp variables
      tmpElements = obj.elements;
      tmpT = obj.t;
      tmpDeltaT = obj.deltaT;
      
      runTimes = zeros(obj.nElements, 1);
      
      for i = 1 : obj.nElements
        tic
        step(tmpElements{i}, tmpT, tmpDeltaT);
        runTimes(i) = toc;
      end
    end
    
    
    % run the simulation (current t to tMax)
    function runTimes = runWithTimer(obj, tMax, initialize, closeWhenFinished)
      if ~obj.initialized || nargin >= 3 && initialize
        init(obj);
      end
      
      runTimes = zeros(obj.nElements, 1);
      
      while obj.t < tMax
        runTimes = runTimes + stepWithTimer(obj);
      end
      
      if nargin >= 4 && closeWhenFinished
        close(obj);
      end
    end
    
    
    % initialize object with try/catch catch blocks and report which
    % elements cause errors
    function obj = tryInit(obj)
      for i = 1 : obj.nElements
        try
          init(obj.elements{i});
        catch errorMessage
          disp(['Element ''' obj.elementLabels{i} ''' caused an error during initialization.']);
          disp(['Error message: ' errorMessage.message]);
          disp(['Element ''' obj.elementLabels{i} ''':']);
          obj.elements{i} %#ok<NOPRT>
          return;
        end
      end
      obj.t = obj.tZero;
      obj.initialized = true;
    end
    
    
    % perform one step of the simulation with try/catch blocks and report
    % which elements cause errors
    function obj = tryStep(obj)
      obj.t = obj.t + obj.deltaT;
      for i = 1 : obj.nElements
        try
          step(obj.elements{i}, obj.t, obj.deltaT);
        catch errorMessage
          disp(['Element ''' obj.elementLabels{i} ''' caused an error in step function at time ' num2str(obj.t) '.']);
          disp(['Error message: ' errorMessage.message]);
          disp(['Element ''' obj.elementLabels{i} ''':']);
          obj.elements{i} %#ok<NOPRT>
          disp('Input components:');
          for j = 1 : obj.elements{i}.nInputs
            disp(['element ''' obj.elements{i}.inputElements{j}.label ''', component ''' , ...
              obj.elements{i}.inputComponents{j}, ...
              ''', size: [', num2str(size(obj.elements{i}.inputElements{j}.(obj.elements{i}.inputComponents{j}))) ']']);
          end
          return;
        end
      end
    end
    
    
    % add new element with connections
    function obj = addElement(obj, element, inputLabels, inputComponents, targetLabels, componentsForTargets) %, inputInfo, targetInfo)
      if ~isa(element, 'Element')
        error('Simulator:addElement:invalidElement', ...
          'Argument ''element'' must be an object handle of a class derived from the superclass ''Element''.');
      end
      if isempty(element.label) || ~ischar(element.label) || size(element.label, 1) ~= 1
        error('Simulator:addElement:invalidLabel', 'Label of added element must be a non-empty character string.');
      end
      if any(strcmp(element.label, obj.elementLabels))
        error('Simulator:addElement:duplicateLabel', 'Label ''%s'' is already used in simulator object.', ...
          element.label);
      end
      for i = 1 : obj.nElements
        if element == obj.elements{i}
          error('Simulator:addElement:duplicateHandle', ...
            ['A handle to the same element object already exists in the simulator object. ' ...
            'Create a new instance of the element class to add another element of the same type to the simulator.']);
        end
      end
      
      obj.nElements = obj.nElements + 1;
      obj.elementLabels{end+1} = element.label;
      obj.elements{end+1} = element;
      
      if nargin >= 3 && ~isempty(inputLabels) % inputs to the new element
        if ~iscell(inputLabels)
          inputLabels = cellstr(inputLabels);
        end
        
        if nargin < 4 || isempty(inputComponents)
          inputComponents = cell(numel(inputLabels), 1);
        elseif ~iscell(inputComponents)
          inputComponents = cellstr(inputComponents);
        end
        
        if numel(inputLabels) ~= numel(inputComponents)
          error('Simulator:addElement:inconsistentArguments', ...
            'Argument ''inputComponents'' must have the same number of entries as argument ''inputLabels'', or be empty.')
        end
        
        for i = 1 : numel(inputLabels)
          elementIndex = find(strcmp(inputLabels{i}, obj.elementLabels), 1);
          if isempty(elementIndex)
            error('Simulator:addElement:invalidInputLabel', ...
              'Element label ''%s'' requested as input for new element not found in simulator object.', ...
              inputLabels{i});
          end
          inputHandle = obj.elements{elementIndex};
          if isempty(inputComponents{i})
            element.addInput(inputHandle, inputHandle.defaultOutputComponent());
          elseif inputHandle.isComponent(inputComponents{i})
            element.addInput(inputHandle, inputComponents{i});
          else
            error('Simulator:addElement:invalidInputComponent', ...
              'Invalid input component ''%s'' requsted for input element ''%s''.', ...
              inputComponents{i}, inputLabels{i});
          end
        end
      end
      
      if nargin  >= 5 && ~isempty(targetLabels) % inputs from the new element
        if ~iscell(targetLabels)
          targetLabels = cellstr(targetLabels);
        end
        
        if nargin < 6 || isempty(componentsForTargets)
          componentsForTargets = cell(numel(targetLabels), 1);
        elseif ~iscell(componentsForTargets)
          componentsForTargets = cellstr(componentsForTargets);
        end
        
        if numel(targetLabels) ~= numel(componentsForTargets)
          error('Simulator:addElement:inconsistentArguments', ...
            ['Argument ''componentsForTargets'' must have the same number of entries as argument ''targetLabels''', ...
            'or be empty.'])
        end
        
        for i = 1 : numel(targetLabels)
          elementIndex = find(strcmp(targetLabels{i}, obj.elementLabels), 1);
          if isempty(elementIndex)
            error('Simulator:addElement:invalidTargetLabel', ...
              'Element label ''%s'' requested as target for new element not found in simulator object', ...
              targetLabels{i});
          end
          targetHandle = obj.elements{elementIndex};
          if isempty(componentsForTargets{i})
            targetHandle.addInput(element, element.defaultOutputComponent);
          elseif element.isComponent(componentsForTargets{i})
            targetHandle.addInput(element, componentsForTargets{i});
          else
            error('Simulator:addElement:invalidComponentForTarget', ...
              'Invalid component ''%s'' of new element requsted for target element ''%s''.', ...
              componentsForTargets{i}, targetLabels{i});
          end
        end
      end
    end
    
    
    % add a new connections between existing elements
    function obj = addConnection(obj, inputLabels, inputComponents, targetLabel)
      if nargin < 4 || ~ischar(targetLabel)
        error('Simulator:addConnection:noTargetLabel', ...
          'Argument targetLabel must be a single string.');
      end
      elementIndex = find(strcmp(targetLabel, obj.elementLabels), 1);
      if isempty(elementIndex)
        error('Simulator:addConnection:invalidTargetLabel', ...
          'Element label ''%s'' requested as target for connection not found in simulator object.', ...
          targetLabel);
      end
      targetHandle = obj.elements{elementIndex};
      
      if ~iscell(inputLabels)
        inputLabels = cellstr(inputLabels);
      end
      if isempty(inputComponents)
        inputComponents = cell(numel(inputLabels), 1);
      elseif ~iscell(inputComponents)
        inputComponents = cellstr(inputComponents);
      end
      
      if numel(inputLabels) ~= numel(inputComponents)
        error('Simulator:addConnection:inconsistentArguments', ...
            'Argument ''inputComponents'' must have the same number of entries as argument ''inputLabels'', or be empty.')
      end
      
      for i = 1 : numel(inputLabels)
        elementIndex = find(strcmp(inputLabels{i}, obj.elementLabels), 1);
        if isempty(elementIndex)
          error('Simulator:addConnection:invalidInputLabel', ...
            'Element label ''%s'' requested as input for connection not found in simulator object.', ...
            inputLabels{i});
        end
        inputHandle = obj.elements{elementIndex};
        if isempty(inputComponents{i})
          targetHandle.addInput(inputHandle, inputHandle.defaultOutputComponent);
        elseif inputHandle.isComponent(inputComponents{i})
          targetHandle.addInput(inputHandle, inputComponents{i});
        else
          error('Simulator:addElement:invalidInputComponent', ...
            'Invalid input component ''%s'' requsted for input element ''%s''.', ...
            inputComponents{i}, inputLabels{i});
        end
      end

    end
    
    
    % check whether string matches label of an element in the simulator object
    function r = isElement(obj, label)
      r = any(strcmp(label, obj.elementLabels));
    end
    
    
    % get element handle for element label
    function elementHandle = getElement(obj, elementLabel)
      i = find(strcmp(elementLabel, obj.elementLabels), 1);
      if isempty(i)
        elementHandle = [];
      else
        elementHandle = obj.elements{i};
      end
    end
    
    
    % get component of an element
    function component = getComponent(obj, elementLabel, componentName)
      i = find(strcmp(elementLabel, obj.elementLabels), 1);
      if isempty(i)
        error('Simulation:getComponent:unknownElement', 'No element ''%s'' in simulator object.', elementLabel);
      end
      
      if obj.elements{i}.isComponent(componentName)
        component = obj.elements{i}.(componentName);
      else
        error('Simulation:getComponent:invalidComponent', ...
          'Invalid component %s for element %s in simulator object.', componentName, elementLabel);
      end
    end
    
    
    % get parameter value of an element
    function value = getElementParameter(obj, elementLabel, parameterName)
      i = find(strcmp(elementLabel, obj.elementLabels), 1);
      if isempty(i)
        error('Simulation:getElementParameter:unknownElement', 'No element ''%s'' in simulator object.', elementLabel);
      end
      
      if obj.elements{i}.isParameter(parameterName)
        value = obj.elements{i}.(parameterName);
      else
        error('Simulation:getElementParameter:invalidParameter', ...
          'Invalid parameter ''%s'' for element ''%''s in simulator object.', parameterName, elementLabel);
      end
    end
    
    
    % set multiple parameters of one or multiple elements, re-initialize
    % and perform step if necessary to apply changes
    function obj = setElementParameters(obj, elementLabels, parameterNames, newValues)
      if ischar(elementLabels)
        elementLabels = cellstr(elementLabels);
      end
      if ischar(parameterNames)
        parameterNames = cellstr(parameterNames);
      end
      if ~iscell(newValues)
        if numel(parameterNames) == 1
          newValues = {newValues};
        else
          newValues = num2cell(newValues);
        end
      end
      if numel(parameterNames) ~= numel(newValues)
        error('Simulation:setElementParameter:argumentSizeMismatch', ...
          ['Arguments ''parameterNames'' and ''newValues'' must be cell arrays of the same size, ' ...
          'or a single string and a matrix/scalar value']);
      end
        
      % check newValues
      
      if numel(elementLabels) == 1
        nChangedElements = 1;
        elementLabelsUnique = elementLabels;
        parameterNamesSorted = {parameterNames};
        valuesSorted = {newValues};
      else
        [elementLabelsUnique, I1, I2] = unique(elementLabels); %#ok<ASGLU>
        nChangedElements = numel(elementLabelsUnique);
        parameterNamesSorted = cell(nChangedElements, 1);
        valuesSorted = cell(nChangedElements, 1);
        for i = 1 : nChangedElements
          parameterNamesSorted{i} = parameterNames(I2 == i);
          valuesSorted{i} = newValues(I2 == i);
        end
      end
      
      for i = 1 : nChangedElements
        iElement = find(strcmp(elementLabelsUnique{i}, obj.elementLabels), 1);
        if isempty(iElement)
          error('Simulation:setElementParameter:unknownElement', 'No element %s in simulator object.', elementLabels{i});
        end
        elementHandle = obj.elements{iElement};
        
        elementStep = false;
        elementInit = false;
        
        for j = 1 : numel(parameterNamesSorted{i})
          if ~isParameter(elementHandle, parameterNamesSorted{i}{j})
            error('Simulation:setElementParameter:unknownParameter', ...
              'Invalid parameter %s for element %s in simulator object.', ...
              parameterNamesSorted{i}{j}, elementLabelsUnique{i});
          end
          
          changeStatus = getParamChangeStatus(elementHandle, parameterNamesSorted{i}{j});
          if ~ParameterStatus.isChangeable(changeStatus)
            error('Simulation:setElementParameter:fixedParameter', ...
              'Parameter %s for element %s cannot be changed because it has ParameterStatus ''Fixed''.', ...
              parameterNamesSorted{i}{j}, elementLabelsUnique{i});
          end
          
          elementHandle.(parameterNamesSorted{i}{j}) = valuesSorted{i}{j};
          elementInit = elementInit || ParameterStatus.requiresInit(changeStatus);
          elementStep = elementStep || ParameterStatus.requiresStep(changeStatus);
        end
        
        if obj.initialized
          if elementInit || elementStep
            init(elementHandle);
          end
          if elementStep
            step(elementHandle, obj.t, obj.deltaT);
          end
        end
      end
    end
    
    
    % save settings of simulator object in JSON format
    function success = saveSettings(obj, filename)
      simulator = obj.toStruct;
      str = savejson('simulator', simulator);
      
      fid = fopen(filename, 'w');
      if fid == -1
        success = false;
      else
        fprintf(fid, '%s', str);
        fclose(fid);
        success = true;
      end
    end
    
    
    % load settings from file in JSON format (keeps elements and connections the same)
    function success = loadSettings(obj, filename, parameters)
      changeableOnly = false;
      if nargin >= 3 
        if strcmpi(parameters, 'changeable')
          changeableOnly = true;
        elseif ~strcmpi(parameters, 'all')
          error('Simulator:loadSettings:invalidArgument', ...
            'Argument ''parameters'' must be either ''all'' or ''changeable''.');
        end
      end
      fid = fopen(filename, 'r');
      if fid == -1
        success = false;
      else
        str = fscanf(fid, '%c');
        jsonStruct = loadjson(str);
        obj.parametersFromStruct(jsonStruct.simulator, changeableOnly);
        fclose(fid);
        success = true;
      end
    end
    
    
    % set elements and parameters from json-compatible struct
    function obj = fromStruct(obj, simStruct)
      if ~iscell(simStruct.elements) % for compatibility with JSONlab versions before 0.9.1
        simStruct.elements = num2cell(simStruct.elements);
      end
      for i = 1 : simStruct.nElements
        if ~iscell(simStruct.elements{i}.input)
          simStruct.elements{i}.input = num2cell(simStruct.elements{i}.input);
        end
      end
      
      obj.deltaT = simStruct.deltaT;
      obj.tZero = simStruct.tZero;
      
      obj.nElements = simStruct.nElements;
      obj.elementLabels = cell(1, obj.nElements);
      obj.elements = cell(1, obj.nElements);
      
      % create elements and set parameters
      for i = 1 : obj.nElements
        obj.elementLabels{i} = simStruct.elements{i}.label;
        obj.elements{i} = feval(simStruct.elements{i}.class);
        obj.elements{i}.label = simStruct.elements{i}.label;
        
        paramNames = obj.elements{i}.getParameterList();
        for j = 1 : length(paramNames)
          if isfield(simStruct.elements{i}.param, paramNames{j})
            obj.elements{i}.(paramNames{j}) = simStruct.elements{i}.param.(paramNames{j});
          end
        end
      end
      
      % create inputs (after all elements have been created to avoid invalid handles)
      for i = 1 : obj.nElements
        for j = 1 : simStruct.elements{i}.nInputs
          iInput = find(strcmp(simStruct.elements{i}.input{j}.label, obj.elementLabels), 1);
          obj.elements{i}.addInput(obj.elements{iInput}, simStruct.elements{i}.input{j}.component);
        end
      end
      
      obj.initialized = false;
    end
    
    
    % set parameters from json-compatible struct, keeping the existing elements and connections
    function obj = parametersFromStruct(obj, simStruct, changeableOnly)
      if nargin < 3
        changeableOnly = false;
      end
      
      if ~iscell(simStruct.elements) % for compatibility with JSONlab 0.9.1
        simStruct.elements = num2cell(simStruct.elements);
      end
      
      obj.deltaT = simStruct.deltaT;
      obj.tZero = simStruct.tZero;
      
      elementsOverwritten = zeros(1, obj.nElements);
      elementsNotFound = zeros(1, simStruct.nElements);
      
      for i = 1 : simStruct.nElements
        iHandle = find(strcmp(simStruct.elements{i}.label, obj.elementLabels), 1);
        if isempty(iHandle) || ~strcmp(class(obj.elements{iHandle}), simStruct.elements{i}.class)
          elementsNotFound(i) = true;
        else
          paramNames = obj.elements{iHandle}.getParameterList;
          for j = 1 : length(paramNames)
            if isfield(simStruct.elements{i}.param, paramNames{j}) && (~changeableOnly ...
                || ParameterStatus.isChangeable(obj.elements{iHandle}.getParamChangeStatus(paramNames{j})))
              obj.elements{iHandle}.(paramNames{j}) = simStruct.elements{i}.param.(paramNames{j});
            end
          end
          elementsOverwritten(iHandle) = true;
        end
      end
      
      obj.initialized = false;
      
      if ~all(elementsOverwritten) || any(elementsNotFound)
        msg = '';
        if ~all(elementsOverwritten)
          msg = [msg 'Some elements in the simulator object were not specified in the parameter struct' ...
            ' and will retain their previous settings: '];
          for i = find(~elementsOverwritten)
            msg = [msg class(obj.elements{i}) ' element ''' obj.elements{i}.label ''', ']; %#ok<AGROW>
          end
          msg = [msg(1:end-2) '\n'];
        end
        if any(elementsNotFound)
          msg = [msg, 'For some elements specified in the parameter struct, no matching elements were found' ...
            'in the simulator object: '];
          for i = find(elementsNotFound)
            msg = [msg simStruct.elements{i}.class ' element ''' simStruct.elements{i}.label ''', ']; %#ok<AGROW>
          end
          msg = [msg(1:end-2) '\n'];
        end
        warning('Simulator:parametersFromStruct:elementMismatch', msg);
      end
    end
    
    
    % convert settings of simulator object to json-compatible struct (for saving)
    function simStruct = toStruct(obj)
      elementsStruct = struct('label', obj.elementLabels, 'class', cell(1, obj.nElements), ...
        'param', cell(1, obj.nElements), 'nInputs', cell(1, obj.nElements), 'input', cell(1, obj.nElements));
      for i = 1 : obj.nElements
        elementsStruct(i) = toStruct(obj.elements{i});
      end
        
      simStruct = struct('deltaT', obj.deltaT, 'tZero', obj.tZero, 'nElements', obj.nElements, ...
        'elementLabels', {obj.elementLabels}, 'elements', elementsStruct);
    end
        
  end
  
end


