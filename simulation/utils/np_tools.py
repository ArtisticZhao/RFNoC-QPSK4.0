# coding: utf-8
import numpy as np


"""
@brief: 归一化到 [-1, +1]
"""
def normalize(data):
    max_abs = np.max(np.abs(data))
    return data / max_abs

