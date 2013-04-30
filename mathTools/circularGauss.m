% range_x must be equally spaced and monotone, with at least two elements;
% the spacing between the last and the first element is assumed to
% be the same as that between any subsequent elements

function g = circularGauss(range_x, mu, sigma, mode)

if nargin < 4
  mode = 'min';
elseif ~strcmp(mode, 'min') && ~strcmp(mode, 'sum')
  error('Bad parameter value for mode (must be either min or sum)');
end

l = abs(range_x(end) - 2*range_x(1) + range_x(2));
m = min(range_x);
mu_shifted = mod(mu - m, l) + m;

if sigma == 0
  g = double(range_x == mu_shifted);
else
  d = abs(range_x - mu_shifted);
  if strcmp(mode, 'min')
    g = exp(-0.5 * min(d, l - d).^2 / sigma^2);
  else
    g = exp(-0.5 * d.^2 / sigma^2) + exp(-0.5 * (l-d).^2 / sigma^2);
  end
end

