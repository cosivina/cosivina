% TimeDisplay (COSIVINA toolbox)
%   Visualization that prints the current simulation time.
% 
% Constructor call: TimeDisplay(caption, units, valueFormat, position)
%
% Arguments:
% caption - string printed before the simulation time (optional, default
%   is 'Simulation time: '
% units - string printed after the simulation time (optional, empty by
%   default)
% valueFormat - string specifying the number format in which the simulation
%   time is displayed (optional, see the Matlab documentation of the
%   fprintf function for help on constructing that string)
% position - position of the control in the GUI figure window in relative
%   coordinates (optional, is overwritten when specifying a grid position
%   in the GUI's addVisualization function)
%
% Example:
% h = TimeDisplay('Time: ', ' s', '%0.1f');
%
% To place this visualization in the controls grid of a GUI:
% gui.addVisualization(TimeDisplay(), [1, 1], [1, 1], 'control');


classdef TimeDisplay < Visualization
  properties
    simulatorHandle
    textHandle
    
    caption = 'Simulation time: ';
    units = '';
    valueFormat = '%0.0f';
    relPaddingWidth = 0.025;
  end
  
  methods
    % Constructor    
    function obj = TimeDisplay(caption, units, valueFormat, position)
      if nargin >= 1
        obj.caption = caption;
      end
      if nargin >= 2
        obj.units = units;
      end
      if nargin >= 3
        obj.valueFormat = valueFormat;
      end      
      if nargin >= 4
        obj.position = position;
      else
        obj.position = [];
      end
    end
    
    
    % connect to simulator object
    function obj = connect(obj, simulatorHandle)
      obj.simulatorHandle = simulatorHandle;
    end
    
    
    % initialization
    function obj = init(obj, figureHandle)
      textPosition = [obj.position(1) + obj.relPaddingWidth * obj.position(3), obj.position(2), ...
        obj.position(3) * (1 - 2 * obj.relPaddingWidth), obj.position(4)];
      obj.textHandle = uicontrol('Parent', figureHandle, 'Style', 'text', 'Units', 'norm', ...
        'HorizontalAlignment', 'left', ...
        'String', [obj.caption, num2str(obj.simulatorHandle.t, obj.valueFormat), obj.units], ...
        'Position', textPosition, 'BackgroundColor', 'w');
    end
    
    
    % update
    function obj = update(obj)
      set(obj.textHandle, 'String', [obj.caption, num2str(obj.simulatorHandle.t, obj.valueFormat), obj.units]);
    end
  end
end


