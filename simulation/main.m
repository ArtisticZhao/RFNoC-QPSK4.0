% QPSK全流程的仿真入口
close all;
%% 仿真参数设置

N = 10000;  % 数据点数
sps = 5;    % samples per symbol
debug = 1;  % 调试选项
rrc_rolloff = 0.5; % RRC 滤波器滚降系数
EsN0     = 20;  % Target Es/N0
phaseOffset = pi/6;   % 接收时的相位偏差
freqOffset  = 60e3 / (2 * 2.5e6*sps);       % 接收时的频率偏差， 归一化频率 （数字频率）
[data_tx, data_baseband] = qpsk_tx_gen(N, sps, rrc_rolloff, debug);

% 计算信道参数
EbN0 = EsN0 / log2(4); % QPSK
snr = (10^(EbN0/10))/sps*2;
fprintf("SNR = %f dB\n", snr);
%% 信道部分
% 添加噪声
txSigPower = 1 / sqrt(sps);
data_rx = awgn(data_tx, EsN0, txSigPower);
% 接收相位差
data_rx = data_rx .* exp(-1j* phaseOffset);
% 接收频差
t = (0: N*sps-1);
data_rx = data_rx' .* exp(1j*2*pi * freqOffset * t);


if debug
    figure
    plot(data_rx, '.')
    title('data_{rx} constellation')
    figure
    plot(real(data_rx))
    xlim([0, sps*20])
    title('data_{rx} time scope')
end

% --------------------  RX ---------------------- 
%% time 同步
data_rx_sync = polyphase_clock_sync(sps, data_rx, rrc_rolloff, 32, debug);