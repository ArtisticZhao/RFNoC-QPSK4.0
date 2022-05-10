n = (-100: 100);
y = rrc(n, 0.5, 1e6);
plot(y)

function y = rrc(t, beta, Ts)
    y0 = 1/Ts*(1+beta*(4/pi-1));
    yts = beta/Ts/sqrt(2) * ( (1+2/pi)*sin(pi/4/beta) + (1-2/pi)*cos(pi/4/beta) );
    yo = 1/Ts *  ( sin(pi*t./Ts .*(1-beta)) + 4*beta.*t ./Ts .* cos(pi.*t./Ts .*(1+beta))  ) ...
        ./(pi .* t ./Ts .*(1-(4*beta.*t./Ts).^2));
    yo(isnan(yo)) = 0;
    
    y = y0.*(t==0) + yts.*(t==Ts/4/beta | t==-Ts/4/beta) + yo.*(t~=0 & t~=Ts/4/beta & t~=-Ts/4/beta );
end

% function y = rrc(n, beta, Fs)
%     T = 1/Fs;
%     y = 2*beta/pi/sqrt(T) * (cos((1+beta)*pi*n) + sin((1-beta)*pi*n)./(4*beta*n) ) ./ (1- (4*beta*n).^2);
% end