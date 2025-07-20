% xml concatenator by AstreTunes from SEA group
% Coded on MATLAB version R2022b, works theoratically on R2020b or later versions

%% Preparations

clc
clear
close all
dbstop if error

% Parameter
keepLegacyFiles = 1;
migrateAnimation = 1;
underwaterModel = 'false';
abovewaterModel = 'true';
pathModsSDK = '.\ModsSDK';

% Prepare log
logFile = fopen('xmlRectify.log', 'w');
logCount = 0;

%% Parse mods

% Look for compile.info and build mod list
listMod = dir(".\**\compile.info");

for indMod = 1: size(listMod, 1)
    
    currentPath = listMod(indMod).folder;
    listModel = dir([currentPath, '\*\*.model']); % look for lod0 .model files

    for indModel = 1: size(listModel, 1)
    
        folderSplit = split(listModel(indModel).folder, '\');
        modelType = char(folderSplit(end));
        shipID = char(folderSplit(end-1));
        modRoot = char(strjoin(folderSplit(1:end-2), '\'));
%         fileModelLod0_completeFileName = [listModel(indModel).folder, '\', listModel(indModel).name];
        fileModelLod0_path = listModel(indModel).folder;
        fileModelLod0_lodsPath = [fileModelLod0_path, '\lods'];
        fileModelLod0_fileName = listModel(indModel).name;
        disp(['processing ', fileModelLod0_path, '\', fileModelLod0_fileName, ' ...']);

        % make copy of the current .model file
        if isempty(dir([fileModelLod0_path, '\', fileModelLod0_fileName, 'bak']))
            copyfile([fileModelLod0_path, '\', fileModelLod0_fileName], [fileModelLod0_path, '\', fileModelLod0_fileName, 'bak']);
        end

        % load data from .model and .visual files
        lod1Exist = 0;
        lod2Exist = 0;
        lod3Exist = 0;
        lod4Exist = 0;
        isPort = 0;
        textModelLod0 = readlines([fileModelLod0_path, '\', fileModelLod0_fileName, 'bak']);
        dataModelLod0 = parseModel(textModelLod0, 0, modRoot);
        if isempty(dir([dataModelLod0.visualFile, 'bak']))
            copyfile(dataModelLod0.visualFile, [dataModelLod0.visualFile, 'bak']);  % make copy of nodefullVisual file
        end
        textVisualLod0 = readlines([dataModelLod0.visualFile, 'bak']);
        listNodesLod0 = parseSkeleton(textVisualLod0);
        renderSetsLod0 = parseRenderSets(textVisualLod0);
        switch dataModelLod0.parentLod
            case 1
                lod1Exist = 1;
                textModelLod1 = readlines(dataModelLod0.parentFile);
                dataModelLod1 = parseModel(textModelLod1, 1, modRoot);
                textVisualLod1 = readlines(dataModelLod1.visualFile);
                listNodesLod1 = parseSkeleton(textVisualLod1);
                renderSetsLod1 = parseRenderSets(textVisualLod1);
                for indNode = 1: size(listNodesLod1, 2)
                    if ~max(strcmp(listNodesLod0, listNodesLod1(indNode)))
                        fprintf(logFile, '%s: Skeleton node %s not found in %s, please check manually.\r\n', dataModelLod1.visualFile, char(listNodesLod1(indNode)), dataModelLod0.visualFile);
                        logCount = logCount + 1;
                    end
                end
                if dataModelLod1.parentLod == 2
                    lod2Exist = 1;
                    textModelLod2 = readlines(dataModelLod1.parentFile);
                    dataModelLod2 = parseModel(textModelLod2, 2, modRoot);
                    textVisualLod2 = readlines(dataModelLod2.visualFile);
                    listNodesLod2 = parseSkeleton(textVisualLod2);
                    renderSetsLod2 = parseRenderSets(textVisualLod2);
                    for indNode = 1: size(listNodesLod2, 2)
                        if ~max(strcmp(listNodesLod0, listNodesLod2(indNode)))
                            fprintf(logFile, '%s: Skeleton node %s not found in %s, please check manually.\r\n', dataModelLod2.visualFile, char(listNodesLod2(indNode)), dataModelLod0.visualFile);
                            logCount = logCount + 1;
                        end
                    end
                    if dataModelLod2.parentLod == 3
                        lod3Exist = 1;
                        textModelLod3 = readlines(dataModelLod2.parentFile);
                        dataModelLod3 = parseModel(textModelLod3, 3, modRoot);
                        textVisualLod3 = readlines(dataModelLod3.visualFile);
                        listNodesLod3 = parseSkeleton(textVisualLod3);
                        renderSetsLod3 = parseRenderSets(textVisualLod3);
                        for indNode = 1: size(listNodesLod3, 2)
                            if ~max(strcmp(listNodesLod0, listNodesLod3(indNode)))
                                fprintf(logFile, '%s: Skeleton node %s not found in %s, please check manually.\r\n', dataModelLod3.visualFile, char(listNodesLod3(indNode)), dataModelLod0.visualFile);
                                logCount = logCount + 1;
                            end
                        end
                    end
                end
            case 4
                lod4Exist = 1;
                textModelLod4 = readlines(dataModelLod0.parentFile);
                dataModelLod4 = parseModel(textModelLod4, 4, modRoot);
                textVisualLod4 = readlines(dataModelLod4.visualFile);
                listNodesLod4 = parseSkeleton(textVisualLod4);
                renderSetsLod4 = parseRenderSets(textVisualLod4);
                for indNode = 1: size(listNodesLod4, 2)
                    if ~max(strcmp(listNodesLod0, listNodesLod4(indNode)))
                        fprintf(logFile, '%s: Skeleton node %s not found in %s, please check manually.\r\n', dataModelLod4.visualFile, char(listNodesLod4(indNode)), dataModelLod0.visualFile);
                        logCount = logCount + 1;
                    end
                end
            case -1 % no lod available, consider isPort
                if strcmp(modelType, 'ship') && contains(fileModelLod0_fileName, '_ports.', 'IgnoreCase', true) % case of _ports.model in ship/
                    isPort = 1;
                end
            otherwise
                fprintf(logFile, '%s: Abnormal lod hierarchy, please check manually.\r\n', [fileModelLod0_path, '\', fileModelLod0_fileName]);
        end

        % grab animation path from ModsSDK
        if migrateAnimation && dataModelLod0.isAnimated
            if isempty(dir([pathModsSDK, '\', dataModelLod0.visualShipID, '\', modelType, '\', fileModelLod0_fileName]))
                fprintf(logFile, '%s: Failed to find corresponding SDK file for animation path.\r\n', [fileModelLod0_path, '\', fileModelLod0_fileName]);
                logCount = logCount + 1;
                dataModelLod0.isAnimated = -1;
            else
                textModelSdk = readlines([pathModsSDK, '\', dataModelLod0.visualShipID, '\', modelType, '\', fileModelLod0_fileName]);
                [animSdk, animCountSdk] = parseAnimation(textModelSdk);
                if animCountSdk == 0
                    fprintf(logFile, '%s: Failed to find animation node in corresponding SDK file.\r\n', [fileModelLod0_path, '\', fileModelLod0_fileName]);
                    logCount = logCount + 1;
                    dataModelLod0.isAnimated = 0;
                end
            end
        end
        
        % write new .model file
        fileModelNeo = fopen([fileModelLod0_path, '\', fileModelLod0_fileName], 'w');
        fprintf(fileModelNeo, '<%s>\r\n', fileModelLod0_fileName); % write filename
        fprintf(fileModelNeo, '\t<visual>\t%s.visual\t</visual>\r\n', dataModelLod0.visual);    % write visual node
        if dataModelLod0.isAnimated == 1  % write animations node
            fprintf(fileModelNeo, '\t<animations>\r\n');
            for indAnim = 1: animCountSdk
                fprintf(fileModelNeo, '\t\t%s\r\n', animSdk(indAnim));
            end
            fprintf(fileModelNeo, '\t</animations>\r\n');
        else    % write empty animations node
            fprintf(fileModelNeo, '\t<animations />\r\n');
        end
        fprintf(fileModelNeo, '\t<dyes />\r\n');   % write dye node, which is always empty
        fprintf(fileModelNeo, '\t<metaData>\t%s\t</metaData>\r\n', dataModelLod0.metaData);   % write metaData
        fprintf(fileModelNeo, '</%s>\r\n', fileModelLod0_fileName); % write /filename
        fclose(fileModelNeo);

        % write new .visual file
        fileVisualNeo = fopen(dataModelLod0.visualFile, 'w');
        fileVisualBak = fopen([dataModelLod0.visualFile, 'bak'], 'rt');
        % write filename
        fprintf(fileVisualNeo, '<%s>\r\n', [dataModelLod0.visualName, '.visual']);
        % copy skeleton from lod0 visual
        fprintf(fileVisualNeo, '\t<skeleton>\r\n');
        isInNode = 0;
        lineVisualBak = fgetl(fileVisualBak);
        while lineVisualBak ~= -1
            if ~isInNode && ~isempty(regexp(lineVisualBak, '^(\t|    )<node>', 'once'))
                isInNode = 1;
            end
            if isInNode
                fprintf(fileVisualNeo, '\t%s\r\n', lineVisualBak);
                if ~isempty(regexp(lineVisualBak, '^(\t|    )</node>', 'once'))
                    break
                end
            end
            lineVisualBak = fgetl(fileVisualBak);
        end
        fclose(fileVisualBak);
        clear isInNode;
        fprintf(fileVisualNeo, '\t</skeleton>\r\n');
        % write properties
        fprintf(fileVisualNeo, '\t<properties>\r\n');
        fprintf(fileVisualNeo, '\t\t<underwaterModel>\t%s\t</underwaterModel>\r\n', underwaterModel);
        fprintf(fileVisualNeo, '\t\t<abovewaterModel>\t%s\t</abovewaterModel>\r\n', abovewaterModel);
        fprintf(fileVisualNeo, '\t</properties>\r\n');
        % write boundingBox
        fileVisualBak = fopen([dataModelLod0.visualFile, 'bak'], 'rt');
        isInBoundingBox = 0;
        lineVisualBak = fgetl(fileVisualBak);
        while lineVisualBak ~= -1
            if ~isInBoundingBox && ~isempty(regexp(lineVisualBak, '^(\t|    )<boundingBox>', 'once'))
                isInBoundingBox = 1;
            end
            if isInBoundingBox
                fprintf(fileVisualNeo, '%s\r\n', lineVisualBak);
                if ~isempty(regexp(lineVisualBak, '^(\t|    )</boundingBox>', 'once'))
                    break
                end
            end
            lineVisualBak = fgetl(fileVisualBak);
        end
        fclose(fileVisualBak);
        clear isInBoundingBox;
        % write renderSets
        writtenRenderSets = "";
        writtenRenderSetCount = 0;
        if isPort
            fprintf(fileVisualNeo, '\t<renderSets />\r\n');
        elseif lod4Exist
            fprintf(fileVisualNeo, '\t<renderSets>\r\n');
            for indRS = 1: size(renderSetsLod4, 2)
                fprintf(fileVisualNeo, '\t\t<renderSet>\r\n');
                fprintf(fileVisualNeo, '\t\t\t<name>\t%s\t</name>\r\n', renderSetsLod4(indRS).name);
                fprintf(fileVisualNeo, '\t\t\t%s\r\n', char(renderSetsLod4(indRS).tawso));
                fprintf(fileVisualNeo, '\t\t\t<nodes>\r\n');
                for indRSNode = 1: size(renderSetsLod4(indRS).nodes, 2)
                    fprintf(fileVisualNeo, '\t\t\t\t%s\r\n', renderSetsLod4(indRS).nodes(indRSNode));
                end
                fprintf(fileVisualNeo, '\t\t\t</nodes>\r\n');
                fprintf(fileVisualNeo, '\t\t\t<material>\r\n');
                fprintf(fileVisualNeo, '\t\t\t\t%s\r\n', char(renderSetsLod4(indRS).materialIdentifier));
                fprintf(fileVisualNeo, '\t\t\t\t%s\r\n', char(renderSetsLod4(indRS).materialMfm));
                fprintf(fileVisualNeo, '\t\t\t</material>\r\n');
                fprintf(fileVisualNeo, '\t\t</renderSet>\r\n');
            end
            fprintf(fileVisualNeo, '\t</renderSets>\r\n');
        else
            if ~isempty(renderSetsLod0)
                % write start mark
                fprintf(fileVisualNeo, '\t<renderSets>\r\n');
                % write lod0 renderSets
                for indRS = 1: size(renderSetsLod0, 2)
                    fprintf(fileVisualNeo, '\t\t<renderSet>\r\n');
                    fprintf(fileVisualNeo, '\t\t\t<name>\t%s\t</name>\r\n', renderSetsLod0(indRS).name);
                    writtenRenderSetCount = writtenRenderSetCount + 1;
                    writtenRenderSets(writtenRenderSetCount) = renderSetsLod0(indRS).name;
                    fprintf(fileVisualNeo, '\t\t\t%s\r\n', char(renderSetsLod0(indRS).tawso));
                    fprintf(fileVisualNeo, '\t\t\t<nodes>\r\n');
                    for indRSNode = 1: size(renderSetsLod0(indRS).nodes, 2)
                        fprintf(fileVisualNeo, '\t\t\t\t%s\r\n', renderSetsLod0(indRS).nodes(indRSNode));
                    end
                    fprintf(fileVisualNeo, '\t\t\t</nodes>\r\n');
                    fprintf(fileVisualNeo, '\t\t\t<material>\r\n');
                    fprintf(fileVisualNeo, '\t\t\t\t%s\r\n', char(renderSetsLod0(indRS).materialIdentifier));
                    fprintf(fileVisualNeo, '\t\t\t\t%s\r\n', char(renderSetsLod0(indRS).materialMfm));
                    fprintf(fileVisualNeo, '\t\t\t</material>\r\n');
                    fprintf(fileVisualNeo, '\t\t</renderSet>\r\n');
                end
                if lod1Exist    % write lod1 renderSets if lod1 exists
                    for indRS = 1: size(renderSetsLod1, 2)
                        if ~max(strcmp(writtenRenderSets, renderSetsLod1(indRS).name))
                            fprintf(fileVisualNeo, '\t\t<renderSet>\r\n');
                            fprintf(fileVisualNeo, '\t\t\t<name>\t%s\t</name>\r\n', renderSetsLod1(indRS).name);
                            writtenRenderSetCount = writtenRenderSetCount + 1;
                            writtenRenderSets(writtenRenderSetCount) = renderSetsLod1(indRS).name;
                            fprintf(fileVisualNeo, '\t\t\t%s\r\n', char(renderSetsLod1(indRS).tawso));
                            fprintf(fileVisualNeo, '\t\t\t<nodes>\r\n');
                            for indRSNode = 1: size(renderSetsLod1(indRS).nodes, 2)
                                fprintf(fileVisualNeo, '\t\t\t\t%s\r\n', renderSetsLod1(indRS).nodes(indRSNode));
                            end
                            fprintf(fileVisualNeo, '\t\t\t</nodes>\r\n');
                            fprintf(fileVisualNeo, '\t\t\t<material>\r\n');
                            fprintf(fileVisualNeo, '\t\t\t\t%s\r\n', char(renderSetsLod1(indRS).materialIdentifier));
                            fprintf(fileVisualNeo, '\t\t\t\t%s\r\n', char(renderSetsLod1(indRS).materialMfm));
                            fprintf(fileVisualNeo, '\t\t\t</material>\r\n');
                            fprintf(fileVisualNeo, '\t\t</renderSet>\r\n');
                        else
                            fprintf(logFile, '%s: Node %s duplicated, ignoring.\r\n', dataModelLod1.visualFile, renderSetsLod1(indRS).name);
                            logCount = logCount + 1;
                        end
                    end
                    if lod2Exist    % write lod2 renderSets if lod2 exists
                        for indRS = 1: size(renderSetsLod2, 2)
                            if ~max(strcmp(writtenRenderSets, renderSetsLod2(indRS).name))
                                fprintf(fileVisualNeo, '\t\t<renderSet>\r\n');
                                fprintf(fileVisualNeo, '\t\t\t<name>\t%s\t</name>\r\n', renderSetsLod2(indRS).name);
                                writtenRenderSetCount = writtenRenderSetCount + 1;
                                writtenRenderSets(writtenRenderSetCount) = renderSetsLod2(indRS).name;
                                fprintf(fileVisualNeo, '\t\t\t%s\r\n', char(renderSetsLod2(indRS).tawso));
                                fprintf(fileVisualNeo, '\t\t\t<nodes>\r\n');
                                for indRSNode = 1: size(renderSetsLod2(indRS).nodes, 2)
                                    fprintf(fileVisualNeo, '\t\t\t\t%s\r\n', renderSetsLod2(indRS).nodes(indRSNode));
                                end
                                fprintf(fileVisualNeo, '\t\t\t</nodes>\r\n');
                                fprintf(fileVisualNeo, '\t\t\t<material>\r\n');
                                fprintf(fileVisualNeo, '\t\t\t\t%s\r\n', char(renderSetsLod2(indRS).materialIdentifier));
                                fprintf(fileVisualNeo, '\t\t\t\t%s\r\n', char(renderSetsLod2(indRS).materialMfm));
                                fprintf(fileVisualNeo, '\t\t\t</material>\r\n');
                                fprintf(fileVisualNeo, '\t\t</renderSet>\r\n');
                            else
                                fprintf(logFile, '%s: Node %s duplicated, ignoring.\r\n', dataModelLod2.visualFile, renderSetsLod2(indRS).name);
                                logCount = logCount + 1;
                            end
                        end
                        if lod3Exist    % write lod3 renderSets if lod3 exists
                            for indRS = 1: size(renderSetsLod3, 2)
                                if ~max(strcmp(writtenRenderSets, renderSetsLod3(indRS).name))
                                    fprintf(fileVisualNeo, '\t\t<renderSet>\r\n');
                                    fprintf(fileVisualNeo, '\t\t\t<name>\t%s\t</name>\r\n', renderSetsLod3(indRS).name);
                                    writtenRenderSetCount = writtenRenderSetCount + 1;
                                    writtenRenderSets(writtenRenderSetCount) = renderSetsLod3(indRS).name;
                                    fprintf(fileVisualNeo, '\t\t\t%s\r\n', char(renderSetsLod3(indRS).tawso));
                                    fprintf(fileVisualNeo, '\t\t\t<nodes>\r\n');
                                    for indRSNode = 1: size(renderSetsLod3(indRS).nodes, 2)
                                        fprintf(fileVisualNeo, '\t\t\t\t%s\r\n', renderSetsLod3(indRS).nodes(indRSNode));
                                    end
                                    fprintf(fileVisualNeo, '\t\t\t</nodes>\r\n');
                                    fprintf(fileVisualNeo, '\t\t\t<material>\r\n');
                                    fprintf(fileVisualNeo, '\t\t\t\t%s\r\n', char(renderSetsLod3(indRS).materialIdentifier));
                                    fprintf(fileVisualNeo, '\t\t\t\t%s\r\n', char(renderSetsLod3(indRS).materialMfm));
                                    fprintf(fileVisualNeo, '\t\t\t</material>\r\n');
                                    fprintf(fileVisualNeo, '\t\t</renderSet>\r\n');
                                else
                                    fprintf(logFile, '%s: Node %s duplicated, ignoring.\r\n', dataModelLod3.visualFile, renderSetsLod3(indRS).name);
                                    logCount = logCount + 1;
                                end
                            end
                        end
                    end
                end
                % write end mark
                fprintf(fileVisualNeo, '\t</renderSets>\r\n');
            else
                fprintf(logFile, '%s: No renderSet found in lod0 visual.\r\n', dataModelLod0.visualFile);
                logCount = logCount + 1;
                fprintf(fileVisualNeo, '\t<renderSets />\r\n');
            end
        end
        % write lods
        fprintf(fileVisualNeo, '\t<lods>\r\n');
        % write lod0 lod
        fprintf(fileVisualNeo, '\t\t<lod>\r\n');
        fprintf(fileVisualNeo, '\t\t\t<extent>\t%s\t</extent>\r\n', dataModelLod0.extent);
        fprintf(fileVisualNeo, '\t\t\t<castsShadow>\t%s\t</castsShadow>\r\n', dataModelLod0.castsShadow);
        if ~isempty(renderSetsLod0)
            fprintf(fileVisualNeo, '\t\t\t<renderSets>\r\n');
            for indRS = 1: size(renderSetsLod0, 2)
                fprintf(fileVisualNeo, '\t\t\t\t<renderSet>\t%s\t</renderSet>\r\n', renderSetsLod0(indRS).name);
            end
            fprintf(fileVisualNeo, '\t\t\t</renderSets>\r\n');
        else
            fprintf(fileVisualNeo, '\t\t\t<renderSets />\r\n');
        end
        fprintf(fileVisualNeo, '\t\t</lod>\r\n');
        if lod1Exist % write lod1 lod
            fprintf(fileVisualNeo, '\t\t<lod>\r\n');
            fprintf(fileVisualNeo, '\t\t\t<extent>\t%s\t</extent>\r\n', dataModelLod1.extent);
            fprintf(fileVisualNeo, '\t\t\t<castsShadow>\t%s\t</castsShadow>\r\n', dataModelLod1.castsShadow);
            fprintf(fileVisualNeo, '\t\t\t<renderSets>\r\n');
            for indRS = 1: size(renderSetsLod1, 2)
                fprintf(fileVisualNeo, '\t\t\t\t<renderSet>\t%s\t</renderSet>\r\n', renderSetsLod1(indRS).name);
            end
            fprintf(fileVisualNeo, '\t\t\t</renderSets>\r\n');
            fprintf(fileVisualNeo, '\t\t</lod>\r\n');
            if lod2Exist
                fprintf(fileVisualNeo, '\t\t<lod>\r\n');
                fprintf(fileVisualNeo, '\t\t\t<extent>\t%s\t</extent>\r\n', dataModelLod2.extent);
                fprintf(fileVisualNeo, '\t\t\t<castsShadow>\t%s\t</castsShadow>\r\n', dataModelLod2.castsShadow);
                fprintf(fileVisualNeo, '\t\t\t<renderSets>\r\n');
                for indRS = 1: size(renderSetsLod2, 2)
                    fprintf(fileVisualNeo, '\t\t\t\t<renderSet>\t%s\t</renderSet>\r\n', renderSetsLod2(indRS).name);
                end
                fprintf(fileVisualNeo, '\t\t\t</renderSets>\r\n');
                fprintf(fileVisualNeo, '\t\t</lod>\r\n');
                if lod3Exist
                    fprintf(fileVisualNeo, '\t\t<lod>\r\n');
                    fprintf(fileVisualNeo, '\t\t\t<extent>\t%s\t</extent>\r\n', dataModelLod3.extent);
                    fprintf(fileVisualNeo, '\t\t\t<castsShadow>\t%s\t</castsShadow>\r\n', dataModelLod3.castsShadow);
                    fprintf(fileVisualNeo, '\t\t\t<renderSets>\r\n');
                    for indRS = 1: size(renderSetsLod3, 2)
                        fprintf(fileVisualNeo, '\t\t\t\t<renderSet>\t%s\t</renderSet>\r\n', renderSetsLod3(indRS).name);
                    end
                    fprintf(fileVisualNeo, '\t\t\t</renderSets>\r\n');
                    fprintf(fileVisualNeo, '\t\t</lod>\r\n');
                end
            end
        elseif lod4Exist
            fprintf(fileVisualNeo, '\t\t<lod>\r\n');
            fprintf(fileVisualNeo, '\t\t\t<extent>\t%s\t</extent>\r\n', dataModelLod4.extent);
            fprintf(fileVisualNeo, '\t\t\t<castsShadow>\t%s\t</castsShadow>\r\n', dataModelLod4.castsShadow);
            fprintf(fileVisualNeo, '\t\t\t<renderSets>\r\n');
            for indRS = 1: size(renderSetsLod4, 2)
                fprintf(fileVisualNeo, '\t\t\t\t<renderSet>\t%s\t</renderSet>\r\n', renderSetsLod4(indRS).name);
            end
            fprintf(fileVisualNeo, '\t\t\t</renderSets>\r\n');
            fprintf(fileVisualNeo, '\t\t</lod>\r\n');
        end
        fprintf(fileVisualNeo, '\t</lods>\r\n');
        % write /filename
        fprintf(fileVisualNeo, '</%s>\r\n', [dataModelLod0.visualName, '.visual']); 

        clear textModelLod0 textModelLod1 textModelLod2 textModelLod3 textModelLod4;
        clear dataModelLod0 dataModelLod1 dataModelLod2 dataModelLod3 dataModelLod4;
        clear writtenRenderSets writtenRenderSetCount;

    end

end

%% End

fclose all;
disp('Routine finished.');
if logCount > 0
    disp('Issue(s) occurred, please check log file.');
end

%% Function to load data from .model file text
function dataModel = parseModel(textModel, lod, modRoot)

    % initialize
    dataModel.lod = lod;
    dataModel.castsShadow = "";
    dataModel.extent = "";
    dataModel.metaData = "";
    dataModel.parent = "";
    dataModel.parentLod = -1;
    dataModel.visual = "";
    if lod == 0 
        dataModel.isAnimated = 0;
    end

    % read data
    indLine = 1;
    while indLine < size(textModel, 1)
        if contains(textModel(indLine), '<castsShadow>')
            labelPattern = '<castsShadow>\s*([a-zA-Z0-9_]+)\s*</castsShadow>';
            match = regexp(textModel(indLine), labelPattern, 'tokens');
            dataModel.castsShadow = match{1}{1};
        elseif contains(textModel(indLine), '<parent>')
            labelPattern = '<parent>\s*([a-zA-Z0-9_/.() -]+)\s*</parent>';
            match = regexp(textModel(indLine), labelPattern, 'tokens');
            dataModel.parent = match{1}{1};
        elseif contains(textModel(indLine), '<extent>')
            labelPattern = '<extent>\s*([a-zA-Z0-9_.]+)\s*</extent>';
            match = regexp(textModel(indLine), labelPattern, 'tokens');
            dataModel.extent = match{1}{1};
        elseif contains(textModel(indLine), '<nodefullVisual>')
            labelPattern = '<nodefullVisual>\s*([a-zA-Z0-9_/.() -]+)\s*</nodefullVisual>';
            match = regexp(textModel(indLine), labelPattern, 'tokens');
            dataModel.visual = match{1}{1};
        elseif contains(textModel(indLine), '<metaData>')
            labelPattern = '<metaData>\s*([a-zA-Z0-9_.| ]+)\s*</metaData>';
            match = regexp(textModel(indLine), labelPattern, 'tokens');
            dataModel.metaData = match{1}{1};
        elseif contains(textModel(indLine), '<animation>')
            if lod == 0
                dataModel.isAnimated = 1;
            end
        end
        indLine = indLine + 1;
    end
    clear match;

    % find next lod
    parentSplit = split(dataModel.parent, '_');
    if strcmp(parentSplit(end), "lod1")
        dataModel.parentLod = 1;
    elseif strcmp(parentSplit(end), "lod2")
        dataModel.parentLod = 2;
    elseif strcmp(parentSplit(end), "lod3")
        dataModel.parentLod = 3;
    elseif strcmp(parentSplit(end), "lod4")
        dataModel.parentLod = 4;
    end

    % find next ship and path to next .model
    if dataModel.parentLod ~= -1
        parentSplit = split(dataModel.parent, '/');
        dataModel.parentShipID = char(parentSplit(end-3));
        dataModel.parentFile = [modRoot, '\', char(strjoin(parentSplit(end-3: end), '\')), '.model'];
    end

    % find path to .visual
    visualSplit = split(dataModel.visual, '/');
    dataModel.visualName = char(visualSplit(end));
    if contains(dataModel.visual, '/lods/')
        dataModel.visualShipID = char(visualSplit(end-3));
        dataModel.visualFile = [modRoot, '\', char(strjoin(visualSplit(end-3: end), '\')), '.visual'];
    else
        dataModel.visualShipID = char(visualSplit(end-2));
        dataModel.visualFile = [modRoot, '\', char(strjoin(visualSplit(end-2: end), '\')), '.visual'];
    end

end

%% Function to load animations from SDK .model file text
function [animations, animationCount] = parseAnimation(textModel)
    animations = "";
    animationCount = 0;
    indLine = 1;
    while indLine < size(textModel, 1)
        if contains(textModel(indLine), '<animation>')
            animationCount = animationCount + 1;
            animations(animationCount) = strip(textModel(indLine));
        end
        indLine = indLine + 1;
    end
end

%% Function to list skeleton nodes from .visual file text
function listNodes = parseSkeleton(textVisual)
    listNodes = "";
    nodeCount = 0;
    isInNode = 0;
    indLine = 1;
    while indLine < size(textVisual, 1)
        if ~isInNode && (strcmp(char(textVisual(indLine)), '	<node>') || strcmp(char(textVisual(indLine)), '    <node>'))
            isInNode = 1;
        end
        if isInNode
            if contains(textVisual(indLine), '<identifier>')
                nodeCount = nodeCount + 1;
                labelPattern = '<identifier>\s*([a-zA-Z0-9_ ]+)\s*</identifier>';
                match = regexp(textVisual(indLine), labelPattern, 'tokens');
                listNodes(nodeCount) = match{1}{1};
            end
            if ~isempty(regexp(textVisual(indLine), '^(\t|    )</node>', 'once'))
                isInNode = 0;
                break
            end
        end
        indLine = indLine + 1;
    end
end

%% Function to load renderSet data from .visual file text
function dataRenderSets = parseRenderSets(textVisual)
    dataRenderSets = [];
    labelPattern = '<vertices>\s*([a-zA-Z0-9_]+)\.vertices\s*</vertices>'; 
    countRenderSets = 0;
    indLine = 1;
    while indLine < size(textVisual, 1)
        if strcmp(strip(textVisual(indLine)), '<renderSet>')
            countRenderSets = countRenderSets + 1;
            countNodes = 0;
            dataRenderSets(countRenderSets).nodes = "";
            while ~strcmp(strip(textVisual(indLine)), '</renderSet>')
                if contains(textVisual(indLine), '<treatAsWorldSpaceObject>')
                    dataRenderSets(countRenderSets).tawso = strip(textVisual(indLine));
                elseif contains(textVisual(indLine), '<node>')
                    countNodes = countNodes + 1;
                    dataRenderSets(countRenderSets).nodes(countNodes) = strip(textVisual(indLine));
                elseif contains(textVisual(indLine), '<vertices>')
                    match = regexp(textVisual(indLine), labelPattern, 'tokens');
                    dataRenderSets(countRenderSets).name = match{1}{1};
                    clear match;
                elseif contains(textVisual(indLine), '<identifier>')
                    dataRenderSets(countRenderSets).materialIdentifier = strip(textVisual(indLine));
                elseif contains(textVisual(indLine), '<mfm>')
                    dataRenderSets(countRenderSets).materialMfm = strip(textVisual(indLine));
                end
                indLine = indLine + 1;
            end
        end
        indLine = indLine + 1;
    end
end