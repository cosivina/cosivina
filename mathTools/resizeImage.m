% This is a simple replacement of the imresize function from the Image
% Processing Toolbox. The image is interpolated using the function interp2.
%
% Usage:
% B = resizeImage(A, SCALE) scales the image up or down by a factor SCALE.
% B = resizeImage(A, [NUMROWS, NUMCOLS]) scales the image up or down to the
%   specified size.
% B = resizeImage(..., METHOD) uses the specified method for the
%   interpolation. Possible values are  '*nearest', '*linear', '*spline', or
%   '*cubic'. See help of interp2 for further information.
% The input image A should be either an MxN or MxNx3 matrix.


function B = resizeImage(A, scaleOrRowsCols, method)

if nargin < 3
  method = '*linear';
end

rowsA = size(A, 1);
colsA = size(A, 2);
channels = size(A, 3);
classA = class(A);

if numel(scaleOrRowsCols) == 1
  rowsB = ceil(scaleOrRowsCols * rowsA);
  colsB = ceil(scaleOrRowsCols * colsA);
elseif numel(scaleOrRowsCols) == 2
  rowsB = ceil(scaleOrRowsCols(1));
  colsB = ceil(scaleOrRowsCols(2));
else
  error('resizeImage:invalidArgument', 'Argument SCALEORROWSCOLS must be either a scalar or a two-element vector.');
end


if ~isa(A, 'double');
  A = double(A);
end

IY = (1 : rowsB) * rowsA/rowsB - rowsA/(2*rowsB) + 1/2;
IX = (1 : colsB) * colsA/colsB - colsA/(2*colsB) + 1/2;

B = zeros(rowsB, colsB, channels, classA);
for i = 1 : channels
  B(:, :, i) = interp2(A(:, :, i), IX, IY', method);
end

