// SOME NOTES:
// Kerbin is ~1/10 that of Earth so I will be using that to simplify altitudes, etc before Munar insertion burn


global stagingRocket TO FALSE.

function main {
    // Write a function to wait until Mun is in proper position for launch... Also... Figure out when Mun is in a proper position to launch...
    // waitFunction().
    launchStart().
    print "Lift Off!".
    ascentGuidance().
    // 180km should give enough leeway to make 190 during the periapsis raise
    until apoapsis > 185000 {
        PRINT "Monitoring Ascent Staging...".
        ascentStaging().
    }
    
    // modify circ burn to be perigee raising burn after main stage separation
    PRINT "First perigee raise burn commencing.".
    perigeeRaisingBurn().
    PRINT "First perigee raise burn ended. Second burn ready.".
    secondPerigeeRaisingBurn().
    PRINT "Second perigee raise burn ended.".
    // munarTransferBurn().
}

function launchStart {
    sas OFF.
    print "Guidance Internal".
    lock throttle to 1.
    for i in range(0,5){
        print "Countdown: " + (5 - i).
        wait 1.
    }
    print "All systems go.".
    stageRocket("Launch").
}

function stageRocket {
    parameter stageName.

    wait until stage:ready.
    SET stagingRocket TO TRUE.
    PRINT "Staging " + stageName + "...".
    stage.
    SET stagingRocket TO FALSE.
}

function ascentGuidance {
    PRINT "Ascent Guidance Operational...".
    lock targetPitch to 88.963 - 1.03287 * alt:radar^0.409511.
    lock steering to heading(90, targetPitch).
}

function ascentStaging {
    if not(defined oldThrust) {
        global oldThrust is ship:availablethrust.
    }
    if ship:availablethrust < (oldThrust - 10) {
        until false {
            stageRocket("Rocket"). wait 1.
            // abortSystemMonitor().
            if ship:availableThrust > 0 { 
            break.
            }
        }
        global oldThrust is ship:availablethrust.
    }
}

function perigeeRaisingBurn {
    // initial orion orbit is ~160x1900km
    // below 70km is atmo on Kerbin

    lock steering to PROGRADE.
    lock THROTTLE to 0.
    // burn, and stage, until periapsis is 90km 
    PRINT "Wait until apoapsis < 2s.".
    set kuniverse:timewarp:rate to 10.
    WAIT UNTIl ETA:APOAPSIS < 2.
    set kuniverse:timewarp:rate to 1.
    until periapsis > 40000 {
        lock THROTTLE to 1.
    }
    LOCK THROTTLE TO 0.
    // this first one pops the fairing, maybe find a more appropriate way to do this. eg wait until alt is >70000 to pop or something
    stageRocket("Rocket"). wait 1.
    // then stage launch abort system off of ship
    stageRocket("Rocket"). wait 1.
    // now onto the next rocket stage
    stageRocket("Rocket"). wait 1.
    until periapsis > 90000 {
        lock THROTTLE to 1.
    }
    LOCK THROTTLE TO 0.
}

function secondPerigeeRaisingBurn {

}

main().