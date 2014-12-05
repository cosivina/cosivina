% SlicePlot (COSIVINA toolbox)
%   Visualization that plots one-dimensional slices (rows or columns) taken
%   at specified positions from one or several two-dimensional input
%   matrices.
% 
% Constructor call:
% SlicePlot(plotElements, plotComponents, plotSlices, ...
%   sliceOrientations, scales, plotOrientation, axesProperties, ...
%   plotProperties, title, xlabel, ylabel, position)
%
% Arguments:
% plotElements - string or cell array of strings listing the labels of
%   the elements from which slices should be plotted
% plotComponents - string or cell array of strings listing the component
%   names from which slices should be plotted for the specified elements;
%   one pair of entries from plotElements and plotComponents fully
%   specifies the source data for one set of slice plots
% plotSlices - integer vector or cell of integer vector, specifying for
%   each entry in plotElements a set of indices of the rows or columns
%   that should be plotted
% sliceOrientations - string or cell array of strings with each entry
%   either 'horizontal' or 'vertical', specifying the slice orientation
%   (rows or columns) for each entry in plotElements
% scales - scalar or numeric vector specifying a scaling factor for each
%   set of slices (optional, by default all scaling factors are 1)
% plotOrientation - string specifying the orientation of all plots,
%   should be either horizontal (default) or vertical
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
% h = SlicePlot('field u', 'activation', [25, 50, 75], 'horizontal', ...
%   1, 'horizontal', {'YLim', [-10, 10]}, {{'r-'}, {'g-'}, {'b-'}}, ...
%   'three slices through field u', 'field position', 'activation');





