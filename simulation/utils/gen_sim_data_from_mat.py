# coding: utf-8
from scipy.io import loadmat
import numpy as np
from bitstring import BitArray

mt = loadmat('data.mat')
i = mt['rx_real']
q = mt['rx_img']

print(i)
r0 = 1/2**11

i_int = np.floor(i/r0)[0]
q_int = np.floor(q/r0)[0]
# iq_binstr = []
f = open('iq_data.txt', 'w')
for i in range(len(i_int)):
    istr = BitArray(int=int(i_int[i]), length=16).bin
    qstr = BitArray(int=int(q_int[i]), length=16).bin
    # iq_binstr.append(istr+qstr+'\n')
    f.write(istr+qstr+'\n')
# f.writelines(iq_binstr)
f.close()
