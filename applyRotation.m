function manMatch = applyRotation(manMatch, rotation)

ncycle = length(rotation);
for i = 1:ncycle
    thisPair = rotation{i};
    nextPair = rotation{mod(i, ncycle) + 1};
    manMatch(thisPair(1)) = nextPair(2);
end

end
