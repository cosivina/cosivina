function g = gauss(range_x, mu, sigma)

if sigma == 0
  g = double(range_x == mu);
else
  g = exp(-0.5 * (range_x-mu).^2 / sigma^2);
end

