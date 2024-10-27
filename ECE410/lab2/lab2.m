clear
clc
lambda2 = 10.5;
lambda1 = 1.7265;
M = 0.8211;
A = [0,1;0,-lambda2/M];
B = [0;lambda1/M];
C = [1,0];

[K1,K2] = state_feedback_design(A,B,[-2;-2]);
eig(A + B*[K1,K2]);

[L1,L2]=observer_design(A,[-10;-10]);
eig(A-[L1;L2]*C);

[Actrl,Bctrl,Cctrl,Dctrl] = output_feedback_controller(A,B,C,[-2;-2],[-10;-10])

function [Actrl,Bctrl,Cctrl,Dctrl]=output_feedback_controller(A,B,C,p_feedback,p_observer)
[K1,K2] = state_feedback_design(A,B,p_feedback);
[L1,L2] = observer_design(A,p_observer);
Actrl = A + B*[K1,K2]-[L1;L2]*C;
Bctrl = [[L1;L2],-B*[K1,K2]];
Cctrl = [K1,K2];
Dctrl = [0,-K1,-K2];
end

function [K1,K2] = state_feedback_design(A,B,p)
K1 = -p(1,1)*p(2,1)/B(2,1);
K2 = (-A(2,2)+p(1,1)+p(2,1))/B(2,1);
end

function [L1,L2] = observer_design(A,p)
L1 = A(2,2)-(p(1,1)+p(2,1));
L2 = L1*A(2,2)+p(1,1)*p(2,1);
end