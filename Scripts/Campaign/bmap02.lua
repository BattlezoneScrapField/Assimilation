--[[
    Borg 02 Lua Mission Script
    Written by AI_Unit
--]]

-- Objectives.
local BuildObjective1 = "Build a Constructor";
local BuildObjective2 = "Build a Refinery";
local BuildObjective3 =
"Build a Tug and tow the pod back to the refinery. If you have no scrap, demolish a Relay Bunker with the Constructor.";
local NavObjective = "Place a Nav Beacon near the refinery and another by a pod to send the Tug there and back faster.";
local RecyclerObjective = "Demolish some buildings for scrap if you need to.";
local GateChargingObjective = "Gate is charging. It'll be ready in 5 minutes.";
local GateReadyObjectives = "Gate is ready. Get in it NOW.";
local PodsObjectives = "Collect all pods.";

-- Mission important variables.
local Mission = {
    m_MissionTime = 0,
    m_MissionDifficulty = 0,

    m_PlayerTeam = 1,
    m_AlliedTeam = 2,
    m_EnemyTeam = 5,

    m_MainPlayer = nil,

    m_Scout1 = nil,
    m_Scout2 = nil,
    m_Man = nil,
    m_Recycler = nil,
    m_Pod1 = nil,
    m_Pod2 = nil,
    m_Pod3 = nil,
    m_Pod4 = nil,
    m_Pod5 = nil,
    m_StarPort = nil,

    m_ConstructorObjectiveCompleted = false,
    m_RefineryObjectiveCompleted = false,
    m_RefineryActive = false,
    m_TugBuilt = false,
    m_MissionOver = false,

    m_MissionDelayTime = 0,

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
    PreloadODF("b_isdf_recy");
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
    local className = GetClassLabel(h);
    local odfName = GetCfg(h);

    if (teamNum == Mission.m_PlayerTeam) then
        SetSkill(h, 3);

        print(className);
        print(odfName);

        if (className == "CLASS_CONSTRUCTIONRIG") then
            ClearObjectives();
            AddObjective(BuildObjective1, "GREEN");
            AddObjective(BuildObjective2, "WHITE");
            AddObjective(RecyclerObjective, "PURPLE");
            Mission.m_ConstructorObjectiveCompleted = true;
        elseif (odfName == "ibrefin") then
            ClearObjectives();
            AddObjective(BuildObjective3, "WHITE");
            Mission.m_RefineryObjectiveCompleted = true;
        elseif (className == "CLASS_TUG") then
            ClearObjectives();
            AddObjective(NavObjective, "WHITE");
            Mission.m_TugBuilt = true;
        end
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

    RefineryBrain();
end

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Mission Related Logic --------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
Functions[1] = function()
    -- TODO: Add the IFace logic.

    Ally(1, 2);

    Mission.m_Scout1 = BuildObject("ivscout", Mission.m_AlliedTeam, "recy");
    Mission.m_Scout2 = BuildObject("ivscout", Mission.m_PlayerTeam, "recy");
    Mission.m_Man = BuildObject("ispilo", Mission.m_AlliedTeam, "man");

    Mission.m_Pod1 = BuildObject("R_podS", 0, "pod1");
    Mission.m_Pod2 = BuildObject("R_podS", 0, "pod2");
    Mission.m_Pod3 = BuildObject("R_podS", 0, "pod3");
    Mission.m_Pod4 = BuildObject("R_podS", 0, "pod4");
    Mission.m_Pod5 = BuildObject("R_podS", 0, "pod5");

    Mission.m_StarPort = GetHandle("unnamed_ivstarp");
    Mission.m_Recycler = BuildObject("b_isdf_recy", Mission.m_PlayerTeam, "recy");

    SetScrap(Mission.m_PlayerTeam, 100);

    -- Remove the player ODF that is saved as part of the BZN.
    local PlayerEntryH = GetPlayerHandle(1);

    if (PlayerEntryH ~= nil) then
        RemoveObject(PlayerEntryH);
    end

    Mission.m_MainPlayer = BuildObject("ivscout", Mission.m_PlayerTeam, "recy");
    AddPilotByHandle(Mission.m_MainPlayer);
    SetAsUser(Mission.m_MainPlayer, Mission.m_PlayerTeam);

    AudioMessage("isdf1201.wav");
    CameraReady();

    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[2] = function()
    local camPathDone = CameraPath("campath", 1000, 500, Mission.m_Man);

    if (camPathDone == false) then
        return;
    end

    CameraFinish();

    RemoveObject(Mission.m_Man);

    ClearObjectives();
    AddObjective(BuildObjective1, "WHITE");

    AudioMessage("b_scrap_1.wav");

    Mission.m_MissionDelayTime = Mission.m_MissionTime + SecondsToTurns(7);
    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[3] = function()
    if (Mission.m_MissionDelayTime > Mission.m_MissionTime) then return end;

    AddObjective(BuildObjective2, "WHITE");
    AddObjective(RecyclerObjective, "PURPLE");

    AudioMessage("b_scrap_2.wav");
    Goto(Mission.m_Scout1, "scout1", 1);

    Mission.m_MissionState = Mission.m_MissionState + 1;
end

Functions[4] = function()

end

function AttackBrain()

end

function RefineryBrain()
    if (Mission.m_RefineryActive == false) then return end;

    -- Check to see if the first pod is around.
    if (IsAround(Mission.m_Pod1)) then
        if (GetDistance(Mission.m_Pod1, Mission.m_Refinery) < 70) then

        end
    end

    if (IsAround(Mission.m_Pod2)) then

    end

    if (IsAround(Mission.m_Pod3)) then

    end

    if (IsAround(Mission.m_Pod4)) then

    end

    if (IsAround(Mission.m_Pod5)) then

    end
end
