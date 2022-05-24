import pandas as pd
from bitstring import BitArray

def load_list(path: str):
    """
    @brief: 加载questasim导出的list文件
    @param path: list path
    @return:
    """
    def removeX(df):
        for colname in df.columns:
            if colname == 'ps' or colname == 'delta':
                continue
            last = None
            for i in range(len(df[colname])):
                if 'x' in df.loc[i, colname]:
                    # 用旧的数据替换
                    if last is not None:
                        df.loc[i, colname] = last
                    else:
                        df.loc[i, colname] = df.loc[i, colname].replace('x', '0')
                last = df.loc[i, colname]
        return df

    def convDataHex(x):
        h_index = x.find('h')
        if 'x' in x:
            print("XXXX")
            return 0
        if h_index > -1:
            length = int(x[:h_index-1])
            data = BitArray(hex=x[h_index+1:]).bin
            data = BitArray(bin=data[len(data)-length:]).int
            return data
        else:
            return 0

    data = pd.read_csv(path, delimiter=r"\s+")
    data = removeX(data)
    for colname in data.columns:
        if colname == 'ps' or colname == 'delta':
            continue
        data[colname] = data[colname].map(lambda x:convDataHex(x))
    return data


if __name__ == '__main__':
    load_list('/home/lilacsat/Playground/rfnoc/RFNoC-QPSK4.0/rfnoc/fpga/rfnoc_block_costas/xsim_proj/xsim_proj.sim/sim_1/behav/questa/list.lst')