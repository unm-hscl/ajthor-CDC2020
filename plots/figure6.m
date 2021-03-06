%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure6.m
%
% This figure shows the results of the KernelDistributionEmbeddings 
% algorithm. Specifically, for the planar quadcopter system with affine
% disturbance and stationary policy. The the results are shown for 
% gaussian and beta disturbances. 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We start by defining the problem. This means specifying the time horizon, the
% constraint set, or "safe set", and the target set.
clc, clear, close all
% We define the time horizon as N=5.
N = 5;

safe_set_x = [-1 1]';
K = @(x) prod(double(x(3:6:end, :) >= 0 & ...
                  x(1:6:end, :) >= safe_set_x(1:2:end)& ...
                  x(1:6:end, :) <= safe_set_x(2:2:end)&...
                  x(3:6:end, :) < 0.8),1);
target_set_x = [-1 1]';
T = @(x) prod(double(x(3:6:end, :) >= 0.8& ...
                  x(1:6:end, :) >= target_set_x(1:2:end)& ...
                  x(1:6:end, :) <= target_set_x(2:2:end)),1);

args = {'TimeHorizon', N, 'ConstraintSet', K, 'TargetSet', T};
problem = FirstHittingTimeProblem(args{:});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate the samples of the system via simulation.

Ts = 0.25;
X_d = [0 0 1 0 0 0]';
Xmin = -1.1;
Xmax = 1.1;
dXmin = 0;
dXmax = -0.1;
Ymin = -0.1;
Ymax = 1;
dYmin = -0.1;
dYmax = 0.1;
Tmin = -pi;
Tmax = pi;
dTmin = -0.1;
dTmax = 0.1;
el = [10, 3, 10, 3, 3, 2];
Umin = -1;
Umax = 1;
dtype = 1;

X = linspace(Xmin, Xmax, el(1));
dX = linspace(dXmin, dXmax, el(2));
Y = linspace(Ymin, Ymax, el(3));
dY = linspace(dYmin, dYmax, el(4));
T = linspace(Tmin, Tmax, el(5));
dT = linspace(dTmin, dTmax, el(6));

[dTdT, TT, dYdY, YY, dXdX, XX] = ndgrid(dT, T, dY, Y, dX, X);

X = reshape(XX, 1, []);
dX = reshape(dXdX, 1, []);
Y = reshape(YY, 1, []);
dY = reshape(dYdY, 1, []);
T = reshape(TT, 1, []);
dT = reshape(dTdT, 1, []);

Xs = [X; dX; Y; dY; T; dT];
for k = 1:size(Xs,2)
    Us(:,k) = quadInputGen(60,Ts,Xs(:,k),X_d);
end
% load('quadSamples.mat')
Us2 = 0.01*Us(1:2,:);
Ys = generate_output_samples_quad(Xs,Us2,Ts,1);

args1 = {[6 1], 'X', Xs, 'U', Us2, 'Y', Ys};
samplesWithGaussianDisturbance = SystemSamples(args1{:});

Ys = generate_output_samples_quad(Xs,Us2,Ts,2);

args2 = {[6 1], 'X', Xs, 'U', Us2, 'Y', Ys};
samplesWithBetaDisturbance = SystemSamples(args2{:});

% Generate test points.
% s = linspace(-1, 1, 100);
% [X1, X2] = meshgrid(s);
x = linspace(-1.1, 1.1, 100);
y = linspace(0, 1, 100);
z = zeros(1, 100^2);
[xx, yy] = meshgrid(x, y);
xx = reshape(xx, 1, []);
yy = reshape(yy, 1, []);
Xtest = [xx; z; yy; z; z; z];
Utest = zeros(2,size(Xtest,2));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define the algorithm.
args = {'Sigma', 0.1, 'Lambda', 1};
algorithm = KernelDistributionEmbeddings(args{:});

% Compute the safety probabilities.
args = {problem, samplesWithGaussianDisturbance, Xtest, Utest};

PrGauss = algorithm.ComputeSafetyProbabilities(args{:});


% % Compute the safety probabilities.
args = {problem, samplesWithBetaDisturbance, Xtest, Utest};
tic
PrBeta = algorithm.ComputeSafetyProbabilities(args{:});
toc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plot the results.
width = 80;
height = 137;

figure('Units', 'points', ...
       'Position', [0, 0, 243, 172])

ax1 = subplot(1, 2, 1, 'Units', 'points');
surf(ax1, x, y, reshape(PrGauss(1, :), 100, 100), 'EdgeColor', 'none');
view([0 90]);
axis([-1.1 1.1 0.5 1])

colorbar(ax1, 'off');
ax1.Position = [30, 25, width, 137];
ax1.XLabel.Interpreter = 'latex';
ax1.XLabel.String = '$z_{1}$';
ax1.YLabel.Interpreter = 'latex';
ax1.YLabel.String = '$z_{2}$';
set(ax1, 'FontSize', 8);

ax2 = subplot(1, 2, 2, 'Units', 'points');
surf(ax2, x, y, reshape(PrBeta(1, :), 100, 100), 'EdgeColor', 'none');
view([0 90]);
axis([-1.1 1.1 0.5 1])

colorbar(ax2);
ax2.YAxis.Visible = 'off';
ax2.Position = [30 + 90, 25, width, 137];
ax2.XLabel.Interpreter = 'latex';
ax2.XLabel.String = '$z_{1}$';
ax2.YLabel.Interpreter = 'latex';
ax2.YLabel.String = '$z_{2}$';
set(ax2, 'FontSize', 8);
