function Xtriu = ctril(X,k)
% Extracts the lower triangular part of X.
%
% function Xtriu = ctril(X,k)
%
% This function can be seen as tril(X,k) but is compatible with dlarrays
% and structs with fields real and imag.
%
% See also: manoptAD

% This file is part of Manopt: www.manopt.org.
% Original author: Xiaowen Jiang, Aug. 31, 2021.
% Contributors: Nicolas Boumal
% Change log:

    switch nargin
        case 1
            if isstruct(X) && isfield(X,'real')
                index0 = find(tril(ones(size(X.real)))==0);
                Xtriu = X;
                Xtriu.real(index0) = 0;
                Xtriu.imag(index0) = 0;
        
            elseif isnumeric(X) && ~isdlarray(X)
                Xtriu = tril(X);
            
            elseif isdlarray(X)
                Xtriu = dlarray(zeros(size(X)));
                index1 = find(tril(ones(size(X)))==1);
                Xtriu(index1) = X(index1);
                
            else
                ME = MException('ctriu:inputError', ...
                'Input does not have the expected format.');
                throw(ME);
            end
        case 2
            if isstruct(X) && isfield(X,'real')
                index0 = find(tril(ones(size(X.real)),k)==0);
                Xtriu = X;
                Xtriu.real(index0) = 0;
                Xtriu.imag(index0) = 0;
        
            elseif isnumeric(X) && ~isdlarray(X)
                Xtriu = tril(X,k);
            
            elseif isdlarray(X)
                Xtriu = dlarray(zeros(size(X)));
                index1 = find(tril(ones(size(X)),k)==1);
                Xtriu(index1) = X(index1);
                
            else
                ME = MException('ctril:inputError', ...
                'Input does not have the expected format.');
                throw(ME);
            end
    otherwise
        error('Too many input arguments.');
    end
end

