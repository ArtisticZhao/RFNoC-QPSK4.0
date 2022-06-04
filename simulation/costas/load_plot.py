from bitstring import BitArray
import matplotlib.pyplot as plt
import numpy as np
import os
import matplotlib as mpl
mpl.rcParams["savefig.directory"] = str(os.chdir(os.path.dirname(os.path.abspath(__file__))))
plt.rcParams["font.sans-serif"] = ["SimHei"]  # 设置字体
plt.rcParams["axes.unicode_minus"] = False    # 正常显示负号

import sys
p = os.path.join(os.path.dirname(os.path.abspath(__file__)), os.pardir)
print(p)
sys.path.insert(1, p)
from utils import load_tools

df = load_tools.load_list('data_foff.lst')

# 读取输入数据
f = open('./iq_data.txt', 'r')
i_ = []
q_ = []
while True:
    line = f.readline()
    if not line:
        break
    if 'x' in line:
        continue
    i = BitArray(bin=line[0:16]).int / 2**15
    q = BitArray(bin=line[16:]).int / 2**15
    i_.append(i)
    q_.append(q)
f.close()
# 读取输出数据
f = open('./iq_out.txt', 'r')
i_o = []
q_o = []
while True:
    line = f.readline()
    if not line:
        break
    if 'x' in line:
        continue
    i = BitArray(bin=line[0:16]).int / 2**15
    q = BitArray(bin=line[16:]).int / 2**15
    i_o.append(i)
    q_o.append(q)
f.close()

f = plt.subplot(1, 2, 1)
f.scatter(i_, q_)
f.set_xlabel("实信号（归一化幅值）")
f.set_ylabel("虚信号（归一化幅值）")
f.set_title("(a) 固定相差输入信号", y=-0.2)

sp = 4000
alpha = np.linspace(0, 1, sp)
f = plt.subplot(1, 2, 2)
unlock = f.scatter(i_o[:sp], q_o[:sp], alpha=alpha, marker='o')
lock = f.scatter(i_o[sp:-10000], q_o[sp:-10000], marker='x')
f.set_xlabel("实信号（归一化幅值）")
f.set_ylabel("虚信号（归一化幅值）")
f.set_title("(b) 极性Costas环输出信号", y=-0.2)
f.legend([unlock, lock], ['未锁定', '锁定'], loc="upper right")
legend = f.get_legend()
for lh in legend.legendHandles:
    lh.set_alpha(1)

# 取出pd中间的莫名奇妙的0
pd = df['pd']
last = pd[0]
print(len(pd))
for i in range(len(pd)):
    if abs(pd[i]) < 1000*2**13:
        print(f"i={i}, {pd[i]}, {last}")
        pd[i] = last
    last = pd[i]
        
# 中间数据绘制
plt.figure()
plt.subplot(2, 1, 1)
plt.plot(pd/2**13)
plt.xlim(0, 3000)
plt.title("(a) 鉴相器输出曲线", y=-0.45)
plt.xlabel("采样点(n)")
plt.ylabel("相位误差")

plt.subplot(2, 1, 2)
plt.plot(df['pacc']/2**13)
plt.title("(b) 相位累加器输出曲线", y=-0.45)
plt.xlabel("采样点(n)")
plt.ylabel("相位误差")
plt.show()

