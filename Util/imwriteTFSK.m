function [] = imwriteTFSK(Volume,name)
%imwriteTFSK 写入3D-tiff文件（支持single/double)
%    imwriteTFSK(volume,name)
t = Tiff(name,'w'); % Filename by variable name
tagstruct.ImageLength       = size(Volume,1);
tagstruct.ImageWidth        = size(Volume,2);
tagstruct.Photometric       = Tiff.Photometric.MinIsBlack;

a = 'single';
b = 'double';
c = 'uint8';
d = 'uint16';

if  strcmp(a,class(Volume))==1
    tagstruct.BitsPerSample	= 32;
    tagstruct.SampleFormat	= Tiff.SampleFormat.IEEEFP;
elseif strcmp(b,class(Volume))==1
    warning('ImageJ may not support double/64-bit tiff!');
    tagstruct.BitsPerSample	= 64;
    tagstruct.SampleFormat	= Tiff.SampleFormat.IEEEFP;
elseif strcmp(c,class(Volume))==1
    tagstruct.BitsPerSample	= 8;
    tagstruct.SampleFormat	= Tiff.SampleFormat.UInt;
elseif strcmp(d,class(Volume))==1
    tagstruct.BitsPerSample	= 16;
    tagstruct.SampleFormat	= Tiff.SampleFormat.UInt;
end



% if(class(Volume) == 'single')
%     tagstruct.BitsPerSample	= 32;
%     tagstruct.SampleFormat	= Tiff.SampleFormat.IEEEFP;
% elseif(class(Volume) == 'double')
%     warning('ImageJ may not support double/64-bit tiff!');
%     tagstruct.BitsPerSample	= 64;
%     tagstruct.SampleFormat	= Tiff.SampleFormat.IEEEFP;
% elseif(class(Volume) == 'uint8')
%     tagstruct.BitsPerSample	= 8;
%     tagstruct.SampleFormat	= Tiff.SampleFormat.UInt;
% elseif(class(Volume) == 'uint16')
%     tagstruct.BitsPerSample	= 16;
%     tagstruct.SampleFormat	= Tiff.SampleFormat.UInt;
% end
tagstruct.SamplesPerPixel	= 1;
tagstruct.RowsPerStrip      = 16;
tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
tagstruct.Software          = 'MATLAB';
setTag(t,tagstruct)

write(t,squeeze(Volume(:,:,1)));
for i=2:size(Volume,3) % Write image data to the file
    writeDirectory(t);
    setTag(t,tagstruct)
    write(t,squeeze(Volume(:,:,i))); % Append
end
close(t);
end

