import numpy as np
from matplotlib import pyplot as plt
plt.rcParams["font.sans-serif"]=["SimHei"] #设置字体
plt.rcParams["axes.unicode_minus"]=False #正常显示负号

t = np.arange(-4, 7, 0.001)
ys = []
ax = plt.subplot(211)
ax.set_yticks([0, 1], minor=False)
ax.set_xticks(list(range(-4, 8)), minor=False)
for i in range(4):
    y = np.sinc(t-i)
    ys.append(y)
    ax.plot(t, y)
ax.grid()
ax.yaxis.grid(True, which='major')
ax.xaxis.grid(True, which='major')
ax.set_xlabel("基带数据(n)")
a = ax.get_xgridlines()
for i in range(4, 8):
    b = a[i]
    b.set_color('red')
    b.set_linestyle('--')
    b.set_linewidth(1.5)


# ax.xlabel('基带数据(n)')
ax = plt.subplot(212)
ys = np.array(ys)
ax.set_yticks([0, 1], minor=False)
ax.set_xticks(list(range(-4, 8)), minor=False)
sum_ = np.sum(ys, axis=0)
ax.set_xlabel("基带数据(n)")
ax.plot(t, sum_)
ax.grid()

ax.yaxis.grid(True, which='major')
ax.xaxis.grid(True, which='major')
a = ax.get_xgridlines()
for i in range(4, 8):
    b = a[i]
    b.set_color('red')
    b.set_linestyle('--')
    b.set_linewidth(1.5)
plt.show()
