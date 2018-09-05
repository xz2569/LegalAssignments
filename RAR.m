function [SchOLA_student, legalEdges] = RAR(nstudent, nschool, ...
    studentList, schoolList, studentRank, schoolRank, ...
    StuOSA_student, StuOSA_school_bool, StuOSA_school_last)
% INPUT: instance size, preference list, rank list, output from GS
% OUTPUT: SchOLA_student records each student's assignment in School-Optimal Legal Assignment (StuOLA)
%         legalEdges is a boolean array recording (some of) legal edges
% PROCEDURE: Rotate-Remove 
% REFERENCE: Yuri Faenza & Xuan Zhang, 
%            "Legal Assignments and fast EADAM with consent via classical theory of stable matchings"

%% Position at preference list when looking for next s_M(student)
pos_stu = zeros(1,nstudent);
for i = 1:nstudent
    if StuOSA_student(i)==0; continue; end
    pos_stu(i) = studentRank(i, StuOSA_student(i));
end

%% Position of school that students are currently matched to
match_pos_stu = pos_stu;

%% Position of student that school are currently matched to
match_pos_sch_last = StuOSA_school_last;
match_sch_bool = StuOSA_school_bool;

%% Set up double linked list for cycle identification
numNodes = 0;
isSink = zeros(1, nstudent);   isSink(StuOSA_student==0) = 1;
onPath = zeros(1, nstudent);

%% Record Legal Edges
legalEdges = zeros(nstudent, nschool);
for i = 1:nstudent
    if StuOSA_student(i)==0; continue; end
    legalEdges(i, StuOSA_student(i)) = 1;
end

%% Main Rotate-and-Remove Algorithm [Fast-implementation]
while numNodes > 0 || sum(isSink) < nstudent
    %% if linked list empty, add a non-sink node
    if numNodes == 0
        i = 1; while isSink(i); i=i+1; end
        tail = dlnode(i);
        numNodes = 1;
        onPath(i) = 1;
    end
    
    %% Start growing the list - first find s^*_M()
    pos_stu(tail.Data) = pos_stu(tail.Data) + 1;
    while pos_stu(tail.Data) <= nschool && ...
            (studentList(tail.Data, pos_stu(tail.Data)) == 0 || ...
            match_pos_sch_last(studentList(tail.Data, pos_stu(tail.Data))) == 0 || ...
            isSink(schoolList( studentList(tail.Data, pos_stu(tail.Data)), ...
                match_pos_sch_last(studentList(tail.Data, pos_stu(tail.Data)))) ) || ...
            schoolRank( studentList(tail.Data, pos_stu(tail.Data)), tail.Data ) >= ...
                match_pos_sch_last(studentList(tail.Data, pos_stu(tail.Data))))
        pos_stu(tail.Data) = pos_stu(tail.Data) + 1;
    end
    
    %% this is a sink and remove it
    if pos_stu(tail.Data) > nschool  
        isSink(tail.Data) = 1;
        onPath(tail.Data) = 0;
        numNodes = numNodes - 1;
        tail = tail.Prev;
        continue;
    end
    
    %% Add the next node to graph if it is not already on path
    sch = studentList(tail.Data, pos_stu(tail.Data));
    next_stu = schoolList(sch, match_pos_sch_last(sch));
    if ~onPath(next_stu)
        dlnode(next_stu).insertAfter(tail);
        tail = tail.Next;
        onPath(next_stu) = 1;
        numNodes = numNodes + 1;
        continue;
    end
    
    %% If already on path, it is a cycle, and we need to rotate
    while tail.Data ~= next_stu
        sch = studentList(tail.Data, pos_stu(tail.Data));
        legalEdges(tail.Data, sch) = 1;
        
        % update match info for the student
        match_pos_stu(tail.Data) = pos_stu(tail.Data);
        
        % update match info for the school
        match_sch_bool(sch, tail.Data) = 1;
        match_sch_bool(sch, schoolList(sch, match_pos_sch_last(sch))) = 0;
        
        last = match_pos_sch_last(sch);
        while match_sch_bool(sch, schoolList(sch,last)) == 0
            last = last - 1;
        end
        match_pos_sch_last(sch) = last;
        
        % Update linked list
        onPath(tail.Data) = 0;
        tail = tail.Prev;
        delete(tail.Next);
        numNodes = numNodes - 1;
    end
    
    % Handle the last arc in the cycle
    sch = studentList(tail.Data, pos_stu(tail.Data));
    legalEdges(tail.Data, sch) = 1;
    match_pos_stu(tail.Data) = pos_stu(tail.Data);
    match_sch_bool(sch, tail.Data) = 1;
    match_sch_bool(sch, schoolList(sch, match_pos_sch_last(sch))) = 0;
    
    last = match_pos_sch_last(sch);
    while match_sch_bool(sch, schoolList(sch,last)) == 0
        last = last - 1;
    end
    match_pos_sch_last(sch) = last;
    
    onPath(tail.Data) = 0;
    if isempty(tail.Prev)
        delete(tail);
    else
        tail = tail.Prev;
        delete(tail.Next);
        pos_stu(tail.Data) = pos_stu(tail.Data) - 1;    % special case
    end
    numNodes = numNodes - 1;
end

SchOLA_student = zeros(1, nstudent);
for i = 1:nstudent
    if match_pos_stu(i)==0; continue; end
    SchOLA_student(i) = studentList(i, match_pos_stu(i));
end

end