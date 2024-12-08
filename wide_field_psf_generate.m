clc;clear;
filepath = strcat('./Data/PSF');

if ~exist(filepath,'dir')
    mkdir(filepath);
end
%% parameters
M =         21.89;
n =         1;   
NA =        0.5;
lambda =    525*1e-9;
pixel_size = 4e-6; 
zmax =     (10+0.01)*1e-6;
zmin =     (-10+0.01)*1e-6;
zspacing = 2e-6;
k = 2*pi*n/lambda;      
eqtol =     1e-10;
OSR =       1;

%% define object space
x1objspace = 0;
x2objspace = 0;
x3objspace = [zmin:zspacing:zmax];
objspace = ones(length(x1objspace),length(x2objspace),length(x3objspace));% discrete object space

validpts = find(objspace>eqtol);% find non-zero points
numpts = length(validpts);%
[p1indALL, p2indALL, p3indALL] = ind2sub( size(objspace), validpts);% index to subcripts
p1ALL = x1objspace(p1indALL)';% effective obj points x location
p2ALL = x2objspace(p2indALL)';% effective obj points y location
p3ALL = x3objspace(p3indALL)';% effective obj points z location
%%
disp(['Start Calculating PSF...']);
pixelPitch_OSR = pixel_size/OSR; %simulated pixel size after OSR
fx_sinalpha = 1/(2*pixelPitch_OSR);
fov=length(-(80)*OSR:(80)*OSR)*pixelPitch_OSR;  %the size of field of view for the PSF
pixelSize_OSR=length(-(80)*OSR:(80)*OSR); %the number of the pixels for each PSF
fx_step = 1/fov ;
fx_max = fx_sinalpha ;
fx= -fx_max+fx_step/2 : fx_step : fx_max;
[fxcoor, fycoor] = meshgrid( fx , fx );
fx2coor=fxcoor.*fxcoor;
fy2coor=fycoor.*fycoor;

aperture_mask=((fx2coor+fy2coor)<=((NA/(lambda*M)).^2));
psfWAVE2=ones(pixelSize_OSR,pixelSize_OSR).*aperture_mask;


%% Compute
psf = zeros(pixelSize_OSR,pixelSize_OSR,length(x3objspace));
for eachpt=1:length(x3objspace)
    aa = tic;
    if(eachpt<0)
        continue;
    else
        disp(['calcu point #',num2str(eachpt),' ...............']);
        time_s = tic;
        p1 = p1ALL(eachpt); % object point #eachpt x
        p2 = p2ALL(eachpt);
        p3 = p3ALL(eachpt);

        timeWAVE = tic;
        tempP=k*n*p3*realsqrt((1-(fxcoor.*lambda./n.*M).^2-(fycoor.*lambda./n.*M).^2).*aperture_mask);
        tempP = (single(tempP));
        psfWAVE_fAFTERNO=psfWAVE2.*exp(1j*tempP);
        psfWAVE_AFTERNO=fftshift(ifft2(ifftshift(squeeze(psfWAVE_fAFTERNO))));
    end
    
    psfWAVE3 = abs(psfWAVE_AFTERNO).^2;
    tol = 0.0005;
    psfWAVE3(isnan(psfWAVE3)) = 0;
    psfWAVE3(find(psfWAVE3 < (tol*max(psfWAVE3(:))))) = 0;
    psfWAVE3 = psfWAVE3./sum(psfWAVE3(:));

    if (eachpt == ceil(length(x3objspace)/2))
        psf_0 = psfWAVE3;
        save([filepath,'/Ideal_psf_atFocus_M',num2str(M),'_NA',num2str(NA),'_zmin',num2str(zmin),'_zmax',num2str(zmax),'_zspacing',num2str(zspacing),'.mat'],'psf_0','-v7.3');
    end

    psf(:,:,eachpt) = psfWAVE3;   
end
disp(['Saving 3D_PSF matrix file...']);
save([filepath,'/Ideal_3Dpsf_M',num2str(M),'_NA',num2str(NA),'_zmin',num2str(zmin),'_zmax',num2str(zmax),'_zspacing',num2str(zspacing),'.mat'],'psf','-v7.3');
disp(['3D_PSF computation complete.']);
imwriteTFSK(single(abs(psf)),['./Data/PSF/see.tif']);



