close all
N = 40000;
sps = 4;
rrc_damping = 64;   % RRC 滚降系数
loop_bw = 62.8e-3;
n_filter = 32;  % 滤波器组参数，由于rrc参数从外部导入，这里不支持更改暂时
% i路基带数据
data_i = sign(randn([1,N]));
% q路基带数据
data_q = sign(randn([1,N]));
%% 按sps插值
data_tx = zeros(1, N*sps);
for i=1:N
    for k=1:sps
        data_tx(i*sps+k-sps) = data_i(i)+1j*data_q(i);
    end
end

% RRC
rrc_taps_tx = [-0.004102709703147411, -0.005911271553486586, -0.0006446786574088037, 0.005911271553486586, 0.005014423280954361, -0.0038312275428324938, -0.010130664333701134, -0.0038312275428324938, 0.010745192877948284, 0.01649368926882744, 0.0030391993932425976, -0.01649368926882744, -0.015043269842863083, 0.015507349744439125, 0.04254879429936409, 0.015507349744439125, -0.07521635293960571, -0.15723983943462372, -0.10637197643518448, 0.15723983943462372, 0.5800977349281311, 0.9769630432128906, 1.139497995376587, 0.9769630432128906, 0.5800977349281311, 0.15723983943462372, -0.10637197643518448, -0.15723983943462372, -0.07521635293960571, 0.015507349744439125, 0.04254879429936409, 0.015507349744439125, -0.015043269842863083, -0.01649368926882744, 0.0030391993932425976, 0.01649368926882744, 0.010745192877948284, -0.0038312275428324938, -0.010130664333701134, -0.0038312275428324938, 0.005014423280954361, 0.005911271553486586, -0.0006446786574088037, -0.005911271553486586, -0.004102709703147411];
data_tx_rrc = filter(rrc_taps_tx, 4, data_tx);

data_i_rrc = real(data_tx_rrc);
data_q_rrc = imag(data_tx_rrc);


% -- 试试单点的fir filter
% data_q_rrc_ = zeros(1, 160000);
% 
% zf = zeros(1, size(rrc_taps_tx, 2)-1);
% for i=1:160000
%     [data_q_rrc_(i), zf] = filter(rrc_taps_tx, 4, data_q(i), zf);
% end
% isequal(data_q_rrc, data_q_rrc_)
% -- 看起来这样没问题

%% 验证发射RRC滤波器
% plot_y = 100;  % 显示点数
% figure
% subplot(221)
% plot(data_i)
% ylim([-1.2, 1.2])
% xlim([0,plot_y]);
% subplot(222)
% plot(data_q)
% xlim([0,plot_y]);
% ylim([-1.2, 1.2])
% 
% subplot(223)
% plot(data_i_rrc)
% xlim([0,plot_y]);
% subplot(224)
% plot(data_q_rrc)
% xlim([0,plot_y]);

%% 信道部分
% data_rx = data_tx_rrc;

%% 创建polyphase滤波器组

% % 从文件中读取polyphase rrc参数
% rrc_polyphase_taps = importdata('./polyphase_clock_sync/rrc_taps.txt');
% dtaps = taps_to_group(rrc_polyphase_taps, n_filter);
% % 差分滤波器组
% diffed_taps = create_diff_taps(rrc_polyphase_taps);
% d_diff_taps = taps_to_group(diffed_taps, n_filter);
load('./polyphase_clock_sync/matlab.mat')
dtaps = fliplr(polyMf);
d_diff_taps = fliplr(polyDMf);

% figure
% plot(dtaps(:))
% hold on
% plot(d_diff_taps(:))
% hold off


%% 执行过程
k  = 0;                % 符号计数器 （输出计数器）
xI = zeros(1, N);      % 同步输出，out sps=1
e  = zeros(1, N*sps);  % TED输出
v  = zeros(1, N*sps);  % 环路滤波器输出 PI控制器
mu = zeros(1, N);      % Fractional symbol timing offset estimate
m_k = 0;               % 滤波器输入index
cnt = 1;               % 模1计数器
vi = 0;
Kp = -0.002368190349397;
Ki = -4.736380698794215e-06;

% 初始化滤波器组
zf_taps = zeros(n_filter, size(dtaps, 2)-1); % 均是0状态
zf_diff_taps = zeros(n_filter, size(d_diff_taps, 2)-1); 

