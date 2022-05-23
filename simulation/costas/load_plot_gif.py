from bitstring import BitArray
import matplotlib.pyplot as plt

ANI_COUNTER = 1000  ## 动画一帧点数

f = open('./iq_out.txt', 'r')
i_ = []
q_ = []
while True:
    line = f.readline()
    if not line:
        break
    if 'x' in line:
        continue
    i = BitArray(bin=line[0:16]).int
    q = BitArray(bin=line[16:]).int
    i_.append(i)
    q_.append(q)

f.close()

# 绘制动图
#  ax = plt.scatter([0,], [0,])

index = 0
while index + ANI_COUNTER < len(i_):  # 最后几个点不要了
    plt.clf()  # 清空画布
    plt.xlim(-1000, 1000)
    plt.ylim(-1000, 1000)
    plt.scatter(i_[index: index+ANI_COUNTER], q_[index: index+ANI_COUNTER])
    index = index + ANI_COUNTER
    plt.pause(0.2)

#  plt.scatter(i_[-1000:], q_[-1000:])
plt.show()

