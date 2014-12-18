% singleLinkageClustering   Performs a single linkage clustering operation on
%   a binary input and yields the number of clusters, their centers of
%   mass, and their sizes.
% 
% Function call:
% [nClusters, clusterCenters, clusterSizes] =
%   singleLinkageClustering(binaryMap, maxDistance, borderCondition,
%   distanceNorm)
% 
% Inputs:
% binaryMap: a vector or 2d matrix on which the clustering is performed,
%   containing only 1s and 0s
% maxDistance: maximal distance between two points to be linked into a
%   cluster; a maxDistance of 1 means that points have to be direct
%   neighbors to be linked
% borderCondition: 'linear' or 'circular'; circular condition allows
%   clusters to extend across the borders of the map
% distanceNorm: the norm used to compute the distance between two points,
%   either 'L1' (Manhattan distance) or 'L2' (Euclidian distance); for 1d
%   binaryMap, both yield the same result
% 
% Outputs:
% nClusters: number of clusters found
% clusterCenters: an n x 1 vector (for 1d input) or n x 2 matrix containing
%   in each row the coordinates of the center of one cluster
% clusterSizes: an n x 1 vector of cluster sizes (number of points
%   belonging to a cluster)

function [nClusters, clusterCenters, clusterSizes] = singleLinkageClustering(binaryMap, ...
  maxDistance, borderCondition, distanceNorm)

if nargin < 3
  borderCondition = 'linear';
end
if nargin < 4
  distanceNorm = 'l1';
end

if ~(strcmpi(borderCondition, 'linear') || strcmpi(borderCondition, 'circular'))
  error('sLC:arg3Chk', 'BORDERCONDITION must be either ''linear'' or ''circular''');
end
if ~(strcmpi(distanceNorm, 'l1') || strcmpi(distanceNorm, 'l2'))
  error('sLC:arg4Chk', 'DISTANCENORM must be either ''l1'' or ''l2''');
end
if ~ismatrix(binaryMap)
  error('sLC:arg1Chk', 'BINARYMAP must be a vector or a 2-dimensional matrix');
end


circBorder = strcmpi(borderCondition, 'circular');
euclidNorm = strcmpi(distanceNorm, 'l2');

nMapDims = ndims(binaryMap);
if (nMapDims == 2 && any(size(binaryMap)==1))
  nMapDims = 1;
end

clusterCenters = [];
clusterSizes = [];
nClusters = 0;

if nMapDims == 1
  binaryMap = shiftdim(binaryMap); % to get row vector
  mapSize = length(binaryMap);
  I = find(binaryMap);
  if isempty(I)
    return;
  end
  clusterBorders = find([(diff(I) > maxDistance); 1]);
  nClusters = numel(clusterBorders);
  clusterCenters = zeros(nClusters, 1);
  clusterSizes = zeros(nClusters, 1);
  
  clusterStart = 1;
  for i = 1 : numel(clusterBorders)
    clusterCenters(i) = mean(I(clusterStart:clusterBorders(i)));
    clusterSizes(i) = numel(I(clusterStart:clusterBorders(i)));
    clusterStart = clusterBorders(i) + 1;
  end
  
  if (circBorder && nClusters > 1 && I(1) - I(end) + length(binaryMap) <= maxDistance )
    % merge first and last cluster
    nClusters = nClusters - 1;
    newSize = clusterSizes(1) + clusterSizes(end);
    newCenter = (clusterSizes(1)*(clusterCenters(1)+mapSize) + clusterSizes(end)*clusterCenters(end)) / newSize;
    if newCenter > mapSize
      clusterCenters = [mod(newCenter, mapSize); clusterCenters(2:end-1)];
      clusterSizes = [newSize; clusterSizes(2:end-1)];
    else
      clusterCenters = [clusterCenters(2:end-1); newCenter];
      clusterSizes = [clusterSizes(2:end-1); newSize];
    end
  end
  
else
  height = size(binaryMap, 1);
  width = size(binaryMap, 2);
  
  [I, J] = find(binaryMap);
  offsetI = zeros(size(I));
  offsetJ = zeros(size(I));
  
  clusterID = zeros(size(I));
  checked = zeros(size(I));
  currentID = 0;
  
  if (~circBorder && ~euclidNorm)
    p = find(~clusterID, 1);
    while ~isempty(p)
      currentID = currentID + 1;
      clusterID(p) = currentID;
      while ~isempty(p)
        clusterID(~clusterID & abs(I - I(p)) + abs(J - J(p)) <= maxDistance) = currentID;
        checked(p) = 1;
        p = find(clusterID == currentID & ~checked, 1);
      end
      p = find(~clusterID, 1);
    end
  elseif (~circBorder && euclidNorm)
    maxDistSqr = maxDistance^2;
    p = find(~clusterID, 1);
    while ~isempty(p)
      currentID = currentID + 1;
      clusterID(p) = currentID;
      while ~isempty(p)
        clusterID(~clusterID & (I - I(p)).^2 + (J - J(p)).^2 <= maxDistSqr) = currentID;
        checked(p) = 1;
        p = find(clusterID == currentID & ~checked, 1);
      end
      p = find(~clusterID, 1);
    end
  elseif (circBorder && ~euclidNorm)
    II = [I-height, I, I+height];
    JJ = [J-width, J, J+width];
    p = find(~clusterID, 1);
    while ~isempty(p)
      currentID = currentID + 1;
      clusterID(p) = currentID;
      while ~isempty(p)
        [dI, oI] = min(abs(II - I(p)), [], 2);
        [dJ, oJ] = min(abs(JJ - J(p)), [], 2);
        P = ~clusterID & dI + dJ <= maxDistance;
        offsetI(P) = offsetI(p) + (oI(P) - 2) * height;
        offsetJ(P) = offsetJ(p) + (oJ(P) - 2) * width;
        clusterID(P) = currentID;
        checked(p) = 1;
        p = find(clusterID == currentID & ~checked, 1);
      end
      p = find(~clusterID, 1);
    end
  elseif (circBorder && euclidNorm)
    maxDistSqr = maxDistance^2;
    II = [I-height, I, I+height];
    JJ = [J-width, J, J+width];
    p = find(~clusterID, 1);
    while ~isempty(p)
      currentID = currentID + 1;
      clusterID(p) = currentID;
      while ~isempty(p)
        [dI, oI] = min((II - I(p)).^2, [], 2);
        [dJ, oJ] = min((JJ - J(p)).^2, [], 2);
        P = ~clusterID & dI + dJ <= maxDistSqr;
        offsetI(P) = offsetI(p) + (oI(P) - 2) * height;
        offsetJ(P) = offsetJ(p) + (oJ(P) - 2) * width;
        clusterID(P) = currentID;
        checked(p) = 1;
        p = find(clusterID == currentID & ~checked, 1);
      end
      p = find(~clusterID, 1);
    end
  end
  
  nClusters = currentID;
  clusterCenters = zeros(nClusters, 2);
  clusterSizes = zeros(nClusters, 1);
  for i = 1 : nClusters
    mask = (clusterID == i);
    clusterSizes(i) = sum(mask);
    clusterCenters(i, 1) = mod(mean(I(mask) + offsetI(mask)), height);
    clusterCenters(i, 2) = mod(mean(J(mask) + offsetJ(mask)), width);
  end
end







