// SOME NOTES:
// Kerbin is ~1/10 that of Earth so I will be using that to simplify altitudes, etc before Munar insertion burn

global stagingRocket TO FALSE.

function main {
    // Write a function to wait until Mun is in proper position for launch... Also... Figure out when Mun is in a proper position to launch...
    awaitMunarLaunchPosition().
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
    PRINT "First perigee raise burn ended. Apogee raising burn ready.".
    apogeeRaisingBurn().
    PRINT "Apogee raise burn ended.".
    munarTransferBurn().
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
    // initial orion orbit is ~160x1900km, actually another source says 185x2253km
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
    // stage fairing
    stageRocket("Rocket"). wait 1.
    // stage launch abort system
    stageRocket("Rocket"). wait 1.
    // next propulsion stage
    stageRocket("Rocket"). wait 1.

    PANELS ON.
    until periapsis > 90000 {
        lock THROTTLE to 1.
    }
    LOCK THROTTLE TO 0.
}

function apogeeRaisingBurn {
    // second orion orbit is ~185x74,000km
    lock steering to PROGRADE.
    lock THROTTLE to 0.
    // burn, and stage, until apoapsis is 7400km 
    PRINT "Wait until periapsis < 2s.".
    set kuniverse:timewarp:rate to 10.
    WAIT UNTIl ETA:PERIAPSIS < 2.
    set kuniverse:timewarp:rate to 1.
    UNTIL APOAPSIS > 7400000 {
        lock THROTTLE to 1.
    }
    LOCK THROTTLE TO 0.
}

function munarTransferBurn {
    lock steering to PROGRADE.
    lock THROTTLE to 0.
    PRINT "Wait until periapsis < 2s.".
    set kuniverse:timewarp:rate to 10.
    WAIT UNTIl ETA:PERIAPSIS < 2.
    set kuniverse:timewarp:rate to 1.
    // figure out when to fire propulsion until... periapsis at the mun perhaps? or maybe the second encounter? have to test and see
    // UNTIL 
}

function awaitMunarLaunchPosition {
    // Mun Launch Wait Script
    // TODO: also wait for it to be a "new Mun"
    CLEARSCREEN.
    PRINT "Calculating Mun Phase Angle...".

    SET target_body TO MUN.
    // try 130 degree angle, this is not direct ascent
    SET target_angle TO 130. 

    UNTIL 0 {
        // Calculate the angle between KSC (Ship Longitude) and the Mun
        SET current_phase TO MOD(target_body:LONGITUDE - SHIP:LONGITUDE + 360, 360).
        
        SET angle_diff TO MOD(current_phase - target_angle + 360, 360).

        CLEARSCREEN.
        PRINT "Target Phase Angle: " + target_angle.
        PRINT "Current Phase:      " + ROUND(current_phase, 2).
        PRINT "Degrees to Window:  " + ROUND(angle_diff, 2).

        IF angle_diff > 5 {
            SET KUNIVERSE:TIMEWARP:RATE TO 100.
        } ELSE IF angle_diff > 2 {
            SET KUNIVERSE:TIMEWARP:RATE TO 5.
        } ELSE {
            SET KUNIVERSE:TIMEWARP:RATE TO 0.
            PRINT "Window Reached! Prepare for Launch.".
            BREAK.
        }
        WAIT 0.1.
    }
}
main().