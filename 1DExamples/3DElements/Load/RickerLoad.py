import numpy as np
import matplotlib.pyplot as plt

# Set PGF as the backend for LaTeX-compatible figures
# plt.rcParams.update({
#     "text.usetex": True,  # Enable LaTeX
#     "font.family": "serif",
#     "font.serif": ["Times"],  # Match LaTeX's Times New Roman style
#     "axes.labelsize": 12,  # Match LaTeX font sizes
#     "axes.titlesize": 14,
#     "legend.fontsize": 10,
#     "xtick.labelsize": 10,
#     "ytick.labelsize": 10,
#     "grid.linestyle": "--",
#     "grid.alpha": 0.7,
#     "figure.figsize": (6, 4),  # Matches the LaTeX plot size
#     "pgf.rcfonts": False,  # Ensure consistent font rendering
# })

def ricker_pulse(t, A_ricker=100e3, f_ricker=5, t0=1.0):
    """
    Compute the Ricker pulse function.
    
    Parameters:
    t (float or array): Time variable (in seconds)
    A_ricker (float): Amplitude of the Ricker pulse (default 100 kN = 100e3 N)
    f_ricker (float): Frequency of the Ricker pulse (default 5 Hz)
    t0 (float): Time shift (default 1.0 s)
    
    Returns:
    float or array: The Ricker pulse value(s) at time(s) t
    """
    tau = t - t0
    return A_ricker * (1 - (2 * np.pi * f_ricker * tau)**2) * np.exp(-(np.pi * f_ricker * tau)**2)

# Generate time range and compute Ricker pulse
t = np.linspace(0, 2, 1000)
u = ricker_pulse(t,t0=.5)

# Create the figure
fig, ax = plt.subplots(figsize=(6, 4), dpi=300)  # 6x4 inches, 300 DPI for publication quality

# Plot the Ricker pulse
ax.plot(t, u, '-', linewidth=2, label=r'Ricker Pulse')
timeFile = "LoadTime.txt"
forceFile = "LoadForce.txt"
np.savetxt(timeFile, t)
np.savetxt(forceFile, u)


# Customize labels, title, and grid
ax.set_xlabel(r'Time (s)', fontsize=12, fontweight='bold')
ax.set_ylabel(r'Force (N)', fontsize=12, fontweight='bold')
ax.set_title(r'Ricker Pulse Function\\$A = 100$ kN, $f = 5$ Hz, $t_0 = 1.0$ s', 
             fontsize=14, fontweight='bold', pad=10)
ax.grid(True, linestyle='--', alpha=0.7)

# Adjust tick labels for consistency
ax.tick_params(axis='both', which='major', labelsize=10)

# Add legend
ax.legend(fontsize=10, frameon=True, facecolor='white', edgecolor='black')

# Ensure tight layout
plt.tight_layout()

# # Save the figure in PGF format (for direct LaTeX import) and PNG
# plt.savefig('ricker_pulse_pgf.pgf', format='pgf', bbox_inches='tight', dpi=300)
# plt.savefig('ricker_pulse.png', format='png', bbox_inches='tight', dpi=300)

# Display the plot
plt.show()
