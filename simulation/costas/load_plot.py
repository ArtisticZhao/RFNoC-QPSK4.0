from bitstring import BitArray
import matplotlib.pyplot as plt
import numpy as np
import os
import matplotlib as mpl
mpl.rcParams["savefig.directory"] = str(os.chdir(os.path.dirname(os.path.abspath(__file__))))
plt.rcParams["font.sans-serif"]=["SimHei"] #设置字体
plt.rcParams["axes.unicode_minus"]=False #正常显示负号

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
    i = BitArray(bin=line[0:16]).int  / 2**15
    q = BitArray(bin=line[16:]).int  / 2**15
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
    i = BitArray(bin=line[0:16]).int  / 2**15
    q = BitArray(bin=line[16:]).int  / 2**15
    i_o.append(i)
    q_o.append(q)
f.close()

f = plt.subplot(1,2,1)
f.scatter(i_, q_)
f.set_xlabel("实信号（归一化幅值）")
f.set_ylabel("虚信号（归一化幅值）")
f.set_title("(a) 固定相差输入信号", y=-0.1)

sp = 1000
alpha = np.linspace(0, 1, sp)
f = plt.subplot(1,2,2)
unlock = f.scatter(i_o[:sp], q_o[:sp], alpha=alpha)
lock = f.scatter(i_o[sp:], q_o[sp:])
f.set_xlabel("实信号（归一化幅值）")
f.set_ylabel("虚信号（归一化幅值）")
f.set_title("(b) 极性Costas环输出信号", y=-0.1)
f.legend([unlock, lock], ['未锁定', '锁定'], loc="upper right")
legend = f.get_legend()
for lh in legend.legendHandles:
    lh.set_alpha(1)
plt.show()

