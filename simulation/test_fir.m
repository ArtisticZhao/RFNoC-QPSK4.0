close all
N = 100;
sps = 3;
data_i = [1,-1, 1, -1,1,-1, 1, -1];
N =  size(data_i,2);
% data_i = sign(randn([1,N]));
% 按sps插值
% data_tx = repmat(data_i, sps, 1);
data_tx = [data_i; zeros(sps-1, N)];
data_tx = data_tx(:);

coe = rcosdesign(0.5, 6, sps);
ntaps = size(coe,2);
delay = floor(ntaps/2) + floor(sps/2);  % 计算延迟

f = filter(coe,1, data_tx);
% ff = filter(Hps, data_tx);
subplot(311)
stem(f);
xlim([1, 50])
hold on
t = [10,13,16,19];
stem(t, f(t))
subplot(312)
% 重采样
fsOffsetPpm = 10000;
fsRatio = 1 + (fsOffsetPpm * 1e-6); % Rx/Tx clock frequency ratio
tol = 1e-9;
[P, Q] = rat(fsRatio, tol);
resamp = resample(f, 12, 10);

stem(resamp);
xlim([1, 50])
hold on
stem(t, resamp(t))


% subplot(313)
% stem(ff)
% xlim([1, sps*look])