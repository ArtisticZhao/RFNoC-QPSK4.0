from scipy.io import loadmat
import numpy as np
from matplotlib import pyplot as plt
import os
import matplotlib as mpl
mpl.rcParams["savefig.directory"] = str(os.chdir(os.path.dirname(os.path.abspath(__file__))))
plt.rcParams["font.sans-serif"] = ["SimHei"]  # 设置字体
plt.rcParams["axes.unicode_minus"] = False    # 正常显示负号
import sys
p = os.path.join(os.path.dirname(os.path.abspath(__file__)), os.pardir)
sys.path.insert(1, p)
from utils import np_tools

mt = loadmat('./datatx_rx.mat')
data_tx = mt['data_tx']
data_tx = data_tx[100:]
data_rx = mt['data_rx']
data_rx = np_tools.normalize(data_rx)

mt = loadmat('./data_rx_sync.mat')
data_sync = mt['data_rx_sync']
data_sync = np_tools.normalize(data_sync)
data_sync = data_sync.T[100:]

mt = loadmat('./e_v_mu.mat')
e = mt['e'].T
v = mt['v'].T
mu = mt['mu'].T

plt.figure()
f = plt.subplot(1, 2, 1)
f.scatter(data_tx.real, data_tx.imag, marker='.')
f.set_xlabel("实信号（归一化幅值）")
f.set_ylabel("虚信号（归一化幅值）")
f.set_title("(a) 脉冲成形后发送数据星座图", y=-0.2)

f = plt.subplot(1, 2, 2)
f.scatter(data_rx.real, data_rx.imag, marker='.')
f.set_xlabel("实信号（归一化幅值）")
f.set_ylabel("虚信号（归一化幅值）")
f.set_title("(b) $E_s/N_0=10 dB$接收数据星座图", y=-0.2)

plt.figure()
plt.scatter(data_sync.real, data_sync.imag, marker='.')
plt.xlabel("实信号（归一化幅值）")
plt.ylabel("虚信号（归一化幅值）")


def np_move_avg(a, n, mode="same"):
    a = np.reshape(a, a.size)
    return np.convolve(a, np.ones((n,)) / n)


plt.figure()
f = plt.subplot(3, 1, 1)
f.plot(e)
f.plot(np_move_avg(e, 5))
f.set_xlabel("采样点(n)")
f.set_ylabel("$e(n)$")
f.set_title("(a) 定时误差检测器输出", y=-0.5)
f.set_xlim(0, 16000)
f = plt.subplot(3, 1, 2)
f.plot(v)
f.set_xlabel("采样点(n)")
f.set_ylabel("$v(n)$")
f.set_title("(b) 环路滤波器（PI控制器）输出", y=-0.5)
f.set_xlim(0, 16000)
f = plt.subplot(3, 1, 3)
f.plot(mu[:-200])
f.set_xlabel("符号点(s)")
f.set_ylabel(r"$\mu(s)$")
f.set_title("(c) 多相滤波器组索引计数器输出", y=-0.5)
f.set_xlim(0, 4000)
plt.show()
