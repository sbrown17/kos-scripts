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
    PRINT "Calculating Free Return TLI Maneuver...".
    set munar_transfer_node TO NODE(TimeStamp:(1,13,4,42,9),107.834,0,98.847) // 98.847 m/s(prograde), 0.000 m/s(normal), 107.834 m/s(radial), 13d, 04:42:09
    executeNode(tliNode). // You will need an execution function (see below)
}

function executeNode {
//     parameter nd.
    
    // lock steering to nd:deltav.
    // PRINT "Turning to burn vector...".
    // wait until vdot(facing:vector, nd:deltav:normalized) > 0.99. // Wait until aligned
    
    // // Wait until it's time to burn
    // local burnTime is nd:deltav:mag / (ship:availablethrust / ship:mass).
    // PRINT "Waiting for burn time...".
    // wait until nd:eta <= (burnTime / 2).
    
    // // Burn
    // PRINT "Burning!".
    // lock throttle to min(nd:deltav:mag / (ship:availablethrust / ship:mass), 1.0).
    // wait until nd:deltav:mag < 0.1.
    
    // lock throttle to 0.
    // unlock steering.
    // remove nd.
    // PRINT "TLI Complete. Have a good trip!".


    //we only need to lock throttle once to a certain variable in the beginning of the loop, and adjust only the variable itself inside it
    set tset to 0.
    lock throttle to tset.

    set done to False.
    //initial deltav
    set dv0 to nd:deltav.
    until done
    {
        //recalculate current max_acceleration, as it changes while we burn through fuel
        set max_acc to ship:maxthrust/ship:mass.

        //throttle is 100% until there is less than 1 second of time left to burn
        //when there is less than 1 second - decrease the throttle linearly
        set tset to min(nd:deltav:mag/max_acc, 1).

        //here's the tricky part, we need to cut the throttle as soon as our nd:deltav and initial deltav start facing opposite directions
        //this check is done via checking the dot product of those 2 vectors
        if vdot(dv0, nd:deltav) < 0
        {
            print "End burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).
            lock throttle to 0.
            break.
        }

        //we have very little left to burn, less then 0.1m/s
        if nd:deltav:mag < 0.1
        {
            print "Finalizing burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).
            //we burn slowly until our node vector starts to drift significantly from initial vector
            //this usually means we are on point
            wait until vdot(dv0, nd:deltav) < 0.5.

            lock throttle to 0.
            print "End burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).
            set done to True.
        }
    }
    unlock steering.
    unlock throttle.
    wait 1.

    //we no longer need the maneuver node
    remove nd.

    //set throttle to 0 just in case.
    SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
}

function awaitMunarLaunchPosition {
    // Mun Launch Wait Script
    // TODO: also wait for it to be a "new Mun"
    CLEARSCREEN.
    PRINT "Calculating Mun Phase Angle...".

    SET target_body TO MUN.
    SET target_angle TO 300. 

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