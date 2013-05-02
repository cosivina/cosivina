% ParameterStatus (COSIVINA toolbox)
%   Enumeration of possible parameter status.
%
% The following paramter status are distinguished:
% Fixed - the parameter is fixed and should not be changed during
%   simulation (manual change of parameter is still possible, but may
%   require extra care to ensure that the simulation will continue to run
%   properly)
% Changeable - the parameter can be changed at any time and the change will
%   take effect the next time the step function is called
% InitRequired - the parent element must be reinitialized for the parameter
%   change to take effect; the element will be in the appropriate state for
%   the running simulation after the initilization
% InitStepRequired - the element must be reinitialized for the parameter
%   change to take effect, and the step function must be called to bring
%   the element into the appropriate state for the running simulation

classdef ParameterStatus
  properties (Constant)
    Fixed = 0;
    Changeable = 1;
    InitRequired = 2;
    InitStepRequired = 3;
  end
end

