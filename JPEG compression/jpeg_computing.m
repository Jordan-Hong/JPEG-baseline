function [ output_image, compressed_vector, ratio ] = jpeg_computing( input_image, q)
% input_image is an image [colored] matrix
% q is a quality (from 1 to 100 percent), 100 - the best quality and low
% compression, too little values (less than 10) are not guaranteed to work
% output_image is a compressed image [colored] matrix
% compressed_vector is an output binary vector representing the compressed
% image
% ratio is a compression ratio (the more ratio the more data are compressed)
%---------------------------
% define init values
n = 8; % size of blocks
dim1 = size(input_image,1); % image width
dim2 = size(input_image,2); % image height
dim3 = size(input_image,3); % number of channels


ycbcrmap = rgb2ycbcr(im2double(input_image)); % mapping, need double for DCT

% here you can (should) also paste downsampling of chroma components
output_image = zeros(size(input_image), 'double');
compressed_vector = 0;
scale = 255; % need because DCT values of YCbCr are too small to be quantized
% Block processing functions
dct = @(block_struct) T * block_struct.data * T';
T = dctmtx(n); % DCT matrix
% Quantization
% 量化公式參考: 講義Lec7.part2.page 55
[qY, qC] = get_quantization(q); % get quantization matrices with respect to Luminance and Chrominance
quantY = @(block_struct) floor( (block_struct.data./qY)+0.5);
quantC = @(block_struct) floor((block_struct.data./qC)+0.5);
zigzag_out = @(block_struct) zigzag_scan(block_struct.data); % Zigzag scanning for each blocks
% Dequantization & Inverse DCT 
dequantY = @(block_struct) block_struct.data.*qY;
dequantC = @(block_struct) block_struct.data.*qC;
invdct = @(block_struct) T' * block_struct.data * T;
%---------------------------
for ch=1:3 % 分通道完成編碼解碼
    % encoding ---------------------------
    % 4:2:0 subsampling
    if(ch==1)
        channel = ycbcrmap(:,:,ch); % get channel
    else
        chroma = ycbcrmap(:,:,ch); 
        channel = chroma(1:2:end, 1:2:end);
    end
    % compute scaled forward DCT
    channel_dct = blockproc(channel, [n n], dct, 'PadPartialBlocks', true).*scale; 
    % quantization
    if (ch == 1)
        channel_q = blockproc(channel_dct,[n n], quantY);  % quantization for luma
    else
        channel_q = blockproc(channel_dct,[n n], quantC);  % quantization for colors
    end
    channel_zq = blockproc(channel_q,[n n], zigzag_out); % compute entropy code with zigzag scanning for the whole channel
    [comp, dict] = huffman_cod(channel_zq); % huffman encoding % comp = code
    compressed_vector = cat(1, compressed_vector, comp); % add to output    
    % decoding ---------------------------
    [d1,d2] = size(channel);
    decoded_matrix = reshape(huffmandeco(comp, dict), [d1,d2]); % huffman decoding (takes a long time)
    % dequantization
    if (ch == 1)
        channel_dq = blockproc(decoded_matrix,[n n], dequantY);
    else
        channel_dq = blockproc(decoded_matrix,[n n], dequantC);  
    end
    output_data = blockproc(channel_dq./scale,[n n],invdct); % inverse DCT, scale back

    % Chroma upsampling (4:2:0)
    if(ch>1)
        output_data = imresize(output_data, 2, 'nearest'); % 使用最近鄰插值進行上採樣
    end
    output_image(:,:,ch) = output_data(1:dim1, 1:dim2); % set output
end
%---------------------------
compressed_vector = compressed_vector(2:length(compressed_vector)); % remove first symbol
output_image = im2uint8(ycbcr2rgb(output_image)); % back to rgb uint8

% compute compression ratio
% compressed_vector is binary, input image has one byte per pixel
ratio = dim1 * dim2 * dim3 / (length(compressed_vector) /8); % size of huffman dicitonary  is missed
end

