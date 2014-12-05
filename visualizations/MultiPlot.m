% MultiPlot (COSIVINA toolbox)
%   Visualization that creates a set of axes with one or more plots in it,
%   oriented either vertically or horizontally.
%
% Constructor call:
% MultiPlot(plotElements, plotComponents, scales, orientation, 
%   axesProperties, plotProperties, title, xlabel, ylabel, position)
%
% Arguments:
% plotElements - string or cell array of strings (with one entry for each
%   plot) listing the labels of the elements whose components should be
%   plotted
% plotComponents - string or cell array of strings (with one entry for
%   each plot) listing the component names that should be plotted for the
%   specified elements; one pair of entries from plotElements and
%   plotComponents fully specifies the source data for one plot
% scales - scalar or numeric vector specifying a scaling factor for each
%   plot (optional, by default all scaling factors are 1)
% orientation - string specifying the orientation of the plot, should be
%   either horizontal (default) or vertical
% axesProperties - cell array containing a list of valid axes settings
%   (as property/value pairs) that can be applied to the axes handle via
%   the set function (optional, see Matlab documentation on axes for 
%   further information)
% plotProperties - cell array of cell arrays containing lists of valid
%   lineseries settings (as property/value pairs or as a single string
%   specifying the line style) that can be applied to the plot handles
%   via the set function (see Matlab documentation on the plot function
%   for further information); the outer cell array must contain one inner
%   cell array for every plot (optional)
% title - string specifying an axes title (optional)
% xlabel - string specifying an x-axis label (optional)
% ylabel - string specifying a y-axis label (optional)
% position - position of the control in the GUI figure window in relative
%   coordinates (optional, is overwritten when specifying a grid position
%   in the GUI's addVisualization function)
%
% Example:
% h = MultiPlot({'field u', 'field u', 'stimulus A'}, ...
%   {'activation', 'output', 'output'}, [1, 10, 1], 'horizontal', ...
%   {'YLim', [-10, 10]}, { {'b-', 'LineWidth', 2}, {'r-'}, {'g--'} }, ...
%   'perceptual field', 'feature value', 'activation');


classdef MultiPlot < Visualization
  properties
    nPlots = 0;
    plotElementHandles = {};
    plotElementLabels = {};
    plotComponents = {};
    plotScales = [];
    
    axesHandle = 0;
    axesProperties = {};
    
    plotHandles = [];
    plotProperties = {};
    
    title = '';
    xlabel = '';
    ylabel = '';
    
    titleHandle = 0;
    xlabelHandle = 0;
    ylabelHandle = 0;
    
    vertical = false;
    dataProperty = 'YData';
    
    connected = false;
  end
  
  methods
    % Constructor    
    function obj = MultiPlot(plotElements, plotComponents, scales, orientation, axesProperties, plotProperties, ...
        title, xlabel, ylabel, position)
      if nargin >= 2 && ~isempty(plotElements) && ~isempty(plotComponents)
        obj.plotElementLabels = plotElements;
        obj.plotComponents = plotComponents;
        
        if ischar(obj.plotElementLabels)
          obj.plotElementLabels = cellstr(obj.plotElementLabels);
        end
        if ischar(obj.plotComponents)
          obj.plotComponents = cellstr(obj.plotComponents);
        end
        if numel(obj.plotElementLabels) ~= numel(obj.plotComponents)
          error('MultiPlot:MultiPlot:inconsistentArguments', ...
            'Arguments ''plotElements'' and ''plotComponents'' must have the same number of entries.');
        end
        obj.nPlots = numel(obj.plotElementLabels);
      end
      if nargin >= 3 && ~isempty(scales)
        obj.plotScales = scales;
        if ~isnumeric(obj.plotScales) || numel(obj.plotScales) ~= numel(obj.plotElementLabels)
          error('MultiPlot:MultiPlot:inconsistentArguments', ...
            'Argument ''scales'' must be a numeric vector with one entry for each element in ''plotElements''.');
        end
      else
        obj.plotScales = ones(obj.nPlots, 1);
      end
      if nargin >= 4 && ~isempty(orientation)
        if strncmpi(orientation, 'vertical', length(orientation))
          obj.vertical = true;
        elseif ~strncmpi(orientation, 'horizontal', length(orientation))
          warning('MultiPlot:MultiPlot:invalidValue', ...
            'Argument ''orientation'' should be either ''horizontal'' (default) or ''vertical''.');
        end
      end
      if nargin >= 5 && ~isempty(axesProperties)
        obj.axesProperties = axesProperties;
      end
      if nargin >= 6 && ~isempty(plotProperties)
        obj.plotProperties = plotProperties;
      else
        obj.plotProperties = cell(obj.nPlots, 1);
        [obj.plotProperties{:}] = deal(cell(0));
      end
      if nargin >= 7 && ~isempty(title)
        obj.title = title;
      end
      if nargin >= 8 && ~isempty(xlabel)
        obj.xlabel = xlabel;
      end
      if nargin >= 9 && ~isempty(ylabel)
        obj.ylabel = ylabel;
      end
      if nargin >= 10
        obj.position = position;
      end
    end
    
    
    % connect to simulator object
    function obj = connect(obj, simulatorHandle)
      for i = 1 : obj.nPlots
        if simulatorHandle.isElement(obj.plotElementLabels{i})
          obj.plotElementHandles{i} = simulatorHandle.getElement(obj.plotElementLabels{i});
          if ~obj.plotElementHandles{i}.isComponent(obj.plotComponents{i}) ...
              && ~obj.plotElementHandles{i}.isParameter(obj.plotComponents{i})
            error('MultiPlot:connect:invalidComponent', 'Invalid component %s for element %s in simulator object.', ...
              obj.plotComponents{i}, obj.plotElementLabels{i});
          end
        else
          error('MultiPlot:connect:elementNotFound', 'No element %s in simulator object.', obj.plotElementLabels{i});
        end
      end
      
      obj.connected = true;
    end
    
    
    % initialization
    function obj = init(obj, figureHandle)
      obj.axesHandle = axes('Parent', figureHandle, 'Position', obj.position, 'nextPlot', 'add', obj.axesProperties{:});
      if obj.vertical % vertical plots
        for i = 1 : obj.nPlots
          obj.plotHandles(i) = plot(obj.axesHandle, ...
            obj.plotScales(i) * obj.plotElementHandles{i}.(obj.plotComponents{i}), ...
            1 : length(obj.plotElementHandles{i}.(obj.plotComponents{i})), obj.plotProperties{i}{:});
        end
        obj.dataProperty = 'XData';
      else % horizontal plot
        for i = 1 : obj.nPlots
          obj.plotHandles(i) = plot(obj.axesHandle, obj.plotScales(i) * obj.plotElementHandles{i}.(obj.plotComponents{i}), ...
            obj.plotProperties{i}{:});
          set(obj.plotHandles(i), 'XDataMode', 'manual'); % this is a crutch; can't set it at plot creation
        end
        obj.dataProperty = 'YData';
      end
      
      if ~isempty(obj.title)
        obj.titleHandle = title(obj.axesHandle, obj.title); %#ok<CPROP>
      end
      if ~isempty(obj.xlabel)
        obj.xlabelHandle = xlabel(obj.axesHandle, obj.xlabel); %#ok<CPROP>
      end
      if ~isempty(obj.ylabel)
        obj.ylabelHandle = ylabel(obj.axesHandle, obj.ylabel); %#ok<CPROP>
      end
      
    end
    
    
    % update
    function obj = update(obj)
      for i = 1 : obj.nPlots
        set(obj.plotHandles(i), obj.dataProperty, obj.plotScales(i) * obj.plotElementHandles{i}.(obj.plotComponents{i}));
      end
    end
    
    
    % add new plot
    function obj = addPlot(obj, plotElement, plotComponent, scale, plotProperties)
      if obj.connected
        error('MultiPlot:addPlot:noAddAfterConnect', ...
          'Cannot add plots after MultiPlot object has been connected to a simulator (e.g. by adding it to a GUI).');
      end
      
      obj.plotElementLabels{end+1} = plotElement;
      obj.plotComponents{end+1} = plotComponent;
      if nargin >= 4
        obj.plotScales(end+1) = scale;
      else
        obj.plotScales(end+1) = 1;
      end
      if nargin >= 5
        obj.plotProperties{end+1} = plotProperties;
      else 
        obj.plotProperties{end+1} = {};
      end
      
      
      obj.nPlots = obj.nPlots + 1;
      obj.plotHandles(end+1) = 0;
    end
  end
    
  
end