%Define Physical Parameters
M=1.1911;
m=0.23;
l=0.3302;
g=9.8;
alpha1=1.8;
alpha2=10.9;

%Declare Symbolic Real Variables
syms z z_dot theta theta_dot u real
syms z_ddot theta_ddot real  % Second derivatives

% Assign values to z_ddot and theta_ddot based on the equations
z_ddot = ((-m*l)*sin(theta)*theta_dot^2 + m*g*sin(theta)*cos(theta) + alpha1*u - alpha2*z_dot) / (M +m*sin(theta)^2);
theta_ddot = ((-m*l)*sin(theta)*cos(theta)*theta_dot^2 + (M+m)*g*sin(theta) + (alpha1*u - alpha2*z_dot)*cos(theta)) / (l*(M+m*(sin(theta)^2)));

% Define state vector x
x = [z; z_dot; theta; theta_dot];

% Define state derivative vector f, representing f(x, u)
f = [z_dot; z_ddot; theta_dot; theta_ddot];
%% 
% Linearize System at Equilibrium 
matlabFunction(eval(f),'Vars',{x,u},'File','cartpend','Outputs',{'xdot'});
%testing
cartpend([0 0 pi/2 0]',1)
% Equilibrium state and control
x_bar = [0; 0; 0; 0];
u_bar = 0;

% Compute Jacobian of f with respect to x and evaluate at equilibrium
A = subs(jacobian(f, x), [x; u], [x_bar; u_bar]);

% Compute Jacobian of f with respect to u and evaluate at equilibrium
B = subs(jacobian(f, u), [x; u], [x_bar; u_bar]);

% Convert A and B to numeric matrices
A = double(A);
B = double(B);

% Calculate the controllability matrix
Co = ctrb(A, B);
% Check the rank of the controllability matrix
rank_Co = rank(Co);
% Determine controllability
if rank_Co == size(A, 1)
    disp('The system is controllable.');
else
    disp('The system is not controllable.');
end

%% 
% Check Observability

C = [1 0 0 0; 0 0 1 0];
% Compute the observability matrix
O = obsv(A, C);

% Check the rank of the observability matrix
rank_O = rank(O);

% Determine observability
n = size(A, 1); % Number of states
if rank_O == n
    disp('The system is observable.');
else
    disp('The system is not observable.');
end
%%
% Define simulation parameters
Ulim = 5.875;
x0=[0; 0; pi/24; 0];
zeros = [0;0;0];

%% 
% Design gain K
% Desired eigenvalues for A + BK
desired_eigenvalues = [-5.001, -5.002, -5.003, -5]; % 4 eigenvalues at approximately -5
K_ctrl = design_Kgain(A, B, desired_eigenvalues);
K_sfs = K_ctrl;

%% 
% Design gain L
% Desired eigenvalues for A - LC
desired_eigenvalues = [-10.001, -10.002, -10.003, -10]; % Desired locations of eigenvalues
L_ctrl = design_Lgain(A, C, desired_eigenvalues);

%% 
% A B C D ctrl
Actrl = A + B*K_ctrl-L_ctrl*C;
Bctrl = [L_ctrl,-B*K_ctrl];
Cctrl = K_ctrl;
Dctrl = [0,0,-K_ctrl];

% % Run simulation
% out = sim('lab4_prep.slx', 30);
% figure(1)
% subplot(311)
% title('Trial 1: Comparison of the controllers')
% subtitle('Preparation')
% ylabel('z')
% legend('z_sfs' , 'z_ofs', 'zd')
% hold on
% plot(out.z)
% subplot(312)
% ylabel('theta')
% legend('theta_sfs', 'theta_ofs')
% hold on
% plot(out.theta)
% subplot(313)
% ylabel('u')
% hold on
% plot(out.u)
% legend('u_sfs' , 'u_ofs')
% hold off

%% 
% Design gain L
% Desired eigenvalues for A - LC
desired_eigenvalues = [-40.001, -40.002, -40.003, -40]; %Desired locations of eigenvalues
L_ctrl = design_Lgain(A, C, desired_eigenvalues);

%% 
% A B C D ctrl
Actrl = A + B*K_ctrl-L_ctrl*C;
Bctrl = [L_ctrl,-B*K_ctrl];
Cctrl = K_ctrl;
Dctrl = [0,0,-K_ctrl];

% % Run simulation
% out = sim('lab4_prep.slx', 30);
% figure(2)
% subplot(311)
% title('Trial 2: Comparison of the controllers')
% subtitle('Preparation')
% ylabel('z')
% legend('z_sfs' , 'z_ofs', 'zd')
% hold on
% plot(out.z)
% subplot(312)
% ylabel('theta')
% legend('theta_sfs', 'theta_ofs')
% hold on
% plot(out.theta)
% subplot(313)
% ylabel('u')
% hold on
% plot(out.u)
% legend('u_sfs' , 'u_ofs')
% hold off

%% Trial 3
% % Method 1: Evalue assignment
% desired_eigenvalues = [-8.001, -8.002, -8.003, -8]; % 4 eigenvalues at approximately -5
% K_ctrl = design_Kgain(A, B, desired_eigenvalues);
% K_sfs = K_ctrl;
% % 

%Method 2: LQR
% Define Q and R matrices for KLQR1
q1 = 2000; q2 = 0.5; R1 = 1;
Q1 = diag([q1, 0, q2, 0])  % Adjust Q based on system size if necessary
K_LQR1 = -lqr(A, B, Q1, R1);

A_plus_BK_LQR1 = A + B * K_LQR1;
eigenvalues_LQR1 = eig(A_plus_BK_LQR1);
% Display results for KLQR1
disp(K_LQR1);
disp(eigenvalues_LQR1);
K_ctrl=K_LQR1;
K_sfs = K_ctrl;

%% 
% A B C D ctrl

Actrl = A + B*K_ctrl-L_ctrl*C;
Bctrl = [L_ctrl,-B*K_ctrl];
Cctrl = K_ctrl;
Dctrl = [0,0,-K_ctrl];
% Run simulation
out = sim('lab4_prep.slx', 30);
figure(3)
subplot(311)
title('Trial 3: Comparison of the controllers')
subtitle('Preparation')
ylabel('z')
legend('z_sfs' , 'z_ofs', 'zd')
hold on
plot(out.z)
subplot(312)
ylabel('theta')
legend('theta_sfs', 'theta_ofs')
hold on
plot(out.theta)
subplot(313)
ylabel('u')
hold on
plot(out.u)
legend('u_sfs' , 'u_ofs')
hold off

%%Output Feedback Control with Integral Action
C_1 = [1 0 0 0]
Zero_4x1 = [0; 0; 0; 0];

temp1 = [A Zero_4x1];
temp2 = [-C_1 0];
A_bar = [temp1; temp2]

B_bar = [B; 0]

% Calculate the controllability matrix
Co = ctrb(A_bar, B_bar);
% Check the rank of the controllability matrix
rank_Co = rank(Co);
% Determine controllability
if rank_Co == size(A_bar, 1)
    disp('The system (Abar Bbar) is controllable.');
else
    disp('The system is not controllable.');
end

% Define Q and R matrices for KLQR1
q1 = 1; q3 = 0.1; q5 = 1; R = 0.01;
Q = diag([q1, 0, q3, 0, q5])  % Adjust Q based on system size if necessary
K_bar = -lqr(A_bar, B_bar, Q, R)

% Check Eigenvalue
eigenvalues = eig(A_bar+B_bar*K_bar)
% 
% disp("Enter to Arduino:")
% matrixToCommaSeparated(Actrl, 'Actrl');
% matrixToCommaSeparated(Bctrl, 'Bctrl');
% matrixToCommaSeparated(Cctrl, 'Cctrl');
% matrixToCommaSeparated(Dctrl, 'Dctrl');

function matrixToCommaSeparated(matrix, matrixName)
    % Display the name of the matrix
    disp(matrixName);
    
    % Get the size of the matrix
    [rows, cols] = size(matrix);
    
    % Loop through each element and print in the required format
    for i = 1:rows
        for j = 1:cols
            fprintf('%d', matrix(i, j)); % Print each element
            if j < cols
                fprintf(', '); % Add comma after each element except the last one in the row
            end
        end
        fprintf(',\n'); % Add a comma and newline at the end of each row
    end
    fprintf('\n'); % Add a blank line for separation
end

function K_ctrl = design_Kgain(A, B, desired_eigenvalues)
    % design_gain - Compute the gain matrix K for state feedback control
    % such that the eigenvalues of A + BK match the desired eigenvalues.
    %
    % Inputs:
    %   A - State matrix
    %   B - Input matrix
    %   desired_eigenvalues - Vector of desired eigenvalues for A + BK
    %
    % Output:
    %   K_ctrl - Gain matrix for A + BK
    
    % Compute K using the place command for A - BK
    K_ctrl = -place(A, B, desired_eigenvalues);

    % Display the resulting gain matrix
    disp('Gain matrix K_ctrl:');
    disp(K_ctrl);

    % Verify and display the eigenvalues of A + BK
    A_plus_BK = A + B * K_ctrl;
    eigenvalues = eig(A_plus_BK);
    disp('Eigenvalues of A + BK:');
    disp(eigenvalues);
end

function L_ctrl = design_Lgain(A, C, desired_eigenvalues)
    % design_observer_gain - Compute the observer gain matrix L
    % such that the eigenvalues of A - LC match the desired eigenvalues.
    %
    % Inputs:
    %   A - State matrix
    %   C - Output matrix
    %   desired_eigenvalues - Vector of desired eigenvalues for A - LC
    %
    % Output:
    %   L_ctrl - Observer gain matrix for A - LC

    % Compute K using the place command with transposed matrices
    K = place(A', C', desired_eigenvalues);

    % Transpose K to get the observer gain L
    L_ctrl = K';

    % Display the observer gain matrix
    disp('Observer gain L for A - LC:');
    disp(L_ctrl);

    % Verify and display the eigenvalues of A - LC
    A_minus_LC = A - L_ctrl * C;
    eigenvalues = eig(A_minus_LC);
    disp('Eigenvalues of A - LC:');
    disp(eigenvalues);
end
