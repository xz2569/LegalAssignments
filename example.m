%% ASSUMED: Complete preference list!!!!

%% Set up the instance
% instance size and quota
nstudent = 10;
nschool = 5;
qs = [2,2,2,2,2];
% Preference List
[studentList, schoolList] = randPreferenceList(nstudent, nschool);
% Rank List
[studentRank, schoolRank] = preferenceList2rankList(studentList, schoolList);

%% Student Optimal Stable Assignment via GS [Gale-Shapley]
[StuOSA_student, StuOSA_school_bool, StuOSA_school_last] = GS(nstudent, ...
    nschool, qs, studentList, schoolList, schoolRank);

%% School (Student) Optimal Legal Assignment by (reverse) rotate-and-remove
[SchOLA_student, le1] = RAR(nstudent, nschool, studentList, schoolList, ...
    studentRank, schoolRank, StuOSA_student, StuOSA_school_bool, StuOSA_school_last);

[StuOLA_student, le2] = RRAR(nstudent, nschool, studentList, schoolList, ...
    studentRank, StuOSA_student, StuOSA_school_last);

%% Legal Edges in Subinstance
legalEdges = le1 | le2;

%% Set up the legalized subinstance
LstudentList = zeros(nstudent, nschool);
LschoolList = zeros(nschool, nstudent);
for i = 1:nstudent
    for j = 1:nschool
        if legalEdges(i, studentList(i,j))
            LstudentList(i,j) = studentList(i,j);
        end
        if legalEdges(schoolList(j, i), j)
            LschoolList(j,i) = schoolList(j,i);
        end
    end
end

%% CODE BELOW NOT EFFICIENT, Just For Visualization Though
%% Plot the lattice and print list of legal assignments
plot_lattice;