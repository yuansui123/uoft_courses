import time
import numpy as np

from brainflow.board_shim import BoardShim, BrainFlowInputParams, BoardIds
from brainflow.data_filter import DataFilter, WindowOperations, DetrendOperations

def calculate_alpha_beta_ratio(port='COM9'):
    # Step 2: Initialize the board information
    boardID = BoardIds.CYTON_BOARD  # Assuming CYTON_BOARD is the board type
    boardDescr = BoardShim.get_board_descr(boardID)
    sampleRate = int(boardDescr['sampling_rate'])  # Extract and convert sampling rate to integer

    # Step 3: Set the board parameters
    board_params = BrainFlowInputParams()
    board_params.serial_port = port

    # Step 4: Create the board object
    board = BoardShim(boardID, board_params)

    # Step 5: Prepare the board session and start the stream
    board.prepare_session()  # Prepare the board for data streaming
    board.start_stream()  # Start data streaming

    # Step 6: Calculate the nearest power of two for spectral power estimation
    nearest_power_of_2 = DataFilter.get_nearest_power_of_two(sampleRate)

    # Step 7: Acquire data
    time.sleep(2)  # Pause for 2 seconds to accumulate data
    data = board.get_board_data()  # Retrieve data from the board

    # Step 8: Extract the EEG channel information
    eeg_channels = boardDescr['eeg_channels']  # Extract EEG channel information

    # Step 9: Initialize the alpha-beta ratio array
    alpha_beta_ratio = np.zeros(len(eeg_channels))  # Create an array for alpha-beta ratios

    # Step 10: Process each EEG channel
    for count, channel in enumerate(eeg_channels[:2]):
        # a. Apply detrending to the channel data
        DataFilter.detrend(data[channel], DetrendOperations.LINEAR.value)

        # b. Calculate the power spectrum using Welch's method
        psd = DataFilter.get_psd_welch(
            data[channel],
            nearest_power_of_2,
            nearest_power_of_2 // 2,
            sampleRate,
            WindowOperations.HANNING.value
        )

        # c. Extract alpha and beta band power
        alpha_power = DataFilter.get_band_power(psd, 7.0, 13.0)
        beta_power = DataFilter.get_band_power(psd, 14.0, 30.0)

        # d. Compute alpha-beta ratio
        alpha_beta_ratio[count] = beta_power / alpha_power if alpha_power != 0 else 0

    # Step 11: Stop and release the session
    if board.is_prepared():
        board.release_session()

    # Step 12: Return the mean alpha-beta ratio
    return np.mean(alpha_beta_ratio)

# Run as standalone
if __name__ == "__main__":
    try:
        while True:
            ratio = calculate_alpha_beta_ratio(port='COM9')
            print("alpha/beta ratio:", ratio)
    except KeyboardInterrupt:
        quit()


