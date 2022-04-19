close all;
%%%%%%%%%  产生QPSK信号  %%%%%%%%%
% 符号速率
ps = 2.5e6;
% samples per symbol
sps = 10;
% sample rate
fs = ps*sps;
% sample points
N = 40000;

% 设置信噪比
ebn0_db=40;
snr = (10^(ebn0_db/10))/sps*2;

% i路基带数据
data_i = sign(randn([1,N]));
% q路基带数据
data_q = sign(randn([1,N]));
% 成形滤波
% data_i = filter(Hps, data_i);
% data_q = filter(Hps, data_q);


%% 按sps插值
data_tx = zeros(1, N*sps);
for i=1:N
    for k=1:sps
        data_tx(i*sps+k-sps) = data_i(i)+1j*data_q(i);
    end
end


%% 模拟信道噪声, 以下二选一 选择是否包含信道噪声
data_rx = data_tx + (randn([1,N*sps])+1j*randn([1,N*sps])).*sqrt(1/snr);  % 信噪比snr 添加噪声
% data_rx = data_tx;  % 无噪声


%% 接收相位误差
theta_e = pi/6;
data_rx = data_rx * exp(1j*theta_e);


%% 接收频偏, 如果不需要就注释掉下面的内容
% delta_f = 60e3;
% t = [0:(1/ps/sps):(N/ps-1/ps/sps)];
% ejwt = exp(1j*2*pi*delta_f*t);
% data_rx = data_rx .* ejwt;

%% 接收星座图
plot(data_rx, '.');



%%%%%%%%%  解调QPSK  %%%%%%%%%
%%% Note: 一下使用了两种不同的环路滤波器的方案, 采用滑动平均滤波器本质上也是IIR滤波器的一种,
%%%       仿真分析后, 二者性能差别不大, 在FPGA中更容易实现滑动平均滤波器.
%% 滑动滤波器做环路滤波器
mix_out = zeros(1, N*sps);     % 混频器输出, 这里应该就是基带信号了
pacc = 0;                      % 单步环路滤波器输出(相位误差)
pacc_curve = zeros(1, N*sps);  % 保存了每个单步相位误差, 用于绘制图像
pd_out = zeros(1, N*sps);      % 鉴相器输出
% 64点滑动滤波
N_movmean = 64;
for i=1:N*sps
    % 混频器
    mix_out(i) = data_rx(i) * exp(-1j*pacc);
    % 鉴相器
    pd_out(i) = sign(real(mix_out(i)))*imag(mix_out(i)) - sign(imag(mix_out(i)))*real(mix_out(i));
    % 滑动平均滤波, 实现loopfilter
    sum_mean = 0;
    for k=0:N_movmean-1
        if i-k < 1

        else
           sum_mean =  sum_mean + pd_out(i-k);
        end
    end
    d_freq = sum_mean/N_movmean/64*pi/2;
    pacc = pacc + d_freq;
    % update pacc
    pacc_curve(i) = pacc;
end


%% IIR做环路滤波器
% mix_out = zeros(1, N*sps);      % 混频器输出, 这里应该就是基带信号了
% pacc = 0;                       % 单步环路滤波器输出(相位误差)
% pacc_curve = zeros(1, N*sps);   % 保存了每个单步相位误差, 用于绘制图
% pd_out = zeros(1, N*sps);       % 鉴相器输出
%
% pll_damping = 0.707;
% pll_loop_bw = 0.05;
%
% denom = 1.0 + 2.0*pll_damping*pll_loop_bw + pll_loop_bw*pll_loop_bw;
% d_alpha = (4*pll_damping*pll_loop_bw)/denom;
% d_beta = (4*pll_loop_bw*pll_loop_bw)/denom;
%
% d_samples_per_symbol = sps;
% d_freq_max = 3.14;
% d_freq_min = -3.14;
% d_freq = 0;
% freq = 0;
%
% for i=1:N*sps
%     mix_out(i) = data_rx(i) * exp(-1j*pacc);
%
%     pd_out(i) = sign(real(mix_out(i)))*imag(mix_out(i)) - sign(imag(mix_out(i)))*real(mix_out(i));
%
%     % loop filter
%     d_freq = d_freq + d_beta * pd_out(i) / d_samples_per_symbol / d_samples_per_symbol;
%     % 限幅
%     if(d_freq > d_freq_max)
%         d_freq = d_freq_max;
%     elseif(d_freq < d_freq_min)
%         d_freq = d_freq_min;
%     end
%     pacc = pacc + d_freq + d_alpha * pd_out(i) / d_samples_per_symbol;
%
%     % update pacc
%     pacc_curve(i) = pacc;
% end


%% 绘制解调后的图像
figure;
plot(mix_out, '.')
figure;
plot(pd_out)
