function [ comp, dict ] = huffman_cod(input_matrix)
% function computing huffman codes
% input_matrix is a m, n matrix
% comp is huffman codes, dict is a dictionary (for encoding)
input_vector = input_matrix(:); %將掃描完的矩陣攤平再取unique得到symbols
symbols = unique(input_vector);
L = length(symbols);    
m = size(input_matrix, 1);
n = size(input_matrix, 2);
hist_counts = zeros(size(symbols));
probs = zeros(size(symbols));
symbols = reshape(symbols, 1, L);
if length(symbols) < 2
    comp = 0;
    dict = [0 1];
    return;
end
for i = 1:numel(symbols)
    hist_counts(i) = sum(input_matrix(:) == symbols(i)); % 計算每個symbol出現總次數
    probs(i) = hist_counts(i)/(m*n); % 根據總次數求出出現機率
end
% 使用內建函式得到字典(dict)與編碼(comp)
dict = huffmandict(symbols, probs); 
comp = huffmanenco(input_matrix(:),dict); 
end