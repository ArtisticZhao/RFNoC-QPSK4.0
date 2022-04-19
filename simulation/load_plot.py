from bitstring import BitArray
import matplotlib.pyplot as plt

f = open('./iq_out.txt', 'r')
i_ = []
q_ = []
while True:
    line = f.readline()
    if not line:
        break
    i = BitArray(bin=line[0:16]).int
    q = BitArray(bin=line[16:]).int
    i_.append(i)
    q_.append(q)

f.close()

plt.scatter(i_, q_)
plt.show()

