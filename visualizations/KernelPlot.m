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
        obj.titleHandle = title(obj.title); %#ok<CPROP>
      end
      if ~isempty(obj.xlabel)
        obj.xlabelHandle = xlabel(obj.xlabel); %#ok<CPROP>
      end
      if ~isempty(obj.ylabel)
        obj.ylabelHandle = ylabel(obj.ylabel); %#ok<CPROP>
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