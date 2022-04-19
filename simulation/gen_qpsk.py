# coding: utf-8
import numpy as np
import matplotlib.pyplot as plt
from math import sqrt, pi
from cmath import exp
from bitstring import BitArray


N = 4000                        # 发射点数
baudrate = 2.5e6                # 符号率 Hz
sps = 8                         # 接收符号采样数
fs = baudrate*sps               # 采样率
ebn0_db = 40                    # energy per bit to noise power spectral density ratio
snr = (10**(ebn0_db/10))/sps*2  # 信噪比
print(snr)

# -- 产生基带数据
data_i = np.sign(np.random.uniform(-1, 1, N))
data_q = np.sign(np.random.uniform(-1, 1, N))
data_tx = data_i + data_q*1j

PHASE_OFFSET = pi/6
FREQ_OFFSET = 20e3   # Hz

# -- 产生接收数据
data_rx = np.repeat(data_tx, sps)  # 每个符号采样N次
rx_noise = (np.random.normal(0, 1, N*sps) +                   # 产生信道噪声
            np.random.normal(0, 1, N*sps)*1j)*(sqrt(1/snr))
#  data_rx = data_rx + rx_noise         # 加入噪声
#  data_rx = data_rx * exp(1j*PHASE_OFFSET)  # 产生相偏
t = np.arange(0, N/baudrate-0.5/fs, 1/fs)   # 产生时间间隔, stop-0.5/fs  是为了凑点数
ejwt = np.exp(1j*2*pi*FREQ_OFFSET*t)
#  data_rx = data_rx * ejwt  # 加入频偏

# -- 显示收数据
plt.figure()
plt.scatter(data_rx.real, data_rx.imag, alpha=0.6)
plt.show()

# -- 保存接收数据到文件
LSB = 2**-11  # 最小量化单位
i_int = np.floor(data_rx.real/LSB)
q_int = np.floor(data_rx.imag/LSB)

f = open('iq_data.txt', 'w')
for i in range(len(i_int)):
    istr = BitArray(int=int(i_int[i]), length=16).bin
    qstr = BitArray(int=int(q_int[i]), length=16).bin
    # iq_binstr.append(istr+qstr+'\n')
    f.write(istr+qstr+'\n')
# f.writelines(iq_binstr)
f.close()
