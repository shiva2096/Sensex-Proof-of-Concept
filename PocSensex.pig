inputData = load '$Input' using PigStorage('\t');
distinctData = DISTINCT inputData;
sortData = ORDER distinctData BY $0;
store distinctData into '$DistinctLoc';store sortData into '$SortLoc';

