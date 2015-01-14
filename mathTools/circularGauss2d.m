function G = circularGauss2d(range_y, range_x, mu_y, mu_x, sigma_y, sigma_x, mode, circular_y, circular_x)

if nargin < 7 || isempty(mode)
  mode = 'min';
elseif ~strcmp(mode, 'min') && ~strcmp(mode, 'sum')
  error('Bad parameter value for argument MODE (must be either ''min'' or ''sum'').');
end
if nargin < 9
  circular_y = true;
  circular_x = true;
end

if circular_y
  g_y = circularGauss(range_y, mu_y, sigma_y, mode);
else
  g_y = gauss(range_y, mu_y, sigma_y);
end
if circular_x
  g_x = circularGauss(range_x, mu_x, sigma_x, mode);
else
  g_x = gauss(range_x, mu_x, sigma_x);
end

G = g_y' * g_x;