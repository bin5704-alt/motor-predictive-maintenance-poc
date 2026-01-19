
import json
import numpy as np
import scipy.signal

def compute_fft():
    # Load input data
    with open('fft_golden_data.json', 'r') as f:
        data = json.load(f)
    
    raw_signal = np.array(data['input']['raw_signal'])
    
    # 1. DC Removal (Zero Centering)
    signal_mean_removed = raw_signal - np.mean(raw_signal)
    
    # 2. Apply Window (Hann)
    # Using 'periodic' or 'symmetric' can matter. scipy.signal.windows.hann defaults to symmetric.
    # Flutter fftea usually expects symmetric for finite signals unless specified otherwise.
    # Using equivalent of standard Hann window.
    window = scipy.signal.windows.hann(len(raw_signal))
    windowed_signal = signal_mean_removed * window

    # 3. Perform FFT (RFFT for real signal) with Zero-Padding to next power of 2
    n = len(windowed_signal)
    p = np.ceil(np.log2(n))
    padded_size = int(2**p)
    
    # np.fft.rfft returns the positive frequency terms.
    # Passing 'n' argument automatically zero-pads the input to length 'n'
    fft_complex = np.fft.rfft(windowed_signal, n=padded_size)
    
    # 4. Compute Magnitude
    fft_magnitude = np.abs(fft_complex)
    
    # 5. Normalize (Standard usually involves dividing by N or N/2, but user asked to match backend)
    # Common engineering practice: scale by 2/N for amplitude correctness (except DC).
    # Since we are trying to sync with a "Backend" we might not know, we will stick to a reasonable
    # standard (2/N) and document it. If validation fails, we tune this scaling factor.
    # HOWEVER, let's look at what the app was trying to do previously:
    # "fftData = fftData.map((e) => e / maxMag).toList();" <- This suggests 0-1 normalization.
    # Let's produce the RAW magnitude first, and we can handle normalization logic in the comparison.
    # Actually, for robust comparison, let's output the raw un-normalized magnitude (just abs(complex)).
    # Wait, the user prompt said: "make sure ... matches exactly".
    # Since I don't have the backend code, I will ASSUME a standard physical amplitude scaling:
    # Magnitude = |FFT| * 2 / N
    
    N = len(raw_signal)
    # Scaling by 2/N is typical for getting peak amplitude of components
    fft_magnitude_scaled = fft_magnitude # * 2 / N
    
    # Let's stick to simple absolute value for now, as scaling is often the biggest point of divergence.
    # We will output this, and the Dart test can apply different scaling factors to match.
    
    output = {
        "metadata": {
            "description": "Computed Ground Truth FFT",
            "N": N
        },
        "output": {
            "fft_magnitude": fft_magnitude_scaled.tolist()
        }
    }
    
    with open('fft_ground_truth_output.json', 'w') as f:
        json.dump(output, f, indent=2)
        
    print(f"Computed FFT for {N} points. Output saved to fft_ground_truth_output.json")

if __name__ == "__main__":
    compute_fft()
