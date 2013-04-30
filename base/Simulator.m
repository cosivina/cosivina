% todo: test validity of input/target elements and components in addElement


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
            'File ''%s%'' cannot be opened for reading simulator settings. Simulator object will be empty.', ...
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
    
    
    % initialization
    function obj = init(obj)
      obj.t = obj.tZero;
      for i = 1 : obj.nElements
        obj.elements{i}.init();
      end
      obj.initialized = true;
    end
    
    
    % perform one step of the simulation
    function obj = step(obj)
      obj.t = obj.t + obj.deltaT;
      for i = 1 : obj.nElements
        obj.elements{i}.step(obj.t, obj.deltaT);
      end
    end
    
    
    % close all elements
    function obj = close(obj)
      for i = 1 : obj.nElements
        obj.elements{i}.close();
      end
    end
    
    
    % run the simulation (current t to tMax)
    function obj = run(obj, tMax, initialize, close)
      if ~obj.initialized || nargin >= 3 && initialize
        obj.init();
      end

      for tt = obj.t + obj.deltaT : obj.deltaT : tMax
        for i = 1 : obj.nElements
          obj.elements{i}.step(tt, obj.deltaT);
        end
      end
      obj.t = tt;
      if nargin >= 4 && close
        obj.close;
      end
    end
    
    
    % initialize object with try/catch catch blocks and report which
    % elements cause errors
    function obj = tryInit(obj)
      for i = 1 : obj.nElements
        try
          obj.elements{i}.init();
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
          obj.elements{i}.step(obj.t, obj.deltaT);
        catch errorMessage
          disp(['Element ''' obj.elementLabels{i} ''' caused an error in step function at time ' num2str(obj.t) '.']);
          disp(['Error message: ' errorMessage.message]);
          disp(['Element ''' obj.elementLabels{i} ''':']);
          obj.elements{i} %#ok<NOPRT>
          disp('Input components:');
          for j = 1 : obj.elements{i}.nInputs
            disp(['element ''' obj.elements{i}.inputElements{j}.label ''', component ''' , obj.elements{i}.inputComponents{j}, ...
              ''', size: [' num2str(size(obj.elements{i}.inputElements{j}.(obj.elements{i}.inputComponents{j}))) ']']);
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
        
        for i = 1 : numel(inputLabels)
          elementIndex = find(strcmp(inputLabels{i}, obj.elementLabels), 1);
          if isempty(elementIndex)
            error('Simulator:addElement:invalidInputLabel', ...
              'Element label ''%s'' requested as input for new element not found in simulator object', ...
              inputLabels{i});
          end
          inputHandle = obj.elements{elementIndex};
          if isempty(inputComponents{i})
            element.addInput(inputHandle, inputHandle.defaultOutputComponent());
          else
            element.addInput(inputHandle, inputComponents{i});
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
        
        for i = 1 : numel(targetLabels)
          elementIndex = find(strcmp(targetLabels{i}, obj.elementLabels), 1);
          if isempty(elementIndex)
            error('Simulator:addElement:invalidTargetLabel', ...
              'Element label ''%s'' requested as target for new element not found in simulator object', ...
              targetLabels{i});
          end
          targetHandle = obj.elements{elementIndex};
          if isempty(componentsForTargets{i})
            targetHandle.addInput(element, element.defaultOutputComponent());
          else
            targetHandle.addInput(element, componentsForTargets{i});
          end
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
        warning('Simulation:getComponent:unknownElement', 'No element %s in simulator object.', elementLabel);
        component = [];
      else
        if obj.elements{i}.isComponent(componentName)
          component = obj.elements{i}.(componentName);
        else
          warning('Simulation:getComponent:invalidComponent', ...
            'Invalid component %s for element %s in simulator object.', componentName, elementLabel);
          component = [];
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
    function success = loadSettings(obj, filename)
      fid = fopen(filename, 'r');
      if fid == -1
        success = false;
      else
        str = fscanf(fid, '%c');
        jsonStruct = loadjson(str);
        obj.parametersFromStruct(jsonStruct.simulator);
        fclose(fid);
        success = true;
      end
    end
      
    
    
    % set elements and parameters from json-compatible struct
    function obj = fromStruct(obj, simStruct)
      obj.deltaT = simStruct.deltaT;
      obj.tZero = simStruct.tZero;
      
      obj.nElements = simStruct.nElements;
      obj.elementLabels = cell(1, obj.nElements) ;
      obj.elements = cell(1, obj.nElements);
      
      % create elements and set parameters
      for i = 1 : obj.nElements
        obj.elementLabels{i} = simStruct.elements(i).label;
        obj.elements{i} = feval(simStruct.elements(i).class);
        obj.elements{i}.label = simStruct.elements(i).label;
        
        paramNames = obj.elements{i}.getParameterList();
        for j = 1 : length(paramNames)
          if isfield(simStruct.elements(i).param, paramNames{j})
            obj.elements{i}.(paramNames{j}) = simStruct.elements(i).param.(paramNames{j});
          end
        end
      end
      
      % create inputs (after all elements have been created to avoid invalid handles)
      for i = 1 : obj.nElements
        for j = 1 : simStruct.elements(i).nInputs
          iInput = find(strcmp(simStruct.elements(i).input(j).label, obj.elementLabels), 1);
          obj.elements{i}.addInput(obj.elements{iInput}, simStruct.elements(i).input(j).component);
        end
      end
      
      obj.initialized = false;
    end
    
    
    % set parameters from json-compatible struct, keeping the existing elements and connections
    function obj = parametersFromStruct(obj, simStruct)
      obj.deltaT = simStruct.deltaT;
      obj.tZero = simStruct.tZero;
      
      elementsOverwritten = zeros(1, obj.nElements);
      elementsNotFound = zeros(1, simStruct.nElements);
      
      for i = 1 : simStruct.nElements
        iHandle = find(strcmp(simStruct.elements(i).label, obj.elementLabels), 1);
        if isempty(iHandle) || ~strcmp(class(obj.elements{iHandle}), simStruct.elements(i).class)
          elementsNotFound(i) = true;
        else
          paramNames = obj.elements{iHandle}.getParameterList;
          for j = 1 : length(paramNames)
            if isfield(simStruct.elements(i).param, paramNames{j})
              obj.elements{i}.(paramNames{j}) = simStruct.elements(i).param.(paramNames{j});
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
            msg = [msg simStruct.elements(i).class ' element ''' simStruct.elements(i).label ''', ']; %#ok<AGROW>
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
        elementsStruct(i) = obj.elements{i}.toStruct;
      end
        
      simStruct = struct('deltaT', obj.deltaT, 'tZero', obj.tZero, 'nElements', obj.nElements, ...
        'elementLabels', {obj.elementLabels}, 'elements', elementsStruct);
    end
        
  end
  
end


