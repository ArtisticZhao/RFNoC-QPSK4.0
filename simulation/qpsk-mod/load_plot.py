from bitstring import BitArray
import matplotlib.pyplot as plt


f = open('./iq_out.txt', 'r')
i_ = []
q_ = []
while True:
    line = f.readline()
    if not line:
        break
    if 'x' in line:
        continue
    i = BitArray(bin=line[0:16]).int  / 2**15  # sfix16_15
    q = BitArray(bin=line[16:]).int  / 2**15  # sfix16_15
    i_.append(i)
    q_.append(q)

f.close()

plt.figure(0)
plt.scatter(i_, q_)
plt.xlabel("In-phase")
plt.ylabel("Quadrature")
plt.show()

