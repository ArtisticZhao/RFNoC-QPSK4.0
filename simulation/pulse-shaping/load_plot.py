from bitstring import BitArray
import numpy as np
import matplotlib.pyplot as plt
import os
import matplotlib as mpl
mpl.rcParams["savefig.directory"] = os.chdir(os.path.dirname(os.path.abspath(__file__)))
plt.rcParams["font.sans-serif"] = ["SimHei"]  # 设置字体
plt.rcParams["axes.unicode_minus"] = False  # 正常显示负号


def spectrum_plot(samples, fig=None, isreal=True, islog=False, window=0):
    window_size = window if window != 0 else samples.shape[0]
    f_axis = np.arange(-np.pi, np.pi, 2*np.pi / window_size)
    if window==0:
        fft_ = np.fft.fft(samples)
        fft_abs = np.abs(np.fft.fftshift(fft_))
    else:
        # 如果分窗，则做平均
        data_len = samples.shape[0]
        c = window
        r = data_len//c
        drop_size = data_len - c*r
        samples = samples[:-drop_size]
        samp_reshape = samples.reshape(r, c)
        fft_ = np.fft.fft(samp_reshape)
        fft_abs = np.abs(fft_)
        fft_abs = np.mean(fft_abs, axis=0)
        fft_abs = np.fft.fftshift(fft_abs)

    if fig is None:
        fig = plt
    if islog:
        fft_abs = 20*np.log10(fft_abs)
    line, = fig.plot(f_axis, fft_abs)
    if isreal:
        fig.set_xlim(0, np.pi)
    return line

f = open('./iq_out.txt', 'r')
i_ = []
q_ = []
while True:
    line = f.readline()
    if not line:
        break
    if 'x' in line:
        continue
    i = BitArray(bin=line[0:16]).int / 2**15  # sfix16_15
    q = BitArray(bin=line[16:]).int / 2**15  # sfix16_15
    i_.append(i)
    q_.append(q)

f.close()

f = open('./iq_data.txt', 'r')
i_data = []
q_data = []
while True:
    line = f.readline()
    if not line:
        break
    if 'x' in line:
        continue
    i = BitArray(bin=line[0:16]).int / 2**15  # sfix16_15
    q = BitArray(bin=line[16:]).int / 2**15  # sfix16_15
    i_data.append(i)
    q_data.append(q)

f.close()
# 绘制时域图形
plt.figure(0)
f = plt.subplot(2, 1, 1)
ir, = f.plot(i_data)
qr, = f.plot(q_data)
f.set_xlim(0, 50)
f.set_xlabel("采样点(n)")
f.set_ylabel("归一化幅值")
f.set_title("(a) 根升余弦滚降滤波器模块输入", y=-0.4)
f.legend([ir, qr], ['Real', 'Imag'], loc="upper right")

f = plt.subplot(2, 1, 2)
ir, = f.plot(i_)
qr, = f.plot(q_)
f.set_xlim(0, 50)
f.set_xlabel("采样点(n)")
f.set_ylabel("归一化幅值")
f.set_title("(b) 根升余弦滚降滤波器模块输出",  y=-0.4)
f.legend([ir, qr], ['Real', 'Imag'], loc="upper right")

# 绘制频谱图
in_data = np.array(i_data) + 1j* np.array(q_data)
out_data = np.array(i_) + 1j*np.array(q_)

plt.figure(1)
f = plt.subplot(1, 2, 1)
f.set_title("(a) 基带信号频谱", y=-0.2)
f.set_xlabel(r"归一化频率(f)")
f.set_ylabel(r"功率谱密度/dB")
f.set_ylim(-20, 40)
in_f = spectrum_plot(in_data, f, isreal=False, islog=True, window=1024)
f = plt.subplot(1, 2, 2)
f.set_title("(b) 根升余弦滚降滤波器输出频谱", y=-0.2)
f.set_xlabel(r"归一化频率(f)")
f.set_ylabel(r"功率谱密度/dB")
f.set_ylim(-20, 40)
in_f = spectrum_plot(out_data, f, isreal=False, islog=True, window=1024)

plt.show()

# 绘制动图
#  #  ax = plt.scatter([0,], [0,])
#
#  index = 0
#  while index + ANI_COUNTER < len(i_):  # 最后几个点不要了
#      plt.clf()  # 清空画布
#      plt.xlim(-1000, 1000)
#      plt.ylim(-1000, 1000)
#      plt.scatter(i_[index: index+ANI_COUNTER], q_[index: index+ANI_COUNTER])
#      index = index + ANI_COUNTER
#      plt.pause(0.2)
#
#  #  plt.scatter(i_[-1000:], q_[-1000:])
#  plt.show()
#
