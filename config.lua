-- Types of missions:
-- goto: Go to a location and interact with a ped
-- GTA: Steal a car and deliver it to a location
-- Karma is meant to be used to determine what kind of missions you get. If you have negative karma, you will get more illegal missions.

Config = {
-- If pickupitem is empty, not item is needed for the mission to be completed.
Missions = {
    ['mission1'] = {
        name = "StartMission",
        model = "a_m_y_epsilon_01",
        startCoord = vector4(-910.39, -1288.24, 5.01, 133.68),
        targetEvent = "hz-mission:intro:startMission",
        targetIcon = "fa-solid fa-hand",
        targetText = "Start mission",
        type = "goto",
        destination = vector4(-935.19, -1287.32, 5.03, 303.03),
        destinationModel = 'a_m_m_prolhost_01',
        destinationText = 'Lever nøkler',
        finishEvent = "hz-mission:finishMission",
        itemReward = "advancedlockpick",
        finishedMessage = "Du fullførte oppdraget, du fikk et avansert dirkesett.",
        pickupItem = "",
        levelRequirement = 0,
        karma = 1

    },

    ['mission2'] = {
        name = "StartMission2",
        model = "a_m_m_malibu_01",
        startCoord = vector4(-914.98, -1291.68, 5.02, 309.1),
        targetEvent = "hz-mission:gta:startMission",
        targetIcon = "fa-solid fa-hand",
        targetText = "Stjel bil",
        type = "gta",
        destination = vector4(-931.14, -1297.89, 5.02, 113.46),
        destinationModel = 'a_m_y_epsilon_01',
        destinationText = 'Lever',
        finishEvent = "hz-mission:finishMission",
        itemReward = "",
        finishedMessage = "Du fullførte oppdraget, du fikk et avansert dirkesett.",
        carModel = 'dubsta',
        carDeliverDestination = vector4(-954.7, -1287.38, 5.03, 118.74),
        carName = 'Oppdrag',
        paymentType = "bank",
        rewardAmount = "1000",
        levelRequirement = 2,
        description = "Test mission for GTA mission using ox lib for menu.",
        karma = -1

    },

    ['mission3'] = {
        name = "StartMission3",
        model = "a_m_m_malibu_01",
        startCoord = vector4(-528.39, -2873.7, 6.0, 167.75),
        targetEvent = "hz-mission:post:startMission",
        targetIcon = "fa-solid fa-hand",
        targetText = "Ran posten",
        type = "post",
        destination = vector4(-523.91, -2865.61, 5.9, 46.28),
        destinationModel = 'a_m_y_epsilon_01',
        destinationText = 'Ran',
        finishEvent = "hz-mission:finishMission",
        itemReward = "advancedlockpick",
        finishedMessage = "Du fullførte oppdraget, du fikk et avansert dirkesett.",
        carModel = 'BOXVILLE2',
        carName = 'Ran'

    },
}
}