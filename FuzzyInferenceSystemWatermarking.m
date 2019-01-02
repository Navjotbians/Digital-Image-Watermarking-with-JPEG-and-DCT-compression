clc;
clear all;
close all;
% save start time
start_time=cputime;

% read in the cover object
file_name1='tiger.bmp';

cover_object=imread(file_name1);
red_channel=cover_object(:,:,1);
green_channel=cover_object(:,:,2);
blue_channel=cover_object(:,:,3);
cover_object1=cover_object;
cover_object1=blue_channel;
cover_object=im2double(cover_object1);

% determine size (Height and Width) of cover image
Mc=size(cover_object,1);	      
Nc=size(cover_object,2);	        

blocksize=8; 

% determine maximum message size based on cover object, and blocksize
max_message=Mc*Nc/(blocksize^2);

% process the image in blocks
% DCT Compression also allows for significant data compression in case of
% image processing

x=1;
y=1;
sum_dc=0;
  for kk=1:max_message
       
        % transform block 
        image_block=dct2(cover_object(y:y+blocksize-1,x:x+blocksize-1));
        sum_dc=sum_dc + image_block(1,1);
    if (x+blocksize) >= Nc
        x=1;
        y=y+blocksize;
    else
        x=x+blocksize;
    end
        
        end
%claculate mean of all dc cofficients
mean_dc=sum_dc/max_message;

        % process the image in blocks

% Since Human Visual System is most sensitive to luminance , contrast and 
% brightness, as referred by many papers, we have taken only these components 
% from the RGB channel 

x=1;
y=1;
sum_dc=0;
  for kk=1:max_message
       
        % transform block 
        image_block=dct2(cover_object(y:y+blocksize-1,x:x+blocksize-1));
        % calculate luminance senstivity
        luminance(1,kk)=(image_block(1,1)/mean_dc)/2;     %------- range(0-2)
        % calculate average contrast
        te=statxture(image_block);
        average_contrast(1,kk)=te(2);
        % calculate threshold
        threshold(1,kk)=graythresh(image_block);        %-------range(0-1)
        % calculate normalized variance value
        variance(1,kk)=te(3);                            %------- range(0-1)
        % move on to next block. At and of row move to next row
        if (x+blocksize) >= Nc
            x=1;
            y=y+blocksize;
        else
            x=x+blocksize;
        end
        
  end
%FIS system for generating watermark invoked & 
%inputs given to it for each block 
dct_fuz=readfis('watermark');  
for kk=1:max_message
    w(1,kk)=evalfis([ luminance(1,kk) threshold(1,kk) variance(1,kk)],dct_fuz);
end

%Whole 256x256 image's dct taken
dct_cover=dct2(cover_object);
val=dct_cover(1,1);
dct_cover(1,1)=min(min(dct_cover)); %for 2d matrix 1st column wise then row 
watermark=randn(1,max_message);

%sort the DCT of cover image so as to obtain the low frequency components
[svals,idx] = sort(dct_cover(:),'descend'); % sort to vector
lvals=svals;
k=0.05;
%idx returns the corresponding indices of all unsorted elements
%useful in preserving the orignal location of all elements

%Take top kk DCT cofficients and spread the watermark (noise)
for i=1:max_message
    svals(i)=svals(i) + (k * watermark(1,i) * w(1,i));
end

% store position in matrix of top 500000 DCT cofficients
for i=1:max_message
[II,JJ] = ind2sub([Mc,Nc],idx(i)); % position in the matrix
row(i)=II;
col(i)=JJ;
end

% transform the sorted vector again into matrix form
for i=1:(Mc*Nc)
        [II,JJ] = ind2sub([Mc,Nc],idx(i));
        dct_watermark(II,JJ)=svals(i);
end


dct_watermark(1,1)=val;
%Take the inverse DCT
watermarked_image=idct2(dct_watermark);

% convert to uint8 and write the watermarked image out to a file
watermarked_image_int=im2uint8(watermarked_image);
imwrite(watermarked_image_int,'dct_fuzzy.bmp','bmp');

% display processing time
elapsed_time=cputime-start_time,

imshow(watermarked_image,[])

%for blue channel values,we use blue channel
i=blue_channel;
j=imread('dct_fuzzy.bmp');
psnr1(i,j);
dlmwrite('dct_fuzzywatermark.txt',watermark);
dlmwrite('dct_fuzzyrow.txt',row);
dlmwrite('dct_fuzzycol.txt',col);
