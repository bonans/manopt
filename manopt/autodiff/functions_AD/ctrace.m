function traceA = ctrace(A)
% Computes the sum of diagonal elements of A.
%
% function traceA = ctrace(A)
%
% Returns the sum of diagonal elements of A. The input A does not
% necessarily to be a square matrix. The function supports both numeric 
% arrays and structs with fields real and imag. Note that trace currently
% does not support dlarrays and ctrace can be seen as a backup function.
%
% See also: manoptAD

% This file is part of Manopt: www.manopt.org.
% Original author: Xiaowen Jiang, July. 31, 2021.
% Contributors: Nicolas Boumal
% Change log:

    if isstruct(A) && isfield(A,'real')
        assert(length(size(A.real))==2,'Input should be a 2-D array')
        m = size(A.real,1);
        n = size(A.real,2);
        realA = A.real;
        imagA = A.imag;
        
        if n >= m
            traceA.real = sum(realA(1:m+1:m^2));
            traceA.imag = sum(imagA(1:m+1:m^2));
        else
            traceA.real = sum(realA(1:m+1:m*n-m+n));
            traceA.imag = sum(imagA(1:m+1:m*n-m+n));
        end
        
    elseif isnumeric(A)
        assert(length(size(A))==2,'Input should be a 2-D array')
        m = size(A,1);
        n = size(A,2);
        if n >= m
            traceA = sum(A(1:m+1:m^2));
        else
            traceA = sum(A(1:m+1:m*n-m+n));
        end

    else
        ME = MException('ctrace:inputError', ...
        'Input does not have the expected format.');
        throw(ME);
    end

end