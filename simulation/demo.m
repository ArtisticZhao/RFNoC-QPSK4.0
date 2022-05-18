L        = 4;         % Oversampling factor
rollOff  = 0.5;       % Pulse shaping roll-off factor
rcDelay  = 10;        % Raised cosine delay in symbols

% Filter:
htx = rcosine(1, L, 'sqrt', rollOff, rcDelay/2);
% Note half of the target delay is used, because when combined
% to the matched filter, the total delay will be achieved.
hrx  = conj(fliplr(htx));

figure
plot(htx)
title('Transmit Filter')
xlabel('Index')
ylabel('Amplitude')

figure
plot(hrx)
title('Rx Filter (Matched Filter)')
xlabel('Index')
ylabel('Amplitude')

p = conv(htx,hrx);

figure
plot(p)
title('Combined Tx-Rx = Raised Cosine')
xlabel('Index')
ylabel('Amplitude')

% And let's highlight the zero-crossings
zeroCrossings = NaN*ones(size(p));
zeroCrossings(1:L:end) = 0;
zeroCrossings((rcDelay)*L + 1) = NaN; % Except for the central index
hold on
plot(zeroCrossings, 'o')
legend('RC Pulse', 'Zero Crossings')
hold off
M = 2; % PAM Order

% Arbitrary binary sequence alternating between 0 and 1
data = zeros(1, 2*rcDelay);
data(1:2:end) = 1;

% PAM-modulated symbols:
txSym = real(pammod(data, M));

figure
stem(txSym)
title('Symbol Sequence')
xlabel('Symbol Index')
ylabel('Amplitude')

% Upsampling
txUpSequence = upsample(txSym, L);

figure
stem(txUpSequence)
title('Upsampled Sequence')
xlabel('Sample Index')
ylabel('Amplitude')

% Pulse Shaping
txSequence = filter(htx, 1, txUpSequence);

figure
stem(txSequence)
title('Shaped Transmit Sequence')
xlabel('Index')
ylabel('Amplitude')

timeOffset = 1; % Delay (in samples) added

% Delayed sequence
rxDelayed = [zeros(1, timeOffset), txSequence(1:end-timeOffset)];

mfOutput = filter(hrx, 1, rxDelayed); % Matched filter output

figure
stem(mfOutput)
title('Matched Filter Output (Correlative Receiver)')
xlabel('Index')
ylabel('Amplitude')

rxSym = downsample(mfOutput, L);

% Generate a vector that shows the selected samples
selectedSamples = upsample(rxSym, L);
selectedSamples(selectedSamples == 0) = NaN;

% And just for illustration purposes
figure
stem(mfOutput)
hold on
stem(selectedSamples, '--r', 'LineWidth', 2)
title('Matched Filter Output (Correlative Receiver)')
xlabel('Index')
ylabel('Amplitude')
legend('MF Output', 'Downsampled Sequence (Symbols)')
hold off

close all
figure
subplot(2,1,1)
stem(mfOutput);
hold on
t = (42:L:size(mfOutput,2));
stem(t, mfOutput(t), '--r')
legend('脉冲成形后输出', '最佳采样点')
title('发射机波形')
xlim([30,size(mfOutput,2)])
subplot(2,1,2)
resa = resample(mfOutput, 10, 1);
phaseoff_re = zeros(1, size(mfOutput,2));

index = 1;
a = 7;
b = 13;
rng('default')  % 不样随机
for i = 1:size(mfOutput,2)
    phaseoff_re(i) = resa(index);
    r = (b-a).*rand(1,1) + a;
    index = index + floor(r);
    if index > size(resa,2)
        index = size(resa,2);
    end
end
hold off
stem(phaseoff_re);
xlim([30,size(phaseoff_re,2)])
hold on
t = (43:L:size(phaseoff_re,2));
stem(t, phaseoff_re(t), '--r')
legend('匹配滤波后输出', '判决采样点')
title('接收机波形')
