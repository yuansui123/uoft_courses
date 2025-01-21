#!/usr/bin/env python
# coding: utf-8

# In[1]:


import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import mne
import scipy.stats as stats
import scipy.ndimage as ndimage


# In[2]:


df = pd.read_csv("rec.txt", header = 4, index_col=False)

df = df[[f' EXG Channel {i}' for i in range(8)] + [' Other.2']]
channel_names = ['FP1', 'FP2', 'C3', 'C4', 'P7', 'P8', 'O1', 'O2', 'photoresistor']
df.columns = channel_names
df[['FP1', 'FP2', 'C3', 'C4', 'P7', 'P8', 'O1', 'O2']] *= 1e-6
df = df.T


# In[3]:


info = mne.create_info(channel_names, 250, ch_types=["eeg"]*8 + ['stim'])
raw = mne.io.RawArray(df, info);


# In[4]:


events = mne.find_events(raw, stim_channel="photoresistor")
mapping = {
    1: "flash",
}
annot_from_events = mne.annotations_from_events(
    events=events,
    event_desc=mapping,
    sfreq=raw.info["sfreq"],
    orig_time=raw.info["meas_date"],
)
raw.set_annotations(annot_from_events);


# In[5]:


raw.plot(duration=25, scalings=dict(eeg=200e-6), clipping=None);


# In[6]:


raw.notch_filter(60)
raw.filter(1,50)


# In[7]:


events[:10], events[-5:]


# In[8]:


stimulate_start = events[4][0]/250+0.5
stimulate_end = events[-1][0]/250+1.0


# In[9]:


# stimulate_start = events[5][0]/250+0.5
# stimulate_end = events[-2][0]/250+1.0


# In[10]:


raw.crop(tmin=stimulate_start, tmax=stimulate_end);


# In[11]:


raw.plot(duration=200, scalings=dict(eeg=200e-6), clipping=None);


# In[12]:


events_from_annot, event_dict = mne.events_from_annotations(raw)
epochs = mne.Epochs(raw, events=events_from_annot)
epochs_data = epochs.get_data()
epochs_data.shape


# In[13]:


epochs.load_data()
baseline_epochs = epochs.copy().crop(tmin=-0.2, tmax=0.0)
baseline_data = baseline_epochs.get_data()
baseline_data.shape


# In[14]:


baseline_mean = baseline_data.mean(axis=2, keepdims=True)
baseline_std = baseline_data.std(axis=2, keepdims=True)
epochs_data = (epochs_data - baseline_mean) / baseline_std


# In[15]:


mask = pd.read_csv('circle_mask.csv', header=None).values.flatten()
mask.shape
circles_array = epochs_data[mask == 1][:, :8, :]
squares_array = epochs_data[mask == 0][:, :8, :]
print("circles array",circles_array.shape)
print("square array",squares_array.shape)


# In[23]:


# plot function
def plot(data_array):
    times = np.arange(data_array.shape[1]) / 250

    plt.figure(figsize=(10, 8))
    n_channels = data_array.shape[0]

    for ch in range(n_channels):
        plt.plot(times, data_array[::-1][ch] + ch * 5)

    plt.xlabel('Time (s)')
    plt.yticks(ticks=np.arange(n_channels) * 5, labels=channel_names[:-1][::-1])
    plt.tight_layout()
    plt.show()

plot(circles_array[11])
plot(squares_array[11])


# In[17]:


t_stats, p_values = stats.ttest_ind(circles_array, squares_array)
sig_p_values = p_values < 0.05
plot(np.abs(t_stats))
plot(sig_p_values)


# In[18]:


cluster_locations = []
for k, channel_p_vals in enumerate(sig_p_values):
    clusters, num_clusters = ndimage.label(channel_p_vals)
    max_cluster_size = 0
    max_cluster_label = None
    for i in range(1, num_clusters + 1):
        cluster_size = np.sum(clusters == i)
        if cluster_size > max_cluster_size:
            max_cluster_size = cluster_size
            max_cluster_label = i
    if max_cluster_label:
        cluster_locations.append(clusters == max_cluster_label)
    else:
        cluster_locations.append(np.zeros_like(clusters))
cluster_locations = np.array(cluster_locations)
new_sig_p_values = np.copy(sig_p_values)
for i in range(len(new_sig_p_values)):
    new_sig_p_values[i] = new_sig_p_values[i] * cluster_locations[i]
plot(new_sig_p_values)


# In[19]:


def single_test(dataset_a, dataset_b):
    t_stats, p_values = stats.ttest_ind(dataset_a, dataset_b)
    t_stats = np.abs(t_stats)
    sig_p_values = p_values < 0.05
    clus_tstat = []
    for k, channel_p_vals in enumerate(sig_p_values):
        clusters, num_clusters = ndimage.label(channel_p_vals)
        max_cluster_size = 0
        max_cluster_label = None
        for i in range(1, num_clusters + 1):
            cluster_size = np.sum(clusters == i)
            if cluster_size > max_cluster_size:
                max_cluster_size = cluster_size
                max_cluster_label = i
        if max_cluster_label:
            largest_cluster_indices = np.where(clusters == max_cluster_label)[0]
            clus_tstat.append(np.sum(t_stats[k][largest_cluster_indices]))
        else:
            clus_tstat.append(0)
    return np.array(clus_tstat)

single_test(circles_array, squares_array)


# In[20]:


def nonparametric_test(dataset_a, dataset_b, n_perm=1000):
    real_cluster_stats = single_test(dataset_a, dataset_b)
    random_higher_count = np.zeros((len(real_cluster_stats),))
    combined_data = np.concatenate([dataset_a, dataset_b], axis=0)

    for i in range(n_perm):
        np.random.shuffle(combined_data)
        perm_a = combined_data[:dataset_a.shape[0]]
        perm_b = combined_data[dataset_a.shape[0]:]

        random_cluster_stats = single_test(perm_a, perm_b)
        random_higher_count += random_cluster_stats > real_cluster_stats

    random_higher_count /= n_perm
    return random_higher_count

nonparametric_p_values = nonparametric_test(circles_array, squares_array)
print(nonparametric_p_values)


# In[25]:


for i in range(len(nonparametric_p_values)):
    if nonparametric_p_values[i] < 0.05:
        x = np.arange(circles_array.shape[2]) / 250
        circles = np.mean(circles_array[:,i,:], axis = 0)
        squares = np.mean(squares_array[:,i,:], axis = 0)
        mini = np.concatenate((circles, squares)).min()
        maxi = np.concatenate((circles, squares)).max()
        mask = cluster_locations[i]
        masked_time = np.extract(mask, x)

        fig, ax = plt.subplots(figsize=(10, 4))
        ax.plot(x, circles, color='red', label='Circles')
        ax.plot(x, squares, color='blue', label='Squares')
        ax.fill_between(x, mini, maxi, where=mask, color='blue', alpha=0.2)
        ax.plot(masked_time, np.full(masked_time.shape, mini*1.1), color='blue')
        ax.text(masked_time.mean(), mini*1.2, '**', ha='center', color='blue')
        ax.set_ylim([mini*1.3, maxi*1.3])

        ax.set_title(f"Channel {channel_names[i]}")
        ax.set_xlabel("Time (s)")
        ax.set_ylabel("Voltage")
        ax.legend(loc='best')
        plt.tight_layout()
        plt.show()