classdef SlicePlot < Visualization
  properties (Constant)
    Horizontal = 0;
    Vertical = 1;
  end
  
  properties
    nSources = 0;
    plotElementHandles = {};
    plotElementLabels = {};
    plotComponents = {};
    plotSlices = {};
    sliceOrientations = {};
    plotScales = [];
    
    plotSlicesAll = [];
    plotsToSources = [];
    
    axesHandle = 0;
    axesProperties = {};
    
    nPlots = 0;
    plotHandles = [];
    plotProperties = {};
    
    title = '';
    xlabel = '';
    ylabel = '';
    
    titleHandle = 0;
    xlabelHandle = 0;
    ylabelHandle = 0;
    
    orientation = SlicePlot.Horizontal;
    dataProperty = 'YData';
    
    connected = false;
  end
  
  methods
    % Constructor    
    function obj = SlicePlot(plotElements, plotComponents, plotSlices, sliceOrientations, scales, plotOrientation, ...
        axesProperties, plotProperties, title, xlabel, ylabel, position)
      if nargin >= 4 && ~isempty(plotElements)
        obj.plotElementLabels = plotElements;
        obj.plotComponents = plotComponents;
        obj.plotSlices = plotSlices;
               
        if ischar(obj.plotElementLabels)
          obj.plotElementLabels = cellstr(obj.plotElementLabels);
        end
        if ischar(obj.plotComponents)
          obj.plotComponents = cellstr(obj.plotComponents);
        end
        if isnumeric(obj.plotSlices)
          obj.plotSlices = {plotSlices};
        end
        if ischar(sliceOrientations)
          sliceOrientations = cellstr(sliceOrientations);
        end
        obj.nSources = numel(obj.plotElementLabels);
        
        if numel(obj.plotComponents) ~= obj.nSources || numel(obj.plotSlices) ~= obj.nSources ...
            || numel(sliceOrientations) ~= obj.nSources
          error('SlicePlot:SlicePlot:inconsistentArguments', ...
            'Arguments plotElements, plotComponents, plotSlices, and sliceOrientations must have the same size.');
        end
        
        obj.sliceOrientations = repmat(SlicePlot.Horizontal, [1, obj.nSources]);
        for i = 1 : obj.nSources
          if strncmpi(sliceOrientations{i}, 'vertical', length(sliceOrientations{i}))
            obj.sliceOrientations(i) = SlicePlot.Vertical;
          elseif ~strncmpi(sliceOrientations{i}, 'horizontal', length(sliceOrientations{i}))
            warning('SlicePlot:SlicePlot:unknownIdentifier', ...
              'Each entry in argument ''sliceOrientation'' should be either ''horizontal'' (default) or ''vertical''.');
          end
        end
        
        for i = 1 : obj.nSources
          obj.nPlots = obj.nPlots + numel(obj.plotSlices{i});
          obj.plotSlicesAll = [obj.plotSlicesAll, reshape(obj.plotSlices{i}, [1, numel(obj.plotSlices{i})])];
          obj.plotsToSources = [obj.plotsToSources, repmat(i, [1, numel(obj.plotSlices{i})])];
        end
      end
      if nargin >= 5 && ~isempty(scales)
        obj.plotScales = scales;
      else
        obj.plotScales = ones(obj.nSources, 1);
      end
      if nargin >= 6 && ~isempty(plotOrientation)
        if strncmpi(plotOrientation, 'vertical', length(plotOrientation))
          obj.orientation = SlicePlot.Vertical;
        elseif ~strncmpi(plotOrientation, 'horizontal', length(plotOrientation))
          warning('SlicePlot:SlicePlot:unknownIdentifier', ...
            'Argument ''plotOrientation'' should be either ''horizontal'' (default) or ''vertical''.');
        end
      end
      if nargin >= 7 && ~isempty(axesProperties)
        obj.axesProperties = axesProperties;
      end
      if nargin >= 8 && ~isempty(plotProperties)
        obj.plotProperties = plotProperties;
      else
        obj.plotProperties = cell(obj.nPlots, 1);
        [obj.plotProperties{:}] = deal(cell(0));
      end
      if nargin >= 9 && ~isempty(title)
        obj.title = title;
      end
      if nargin >= 10 && ~isempty(xlabel)
        obj.xlabel = xlabel;
      end
      if nargin >= 11 && ~isempty(ylabel)
        obj.ylabel = ylabel;
      end
      if nargin >= 12
        obj.position = position;
      end
    end
       
    
    % connect to simulator object
    function obj = connect(obj, simulatorHandle)
      for i = 1 : obj.nSources
        if simulatorHandle.isElement(obj.plotElementLabels{i})
          obj.plotElementHandles{i} = simulatorHandle.getElement(obj.plotElementLabels{i});
          if ~obj.plotElementHandles{i}.isComponent(obj.plotComponents{i}) ...
              && ~obj.plotElementHandles{i}.isParameter(obj.plotComponents{i})
            error('SlicePlot:connect:invalidComponent', 'Invalid component %s for element %s in simulator object.', ...
              obj.plotComponents{i}, obj.plotElementLabels{i});
          end
        else
          error('SlicePlot:connect:elementNotFound', 'No element %s in simulator object.', obj.plotElementLabels{i});
        end
      end
      
      obj.connected = true;
    end
    
    
    % initialization
    function obj = init(obj, figureHandle)
      obj.axesHandle = axes('Parent', figureHandle, 'Position', obj.position, 'nextPlot', 'add', obj.axesProperties{:});
      
      obj.plotHandles = zeros(1, obj.nPlots);
      plotIndex = 1;
      % horizontal plots
      for i = 1 : obj.nSources
        for j = 1 : numel(obj.plotSlices{i})
          if obj.orientation == SlicePlot.Horizontal && obj.sliceOrientations(i) == SlicePlot.Horizontal
            obj.plotHandles(plotIndex) = plot(obj.axesHandle, ...
              obj.plotScales(i) * obj.plotElementHandles{i}.(obj.plotComponents{i})(obj.plotSlices{i}(j), :), ...
              obj.plotProperties{plotIndex}{:});
            set(obj.plotHandles(i), 'XDataMode', 'manual');
          elseif obj.orientation == SlicePlot.Horizontal && obj.sliceOrientations(i) == SlicePlot.Vertical
            obj.plotHandles(plotIndex) = plot(obj.axesHandle, ...
              obj.plotScales(i) * obj.plotElementHandles{i}.(obj.plotComponents{i})(:, obj.plotSlices{i}(j)), ...
              obj.plotProperties{plotIndex}{:});
            set(obj.plotHandles(i), 'XDataMode', 'manual');
          elseif obj.orientation == SlicePlot.Horizontal && obj.sliceOrientations(i) == SlicePlot.Vertical
            obj.plotHandles(i) = plot(obj.axesHandle, ...
              obj.plotScales(i) * obj.plotElementHandles{i}.(obj.plotComponents{i})(obj.plotSlices{i}(j), :), ...
              1 : length(obj.plotElementHandles{i}.(obj.plotComponents{i})), obj.plotProperties{plotIndex}{:});
          else
            obj.plotHandles(i) = plot(obj.axesHandle, ...
              obj.plotScales(i) * obj.plotElementHandles{i}.(obj.plotComponents{i})(:, obj.plotSlices{i}(j)), ...
              1 : length(obj.plotElementHandles{i}.(obj.plotComponents{i})), obj.plotProperties{plotIndex}{:});
          end
          plotIndex = plotIndex + 1;
        end
      end
      
      if obj.orientation == SlicePlot.Horizontal
        obj.dataProperty = 'YData';
      else
        obj.dataProperty = 'XData';
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
        j = obj.plotsToSources(i);
        if obj.sliceOrientations(j) == SlicePlot.Horizontal
          set( obj.plotHandles(i), obj.dataProperty, ...
            obj.plotScales(j) * obj.plotElementHandles{j}.(obj.plotComponents{j})(obj.plotSlicesAll(i), :) );
        else
          set( obj.plotHandles(i), obj.dataProperty, ...
            obj.plotScales(j) * obj.plotElementHandles{j}.(obj.plotComponents{j})(:, obj.plotSlicesAll(i)) );
        end
      end
    end

  end
end


