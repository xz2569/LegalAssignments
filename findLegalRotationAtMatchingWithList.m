function rotations = findLegalRotationAtMatchingWithList(stuMatch, ...
    studentList, schoolList)

%% Initialization
nstudent = size(studentList, 1);
nschool = size(studentList, 2);
dlinks = zeros(1,nstudent);
n_updated = nstudent;

schMatch_last_pos = zeros(1, nschool);
for i = 1:nstudent
    if stuMatch(i) == 0
        dlinks(i) = -1;
        continue 
    end
    hisPos = find(schoolList(stuMatch(i), :)==i);
    if hisPos > schMatch_last_pos(stuMatch(i))
        schMatch_last_pos(stuMatch(i)) = hisPos;
    end
end

%% Construct Directed Graphs: m -> next(m)
while n_updated > 0
    n_updated = 0;
    for stu = 1:nstudent
        if dlinks(stu) == -1                 % student is a sink
            continue
        end
        if dlinks(stu) > 0                   % student pointing to non-sink
            if dlinks(dlinks(stu)) ~= -1
                continue
            end
        end
        hisList = studentList(stu,:);
        
        % starting from school on student's list to find the next node to rotate into
        if dlinks(stu) == 0                  
            sch = stuMatch(stu);
        else
            sch = stuMatch(dlinks(stu));
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% THIS IS NOT EFFICIENT, CHANGE WHEN IN THE MOOD %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        schPos = find(hisList == sch) + 1;
        found = false;
        while schPos <= length(hisList) && ~found
            nextsch = hisList(schPos);
            % handle illegal edges first || school has no assignment
            if nextsch == 0 || schMatch_last_pos(nextsch) == 0
                schPos = schPos + 1;
                continue;
            end
            herList = schoolList(nextsch, :);
            nextStu = herList(schMatch_last_pos(nextsch));
            if dlinks(nextStu) ~= -1 && ...
                    find(herList == nextStu) > find(herList == stu)
                found = true;
                dlinks(stu) = nextStu;
                n_updated = n_updated + 1;
            else 
                schPos = schPos + 1;
            end
        end
        if ~found 
            dlinks(stu) = -1;
            n_updated = n_updated + 1;
        end
    end
end

%% Find cycles
incomingFrom = cell(1,nstudent);
outgoingTo = cell(1,nstudent);
for i = 1:length(dlinks)
    j = dlinks(i);
    if j == -1
        continue
    end
    if isempty(incomingFrom{j})
        incomingFrom{j} = i;
    else
        incomingFrom{j} = [incomingFrom{j} i];
    end
    if isempty(outgoingTo{i})
        outgoingTo{i} = j;
    else
        outgoingTo{i} = [outgoingTo{i} j];
    end
end
% topolgy-sort type of node deletion
exists = true;
while exists 
    exists = false;
    for i=1:nstudent
        if isempty(incomingFrom{i}) && ~isempty(outgoingTo{i})
            exists = true;
            j = outgoingTo{i}; j = j(1);
            temp = incomingFrom{j};
            incomingFrom{j} = temp(temp ~= i);
            outgoingTo{i} = [];
        end
    end
end
% find all cycles
cycles = {};
while sum(~cellfun('isempty', outgoingTo)) > 0
   i=1;
   while isempty(outgoingTo{i})
       i = i+1;
   end
   temp = i;
   while outgoingTo{temp(length(temp))} ~= temp(1)
       thisArr = outgoingTo{temp(length(temp))};
       temp = [temp thisArr(1)];
   end
   for i=1:length(temp)
       outgoingTo{temp(i)} = [];
   end
   cycles = [cycles temp];
end

%% Return rotations
rotations = cell(1,length(cycles));
for i = 1:length(cycles)
    cycle = cycles{i};
    temp = cell(1,length(cycle));
    for j = 1:length(cycle)
        stu = cycle(j);
        sch = stuMatch(stu);
        temp{j} = [stu sch];
    end
    rotations{i} = temp;
end

end