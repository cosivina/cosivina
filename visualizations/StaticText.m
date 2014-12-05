% StaticText (COSIVINA toolbox)
%   Static text display.
%
% Constructor call: StaticText(text, position)
%
% Arguments:
% text - string that is printed in the visualization
% position - position of the control in the GUI figure window in relative
%   coordinates (optional, is overwritten when specifying a grid position
%   in the GUI's addVisualization function)
%
% Example:
% h = StaticText('This field receives no external input.');
%
% To place this visualization in the controls grid of a GUI:
% gui.addVisualization(StaticText('Stimulus controls'), [1, 1], [1, 1], ...
%   'control')


classdef StaticText < Visualization
  properties
    textHandle
    text = '';
  end
  
  
  methods
    % Constructor
    function obj = StaticText(text, position)
      obj.text = text;
      if nargin >= 2
        obj.position = position;
      else
        obj.position = [];
      end
    end
    
    
    % connect to simulator object
    function obj = connect(obj, simulatorHandle) %#ok<INUSD>
      % nothing to do
    end
    
    
    % initialization
    function obj = init(obj, figureHandle)
      obj.textHandle = uicontrol(figureHandle, 'Style', 'text', 'String', obj.text, 'Units', 'norm', ...
        'Position', obj.position, 'HorizontalAlignment', 'left', 'Background', 'w');
    end
    
    
    % update
    function obj = update(obj)
      % nothing to do
    end
  end
end

