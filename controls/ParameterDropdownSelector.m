% ParameterDropdownSelector (COSIVINA toolbox)
%   Control that creates a dropdown menu with an accompanying text field in
%   the GUI. The menu allows to change the values of one or more parameters
%   between a number of presets.
%   Note: If parameters are initialized or changed via other controls to
%   take values that do not match any of the control's presets, the
%   dropdown selector is set to a newly added entry with label
%   [no matching entry].
% 
% Constructor call:
% ParameterDropdownSelector(controlLabel, elementLabels, ...
%   parameterNames, dropdownValues, dropdownLabels, ...
%   initialSelection, toolTip, position)
% 
% Arguments:
% controlLabel - label of the control displayed in the text field next to
%   the dropdown menu
% elementLabels - string or cell array of strings specifying the
%   labels of elements connected to this control
% parameterNames - string or cell array of strings specifying the names of
%   the element parameters controlled by this slider; arguments
%   elementLabels and parameterNames must have the same size, with each
%   pair of entries fully specifying one controlled parameter
% dropdownValues - a numerical array or a cell array of numerical arrays
%   specifying the parameter values associated with each menu entry; if the
%   control is connected to a single element parameter, this argument
%   should be an array with one valid parameter value for each item in the
%   dropdown menu; if multiple parameters are connected, it should be a
%   cell array of such arrays
% dropdownLabels - cell array of strings specifying the menu items in the
%   dropdown menu (optional, if not specified the dropdownValues for the
%   first connected parameter are used as labels)
% initialSelection - integer specifying the initial selection in the 
%   dropdown menu (optional, default is 1)
% tooltip - tooltip displayed when hovering over the control with the mouse
%   (optional)
% position - position of the control in the GUI figure window in relative
%   coordinates (optional, is overwritten when specifying a grid position
%   in the GUI's addControl function)
%
% Examples:
% h = ParameterDropdownSelector('p_sA', 'stimulus A', 'position', ...
%   [25, 50, 75], {'left', 'center', 'right'}, 2, ...
%   'position of stimulus A');
% h = ParameterDropdownSelector('d_s', {'stimulus A', 'stimulus B'},...
%   {'position', 'position'}, {[40, 45, 48], [60, 55, 52]}, ... 
%   {'far', 'close', 'very close'}, 1, 'distance between stimuli A and B');


classdef ParameterDropdownSelector < Control
  properties
    controlLabel
    elementLabels
    parameterNames
    dropdownValues
    dropdownLabels
    nEntries
    toolTip
    
    simulatorHandle
    nParameters
    dropdownHandle
    captionHandle
    
    noMatchingEntry = false; % the current parameter values do not match any presets of the dropdown menu
    
    relCaptionWidth = 0.2; % width of the caption field relative to total control width 
    relPaddingWidth = 0.025; % padding on both sides of the caption
    
    currentValue = 1;
  end
  
  
  methods
    % constructor
    function obj = ParameterDropdownSelector(controlLabel, elementLabels, parameterNames, dropdownValues, dropdownLabels, ...
        initialSelection, toolTip, position)
      obj.controlLabel = controlLabel;
      obj.elementLabels = elementLabels;
      obj.parameterNames = parameterNames;
      obj.dropdownValues = dropdownValues;
      if nargin >= 5
        obj.dropdownLabels = dropdownLabels;
      end
      if nargin >= 6 && ~isempty(toolTip)
        obj.toolTip = toolTip;
      else
        obj.toolTip = obj.controlLabel;
      end
      if nargin >= 7
        obj.currentValue = initialSelection;
      end
      if nargin >= 8
        obj.position = position;
      end
      
      % check consistency of arguments specifying the controlled elements and parameters
      if ~iscell(obj.elementLabels)
        obj.elementLabels = {obj.elementLabels};
      end
      if ~iscell(obj.parameterNames)
        obj.parameterNames = {obj.parameterNames};
      end
      obj.nParameters = length(obj.parameterNames);
      if ~iscell(obj.dropdownValues)
        obj.dropdownValues = {obj.dropdownValues};
      end
      
      
      if ~iscellstr(obj.elementLabels) || ~iscellstr(obj.parameterNames) ...
          || numel(obj.elementLabels) ~= obj.nParameters
        error('ParameterDropdownSelector:ParameterDropdownSelector:argumentMismatch', ...
          ['Arguments elementLabels and parameterNames must be strings or cell arrays of strings '...
          'with equal number of elements.']);
      end
      if numel(obj.dropdownValues) ~= obj.nParameters
        error('ParameterDropdownSelector:ParameterDropdownSelector:argumentMismatch', ...
          ['Number of vectors in argument dropdownValues must match number of parameters specified ' ...
          'in argument parameterNames.']);
      end
      
      % determine entries of dropdown menu, fill in labels if necessary
      obj.nEntries = numel(obj.dropdownValues{1});
      if isempty(obj.dropdownLabels)
        obj.dropdownLabels = cell(obj.nEntries, 1);
        for i = 1 : obj.nEntries
          obj.dropdownLabels{i} = num2str(obj.dropdownValues{1}(i));
        end
      end
      
      % check consistency of dropdownValues vectors, reformat for use in
      % setElementParameters method
      tmpValues = cell(obj.nEntries, 1);
      tmpValues(:) = {cell(1, obj.nParameters)};
      for i = 1 : obj.nParameters
        if numel(obj.dropdownValues{i}) ~= obj.nEntries
          error('ParameterDropdownSelector:ParameterDropdownSelector:argumentMismatch', ...
            'If argument dropdownValues is a cell array, all entries must be of the same size.');
        end
        for j = 1 : obj.nEntries
          tmpValues{j}{i} = obj.dropdownValues{i}(j);
        end
      end
      obj.dropdownValues = tmpValues;
      
      % check consistency of dropdownValues with dropdownLabels and
      % standardize shape of cell array dropdownLabels
      if numel(obj.dropdownLabels) ~= obj.nEntries
        error('ParameterDropdownSelector:ParameterDropdownSelector:argumentMismatch', ...
          'Size of argument dropdownLabels must match size of each vector in argument dropdownValues.');
      end
      obj.dropdownLabels = reshape(obj.dropdownLabels, [obj.nEntries, 1]);
    end
    
    
    % connect to simulator object
    function obj = connect(obj, simulatorHandle)
      obj.simulatorHandle = simulatorHandle;
      for i = 1 : obj.nParameters
        tmpElementHandle = simulatorHandle.getElement(obj.elementLabels{i});
        if isempty(tmpElementHandle) || ~tmpElementHandle.isParameter(obj.parameterNames{i})
          error('ParameterDropdownSelector:connect:invalidParameter', ...
            'No element ''%s'' with parameter ''%s'' in simulator object.', obj.elementLabels{i}, obj.parameterNames{i});
        end
        status = tmpElementHandle.getParamChangeStatus(obj.parameterNames{i});
        if ~ParameterStatus.isChangeable(status) || ParameterStatus.isMatrix(status)
          error('ParameterDropdownSelector:connect:parameterFixed', ...
            'Parameter ''%s'' in element ''%s'' is not a changeable scalar parameter and cannot be set by this GUI control.', ...
            obj.parameterNames{i}, obj.elementLabels{i});
        end
      end
    end
    
    
    % initialize control object
    function obj = init(obj, figureHandle)
      captionPosition = [obj.position(1) + obj.relPaddingWidth * obj.position(3), obj.position(2), ...
        obj.position(3) * obj.relCaptionWidth, obj.position(4)];
      dropdownPosition = [obj.position(1) + (obj.relCaptionWidth + 2*obj.relPaddingWidth) * obj.position(3), ...
        obj.position(2), (1 - obj.relCaptionWidth - 2*obj.relPaddingWidth) * obj.position(3), obj.position(4)];
            
      obj.captionHandle = uicontrol('Parent', figureHandle, 'Style', 'text', 'Units', 'norm', ...
        'HorizontalAlignment', 'left', 'String', [obj.controlLabel], ...
        'Position', captionPosition, 'Tooltip', obj.toolTip, 'BackgroundColor', 'w');
      obj.dropdownHandle = uicontrol('Parent', figureHandle, 'Style', 'popupmenu', 'Units', 'norm', ...
        'Position', dropdownPosition, 'String', obj.dropdownLabels, 'ToolTip', obj.toolTip, 'Value', obj.currentValue);
      
      update(obj);
    end
    
    
    % check control object and update simulator object if required
    function changed = check(obj)
      if get(obj.dropdownHandle, 'Value') ~= obj.currentValue
        changed = true;
        obj.currentValue = get(obj.dropdownHandle, 'Value');
        setElementParameters(obj.simulatorHandle, obj.elementLabels, obj.parameterNames, ...
          obj.dropdownValues{obj.currentValue});
        
        if obj.noMatchingEntry
          set(obj.dropdownHandle, 'String', obj.dropdownLabels, 'Value', obj.currentValue);
          obj.noMatchingEntry = false;
        end
      else
        changed = false;
      end
    end
    
    
    % update control object (e.g. after parameters have been changed in parameter panel)
    function obj = update(obj) % updates the control element
      currentParameterValues = cell(1, obj.nParameters);
      valuesScalar = false(1, obj.nParameters);
      for i = 1 : obj.nParameters
        currentParameterValues{i} = getElementParameter(obj.simulatorHandle, obj.elementLabels{i}, obj.parameterNames{i});
        valuesScalar(i) = isscalar(currentParameterValues{i});
      end
      valuesScalar = find(valuesScalar);
      
      dropdownValuesTmp = obj.dropdownValues;
      for k = 1 : obj.nEntries
        match = true;
        for i = valuesScalar
          if isscalar(dropdownValuesTmp{k}{i}) && dropdownValuesTmp{k}{i} ~= currentParameterValues{i}
            match = false;
            break;
          end
        end
        if match
          obj.currentValue = k;
          break;
        end
      end
      
      if ~match && ~obj.noMatchingEntry
        obj.currentValue = obj.nEntries + 1;
        set(obj.dropdownHandle, 'String', [obj.dropdownLabels; {'[no matching entry]'}], 'Value', obj.currentValue);
        obj.noMatchingEntry = true;
      elseif match && obj.noMatchingEntry
        set(obj.dropdownHandle, 'String', obj.dropdownLabels, 'Value', obj.currentValue);
        obj.noMatchingEntry = false;
      end
    end

  end
end