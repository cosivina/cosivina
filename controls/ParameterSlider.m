% ParameterSlider (COSIVINA toolbox)
%   Control that creates a slider with an accompanying text field in the
%   GUI. The slider is connected to one or more parameters (belonging to a
%   single element or different elements). The parameter value is changed
%   whenever the slider is moved. The range of parameter values covered by
%   the slider as well as a scaling factor for the conversion from slider
%   position to parameter value can be specified.
% 
% Constructor call:
% ParameterSlider(controlLabel, elementLabels, parameterNames, ...
%   sliderRange, valueFormat, scalingFactor, toolTip, position)
% 
% Arguments:
% controlLabel - label of the control displayed in the text field next to
%   the slider
% elementLabels - string or cell array of strings specifying the
%   labels of elements controlled by this slider
% parameterNames - string or cell array of strings specifying the names of
%   the element parameters controlled by this slider; arguments
%   elementLabels and parameterNames must have the same size, with each
%   pair of entries fully specifying one controlled parameter
% sliderRange - two-element vector giving the range of the slider 
% valueFormat - string specifying the format of the parameter value
%   displayed next to the slider (optional, see the Matlab documentation of
%   the fprintf function on construction of that string)
% scalingFactor - scalar value specifying a conversion factor from the
%   element's parameter value to the slider position (optional)
% tooltip - tooltip displayed when hovering over the control with the mouse
%   (optional)
% position - position of the control in the GUI figure window in relative
%   coordinates (optional, is overwritten when specifying a grid position
%   in the GUI's addControl function)
%
% Example:
% h = ParameterSlider('h_u', 'field u', 'h', [-10, 0], '%0.1f', 1,
%   'resting level of field u');


classdef ParameterSlider < Control
  properties
    controlLabel
    elementLabels
    parameterNames
    sliderRange
    valueFormat
    scalingFactor
    toolTip
    
    nParameters
    simulatorHandle
    refElementHandle
    sliderHandle
    captionHandle
    
    relCaptionWidth % size of the slider caption relative to 
    relPaddingWidth % padding on both sides of the caption
    
    lastValue
  end
  
  methods
    % constructor
    function obj = ParameterSlider(controlLabel, elementLabels, parameterNames, sliderRange, ...
        valueFormat, scalingFactor, toolTip, position)
      obj.controlLabel = controlLabel;
      obj.elementLabels = elementLabels;
      obj.parameterNames = parameterNames;
      obj.sliderRange = sliderRange;
      if nargin >= 5 && ~isempty(valueFormat)
        obj.valueFormat = valueFormat;
      else
        obj.valueFormat = '%0.1f';
      end
      if nargin >= 6 && ~isempty(scalingFactor)
        obj.scalingFactor = scalingFactor;
      else
        obj.scalingFactor = 1;
      end
      if nargin >= 7 && ~isempty(toolTip)
        obj.toolTip = toolTip;
      else
        obj.toolTip = obj.controlLabel;
      end
      if nargin >= 8
        obj.position = position;
      else
        obj.position = [];
      end
      
      if ~iscell(obj.elementLabels)
        obj.elementLabels = {obj.elementLabels};
      end
      if ~iscell(obj.parameterNames)
        obj.parameterNames = {obj.parameterNames};
      end
      
      if ~iscellstr(obj.elementLabels) || ~iscellstr(obj.parameterNames) ...
          || numel(obj.elementLabels) ~= numel(obj.parameterNames)
        error('ParameterSlider:ParameterSlider:invalidArguments', ...
          'Arguments elementLabels and parameterNames must be strings or cell arrays of strings with equal number of elements');
      end
      
      obj.nParameters = length(obj.parameterNames);
      obj.relCaptionWidth = 1/3;
      obj.relPaddingWidth = 0.025;
    end
    
    
    % connect to simulator object
    function obj = connect(obj, simulatorHandle)
      obj.simulatorHandle = simulatorHandle;
      
      % check whether elements and parameters exist (and not fixed) in simulator object
      for i = 1 : obj.nParameters
        tmpElementHandle = simulatorHandle.getElement(obj.elementLabels{i});
        if isempty(tmpElementHandle) || ~tmpElementHandle.isParameter(obj.parameterNames{i})
          error('ParameterSlider:connect:invalidParameter', ...
            'No element ''%s'' with parameter ''%s'' in simulator object', obj.elementLabels{i}, obj.parameterNames{i});
        end
        status = tmpElementHandle.getParamChangeStatus(obj.parameterNames{i});
        if ~ParameterStatus.isChangeable(status) || ParameterStatus.isMatrix(status)
          error('ParameterSlider:connect:parameterFixed', ...
            'Parameter ''%s'' in element ''%s'' is not a changeable scalar parameter and cannot be controlled by a slider.', ...
            obj.parameterNames{i}, obj.elementLabels{i});
        end
      end
      
      % first element/parameter is used as reference to set the slider position
      obj.refElementHandle = simulatorHandle.getElement(obj.elementLabels{1}); % this element is used to set the sliced
    end
    
    
    % initialize control object
    function obj = init(obj, figureHandle)
      captionPosition = [obj.position(1) + obj.relPaddingWidth * obj.position(3), obj.position(2), ...
        obj.position(3) * obj.relCaptionWidth, obj.position(4)];
      sliderPosition = [obj.position(1) + (obj.relCaptionWidth + 2*obj.relPaddingWidth) * obj.position(3), ...
        obj.position(2), (1 - obj.relCaptionWidth - 2*obj.relPaddingWidth) * obj.position(3), obj.position(4)];
      obj.lastValue = obj.scalingFactor * obj.refElementHandle.(obj.parameterNames{1});
      
      obj.captionHandle = uicontrol('Parent', figureHandle, 'Style', 'text', 'Units', 'norm', ...
        'HorizontalAlignment', 'left', 'String', [obj.controlLabel '=' num2str(obj.lastValue, obj.valueFormat)], ...
        'Position', captionPosition, 'Tooltip', obj.toolTip, 'BackgroundColor', 'w');
      obj.sliderHandle = uicontrol('Parent', figureHandle, 'Style', 'slider', 'Units', 'norm', ...
        'Position', sliderPosition, 'Min', obj.sliderRange(1), 'Max', obj.sliderRange(2), ...
        'ToolTip', obj.toolTip, 'Value', obj.lastValue);
    end
    
    
    % check control object and update simulator object if required
    function changed = check(obj)
      if get(obj.sliderHandle, 'Value') ~= obj.lastValue
        changed = true;
        obj.lastValue = get(obj.sliderHandle, 'Value');
        set(obj.captionHandle, 'String', [obj.controlLabel '=' num2str(obj.lastValue, obj.valueFormat)]);
        newValues = num2cell(repmat(1/obj.scalingFactor * obj.lastValue, [obj.nParameters, 1]));
        setElementParameters(obj.simulatorHandle, obj.elementLabels, obj.parameterNames, newValues);
      else
        changed = false;
      end
    end
    
    
    % update control object (e.g. after parameters have been changed in parameter panel)
    function obj = update(obj)
      obj.lastValue = obj.scalingFactor * obj.refElementHandle.(obj.parameterNames{1});
      set(obj.captionHandle, 'String', [obj.controlLabel '=' num2str(obj.lastValue, obj.valueFormat)]);
      set(obj.sliderHandle, 'Value', min(max(obj.lastValue, obj.sliderRange(1)), obj.sliderRange(2)));
    end

  end
end

