function G = gauss2d(range_y, range_x, mu_y, mu_x, sigma_y, sigma_x)

g_y = exp(-0.5 * (range_y-mu_y).^2 / sigma_y^2);
g_x = exp(-0.5 * (range_x-mu_x).^2 / sigma_x^2);

G = g_y' * g_x;