strobe = 0; % 符号采样信号
strobe_c = zeros(1, N*sps);
for n=(41-sps):N*sps  % 每一个输入都进行操作
    if strobe ~= 1
        % 非采样过程
        e(n) = 0; % 非采样时, error = 0
    else
        % 采样过程

        % 插值滤波器
%         mu_ = mu(k);
%         if mu_ < 0
%             m_k = m_k - 1;
%             mu_ = mu_ + 1;
%         elseif mu_>=1
%             m_k = m_k + 1;
%             mu_ = mu_ - 1;
%         end
%         filter_idx = floor(n_filter * mu(k)) + 1;
%         [xI(k), zf_taps(filter_idx, :)] = filter(dtaps(filter_idx,:), 1, rxSeq(m_k), zf_taps(filter_idx,:));

        % dMF 检测滤波器
%         [diff, zf_diff_taps(filter_idx, :)] = filter(d_diff_taps(filter_idx,:), 1, rxSeq(m_k), zf_diff_taps(filter_idx,:));


        xI(k) = interpolate(0, rxSeq, m_k, mu(k), [], polyMf);
        % Timing Error Detector:
        a_hat_k = Ksym * slice(xI(k) / Ksym, 4); % Data Symbol Estimate, 这个去了不行
        diff = interpolate(0, rxSeq, m_k, mu(k),  [], polyDMf);
        
        % TED
        e(n) = real(a_hat_k) * real(diff) + imag(a_hat_k) * imag(diff);

    end

    % 计算环路滤波器
    vp = Kp * e(n);
    vi = vi + (Ki * e(n));
    v(n) = vp + vi;

    % 计数器步进
    W = 1/sps + v(n);

    strobe = cnt < W;
    if(strobe)
        k = k + 1;
        m_k = n;
        mu(k) = cnt / W;
        strobe_c(n) = 3;
    end
    % Next modulo-1 counter value:
    cnt = mod(cnt - W, 1);
end

% 去掉尾巴
if (strobe)
    xI = xI(1:k-1);
else
    xI = xI(1:k);
end


%% 绘制结果
figure
plot(xI(0.2*N:end), '.')

figure
subplot(311)
plot(e);
title('e(n)');
subplot(312)
plot(v)
title('PI out v(n)');
subplot(313)
plot(mu)
ylim([-1.2, 1.2])
title('mu')

% subplot(313)
% scatter(out)
%% 本文件中用到的函数
% @brief 输入一系列的滤波器参数，按照一定的规则映射成滤波器组， 函数功能同GR的CPP程序
% @param[in] taps: 一系列的滤波器参数
% @param[in] n_filter: 滤波器组中有多少滤波器
% @return    dtaps: 二维矩阵，一行为一个滤波器的参数
function dtaps = taps_to_group (taps, n_filter)
   [r,c] = size(taps);
   d_taps_per_filter = ceil(c / n_filter);
   % 初始化返回矩阵
   dtaps = zeros(n_filter, d_taps_per_filter);
   % 补齐滤波器系数向量
   append_size = d_taps_per_filter*n_filter - c; % 计算下应该补充多少0
   appends = zeros(1, append_size);
   taps_append = [taps, appends];
   for i=1:n_filter
       for j=1:d_taps_per_filter
          dtaps(i, j) = taps_append(i+(j-1)*n_filter);
       end
   end  
end

% @brief 根据模块输入的滤波器参数（RRC），生成对应的差分滤波器的参数
% @param[in] newtaps  RRC taps
% @param[out] difftaps 差分滤波器参数
function difftaps = create_diff_taps (taps)
    diff_filter = [-1,0,1];
    [r, c] = size(taps);
    taps_size = c;
    difftaps = zeros(1, taps_size);
    difftaps_pushback_index = 2;
    pwr = 0;
    for i=1:taps_size-2
        tap = 0;
        for j=1:3
            tap = tap + diff_filter(j)*taps(i+j-1);
        end
        difftaps(difftaps_pushback_index) = tap;
        difftaps_pushback_index = difftaps_pushback_index + 1;
        pwr = pwr + abs(tap);
    end
    % 归一化
    difftaps = difftaps .*(32 / pwr);
end

