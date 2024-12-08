% 因电脑没有GPU，所有gpu操作改为cpu操作（包括Util)
% 虽然没用GPU操作，但为方便，文件名（如im_shift2_GPU)都不变，特此说明

clc;clear;
addpath('./Util');
filepath = strcat('./Data/PSF');

if ~exist(filepath,'dir')
    mkdir(filepath);
end
%% parameters
Nnum = 15;
M =         21.89;
n =         1;   
NA =        0.5;
lambda =    525*1e-9;
pixel_size = 4e-6; 
fml =       1248e-6;
MLPitch =   pixel_size*Nnum;
zmax =     (20+0.01)*1e-6;
zmin =     (-20+0.01)*1e-6;
zspacing = 1e-6;
k = 2*pi*n/lambda;    
k0 = 2*pi*1/lambda;           % k air
eqtol =     1e-10;
tol =       0.0005; 
OSR =       3;
HALF_ML_NUM = 9;
pixelPitch = pixel_size;
aberration_model = 0;

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
pixelPitch_OSR = MLPitch/OSR/Nnum; %simulated pixel size after OSR
fx_sinalpha = 1/(2*pixelPitch_OSR);
pixelSize_OSR=length(-(HALF_ML_NUM+1)*OSR*Nnum-1:(HALF_ML_NUM+1)*OSR*Nnum+1); %the number of the pixels for each PSF
fov=pixelSize_OSR*pixelPitch_OSR;   %the size of field of view for the PSF
fx_step = 1/fov ;
fx_max = fx_sinalpha ;
fx= -fx_max+fx_step/2 : fx_step : fx_max;
[fxcoor, fycoor] = meshgrid( fx , fx );
fx2coor=fxcoor.*fxcoor;
fy2coor=fycoor.*fycoor;
k2=2*pi/lambda;

aperture_mask=((fx2coor+fy2coor)<=((NA/(lambda*M)).^2));
aperture_mask_size = length(find(aperture_mask(:,ceil(size(aperture_mask,2)/2))));
psfWAVE2=ones(pixelSize_OSR,pixelSize_OSR).*aperture_mask;
%psfWAVE2 = gpuArray(single(psfWAVE2));
psfWAVE2 = single(psfWAVE2);
x1MLspace = (pixelPitch/OSR)* [-(Nnum*OSR-1)/2 : 1 : (Nnum*OSR-1)/2]; % total x space per ML
x2MLspace = (pixelPitch/OSR)* [-(Nnum*OSR-1)/2 : 1 : (Nnum*OSR-1)/2]; % total y space per ML
x1space = (pixelPitch/OSR) * [-(HALF_ML_NUM+1)*OSR*Nnum-1:(HALF_ML_NUM+1)*OSR*Nnum+1]; % x space
x2space = (pixelPitch/OSR) * [-(HALF_ML_NUM+1)*OSR*Nnum-1:(HALF_ML_NUM+1)*OSR*Nnum+1]; % y space
[MLARRAY,MLARRAYab] = calcML(fml, k0, x1MLspace, x2MLspace, x1space, x2space); % micro array phase mask
%MLARRAY = gpuArray(single(MLARRAY));
MLARRAY = single(MLARRAY);

x1objspace = (pixelPitch/M)*[-floor(Nnum/2):1:floor(Nnum/2)];% corresponding object space x1
x2objspace = (pixelPitch/M)*[-floor(Nnum/2):1:floor(Nnum/2)];% corresponding object space x2
XREF = ceil(length(x2objspace)/2);
YREF = ceil(length(x1objspace)/2);

centerPT = floor(length(x1space)/2);
halfWidth = HALF_ML_NUM*Nnum*OSR; %
CP = ( (centerPT-1)/OSR+1 - halfWidth/OSR :1: (centerPT-1)/OSR+1 + halfWidth/OSR);%
H_z = zeros(length(CP),length(CP),Nnum,Nnum);

