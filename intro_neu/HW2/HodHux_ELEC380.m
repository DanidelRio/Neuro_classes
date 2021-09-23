function [V, m, n, h, gkt, gnat, Ik, Ina, Il] = HodHux_ELEC380(I,dt,plot_activation)
%Hodgkin Huxley model of a neuron
%ELEC 480 Fall 2014
%JTRobinson
%
%Input:
%I = a vector of current values [uA]
%dt = time step between I measurments [ms]
%plot_activation (optional) = 1 to plot the activation state variables vs V (default 0)
%
%Output:
%Vm = membrane voltage in mV
%n = sodium activation
%m = potassium activation
%h = 1 - potassium inactivation
%
%State variables: V, n, m, h
%
%DV = 1/C (I - Ik - Ina - Il)
% 
% Il = gl(V-El)
% Ik = gk*n^4(V-Ek)
% Ina = gna*m^3*h(V-Ena)
%
%Dn = (ninf(V) - n)/taun(V)
%Dm = (minf(V) - m)/taum(V)
%Dh = (hinf(V) - h)/tauh(V)

if(nargin<3)
    plot_activation = 0;
end

%starting membrane potential;
Vstart = -65.625; %[mV]

%Constants:
%reversal potentials for various ions
Ek = -77; %[mV]
Ena = 50; %[mV] 
El = -54.4; %[mV] H&H used approx -55 mV

%Membrane capacitance:
C = 1; %[uF]

%maximum conductances [mS]
gna = 120;
gk = 36;
gl = 0.3;

%Constants for GHK eq for channel activation
%from J. Bossu, J Physiol. 496.2 (1996)
%V50n = 57;
%kn = 13.5;

%from Izhikevich pg. 46 (2007)
%K+ Delayed Rectifier 1: Ik = g*n^4*(V-Ek)

%activation
V50n = -50;
kn = 15;

Vmaxn = -79;
sig_n = 50;
Campn = 4.7;
Cbasen = 1.1;

%from Izhikevich pg. 46 (2007)
%Na+ Fast Transient 1: Ina = g*m^3*h*(V-Ena)

%activation:
V50m = -40;
km = 8; %adjusted to match Fig. 2.3 on Pg. 39. probably a typo in the table 

Vmaxm = -38;
sig_m = 30;
Campm = 0.46;
Cbasem = 0.04;

%inactivation
V50h = -60;
kh = -7;

Vmaxh = -67;
sig_h = 20;
Camph = 7.4;
Cbaseh = 1.2;

%initialize the vector sizes
n = zeros(1,length(I));
m = n;
h = n;
V = n;

%set initial conditions:
n(1) = 0.3;
m(1) = 0.006;
h(1) = 0.626;
V(1) = Vstart; %[mV]


%iterate through the input sequence and calculate the response
for(ii=1:length(I)-1);
    
    %display progress (can remove this block if desired)
    if(mod(ii,1000)==0)
        disp(num2str(ii))
        disp(num2str([V(ii) n(ii) m(ii) h(ii)]))
    end
    

    
    %update voltage state variable
    %DV = 1/C (I - Ik - Ina - Il)
    
    %units: 
    %I = uA
    %V = mV, g = mS; g*V = uA
    %C = uF 
    %uA/uC*ms = mV
   
    %full model
    V(ii+1) = V(ii) + dt/C*(I(ii) - gl*(V(ii)-El) - gk*n(ii)^4*(V(ii)-Ek) - gna*m(ii)^3*h(ii)*(V(ii)-Ena));
     
    
    %steady state activation values at the given voltage
    ninf = 1/( 1 + exp( (V50n-V(ii))./kn ) );
    minf = 1/( 1 + exp( (V50m-V(ii))./km ) );
    hinf = 1/( 1 + exp( (V50h-V(ii))./kh ) );
    
    %time constants
    %Izhikevich pg. 45
    taun = Cbasen + Campn*exp(-(Vmaxn-V(ii))^2/sig_n^2);
    taum = Cbasem + Campm*exp(-(Vmaxm-V(ii))^2/sig_m^2);
    tauh = Cbaseh + Camph*exp(-(Vmaxh-V(ii))^2/sig_h^2);
    
    %update activation state variables
    n(ii+1) = n(ii) + dt*(ninf - n(ii))/taun;
    m(ii+1) = m(ii) + dt*(minf - m(ii))/taum;
    h(ii+1) = h(ii) + dt*(hinf - h(ii))/tauh;
    
end %ii

gkt = gk.*n.^4;
gnat = gna.*m.^3.*h;

Ik = gkt.*(V-Ek);
Ina = gnat.*(V-Ena);
Il = gl.*(V-El);

%Diagnostics
if(plot_activation)
Vtest = -100:10;

%steady state activation vs Voltage
ninfV = 1./( 1 + exp((V50n-Vtest)./kn));
minfV = 1./( 1 + exp((V50m-Vtest)./km));
hinfV = 1./( 1 + exp((V50h-Vtest)./kh));

figure;
plot(Vtest,ninfV)
hold on;
plot(Vtest,minfV,'r')
plot(Vtest,hinfV,'k')
title('steady state activations')
legend('n_\infty','m_\infty','h_\infty')
 
%time constants vs Voltage
taunV = Cbasen + Campn.*exp(-(Vmaxn-Vtest).^2./sig_n^2);
taumV = Cbasem + Campm.*exp(-(Vmaxm-Vtest).^2./sig_m^2);
tauhV = Cbaseh + Camph.*exp(-(Vmaxh-Vtest).^2./sig_h^2);

figure;
plot(Vtest,taunV)
hold on;
plot(Vtest,taumV,'r')
plot(Vtest,tauhV,'k')
title('activation time constants')
legend('\tau_n','\tau_m','\tau_h')

end%if(plot_activation)
    
    

