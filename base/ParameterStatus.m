% ParameterStatus (COSIVINA toolbox)
%   Abstract class that defines integer values to indicates the
%   changeability and other properties of a parameter in the element class,
%   as well as methods to test for different properties. The integer is
%   interpreted as bit string, with every bit giving a piece of information
%   on the parameter.
%   
%   The following static methods are provided to test for different
%   properties of a parameter:
%   
%   isChangeable - indicates that the parameter may be changed during a
%     running simulation (e.g. via controls or the parameter panel in a
%     GUI)
%   initRequired - changes to this parameter require a re-initialization of
%     the element to take effect
%   stepRequired - changes to this parameter require a call of the step
%     function after a re-initialization to take effect
%   isMatrix - the parameter is a numeric vector or matrix
%   rowsVariable - the number of rows in the matrix is variable
%   columnsVariable - the number of columns in the matrix is variable
%   sizeVariable - the number of both rows and columns in the matrix is
%     variable


classdef ParameterStatus 
  properties (Constant)
    ChangeableBit = 1;
    InitRequiredBit = 2;
    StepRequiredBit = 3;
    MatrixBit = 4;
    RowsVariableBit = 5;
    ColumnsVariableBit = 6;
    
    Fixed = 0;
    Changeable = 1;
    InitRequired = 3;
    InitStepRequired = 7;
    
    FixedSizeMatrix = 8;
    VariableRowsMatrix = 24;
    VariableColumnsMatrix = 40;
    VariableSizeMatrix = 56;
  end
  
  methods (Static)
    function bool = isChangeable(status)
      bool = bitget(status, ParameterStatus.ChangeableBit);
    end
    
    function bool = requiresInit(status)
      bool = bitget(status, ParameterStatus.InitRequiredBit);
    end
    
    function bool = requiresStep(status)
      bool = bitget(status, ParameterStatus.StepRequiredBit);
    end
    
    function bool = isMatrix(status)
      bool = bitget(status, ParameterStatus.MatrixBit);
    end
    
    function bool = rowsVariable(status)
      bool = bitget(status, ParameterStatus.RowsVariableBit);
    end
    
    function bool = columnsVariable(status)
      bool = bitget(status, ParameterStatus.ColumnsVariableBit);
    end
    
    function bool = sizeVariable(status)
      bool = bitget(status, ParameterStatus.ColumnsVariableBit) & bitget(status, ParameterStatus.RowsVariableBit);
    end
  end
end

