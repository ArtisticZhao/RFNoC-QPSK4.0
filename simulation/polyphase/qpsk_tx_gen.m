function [data_tx, data_baseband] = qpsk_tx_gen(N, sps, rolloff, debug)
% @brief 生成QPSK基带数据
% @param N: 基带数据点数
% @param sps: samples per symbol
% @param rolloff: rrc 滚降系数
% @param debug: 显示调试图像 default = false
%
% @return data_tx: 生成的基带信号
% @return data_baseband: 生成的基带数据

if (nargin < 4)
    debug = 0;
end

% 随机基带数据
data_i = sign(randn([1,N]));
data_q = sign(randn([1,N]));
data_baseband = (data_i + 1j*data_q) * sqrt(2)/2;

% 按sps插值
data_tx = repmat(data_baseband, sps, 1);
data_tx = data_tx(:);

% RRC 滤波器实现
Astop = 30; % 组带衰减值
h = fdesign.pulseshaping(sps, 'Square Root Raised Cosine', 'ast,beta', Astop, rolloff);
Hd = design(h, 'window');
ntaps = size(Hd.coeffs.Numerator, 2);  % 滤波器参数个数
data_tx = filter(Hd, data_tx);

if debug
   figure
   plot(data_tx, '.')
   hold on 
   plot(data_baseband, 'o')
   hold off
   title('Data Tx generation constellation')
   legend('data_{tx}', 'data_{baseband}')
   
   figure
   plot(real(data_tx))
   hold on
   % 绘制基带数据
   delay = floor(ntaps/2) + floor(sps/2);  % 计算延迟
   t = (delay: sps: N*sps);
   stem(t, real(data_baseband(1:end-(N-size(t,2)))))
   hold off
   xlim([0,sps*20]); % 显示20个采样点
   title('Data Tx generation time scope');
   legend('real', 'real_{baseband}');
end

end