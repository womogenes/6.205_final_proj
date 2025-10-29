import numpy as np
from scipy.stats import norm

# Number of entries
N = 1024

# Create evenly spaced probabilities between (0,1)
# Avoid exactly 0 and 1 since the inverse CDF is infinite there
p = (np.arange(N) + 0.5) / N

# Compute inverse CDF (quantile) of the standard normal
gaussian_lookup = norm.ppf(p)

# Print in C array format
print("const float GAUSSIAN_LOOKUP[1024] = {")
for i, val in enumerate(gaussian_lookup):
    sep = "," if i < N - 1 else ""
    print(f"  {val:.8f}f{sep}")
print("};")
