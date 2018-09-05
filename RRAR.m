function [StuOLA_student, legalEdges] = RRAR(nstudent, nschool, ...
    studentList, schoolList, studentRank, StuOSA_student, StuOSA_school_last)
% INPUT: instance size, preference list, rank list, output from GS
% OUTPUT: StuOLA_student records each student's assignment in Student-Optimal Legal Assignment (StuOLA)
%         legalEdges is a boolean array recording (some of) legal edges
% PROCEDURE: Reverse Rotate-Remove 
% REFERENCE: Yuri Faenza & Xuan Zhang, 
%            "Legal Assignments and fast EADAM with consent via classical theory of stable matchings"

%% Position at preference list when looking for next s_M(school)
pos_sch = StuOSA_school_last;

%% Position of student that schools are currently matched to
match_pos_sch_last = pos_sch;

%% Position of school that students are currently matched to
match_pos_stu = zeros(1, nstudent);
for i = 1:nstudent
    if StuOSA_student(i)==0; continue; end
    match_pos_stu(i) = studentRank(i, StuOSA_student(i));
end

%% Set up double linked list for cycle identification
numNodes = 0;
isSink = zeros(1, nschool);   isSink(StuOSA_school_last==0) = 1;
onPath = zeros(1, nschool);

%% Record Legal Edges
legalEdges = zeros(nstudent, nschool);
for i = 1:nstudent
    if StuOSA_student(i)==0; continue; end
    legalEdges(i, StuOSA_student(i)) = 1;
end

%% Main Rotate-and-Remove Algorithm [Fast-implementation]
while numNodes > 0 || sum(isSink) < nschool
    %% if linked list empty, add a non-sink node
    if numNodes == 0
        i = 1; while isSink(i); i=i+1; end
        tail = dlnode(i);
        numNodes = 1;
        onPath(i) = 1;
    end
    
    %% Start growing the list - first find s^*_M()
    pos_sch(tail.Data) = pos_sch(tail.Data) + 1;
    while pos_sch(tail.Data) <= nstudent && ...
            (schoolList(tail.Data, pos_sch(tail.Data)) == 0 || ...
            match_pos_stu(schoolList(tail.Data, pos_sch(tail.Data))) ==0 || ...
            isSink(studentList( schoolList(tail.Data, pos_sch(tail.Data)), ...
                match_pos_stu(schoolList(tail.Data, pos_sch(tail.Data)))) ) || ...
            studentRank( schoolList(tail.Data, pos_sch(tail.Data)), tail.Data ) >= ...
                match_pos_stu(schoolList(tail.Data, pos_sch(tail.Data))))
        pos_sch(tail.Data) = pos_sch(tail.Data) + 1;
    end
    
    %% this is a sink and remove it
    if pos_sch(tail.Data) > nstudent  
        isSink(tail.Data) = 1;
        onPath(tail.Data) = 0;
        numNodes = numNodes - 1;
        tail = tail.Prev;
        continue;
    end
    
    %% Add the next node to graph if it is not already on path
    stu = schoolList(tail.Data, pos_sch(tail.Data));
    next_sch = studentList(stu, match_pos_stu(stu));
    if ~onPath(next_sch)
        dlnode(next_sch).insertAfter(tail);
        tail = tail.Next;
        onPath(next_sch) = 1;
        numNodes = numNodes + 1;
        continue;
    end
    
    %% If already on path, it is a cycle, and we need to rotate
    while tail.Data ~= next_sch
        stu = schoolList(tail.Data, pos_sch(tail.Data));
        legalEdges(stu, tail.Data) = 1;
        
        % update match info for the school
        match_pos_sch_last(tail.Data) = pos_sch(tail.Data);
        
        % update match info for the student
        match_pos_stu(stu) = studentRank(stu, tail.Data);
        
        % Update linked list
        onPath(tail.Data) = 0;
        tail = tail.Prev;
        delete(tail.Next);
        numNodes = numNodes - 1;
    end
    
    % Handle the last arc in the cycle
    stu = schoolList(tail.Data, pos_sch(tail.Data));
    legalEdges(stu, tail.Data) = 1;
    match_pos_sch_last(tail.Data) = pos_sch(tail.Data);
    match_pos_stu(stu) = studentRank(stu, tail.Data);
    
    onPath(tail.Data) = 0;
    if isempty(tail.Prev)
        delete(tail);
    else
        tail = tail.Prev;
        delete(tail.Next);
        pos_sch(tail.Data) = pos_sch(tail.Data) - 1;    % special case
    end
    numNodes = numNodes - 1;
end

StuOLA_student = zeros(1, nstudent);
for i = 1:nstudent
    if match_pos_stu(i)==0; continue; end
    StuOLA_student(i) = studentList(i, match_pos_stu(i));
end

end