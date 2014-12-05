% KernelPlot (COSIVINA toolbox)
%   Visualization that plots an interaction kernel (which may consistent of
%   multiple components) in a fixed range around zero. All specified
%   kernels are first brought to the specified range (cut off/padded with
%   zeros), then added together. Kernel components specified as 'global'
%   are globally added over the whole range.
%
% Constructor call:
% KernelPlot(plotElements, plotComponents, kernelTypes, plotRange,
%   axesProperties, plotProperties, title, xlabel, ylabel, position)
%
% Arguments:
% plotElements - cell array of labels of elements (as strings) that
%   contribute to the plotted interaction kernel
% plotComponents - cell array of element components (as strings) for the
%   corresponding entry in plotElements
% kernelTypes - cell array of strings, with one entry of either 'local' 
%   or 'global' for each entry in plotElements
% plotRange - scalar value determining to which range (positively and
%   negatively from zero) the kernel should be plotted
% axesProperties - cell array containing a list of valid axes settings
%   (as property/value pairs) that can be applied to the axes handle via
%   the set function (optional, see Matlab documentation on axes for
%   further information)
% plotProperties - cell array containing lists of valid
%   lineseries settings as property/value pairs or as a single string
%   specifying the line style) that can be applied to the plot handle
%   via the set function (optional, see Matlab documentation on the plot
%   function for further information)
% title - string specifying an axes title (optional)
% xlabel - string specifying an x-axis label (optional)
% ylabel - string specifying a y-axis label (optional)
% position - position of the control in the GUI figure window in relative
%   coordinates (optional, is overwritten when specifying a grid position
%   in the GUI's addVisualization function)
%
% Example:
% h = KernelPlot({'u -> u', 'u -> u'}, {'kernel', 'amplitudeGlobal'}, ...
%   {'local', 'global'}, 50, {'YLim', [-1, 1]}, {'r-', 'LineWidth', 2}, ...
%   'kernel plot', 'distance in feature space', 'interaction weight');


classdef KernelPlot < Visualization
  properties (Constant)
    Global = 0;
    Local = 1;
  end
  
  properties
    nKernels = 0;
    plotElementHandles = {};
    plotElementLabels = {};
    kernelTypes = {};
    plotComponents = {};

    plotRange = 0;
    
    axesHandle = 0;
    axesProperties = {};
    
    plotHandle = 0;
    plotProperties = {};
    
    title = '';
    xlabel = '';
    ylabel = '';
    
    titleHandle = 0;
    xlabelHandle = 0;
    ylabelHandle = 0;
    
    connected = false;
  end
  
  properties (SetAccess = protected)
    kernelSum = [];
  end
  
  methods
    % Constructor    
    function obj = KernelPlot(plotElements, plotComponents, kernelTypes, plotRange, axesProperties, plotProperties, ...
        title, xlabel, ylabel, position)
      
      if nargin >= 3 && ~isempty(plotElements) && ~isempty(plotComponents)
        obj.plotElementLabels = plotElements;
        obj.plotComponents = plotComponents;
        
        if ischar(obj.plotElementLabels)
          obj.plotElementLabels = cellstr(obj.plotElementLabels);
        end
        if ischar(obj.plotComponents)
          obj.plotComponents = cellstr(obj.plotComponents);
        end
        if ischar(obj.kernelTypes)
          kernelTypes = cellstr(kernelTypes);
        end
        if numel(obj.plotElementLabels) ~= numel(obj.plotComponents) ...
            || numel(obj.plotElementLabels) ~= numel(kernelTypes)
          error('KernelPlot:KernelPlot:inconsistentArguments', ...
            'The sizes of arguments ''plotElements'', ''plotComponents'', and ''kernelTypes'' must match.');
        end
        obj.nKernels = numel(obj.plotElementLabels);
        
        obj.kernelTypes = repmat(KernelPlot.Global, [obj.nKernels, 1]);
        for i = 1 : obj.nKernels
          if strncmpi(kernelTypes{i}, 'local', length(kernelTypes{i}))
            obj.kernelTypes(i) = KernelPlot.Local;
          elseif ~strncmpi(kernelTypes{i}, 'global', length(kernelTypes{i}))
            error('KernelPlot:KernelPlot:invalidKernelType', ...
              'Argument ''kernelTypes'' should only contain the strings ''global'' or ''local''.');
          end
        end
      end
      if nargin >= 4
        obj.plotRange = plotRange;
      end
      if nargin >= 5
        obj.axesProperties = axesProperties;
      end
      if nargin >= 6
        obj.plotProperties = plotProperties;
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
      for i = 1 : obj.nKernels
        if simulatorHandle.isElement(obj.plotElementLabels{i})
          obj.plotElementHandles{i} = simulatorHandle.getElement(obj.plotElementLabels{i});
          if ~obj.plotElementHandles{i}.isComponent(obj.plotComponents{i}) ...
              && ~obj.plotElementHandles{i}.isParameter(obj.plotComponents{i})
            error('KernelPlot:connect:invalidComponent', 'Invalid component %s for element %s in simulator object.', ...
              obj.plotComponents{i}, obj.plotElementLabels{i});
          end
        else
          error('KernelPlot:connect:elementNotFound', 'No element %s in simulator object.', obj.plotElementLabels{i});
        end
      end
      
      obj.connected = true;
    end
    
    
    % initialization
    function obj = init(obj, figureHandle)
      obj.plotRange = round(obj.plotRange);
      obj.kernelSum = zeros(1, 2 * obj.plotRange + 1);

      obj.axesHandle = axes('Parent', figureHandle, 'Position', obj.position, ...
        'XLim', [-obj.plotRange, obj.plotRange], 'nextPlot', 'add', obj.axesProperties{:});
      obj.plotHandle = plot(obj.axesHandle, -obj.plotRange:obj.plotRange, obj.kernelSum, obj.plotProperties{:});
      set(obj.plotHandle, 'XDataMode', 'manual'); % this is a crutch; can't set it at plot creation
      
      if ~isempty(obj.title)
        obj.titleHandle = title(obj.axesHandle, obj.title); %#ok<CPROP>
      end
      if ~isempty(obj.xlabel)
        obj.xlabelHandle = xlabel(obj.axesHandle, obj.xlabel); %#ok<CPROP>
      end
      if ~isempty(obj.ylabel)
        obj.ylabelHandle = ylabel(obj.axesHandle, obj.ylabel); %#ok<CPROP>
      end
      
      obj.update();
    end
    
    
    % update
    function obj = update(obj)
      obj.kernelSum(:) = 0;
      for i = 1 : obj.nKernels
        if obj.kernelTypes(i) == KernelPlot.Local
          kernelRange = (size(obj.plotElementHandles{i}.(obj.plotComponents{i}), 2)-1)/2;
          obj.kernelSum(obj.plotRange + 1 + (-floor(kernelRange) : ceil(kernelRange))) = ...
            obj.kernelSum(obj.plotRange + 1 + (-floor(kernelRange) : ceil(kernelRange))) ...
            + obj.plotElementHandles{i}.(obj.plotComponents{i});
        else
          obj.kernelSum = obj.kernelSum + obj.plotElementHandles{i}.(obj.plotComponents{i});
        end
      end
      
      set(obj.plotHandle, 'YData', obj.kernelSum);
    end
    
    
    % add new plot
    function obj = addPlot(obj, plotElement, plotComponent, kernelType)
      if obj.connected
        error('KernelPlot:addPlot:noAddAfterConnect', ...
          'Cannot add plots after KernelPlot object has been connected to a simulator (e.g. by adding it to a GUI).');
      end
      
      obj.plotElementLabels{end+1} = plotElement;
      obj.plotComponents{end+1} = plotComponent;
      
      obj.kernelTypes(end+1) = KernelPlot.Global;
      if strncmpi(kernelType, 'local', length(kernelType))
        obj.kernelTypes(end+1) = KernelPlot.Local;
      elseif ~strncmpi(kernelType, 'global', length(kernelType))
        error('KernelPlot:KernelPlot:invalidKernelType', ...
          'Argument ''kernelTypes'' should only contain the strings ''global'' or ''local''.');
      end
      
      obj.nKernels = obj.nKernels + 1;
    end
  end

end