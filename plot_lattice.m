% Plot the lattice structure of legal assignments
% Red dots for stable assignments
% Blue dots for legal but unstable assignments

%% Rotations and construct lattice structure
stuMatch = StuOLA_student;
s = [];
t = [];
nodes = {};
mapObj_match = containers.Map();
mapObj_match(num2str(stuMatch)) = 1;
mapObj_id = containers.Map();
mapObj_id('1') = stuMatch;
nodes{1} = ['[' num2str(stuMatch) ']'];
Q = 1;

%% Build the Lattice
while ~isempty(Q)
    sid = Q(1);
    stuMatchInCell = values(mapObj_id, {num2str(sid)});
    stuMatch = stuMatchInCell{1};
    rots = findLegalRotationAtMatchingWithList(stuMatch, LstudentList, LschoolList);
    for i = 1:length(rots)
        nextMatch = applyRotation(stuMatch, rots{i});
        nextMatchStr = num2str(nextMatch);
        if isKey(mapObj_match, nextMatchStr)
            nextSidInCell = values(mapObj_match, {nextMatchStr});
            nextSid = nextSidInCell{1};
        else
            nextSid = mapObj_match.Count + 1;
            mapObj_match(nextMatchStr) = nextSid;
            mapObj_id(num2str(nextSid)) = nextMatch;
            nodes{nextSid} = ['[' nextMatchStr ']'];
        end
        if ~ismember(nextSid, Q)
            Q = [Q nextSid];
        end
        s = [s sid];
        t = [t nextSid];
    end
    Q = Q(2:end);
end

%% Classify matching -> Stable vs Legal
stableNodes = [];
for i = 1:mapObj_id.Count
    stuMatchInCell = values(mapObj_id, {num2str(i)});
    stuMatch = stuMatchInCell{1};
    
    schMatch_last_pos = zeros(1, nschool);
    for stu = 1:nstudent
        if stuMatch(stu) == 0; continue; end
        hisPos = find(schoolList(stuMatch(stu), :)==stu);
        if hisPos > schMatch_last_pos(stuMatch(stu))
            schMatch_last_pos(stuMatch(stu)) = hisPos;
        end
    end

    stable = 1;
    for stu = 1:nstudent
        for sch = 1:nschool
            if (stuMatch(stu) == 0 || ...
                    studentRank(stu, sch) < studentRank(stu, stuMatch(stu))) && ...
               (schMatch_last_pos(sch) == 0 || ...
                    schoolRank(sch, stu) < schMatch_last_pos(sch))
                stable = 0;
                break
            end
        end
        if stable == 0
            break;
        end
    end
    
    if stable
        stableNodes = [stableNodes i];
    end
end

%% Plot Lattice Structure
if (mapObj_id.Count > 1)
    figure
    G = digraph(s, t);
    if nstudent > 6
        h = plot(G, 'Layout', 'layered', 'Direction', 'down');
    else
        h = plot(G, 'Layout', 'layered', 'Direction', 'down', 'NodeLabel', nodes); 
    end
    axis off
    highlight(h,stableNodes,'NodeColor','r');
else 
    stuMatchInCell = values(mapObj_id, {'1'});
    stuMatch = stuMatchInCell{1};
    disp('There is only 1 Legal Matching:');
    stuMatch
end

for i = 1:length(nodes)
    fprintf('%4d: %s\n', i, nodes{i});
end

% saveas(h, ['figure_lattice_n_is_' num2str(n) '.jpg'])