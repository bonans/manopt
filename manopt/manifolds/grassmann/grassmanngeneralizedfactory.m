function M = grassmanngeneralizedfactory(n, p, B)
% Returns a manifold struct of "scaled" vector subspaces.
%
% function M = grassmanngeneralizedfactory(n, p)
% function M = grassmanngeneralizedfactory(n, p, B)
%
% Generalized Grassmann manifold: each point on this manifold is a
% collection of "scaled" vector subspaces of dimension p embedded in R^n.
% The scaling is due to the symmetric positive definite matrix B.
%
% When B is identity, the manifold is the standard Grassmann manifold.
%
% The metric is obtained by making the generalized Grassmannian
% a Riemannian quotient manifold of the generalized Stiefel manifold, i.e.,
% the manifold of "sclaed" orthonormal matrices. Specifically, the scaled
% Stiefel manifold is the set {X : X'*B*X = I}. The genearlized Grassmann
% manifold is the Grassmannian of the generalized Stiefel manifold.
%
% The generalized Stiefel manifold is endowed with a scaled metric
% by making it a Riemannian submanifold of the Euclidean space,
% again endowed with the scaled inner product.
%
% Some notions (not all) are from Section 4.5 of the paper
% "The geometry of algorithms with orthogonality constraints",
% A. Edelman, T. A. Arias, S. T. Smith, SIMAX, 1998.
%
% Paper link: http://arxiv.org/abs/physics/9806030.
%
% See also: stiefelgeneralizedfactory  stiefelfactory  grassmannfactory


% This file is part of Manopt: www.manopt.org.
% Original author: Bamdev Mishra, June 30, 2015.
% Contributors:
%
% Change log:
%   
    
    assert(n >= p, ...
        ['The dimension n of the ambient space must be larger ' ...
        'than the dimension p of the subspaces.']);
    
    if ~exist('B', 'var') || isempty(B)
        B = speye(n); % Standard Grassmann manifold.
    end
    
    
    M.name = @() sprintf('Generalized Grassmann manifold Gr(%d, %d)', n, p);
    
    
    M.dim = @() p*(n - p); % BM: to verify.
    
    
    M.inner = @(X, eta, zeta) trace(eta'*(B*zeta)); % Scaled metric, but horizontally invaraiant.
    
    M.norm = @(X, eta) sqrt(M.inner(X, eta, eta));
    
    M.dist = @distance; % BM: to verify.
    function d = distance(X, Y)
        XtBY = X'*(B*Y); % XtY ---> XtBY
        cos_princ_angle = svd(XtBY); % svd(XtY) ---> svd(XtBY)
        % Two next instructions not necessary: the imaginary parts that
        % would appear if the cosines are not between -1 and 1, when
        % passed to the acos function, would be very small, and would
        % thus vanish when the norm is taken.
        % cos_princ_angle = min(cos_princ_angle,  1);
        % cos_princ_angle = max(cos_princ_angle, -1);
        square_d = norm(acos(cos_princ_angle))^2;
        
        d = sqrt(square_d);
    end
    
    M.typicaldist = @() sqrt(p);
    
    
    % Orthogonal projection of an ambient vector U to the horizontal space
    % at X.
    M.proj = @projection;
    function Up = projection(X, U)
        BX = B*X;
        
        % Projection onto the tangent space
        % U = U - X*symm(BX'*U);
        % Projection onto the horizontal space
        % Up = U - X*skew(BX'*U);
        
        Up = U - X*(BX'*U);
    end
    
    M.tangent = M.proj;
    
    M.egrad2rgrad = @egrad2rgrad;
    function rgrad = egrad2rgrad(X, egrad)
        
        % First, scale egrad according the to the scaled metric in the
        % Euclidean space.
        egrad_scaled = B\egrad;
        
        % Second, project onto the tangent space.
        % No need to project onto the horizontal space as
        % by the Riemannian submersion theory, this quantity also belongs
        % to the horizontal space.
        %
        %
        % rgrad = egrad_scaled - X*symm((B*X)'*egrad_scaled);
        %
        % Verify that symm(BX'*egrad_scaled) = symm(X'*egrad).
        
        rgrad = egrad_scaled - X*symm(X'*egrad);
    end
    
    
    M.ehess2rhess = @ehess2rhess;
    function rhess = ehess2rhess(X, egrad, ehess, H)
        egraddot = ehess;
        Xdot = H;
        
        % Directional derivative of the Riemannian gradient.
        egrad_scaleddot = B\egraddot;
        rgraddot = egrad_scaleddot - Xdot*symm(X'*egrad)...
            - X*symm(Xdot'*egrad)...
            - X*symm(X'*egraddot);
        
        % Project onto the horizontal space.
        rhess = M.proj(X, rgraddot);
    end
    
    
    
    M.retr = @retraction;
    function Y = retraction(X, U, t)
        if nargin < 3
            t = 1.0;
        end
        Y = guf(X + t*U); % Ensure that Y'*B*Y is identity.
    end
    
    
    
    M.exp = @exponential;
    function Y = exponential(X, U, t)
        if nargin == 3
            tU = t*U;
        else
            tU = U;
        end
        
        % restricted_svd is defined later in the file.
        [u, s, v] = restricted_svd(tU);% svd(tU, 0) ---> restricted_svd(tU).
        cos_s = diag(cos(diag(s)));
        sin_s = diag(sin(diag(s)));
        Y = X*v*cos_s*v' + u*sin_s*v';% Verify that Y'*B*Y is identity
        
        % From numerical experiments, it seems necessary to
        % re-orthonormalize. This is overall quite expensive.
        Y = guf(Y);% Ensure that Y'*B*Y is identity.
    end
    
    
    
    
    
    % Test code for the logarithm:
    % gGr = grassmanngeneralizedfactory(5, 2, diag(rand(5,1)));
    % x = gGr.rand()
    % y = gGr.rand()
    % u = gGr.log(x, y)
    % gGr.dist(x, y) % These two numbers should
    % gGr.norm(x, u) % be the same.
    % z = gGr.exp(x, u) % z needs not be the same matrix as y, but it should
    % v = gGr.log(x, z) % be the same point as y on Grassmann: dist almost 0.
    % gGr.dist(z,y)
    M.log = @logarithm;
    function U = logarithm(X, Y)
        YtBX = Y'*(B*X); % YtX ---> YtBX.
        At = (Y' - YtBX*X');
        Bt = YtBX\At;
        [u, s, v] = restricted_svd(Bt');% svd(Bt', 'econ') ---> restricted_svd(Bt').
        
        u = u(:, 1:p);
        s = diag(s);
        s = s(1:p);
        v = v(:, 1:p);
        U = u*diag(atan(s))*v'; % A horizontal vector, i.e., U'*(B*X) is zero.
    end
    
    
    M.hash = @(X) ['z' hashmd5(X(:))];
    
    M.rand = @random;
    function X = random()
        X = guf(randn(n, p)); % Ensure that X'*B*X is identity;
    end
    
    M.randvec = @randomvec;
    function U = randomvec(X)
        U = projection(X, randn(n, p));
        U = U / norm(U(:));
    end
    
    M.lincomb = @lincomb;
    
    M.zerovec = @(X) zeros(n, p);
    
    % This transport is compatible with the generalized polar retraction.
    M.transp = @(X1, X2, d) projection(X2, d);
    
    M.vec = @(X, u_mat) u_mat(:);
    M.mat = @(X, u_vec) reshape(u_vec, [n, p]);
    M.vecmatareisometries = @() false;
    
    
    % Some auxiliary functions
    symm = @(D) (D + D')/2;
    
    function X = guf(D)
        % Generalized uf polar decomposition.
        % X'*B*X is identity.
        
        % This file is part of Manopt: www.manopt.org.
        % Original author: Bamdev Mishra, June 30, 2015.
        % Contributors:
        % Change log:
        
        [u, ~, v] = svd(D, 0);
        X = u*(sqrtm(u'*(B*u))\(v')); % X'*B*X is identity.
    end
    
    function[u s v] = restricted_svd(Y)
        % We compute thin svd usv' of Y such that
        % u'*B*u is identity.
        
        % This file is part of Manopt: www.manopt.org.
        % Original author: Bamdev Mishra, June 30, 2015.
        % Contributors:
        % Change log:
        
        
        [v, ssquare] = eig(Y'*(B*Y));
        ssquarevec = diag(ssquare);
        
        s = diag(abs(sqrt(ssquarevec)));
        u = Y*(v/s);
    end
end

% Linear combination of tangent vectors
function d = lincomb(x, a1, d1, a2, d2) %#ok<INUSL>
    
    if nargin == 3
        d = a1*d1;
    elseif nargin == 5
        d = a1*d1 + a2*d2;
    else
        error('Bad use of grassmanngeneralizedfactory.lincomb.');
    end
    
end