function [xI] = interpolate(method, x, m_k, mu, b_mtx, poly_f)
% [xI] = interpolate(method, x, m_k, mu, b_mtx, poly_h) returns the
% interpolant xI obtained from the vector of samples x.
%
% Args:
%     method -> Interpolation method: polyphase (0), linear (1), quadratic
%               (2), or cubic (3).
%     x      -> Vector of samples based on which the interpolant shall be
%               computed, including the basepoint and surrounding samples.
%     m_k    -> Basepoint index, the index preceding the interpolant.
%     mu     -> Estimated fractional interval between the basepoint index
%               and the desired interpolant instant.
%     b_mtx  -> Matrix with the coefficients for the polynomial
%               interpolator used with method=2 or method=3.
%     poly_f -> Polyphase filter bank that should process the input samples
%               when using the polyphase interpolator (method=0).

    % Adjust the basepoint if mu falls out of the nominal [0,1) range. This
    % step is necessary only to support odd oversampling ratios, when a
    % +-0.5 offset is added to the original mu estimate. In contrast, with
    % an even oversampling ratio, mu is within [0,1) by definition.
    if (mu < 0)
        m_k = m_k - 1;
        mu = mu + 1;
    elseif (mu >= 1)
        m_k = m_k + 1;
        mu = mu - 1;
    end
    assert(mu >= 0 && mu < 1);

    switch (method)
    case 0 % Polyphase interpolator
        % Choose the polyphase subfilter using mu. Use the floor operator
        % to make sure the resulting branch (polyBranch) is always within
        % the acceptable range [1, polyInterpFactor], given that mu is
        % within [0, 1). Also, note it is perfectly feasible to use "round"
        % instead of "floor". In this case, it is only necessary to add an
        % extra subfilter to the filter bank. More specifically, to add a
        % shifted-by-one version of the first subfilter, namely the same
        % subfilter as the first but with a delay shorter by one sampling
        % period (see commit 0537d70). However, this extra complexity is
        % unnecessary, especially if the polyInterpFactor is high enough,
        % when the subfilter phases are already very close to each other.
        polyInterpFactor = size(poly_f, 1);
        polyBranch = floor(polyInterpFactor * mu) + 1;
        polySubfilt = poly_f(polyBranch, :);
        N = length(polySubfilt);
        xI = polySubfilt * x((m_k - N + 1) : m_k);
    case 1 % Linear Interpolator (See Eq. 8.61)
        xI = mu * x(m_k + 1) + (1 - mu) * x(m_k);
    case 2 % Quadratic Interpolator
        % Recursive computation based on Eq. 8.77
        v_l = x(m_k - 1 : m_k + 2).' * b_mtx;
        xI = (v_l(3) * mu + v_l(2)) * mu + v_l(1);
    case 3 % Cubic Interpolator
        % Recursive computation based on Eq. 8.78
        v_l = x(m_k - 1 : m_k + 2).' * b_mtx;
        xI = ((v_l(4) * mu + v_l(3)) * ...
            mu + v_l(2)) * mu + v_l(1);
    end
end

%% Function to map Rx symbols into constellation points
function [z] = slice(y, M)
if (isreal(y))
    % Move the real part of input signal; scale appropriately and round the
    % values to get ideal constellation index
    z_index = round( ((real(y) + (M-1)) ./ 2) );
    % clip the values that are outside the valid range
    z_index(z_index <= -1) = 0;
    z_index(z_index > (M-1)) = M-1;
    % Regenerate Symbol (slice)
    z = z_index*2 - (M-1);
else
    M_bar = sqrt(M);
    % Move the real part of input signal; scale appropriately and round the
    % values to get ideal constellation index
    z_index_re = round( ((real(y) + (M_bar - 1)) ./ 2) );
    % Move the imaginary part of input signal; scale appropriately and
    % round the values to get ideal constellation index
    z_index_im = round( ((imag(y) + (M_bar - 1)) ./ 2) );

    % clip the values that are outside the valid range
    z_index_re(z_index_re <= -1)       = 0;
    z_index_re(z_index_re > (M_bar-1)) = M_bar-1;
    z_index_im(z_index_im <= -1)       = 0;
    z_index_im(z_index_im > (M_bar-1)) = M_bar-1;

    % Regenerate Symbol (slice)
    z = (z_index_re*2 - (M_bar-1)) + 1j*(z_index_im*2 - (M_bar-1));
end
end