% PresetSelector (COSIVINA toolbox)
%   Control that loads full parameter settings for the model from one of a
%   set of predefined parameter files. The control consists of a dropdown
%   menu to select a parameter file (which may be listed with a descriptive
%   label) and a confirmation button. When the button is pressed, the
%   parameter file connected to the currently selected entry in the
%   dropdown menu is loaded.
%   Note: Loading from a parameter file will re-initialize the simulation.
%
% Constructor call:
% PresetSelector(controlLabel, controlledObject, filePath, presetFiles, 
%   presetLabels, toolTip, position)
%
% Arguments:
% controlLabel - label displayed on the confirmation button
% controlledObject - the object that performs the loading operation, which
%   is always the GUI that the control is part of
% filePath - string specifying a common relative or absolute path for all 
%   parameter files (may be empty if files are located in different
%   folders)
% presetFiles - cell array of strings containing the file names (or
%   complete paths) for the parameter files
% presetLabels - cell array of strings containing a label for each
%   parameter file to be shown in the dropdown menu (optional, by default
%   the filenames are used as labels)
% tooltip - tooltip displayed when hovering over the control with the mouse
%   (optional)
% position - position of the control in the GUI figure window in relative
%   coordinates (optional, is overwritten when specifying a grid position
%   in the GUI's addControl function) the GUI
% 
% h = PresetSelector('Select', gui, 'presetsOneLayerField/', ...
%   {'preset_stabilized.json', 'preset_selection.json', 'preset_memory.json'}, ...
%   {'stabilized', 'selection', 'memory'}, ...
%   'Load pre-defined parameter settings');

classdef PresetSelector < Control
  properties
    controlLabel = '';
    presetFiles = {};
    presetLabels = {};
    toolTip
  end
    
  properties (SetAccess = protected)
    controlledObjectHandle
    
    popupMenuHandle
    buttonHandle
  end
  
  methods
    % constructor
    function obj = PresetSelector(controlLabel, controlledObject, filePath, presetFiles, presetLabels,...
        toolTip, position)
      obj.controlLabel = controlLabel;
      obj.controlledObjectHandle = controlledObject;
      obj.presetFiles = presetFiles;
      
      if nargin >= 5 && ~isempty(presetLabels)
        obj.presetLabels = presetLabels;
      else
        obj.presetLabels = obj.presetFiles;
      end 
      if nargin >= 6 && ~isempty(toolTip)
        obj.toolTip = toolTip;
      else
        obj.toolTip = obj.controlLabel;
      end
      if nargin >= 8
        obj.position = position;
      else
        obj.position = [];
      end
     
      if ~iscell(obj.presetLabels)
        obj.presetLabels = cellstr(obj.presetLabels);
      end
      if ~iscell(obj.presetFiles)
        obj.presetFiles = cellstr(obj.presetFiles);
      end
      if numel(obj.presetLabels) ~= numel(obj.presetFiles)
        error('PresetSelector:PresetSelector:inconsistentArguments', ...
          'Arguments ''presetFiles'' and ''presetLabels'' should have the same number of elements');
      end
        
      if ~isempty(filePath)
        for i = 1 : numel(obj.presetFiles)
          obj.presetFiles{i} = fullfile(filePath, obj.presetFiles{i});
        end
      end
    end
    
    
    % connect to simulator object
    function obj = connect(obj, simulatorHandle) %#ok<INUSD>
      if ~isvalid(obj.controlledObjectHandle)
        error('GlobalControlButton:connect:invalidHandle', ...
          'The handle to the object to be controlled by this button is invalid.');
      end
    end
    
    
    % initialize control object
    function obj = init(obj, figureHandle)
      menuPosition = obj.position + [0, obj.position(4)/2, 0, -obj.position(4)/2];
      buttonPosition = obj.position + [0, 0, 0, -obj.position(4)/2];
      
      obj.popupMenuHandle = uicontrol('Parent', figureHandle, 'Style', 'popupmenu', 'Units', 'norm', ...
        'String', obj.presetLabels, 'Position', menuPosition, 'Tooltip', obj.toolTip);
      obj.buttonHandle = uicontrol('Parent', figureHandle, 'Style', 'togglebutton', 'Units', 'norm', ...
        'String', obj.controlLabel, 'Position', buttonPosition, 'Tooltip', obj.toolTip);
    end
    
    
    % check control object and update simulator object if required
    function changed = check(obj)
      if get(obj.buttonHandle, 'Value') == 1
        obj.controlledObjectHandle.loadParameters = true;
        obj.controlledObjectHandle.loadFile = obj.presetFiles{get(obj.popupMenuHandle, 'Value')};
        set(obj.buttonHandle, 'Value', 0);
        changed = true;
      else
        changed = false;
      end
    end
    
    
    % update control object (e.g. after parameters have been changed in parameter panel)
    function obj = update(obj) % updates the control eleme

    end
  end
end


