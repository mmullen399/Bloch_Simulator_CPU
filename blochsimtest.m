% mexcuda mex_blochsim.cu mexsimulator.cu magnetization.cu event_manager.cu -dynamic;
% the first run always takes about 10x longer than subsequent runs. Maybe
% in initializing the GPU?
% types of events: 0 - 7 corresponding to (in order)
% pulse,gradient,pulseAndgrad,delay,acquire,pulseGradAcq,thermaleq,refocus 
n = 128;
x = linspace(-19.2/2,19.2/2,n);
y = x;
z = 0;
obj = phantom(n); %since grid is 2D, object is too. Need 3D object for 3D simulation
                      %there is a package on the matlab file exchange for
                      %3d shepp logan phantom

[xgrid,ygrid,zgrid] = ndgrid(x,y,z);

nEvent = 2;
eventlist = zeros(nEvent,3);
%matlab won't let us assign the enumeration directly in a vector.
%it only permits single entry assignment directly to enumeration.
%e.g. eventlist(1,1) = EventTypes.pulseAndgrad is perfectly allowed.
eventlist(1,:) = [double(EventTypes.pulseAndgrad), 1500*4e-6, 1500];
eventlist(2,:) = [double(EventTypes.acquisition) 1*4e-6 1];
eventlist(3,:) = [double(EventTypes.pulseAndgrad) 1500*4e-6 1500];
eventlist(4,:) = [double(EventTypes.refocus) 1*4e-6 1]; %refocusing event
eventlist(5,:) = [double(EventTypes.acquisition) 1*4e-6 1];

Gx = [.5*ones(1000,1);-.5*ones(500,1);nullTypes.gradNull;nullTypes.gradNull;nullTypes.gradNull];
Gy = [nullTypes.gradNull;nullTypes.gradNull;.1*ones(1000,1);-.1*ones(500,1);nullTypes.gradNull;nullTypes.gradNull];
Gz = [nullTypes.gradNull;nullTypes.gradNull;nullTypes.gradNull;nullTypes.gradNull;nullTypes.gradNull];
[amp,phase] = HSpulse(10,1,1000,1); %r = 10, n = 1, 1000 time points, nonzero 4th entry means sweep goes through 0 offset
rfamp = [62.5*amp';zeros(500,1);nullTypes.rfNull;62.5*amp';zeros(500,1);nullTypes.rfNull;nullTypes.rfNull];
rfphase = [phase';zeros(500,1);nullTypes.rfNull;phase';zeros(500,1);nullTypes.rfNull;nullTypes.rfNull];

sig = 2;
B0max = 15000;
B0 = B0max * exp(-(xgrid.^2 + ygrid.^2 + zgrid.^2)/(2*sig^2));

fprintf('Simulating on grid distorted opposite what B0 causes. \n');
xgrid = xgrid - B0/(4258 * .5);
voxelWidths = cat(3,cat(3,xgrid,ygrid),zgrid);

seqParams = struct();
seqParams.xgrid = xgrid;
seqParams.ygrid = ygrid;
seqParams.zgrid = zgrid;
seqParams.Gx = Gx;
seqParams.Gy = Gy;
seqParams.Gz = Gz;
seqParams.rfamp = rfamp;
seqParams.rfphase = rfphase;
seqParams.events = eventlist;
seqParams.usrObj = obj;
seqParams.B0 = B0;
%avoid having to take all the spatial gradients in C++...
seqParams.VoxelWidths = voxelWidths;

tic;
[mx,my,mz] = mex_blochsim(seqParams);
totaltime = toc;
mxy = mx + 1i*my;

figure();
imagesc((abs(mxy(:,:,2))));

