function G = gauss3d(range_y, range_x, range_z, mu_y, mu_x, mu_z, sigma_y, sigma_x, sigma_z)

g_y = exp(-0.5 * (range_y-mu_y).^2 / sigma_y^2);
g_x = exp(-0.5 * (range_x-mu_x).^2 / sigma_x^2);
g_z = exp(-0.5 * (range_z-mu_z).^2 / sigma_z^2);

g_yx = g_y' * g_x;
G = repmat(g_yx, [1, 1, length(g_z)]) .* repmat(reshape(g_z, 1, 1, []), [length(g_y), length(g_x), 1]);
