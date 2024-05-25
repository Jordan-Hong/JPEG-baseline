clc;
input_image = imread('test.png');
quality = 90;
[ output_image, compressed_vector, ratio ] = jpeg_computing(input_image, quality);

subplot(1,2,1), imshow(input_image) , title('Input Image')% show results
subplot(1,2,2), imshow(output_image), title('Output Image, Q = 90') % show results
imwrite(output_image, 'Earth_Compressed_Q90.jpeg', 'Quality', 90); % Save as JPEG with quality factor 90


