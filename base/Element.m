% Element (COSIVINA toolbox)
%   Abstract base class for architecture elements.

% header for Matlab versions before 2011a (copy function not supported):
% classdef Element < handle

% header for Matlab version 2011a and later:
classdef Element < matlab.mixin.Copyable
    
  properties (Abstract, Constant)
    parameters
    components
    defaultOutputComponent
  end
  
  properties
    label = '';
    nInputs = 0;
    inputElements = {};
    inputComponents = {};
  end
  
  methods (Abstract)
    obj = init(obj)
    obj = step(obj, time, deltaT)
  end
  
  methods
    % destructor method (manually clearing handles to other elements)
    function delete(obj)
      obj.inputElements = {};
    end
    
    
    % close open connections (e.g. to camera or robot)
    function obj = close(obj)
      % nothing to do for most elements
    end
    
    
    % add input to element
    function obj = addInput(obj, inputHandle, inputComponent, optArg) %#ok<INUSD>
      obj.nInputs = obj.nInputs + 1;
      obj.inputElements{end + 1} = inputHandle;
      obj.inputComponents{end + 1} = inputComponent;
    end
    
    
    % check if given string is parameter name in element
    function r = isParameter(obj, name)
      r = isfield(obj.parameters, name);
    end
    
    
    % check if given string is component name in element
    function r = isComponent(obj, name)
      r = any(strcmp(name, obj.components));
    end
    
    
    % get list of element parameters (as cell of string)
    function parameterList = getParameterList(obj)
      parameterList = fieldnames(obj.parameters);
    end
    
    
    % get param change status for given parameter name
    function status = getParamChangeStatus(obj, parameterName)
      if isfield(obj.parameters, parameterName)
        status = obj.parameters.(parameterName);
      else
        error('Element:getParamChangeStatus:unknownParameter', 'No parameter ''%s'' found in element.', parameterName);
      end
    end
    
    
    % convert element settings to struct
    function elementStruct = toStruct(obj)
      param = struct;
      parameterList = fieldnames(obj.parameters);
      
      for i = 1 : length(parameterList)
        param.(parameterList{i}) = obj.(parameterList{i});
      end
      
      if obj.nInputs == 0
        input = [];
      else
        input = struct('label', cell(1, obj.nInputs), 'component', obj.inputComponents);
        for i = 1 : obj.nInputs
          input(i).label = obj.inputElements{i}.label;
        end
      end
      
      elementStruct = struct('label', obj.label, 'class', class(obj), 'param', param, 'nInputs', obj.nInputs, ...
        'input', input);
    end
  end
end
