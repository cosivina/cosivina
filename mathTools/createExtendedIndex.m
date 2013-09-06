% determines the extended index to expand an input for a circular
% convolution

function I = createExtendedIndex(fieldSize, kernelRange)
  I = [fieldSize - kernelRange(2) + 1 : fieldSize, 1:fieldSize, 1 : kernelRange(1)];
end