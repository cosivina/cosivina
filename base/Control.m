% Control (COSIVINA toolbox)
%   Abstract base class for control elements in the GUI.

classdef Control < handle
  properties
    position
  end
  
  methods (Abstract)
    obj = connect(obj, simulatorHandle); % links the control to the simulator object
    obj = init(obj, figureHandle); % creates and initializes graphical control object
    obj = check(obj); % check for changes of the control element and update the simulator
    obj = update(obj); % update the control element, e.g. after parameters have been changed via parameter panel
  end
  
  methods
    function obj = close(obj)
      % nothing to do for most controls
    end
  end
  
end