%% Compute
%% Compute
[XX,YY] = meshgrid(1:size(psfWAVE2,2),1:size(psfWAVE2,1));
for eachpt = 1: length(x3objspace)
    aa = tic;
    if(eachpt<0)
        continue;
    else
        disp(['calcu point #',num2str(eachpt),' ...............']);
        p1 = p1ALL(eachpt); % object point #eachpt x
        p2 = p2ALL(eachpt);
        p3 = p3ALL(eachpt);

        tempP=k2*n*p3*realsqrt((1-(fxcoor.*lambda./n.*M).^2-(fycoor.*lambda./n.*M).^2).*aperture_mask);
        %tempP = gpuArray(single(tempP));
        tempP = single(tempP);
        psfWAVE_fAFTERNO=psfWAVE2.*exp(1j*tempP);
        psfWAVE_AFTERNO=fftshift(ifft2(ifftshift(squeeze(psfWAVE_fAFTERNO))));

        if aberration_model == 1
            %load abberation 
            padr = floor((size(psfWAVE_fAFTERNO,1) - size(aberration,1))/2);
            aberration = padarray(aberration,[padr,padr],0,'both');
            mask_aber = padarray(mask_aber,[padr,padr],0,'both');
            psfWAVE_AFTERNO = ifft2(ifftshift(fftshift(fft2(psfWAVE_AFTERNO)).*exp(1i* aberration) .* mask_aber));
        end


        timeFre = tic;
        for b1 = 1:length(x2objspace)
            for a1 = 1:length(x1objspace)
                timein = tic;
                psfSHIFT0= im_shift2_GPU(psfWAVE_AFTERNO, OSR*(a1-XREF), OSR*(b1-YREF) );%
                f1=fresnel2D_GPU(psfSHIFT0.*MLARRAY.*MLARRAYab, pixelPitch/OSR, fml,lambda);%
                f1= im_shift2_GPU(f1, -OSR*(a1-XREF), -OSR*(b1-YREF) );%
                [f1_AP_resize, x1shift, x2shift] = pixelBinning_GPU(abs(f1).^2, OSR);
                f1_CP = f1_AP_resize( CP - x1shift, CP-x2shift );
                H_z(:,:,a1,b1) = gather(f1_CP);%
                tt = toc(timein);
                disp(['calcu one point H take ',num2str(tt),' sec....']);
            end
        end
        tt = toc(timeFre);
        disp(['calcu H take ',num2str(tt),' sec....']);
        H4Dslice = H_z;
        H4Dslice(H4Dslice< (tol*max(H4Dslice(:))) ) = 0;% remove noise
        H_z = H4Dslice;

        disp(['normalize...NA_',num2str(NA)]);
        
        sss = H_z(:,:,(Nnum+1)/2,(Nnum+1)/2);
        for b2 = 1:length(x2objspace)
            for a2 = 1:length(x1objspace)
                H_z(:,:,a2,b2) = H_z(:,:,a2,b2)./sum(sss(:));
            end
        end

        %% determine the psf size
        IMGsize=size(H_z,1)-mod((size(H_z,1)-Nnum),2*Nnum);      
        sLF=zeros(IMGsize,IMGsize,Nnum,Nnum);
        index1=round(size(H_z,1)/2)-fix(size(sLF,1)/2);
        index2=round(size(H_z,1)/2)+fix(size(sLF,1)/2);
        
        for ii=1:size(H_z,3)
            for jj=1:size(H_z,4)
                sLF(:,:,ii,jj)=im_shift3(squeeze(H_z(index1:index2,index1:index2,ii,jj)),ii-((Nnum+1)/2), jj-(Nnum+1)/2);
            end
        end   

        bb=zeros(Nnum,Nnum,size(sLF,1)/size(H_z,3),size(sLF,2)/size(H_z,4),Nnum,Nnum);
        for i=1:size(H_z,3)
            for j=1:size(H_z,4)
                for a=1:size(sLF,1)/size(H_z,3)
                    for b=1:size(sLF,2)/size(H_z,4)
                        bb(i,j,a,b,:,:)=squeeze(sLF((a-1)*Nnum+i,(b-1)*Nnum+j,:,:));
                    end
                end
            end
        end
        WDF=zeros(size(sLF,1),size(sLF,2),Nnum,Nnum  );
        for a=1:size(sLF,1)/size(H_z,3)
            for c=1:Nnum
                x=Nnum*a+1-c;
                for b=1:size(sLF,2)/size(H_z,4)
                    for d=1:Nnum
                        y=Nnum*b+1-d;
                        WDF(x,y,:,:)=squeeze(bb(:,:,a,b,c,d));
                    end
                end
            end
        end

        psf_z=WDF;
%         save([savePath,'/psf_meta_',num2str(eachpt),'.mat'],'psf_z','-v7.3');
%         save([filepath,'/psf_layer_',num2str(eachpt),'.mat'],'psf_z','H_z','-v7.3');
        onetime = toc(aa);
        disp(['idz = ',num2str(eachpt),' take_time ',num2str(onetime),' sec......']);
        psf(:,:,:,:,eachpt) = psf_z;
        save([filepath,'/IdealLF_3Dpsf_M',num2str(M),'_NA',num2str(NA),'_zmin',num2str(zmin),'_zmax',num2str(zmax),'_zspacing',num2str(zspacing),'.mat'],'psf','-v7.3');

    end
end

% for u = 1: 15
%     for v = 1:15
%         if (u == 1 && v == 1)
%             imwrite(uint16(psf_z(:, :, u, v)*100), [filepath,'/psf_z_see.tif']);
%         else
%             imwrite(uint16(psf_z(:, :, u, v)*100), [filepath,'/psf_z_see.tif'],'Writemode', 'append');
%         end
%     end
% end


