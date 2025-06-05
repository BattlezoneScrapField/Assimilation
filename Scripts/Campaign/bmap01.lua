--[[
    Borg 01 Lua Mission Script
    Written by AI_Unit
--]]

-- Objectives.
local ScanObjectiveA = "Get within 40 meters from it.";
local ScanObjectiveB =
"OK, running scans now. Stay there for 20 seconds for scans to complete. Stay within 40 meters from it.";
local WarningObjective =
"Enemy is hostile. Destroy it now. Watch yourself, my scanners are picking up multiple ships on your way to the base. I've dropped a nav.";
local StartportObjective = "Get into the Starport and meet me in space.";
local WaitObjective = "Wait for further orders.";

-- Mission important variables.
local Mission = {
    m_MissionTime = 0,
    m_MissionDifficulty = 0,

    m_PlayerTeam = 1,
    m_AlliedTeam = 2,
    m_EnemyTeam = 5,

    m_Scout1 = nil,
    m_Scout2 = nil,
    m_Scout3 = nil,

    m_Enemy = nil,
    m_MainPlayer = nil,

    m_Nav1 = nil,

    m_Starport = nil,

    m_ScanObjectiveShown = false,
    m_MissionOver = false,

    m_MissionDelayTime = 0,
    m_ScanProgress = 0,
    m_ScanDelayTime = 0,

    -- Steps for each section.
    m_MissionState = 1,
}

-- Functions Table
local Functions = {};

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Event Driven Functions -------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
function InitialSetup()
    -- Do not auto group units.
    SetAutoGroupUnits(false);

    -- Preload the ODFs for the mission.
    PreloadODF("ivscout");
    PreloadODF("b_scout");
end

function Save()
    return Mission;
end

function Load(MissionData)
    -- Do not auto group units.
    SetAutoGroupUnits(false);

    -- Load mission data.
    Mission = MissionData;
end

function AddObject(h)
    local teamNum = GetTeamNum(h);

    if (teamNum == Mission.m_PlayerTeam) then
        SetSkill(h, 3);
    end
end

function Update()
    -- Keep track of our time.
    Mission.m_MissionTime = Mission.m_MissionTime + 1;

    -- Get the main player
    Mission.m_MainPlayer = GetPlayerHandle(1);

    if (Mission.m_MissionOver) then
        return;
    end

    -- Run each function for the mission.
    Functions[Mission.m_MissionState]();
end

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Mission Related Logic --------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
Functions[1] = function()
    Ally(1, 2);

    Mission.m_Scout1 = BuildObject("ivscout", Mission.m_AlliedTeam, "sp1");
    Mission.m_Scout2 = BuildObject("ivscout", Mission.m_AlliedTeam, "sp2");
    Mission.m_Scout3 = BuildObject("ivscout", Mission.m_AlliedTeam, "sp3");
    Mission.m_Starport = GetHandle("unnamed_ivstarp");

    SetScrap(Mission.m_PlayerTeam, 10);

    Mission.m_Enemy = BuildObject("b_scout", Mission.m_EnemyTeam, "bscout");

    Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(3);
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[2] = function()
    -- Wait for the delay to finish.
    if (Mission.m_MissionTime < Mission.m_MissionDelayTime) then
        return;
    end

    AudioMessage("b1_intro.wav");
    SetPerceivedTeam(Mission.m_MainPlayer, Mission.m_EnemyTeam);
    AddObjective(WaitObjective, "BLUE");

    Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(8);
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[3] = function()
    -- Wait for the delay to finish.
    if (Mission.m_MissionTime < Mission.m_MissionDelayTime) then
        return;
    end

    StartSoundEffect("b1_ship");
    CameraReady();

    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[4] = function()
    local isCamDone = CameraPath("campath", 1000, 2000, Mission.m_Enemy);

    if (isCamDone) then
        CameraFinish();
        ClearObjectives();
        AddObjective(ScanObjectiveA, "WHITE");
        Mission.m_MissionState = Mission.m_MissionState + 1;
    end
end

Functions[5] = function()
    -- Wait for the player to get close enough.
    if (GetDistance(Mission.m_MainPlayer, Mission.m_Enemy) > 40) then
        return;
    end

    if (Mission.m_ScanObjectiveShown == false) then
        ClearObjectives();
        AddObjective(ScanObjectiveB, "WHITE");
        Mission.m_ScanObjectiveShown = true;
    end

    if (Mission.m_ScanDelayTime < Mission.m_MissionTime) then
        if (Mission.m_ScanProgress == 10) then
            ClearObjectives();
            AddObjective(ScanObjectiveB, "BLUE");
        elseif (Mission.m_ScanProgress >= 20) then
            ClearObjectives();
            AddObjective(ScanObjectiveB, "GREEN");

            Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(10);
            Mission.m_MissionState = Mission.m_MissionState + 1;
        end

        Mission.m_ScanProgress = Mission.m_ScanProgress + 1;
        Mission.m_ScanDelayTime = Mission.m_MissionTime + SecondsToTurns(1);
    end
end

Functions[6] = function()
    -- Wait for the delay to finish.
    if (Mission.m_MissionTime < Mission.m_MissionDelayTime) then
        return;
    end

    ClearObjectives();
    AddObjective(WarningObjective, "RED");
    AddObjective(StartportObjective, "WHITE");

    SetPerceivedTeam(Mission.m_MainPlayer, Mission.m_PlayerTeam);

    Attack(Mission.m_Enemy, Mission.m_MainPlayer);

    Follow(Mission.m_Scout1, Mission.m_MainPlayer);
    Follow(Mission.m_Scout2, Mission.m_MainPlayer);
    Follow(Mission.m_Scout3, Mission.m_MainPlayer);

    Mission.m_Nav1 = BuildObject("ibnav", Mission.m_PlayerTeam, "navspace");

    SetObjectiveName(Mission.m_Nav1, "ISDF Base");
    SetObjectiveOn(Mission.m_Nav1);

    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[7] = function()
    if (GetDistance(Mission.m_MainPlayer, Mission.m_Starport) > 30) then
        return;
    end

    SucceedMission(GetTime() + 5, "b1_text01.des");
    Mission.m_MissionOver = true;
end
