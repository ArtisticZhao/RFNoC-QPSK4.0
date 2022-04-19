% rx_real = (real(data_rx/sqrt(2))+1)/2;
% rx_img = (imag(data_rx/sqrt(2))+1)/2;
% r0 = 1/2^16;
% iq_data = strings(1,length(data_rx));
% for i=1:length(data_rx)
%     % 量化
%     binstr = dec2bin(round(rx_real(i)/r0));
%     iq_data(i)=binstr;
%    % + round(rx_img(i)/r0);
% end
% iq_data = iq_data';

rx_real = real(data_rx);
rx_img = imag(data_rx);
save('data.mat', 'rx_real', 'rx_img')
