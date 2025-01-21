
# Importing necessary libraries
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import mne
import scipy.stats as stats
import scipy.ndimage as ndimage

# Read in data from a text file and select relevant columns
df = pd.read_csv("rec.txt", header=4, index_col=False)
name = "rec.txt"
df = df[[f' EXG Channel {i}' for i in range(8)] + [' Other.2']]  # Select EEG channels and other data
channel_names = ['FP1', 'FP2', 'C3', 'C4', 'P7', 'P8', 'O1', 'O2', 'photoresistor']  # Define channel names
df.columns = channel_names  # Rename columns
df[['FP1', 'FP2', 'C3', 'C4', 'P7', 'P8', 'O1', 'O2']] *= 1e-6  # Convert EEG data from uV to V
df = df.T  # Transpose the data to match the expected format

# Create MNE info structure for the EEG data
info = mne.create_info(channel_names, 250, ch_types=["eeg"]*8 + ['stim'])
raw = mne.io.RawArray(df, info)  # Create raw MNE data object

# Detect events from the stim channel and map to custom labels
events = mne.find_events(raw, stim_channel="photoresistor")
mapping = {1: "flash"}
annot_from_events = mne.annotations_from_events(
    events=events,
    event_desc=mapping,
    sfreq=raw.info["sfreq"],
    orig_time=raw.info["meas_date"],
)
raw.set_annotations(annot_from_events)

# Plot the raw EEG data for 25 seconds
raw.plot(duration=25, scalings=dict(eeg=200e-6), clipping=None)

# Apply notch filter at 60 Hz to remove power line noise, and bandpass filter between 1-50 Hz
raw.notch_filter(60)
raw.filter(1, 50)

# Show the first 10 and last 5 events for inspection
events[:10], events[-5:]

# Define stimulation start and end times based on events
stimulate_start = events[4][0] / 250 + 0.5  # Start time in seconds
stimulate_end = events[-1][0] / 250 + 1.0  # End time in seconds

# Crop the raw data to the stimulation period
raw.crop(tmin=stimulate_start, tmax=stimulate_end)

# Plot the cropped raw data for 200 seconds
raw.plot(duration=200, scalings=dict(eeg=200e-6), clipping=None)

# Extract epochs from the raw data based on events
events_from_annot, event_dict = mne.events_from_annotations(raw)
epochs = mne.Epochs(raw, events=events_from_annot)
epochs_data = epochs.get_data()  # Get epoch data
epochs_data.shape

# Load the data and calculate baseline mean and standard deviation
epochs.load_data()
baseline_epochs = epochs.copy().crop(tmin=-0.2, tmax=0.0)
baseline_data = baseline_epochs.get_data()
baseline_data.shape
baseline_mean = baseline_data.mean(axis=2, keepdims=True)
baseline_std = baseline_data.std(axis=2, keepdims=True)

# Normalize the epoch data by subtracting baseline mean and dividing by baseline std
epochs_data = (epochs_data - baseline_mean) / baseline_std

# Load mask for the circular regions and split data based on mask values
mask = pd.read_csv('circle_mask.csv', header=None).values.flatten()
mask.shape
circles_array = epochs_data[mask == 1][:, :8, :]
squares_array = epochs_data[mask == 0][:, :8, :]
print("circles array", circles_array.shape)
print("square array", squares_array.shape)

# Define a plot function to visualize data
def plot(data_array, title="test"):
    times = np.arange(data_array.shape[1]) / 250  # Time axis based on sampling rate of 250 Hz
    plt.figure(figsize=(10, 8))
    n_channels = data_array.shape[0]  # Number of channels
    for ch in range(n_channels):
        plt.plot(times, data_array[::-1][ch] + ch * 5)  # Plot each channel, offset for clarity
    plt.title(title, fontsize=22)
    plt.xlabel('Time (s)')
    plt.yticks(ticks=np.arange(n_channels) * 5, labels=channel_names[:-1][::-1])  # Reverse order of channels
    plt.tight_layout()
    plt.show()



# Plot the results for significant clusters
for i in range(len(nonparametric_p_values)):
    if nonparametric_p_values[i] < 0.05:
        x = np.arange(circles_array.shape[2]) / 250
        circles = np.mean(circles_array[:, i, :], axis=0)
        squares = np.mean(squares_array[:, i, :], axis=0)
        mini = np.concatenate((circles, squares)).min()
        maxi = np.concatenate((circles, squares)).max()
        mask = cluster_locations[i]
        masked_time = np.extract(mask, x)
        fig, ax = plt.subplots(figsize=(10, 4))
        ax.plot(x, circles, color='red', label='Circles')
        ax.plot(x, squares, color='blue', label='Squares')
        ax.fill_between(x, mini, maxi, where=mask, color='blue', alpha=0.2)
        ax.plot(masked_time, np.full(masked_time.shape, mini*1.1), color='blue')
