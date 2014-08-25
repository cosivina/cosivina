% function to compute the new pose (position and orientation) for a
% differential drive robot given its old pose and the distance travelled by
% both wheels; all distance measures provided by the arguments must be in
% the same units; an orientation of zero means that the robot is oriented
% in the direction of the x-axis; orientation are given in the range [-pi,
% pi)
% 
% Inputs:
% wheelDistance - two-element vector containing distances travelled by left
%   and right wheel
% oldPos - last position of the robot in the form [x-position; y-position]
% oldPhi - last orientation of the robot (in radiants)
% wheelbase - distance between the two wheels of the robot
% 
% Output:
% newPos - new position of the robot as [x-position; y-position]
% newPhi - new orientation of the robot


function [newPos, newPhi] = pathIntegrationDifferentialDrive(wheelDistance, oldPos, oldPhi, wheelbase)

if wheelDistance(1) == wheelDistance(2) % driving straight forward
  dPos = [wheelDistance(1); 0];
  dPhi = 0;
elseif wheelDistance(1) == -wheelDistance(2) % rotation on the spot
  dPos = [0; 0];
  dPhi = (wheelDistance(2) - wheelDistance(1)) / wheelbase;
else
  b = 0.5 * (wheelDistance(2) + wheelDistance(1)); % rotation around icc
  r = b * wheelbase / (wheelDistance(2) - wheelDistance(1));
  dPhi = b/r;
  dPos = [r * sin(dPhi); r * (1 - cos(dPhi))];
end

newPos = oldPos + [cos(oldPhi), -sin(oldPhi); sin(oldPhi), cos(oldPhi)] * dPos;
newPhi = mod(oldPhi + dPhi + pi, 2*pi) - pi;

