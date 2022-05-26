function [data_out] = polyphase_clock_sync(sps, data_in, rollOff, n_filters, debug)
% @brief 基于polyphase的时钟恢复模块
% @param sps: 输入数据的sps
% @param data_in: 输入的数据数组
% @param rollOff: RRC滚降系数
% @param n_filters: polyphase插值系数
% @param debug: default = false
% 
% @return data_out: 同步后的数据, sps=1
if (nargin < 4)
    debug = 0;
end
%% 生成滤波器系数
interpCoeffs = sqrt(n_filters) * rcosdesign(rollOff, 10, sps * n_filters);  % 插值滤波器参数
derivativeFilterCoeffs = derivativeMf(interpCoeffs, n_filters);
if debug
    figure
    plot(interpCoeffs)
    title('interpolation factor & derivative match filter coeffs')
    hold on
    plot(derivativeFilterCoeffs)
    plot(interpCoeffs.*derivativeFilterCoeffs)
    legend('Match filter', 'Derivative match filter', 'MF * dMF')
end
polyFilterBank = polyFilterGroup(interpCoeffs, n_filters);
derivativePolyFilterBank = polyFilterGroup(derivativeFilterCoeffs, n_filters);

%% 执行过程
n_samples = size(data_in, 2);
if n_samples == 1
   % 这是列向量
   data_in = data_in';  % 统一使用行向量
   n_samples = size(data_in, 2);
end

N = floor(n_samples/sps);  % N symbols
k  = 0;                % 符号计数器 （输出计数器）
xI = zeros(1, N);      % 同步输出，out sps=1
e  = zeros(1, N*sps);  % TED输出
v  = zeros(1, N*sps);  % 环路滤波器输出 PI控制器
mu = zeros(1, N);      % Fractional symbol timing offset estimate
m_k = 0;               % 滤波器输入index
cnt = 1;               % 模1计数器
vi = 0;

%% 环路参数计算
Bn_Ts    = 0.01;       % Loop noise bandwidth (Bn) times symbol period (Ts)
eta      = 1;          % Loop damping factor
Ex       = 1;          % Average symbol energy
% Time-error Detector Gain (TED Gain)
Kp = calcTedKp('MLTED', rollOff);

% Scale Kp based on the average symbol energy (at the receiver)
K  = 1; % Assume channel gain is unitary (or that an AGC is used)
Kp = K * Ex * Kp;
% NOTE: if using the GTED when K is not 1, note the scaling is K^2 not K.

% Counter Gain
K0 = -1;
% Note: this is analogous to VCO or DDS gain, but in the context of timing
% recovery loop.

% PI Controller Gains:
[ K1, K2 ] = piLoopConstants(Kp, K0, eta, Bn_Ts, sps);

Kp = K1;
Ki = K2;
Ksym = sqrt(2)/2;      % 将星座图的范围调整到 +-1 的系数
strobe = 0; % 符号采样信号

n_start = size(polyFilterBank, 2) - sps;   % 由于滤波器的构造，需要有一些点

for n = n_start:n_samples
    if strobe ~= 1
        % 非采样过程
        e(n) = 0; % 非采样时, error = 0
    else
        xI(k) = interpolate(data_in, m_k, mu(k), polyFilterBank);
        % Timing Error Detector:
        a_hat_k = Ksym * slice(xI(k) / Ksym, 4); % Data Symbol Estimate, 这个去了不行
        diff = interpolate(data_in, m_k, mu(k), derivativePolyFilterBank);
        
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

data_out = xI;

if debug
    % 绘制同步后的星座图
    figure
    plot(xI(0.2*N:end), '.')
    title("data_{rx} time sync constellation");
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
end

% save to python plot
save('./e_v_mu.mat', 'e', 'v', 'mu');

end

function polyFilterBank = polyFilterGroup(taps, n_filters)
% @brief 按照polyphase论文的想法，将滤波器系数进行分组
% @param taps: 分组前的滤波器
% @param n_filters: 分的组数
%
% @Return group_tap: 分组后的系数矩阵，每一行为一个独立的滤波器参数
c = size(taps, 2);
d_taps_per_filter = ceil(c / n_filters);

% 补齐滤波器系数向量
append_size = d_taps_per_filter*n_filters - c; % 计算下应该补充多少0
appends = zeros(1, append_size);
taps_append = [taps, appends];

% 将滤波器参数纵向拆分, 规律如下所示
% t1 tn+1  ...
% t2 tn+2  ...
% ...
% tn  ...
polyFilterBank = reshape(taps_append, n_filters, d_taps_per_filter);

end

function [dmf] = derivativeMf(mf, n_filters)
% @brief 根据输入的滤波器参数，给出该滤波器的差分滤波器
% @param mf: match filter coeffs
% @param n_filters: 滤波器组中滤波器个数
% 
% @return dmf: 差分滤波器系数
h = n_filters * [0.5 0 -0.5];
central_diff_mf = conv(h, mf);
% Skip the tail and head so that the dMF length matches the MF length
dmf = central_diff_mf(2:end-1);
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

function [xI] = interpolate(x, m_k, mu, poly_f)
% [xI] = interpolate(method, x, m_k, mu, b_mtx, poly_h) returns the
% interpolant xI obtained from the vector of samples x.
%
% Args:
%     x      -> Vector of samples based on which the interpolant shall be
%               computed, including the basepoint and surrounding samples.
%     m_k    -> Basepoint index, the index preceding the interpolant.
%     mu     -> Estimated fractional interval between the basepoint index
%               and the desired interpolant instant.
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
    
    polyInterpFactor = size(poly_f, 1);
    polyBranch = floor(polyInterpFactor * mu) + 1;
    polySubfilt = poly_f(polyBranch, :);
    polySubfilt = fliplr(polySubfilt);  % 为了方便计算进行翻转
    N = length(polySubfilt);
    xI = polySubfilt * x((m_k - N + 1) : m_k)';
end