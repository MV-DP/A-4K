
# Update period for systems loop
UPDATE_PERIOD = 0.2;


# =============================== Pilot G stuff======================================

pilot_g = props.globals.getNode("accelerations/pilot-g", 1);
timeratio = props.globals.getNode("accelerations/timeratio", 1);
pilot_g_damped = props.globals.getNode("accelerations/pilot-g-damped", 1);

pilot_g.setDoubleValue(0);
pilot_g_damped.setDoubleValue(0);
timeratio.setDoubleValue(0.03);

var g_damp = 0;

updatePilotG = func {
        var n = timeratio.getValue();
	var g = pilot_g.getValue() ;

	g_damp = ( g * n) + (g_damp * (1 - n));

	pilot_g_damped.setDoubleValue(g_damp);

# print(sprintf("pilot_g_damped in=%0.5f, out=%0.5f", g, g_damp));

        settimer(updatePilotG, 0.1);

} #end updatePilotG()

updatePilotG();

# headshake - this is a modification of the original work by Josh Babcock

# Define some stuff with global scope

xConfigNode = '';
yConfigNode = '';
zConfigNode = '';

xAccelNode = '';
yAccelNode = '';
zAccelNode = '';

var xDivergence_damp = 0;
var yDivergence_damp = 0;
var zDivergence_damp = 0;

var last_xDivergence = 0;
var last_yDivergence = 0;
var last_zDivergence = 0;

# Make sure that some vital data exists and set some default values
enabledNode = props.globals.getNode("/sim/headshake/enabled", 1);
enabledNode.setBoolValue(1);

xMaxNode = props.globals.getNode("/sim/headshake/x-max-m",1);
xMaxNode.setDoubleValue( 0.025 );

xMinNode = props.globals.getNode("/sim/headshake/x-min-m",1);
xMinNode.setDoubleValue( -0.01 );

yMaxNode = props.globals.getNode("/sim/headshake/y-max-m",1);
yMaxNode.setDoubleValue( 0.01 );

yMinNode = props.globals.getNode("/sim/headshake/y-min-m",1);
yMinNode.setDoubleValue( -0.01 );

zMaxNode = props.globals.getNode("/sim/headshake/z-max-m",1);
zMaxNode.setDoubleValue( 0.01 );

zMinNode = props.globals.getNode("/sim/headshake/z-min-m",1);
zMinNode.setDoubleValue( -0.03 );

view_number_Node = props.globals.getNode("/sim/current-view/view-number",1);
view_number_Node.setDoubleValue( 0 );

time_ratio_Node = props.globals.getNode("/sim/headshake/time-ratio",1);
time_ratio_Node.setDoubleValue( 0.003 );

seat_vertical_adjust_Node = props.globals.getNode("/controls/seat/vertical-adjust",1);
seat_vertical_adjust_Node.setDoubleValue( 0 );

xThreasholdNode = props.globals.getNode("/sim/headshake/x-threashold-g",1);
xThreasholdNode.setDoubleValue( 0.5 );

yThreasholdNode = props.globals.getNode("/sim/headshake/y-threashold-g",1);
yThreasholdNode.setDoubleValue( 0.5 );

zThreasholdNode = props.globals.getNode("/sim/headshake/z-threashold-g",1);
zThreasholdNode.setDoubleValue( 0.5 );

# We will use these later
xConfigNode = props.globals.getNode("/sim/view/config/z-offset-m");
yConfigNode = props.globals.getNode("/sim/view/config/x-offset-m");
zConfigNode = props.globals.getNode("/sim/view/config/y-offset-m");

xAccelNode = props.globals.getNode("/accelerations/pilot/x-accel-fps_sec",1);
xAccelNode.setDoubleValue( 0 );
yAccelNode = props.globals.getNode("/accelerations/pilot/y-accel-fps_sec",1);
yAccelNode.setDoubleValue( 0 );
zAccelNode = props.globals.getNode("/accelerations/pilot/z-accel-fps_sec",1);
zAccelNode.setDoubleValue(-32 );


headShake = func {

    # First, we don't shake outside the vehicle. Inside, we boogie down.
    # There are two coordinate systems here, one used for accelerations, and one used for the viewpoint.
    # We will be using the one for accelerations.
    var enabled = enabledNode.getValue();
    var view_number= view_number_Node.getValue();
    var n = timeratio.getValue();
    var seat_vertical_adjust = seat_vertical_adjust_Node.getValue();


    if ( (enabled) and ( view_number == 0)) {

	var xConfig = xConfigNode.getValue();
        var yConfig = yConfigNode.getValue();
        var zConfig = zConfigNode.getValue();

        var xMax = xMaxNode.getValue();
        var xMin = xMinNode.getValue();
        var yMax = yMaxNode.getValue();
        var yMin = yMinNode.getValue();
        var zMax = zMaxNode.getValue();
        var zMin = zMinNode.getValue();

	#work in G, not fps/s
        var xAccel = xAccelNode.getValue()/32;
        var yAccel = yAccelNode.getValue()/32;
        var zAccel = (zAccelNode.getValue() + 32)/32; # We aren't counting gravity

	var xThreashold =  xThreasholdNode.getValue();
	var yThreashold =  yThreasholdNode.getValue();
	var zThreashold =  zThreasholdNode.getValue();

        # Set viewpoint divergence and clamp
        # Note that each dimension has it's own special ratio and +X is clamped at 1cm
        # to simulate a headrest.

        if (xAccel < -1) {
            xDivergence = ((( -0.0506 * xAccel ) - ( 0.538 )) * xAccel - ( 0.9915 )) * xAccel - 0.52;
        } elsif (xAccel > 1) {
            xDivergence = ((( -0.0387 * xAccel ) + ( 0.4157 )) * xAccel - ( 0.8448 )) * xAccel + 0.475;
        }else {
	    xDivergence = 0;
	}
#        setprop("/sim/current-view/z-offset-m", (xConfig + xDivergence));

        if (yAccel < -0.5) {
            yDivergence = ((( -0.013 * yAccel ) - ( 0.125 )) * yAccel - (  0.1202 )) * yAccel - 0.0272;
            } elsif (yAccel > 0.5) {
            yDivergence = ((( -0.013 * yAccel ) + ( 0.125 )) * yAccel - (  0.1202 )) * yAccel + 0.0272;
        }else {
	    yDivergence = 0;
	}
#        setprop("/sim/current-view/x-offset-m", (yConfig + yDivergence));

        if (zAccel < -1) {
	    zDivergence = ((( -0.0506 * zAccel ) - ( 0.538 )) * zAccel - ( 0.9915 )) * zAccel - 0.52;
        } elsif (zAccel > 1) {
            zDivergence = ((( -0.0387 * zAccel ) + ( 0.4157 )) * zAccel - ( 0.8448 )) * zAccel + 0.475;
	} else {
	    zDivergence = 0;
        }


	xDivergence_total = ( xDivergence * 0.25 ) + ( zDivergence * 0.25 );
	if (xDivergence_total > xMax){xDivergence_total = xMax;}
        if (xDivergence_total < xMin){xDivergence_total = xMin;}

	if (abs(last_xDivergence - xDivergence_total) <= xThreashold){
	        xDivergence_damp = ( xDivergence_total * n) + ( xDivergence_damp * (1 - n));
	#	print ("x low pass");
	} else {
		xDivergence_damp = xDivergence_total;
	#	print ("x high pass");
	}

	last_xDivergence = xDivergence_damp;

#print (sprintf("x total=%0.5f, x min=%0.5f, x div damped=%0.5f", xDivergence_total, xMin , xDivergence_damp));

	yDivergence_total = yDivergence;
        if (yDivergence_total >= yMax){yDivergence_total = yMax;}
        if (yDivergence_total <= yMin){yDivergence_total = yMin;}

	if (abs(last_yDivergence - yDivergence_total) <= yThreashold){
		yDivergence_damp = ( yDivergence_total * n) + ( yDivergence_damp * (1 - n));
       	# 	print ("y low pass");
	} else {
		yDivergence_damp = yDivergence_total;
	#	print ("y high pass");
	}

	last_yDivergence = yDivergence_damp;

#print (sprintf("y=%0.5f, y total=%0.5f, y min=%0.5f, y div damped=%0.5f",yDivergence, yDivergence_total, yMin , yDivergence_damp));

	zDivergence_total =  xDivergence + zDivergence;
        if (zDivergence_total >= zMax){zDivergence_total = zMax;}
        if (zDivergence_total <= zMin){zDivergence_total = zMin;}

	if (abs(last_zDivergence - zDivergence_total) <= zThreashold){
        	zDivergence_damp = ( zDivergence_total * n) + ( zDivergence_damp * (1 - n));
        #        print ("z low pass");
	} else {
		zDivergence_damp = zDivergence_total;
	#	print ("z high pass");
	}

	last_zDivergence = zDivergence_damp;

#print (sprintf("z total=%0.5f, z min=%0.5f, z div damped=%0.5f", zDivergence_total, zMin , zDivergence_damp));

	setprop("/sim/current-view/z-offset-m", xConfig + xDivergence_damp );
        setprop("/sim/current-view/x-offset-m", yConfig + yDivergence_damp );
	setprop("/sim/current-view/y-offset-m", zConfig + zDivergence_damp + seat_vertical_adjust );
    }
    settimer(headShake,0 );

}

headShake();
# ======================================= end Pilot G stuff ============================


# Weapons handling
var master = props.globals.getNode("controls/armament/master", 1);
var gun = props.globals.getNode("controls/armament/guns", 1);
var fire_cannon = props.globals.getNode("controls/armament/trigger-cannon", 1);
var nosetail = props.globals.getNode("controls/armament/nose-tail", 1);
var function_select = props.globals.getNode("controls/armament/function-select", 1);
var emergency_function_select = props.globals.getNode("controls/armament/emergency-function-select", 1);
var stations = props.globals.getNode("/controls/armament").getChildren("station");


setlistener("/controls/armament/trigger", func(n) {
  if (master.getValue()) {
	if (gun.getValue()) {
	  fire_cannon.setBoolValue(n.getValue());
	}

	if (function_select.getValue() == 1) {
	  # Rockets armed
	  foreach (var station; stations) {
		if (station.getNode("selected", 1).getValue() == 1)
		{
		  station.getNode("release-rocket", 1).setBoolValue(n.getValue());
		}
	  }
	}
  }
});

setlistener("/controls/armament/bomb", func(n) {
  if (master.getValue()) {
	if ((function_select.getValue() == 5) and (nosetail.getValue() != 0)) {
	  # Bombs armed
	  foreach (var station; stations) {
		if (station.getNode("selected", 1).getValue() == 1)
		{
		  station.getNode("release-stick", 1).setBoolValue(n.getValue());
		}
	  }
	}
  }
});

# Listeners for TER carrying 3 Mk82 bombs, which are released individually.
setlistener("controls/armament/station[1]/release-stick", func(n) {
  if (getprop("controls/armament/station[1]/release-stick-1") == 0) {
		setprop("controls/armament/station[1]/release-stick-1", 1);
		setprop("/sim/weight[1]/weight-lb", 531 + 531 + 105);
  } else if (getprop("controls/armament/station[1]/release-stick-2") == 0) {
		setprop("controls/armament/station[1]/release-stick-2", 1);
		setprop("/sim/weight[1]/weight-lb", 531 + 105);
  } else if (getprop("controls/armament/station[1]/release-stick-3") == 0) {
		setprop("controls/armament/station[1]/release-stick-3", 1);
		setprop("/sim/weight[1]/weight-lb", 105);
  }
});

setlistener("controls/armament/station[3]/release-stick", func(n) {
  if (getprop("controls/armament/station[3]/release-stick-1") == 0) {
		setprop("controls/armament/station[3]/release-stick-1", 1);
		setprop("/sim/weight[3]/weight-lb", 531 + 531 + 105);
  } else if (getprop("controls/armament/station[3]/release-stick-2") == 0) {
		setprop("controls/armament/station[3]/release-stick-2", 1);
		setprop("/sim/weight[3]/weight-lb", 531 + 105);
  } else if (getprop("controls/armament/station[3]/release-stick-3") == 0) {
		setprop("controls/armament/station[3]/release-stick-3", 1);
		setprop("/sim/weight[3]/weight-lb", 105);
  }
});

# Listeners to handle droptanks being dropped - need to set fuel contents appropriately.
setlistener("/controls/armament/station[2]/release-stick", func(n) {
  setprop("/consumables/fuel/tank[3]/level-gal_us", 0.0);
  setprop("/sim/weight[2]/weight-lb", 0.0);
});

# Auto-armed spoilers
var spoilers = props.globals.getNode("controls/flight/spoilers", 1);
var spoilers_armed = props.globals.getNode("controls/flight/spoilers-armed", 1);
var throttle = props.globals.getNode("controls/engines/engine[0]/throttle", 1);
var left_main_wow = props.globals.getNode("gear/gear[1]/wow", 1);

var updateSpoilers = func {
	if (spoilers_armed.getValue() and
		left_main_wow.getValue() and
		(throttle.getValue() < 0.7))
	{
		spoilers.setValue(1);
	} else {
		spoilers.setValue(0);
	}
}

var spoiler_light = props.globals.getNode("sim/alarms/spoiler", 1);
var spoiler_pos = props.globals.getNode("surface-positions/spoiler-pos-norm", 1);

var speedbrake_light = props.globals.getNode("sim/alarms/speedbrake", 1);
var speedbrake_pos = props.globals.getNode("surface-positions/speedbrake-pos-norm", 1);
var gear_light = props.globals.getNode("sim/alarms/gear", 1);
var gear_pos = props.globals.getNode("gear/gear[0]/position-norm", 1);

var updateWarningLights = func {
	spoiler_light.setValue(spoiler_pos.getValue() > 0.0 ? 1 : 0);
	speedbrake_light.setValue(speedbrake_pos.getValue() > 0.0 ? 1 : 0);

	if ((gear_pos.getValue() > 0.01) and (gear_pos.getValue() < 0.99)) {
		gear_light.setValue(1.0);
	} else {
		gear_light.setValue(0.0);
	}
}

# APC should adjust throttle depending on the AoA. This is a much simpler
# system than (say) the F-14b, so no need for a proper PID.

var APCState = props.globals.getNode("/controls/engines/engine[0]/apc",1);
var AOASlow = props.globals.getNode("sim/aoa-indexer/slow-deg", 1);
var AOAFast = props.globals.getNode("sim/aoa-indexer/fast-deg", 1);
var AOA = props.globals.getNode("orientation/alpha-deg",1);
var throttleProp = props.globals.getNode("/controls/engines/engine/throttle");
var thrustProp = props.globals.getNode("engines/engine/n2");
var wow = props.globals.getNode("gear/gear[1]/wow");

# Throttle adjustment rate per second.
var THROTTLE_RATE = 0.1;

var updateAPC = func {
	if (APCState.getValue()) {
		# Disengage if:
		# - weight on the main gear
		# - rpm < 70%
		# - Over-ride of 25-30lbs force (simulated as 100% throttle)
		if ((wow.getBoolValue())            or
		    (thrustProp.getValue() < 0.7) or
		    (throttleProp.getValue() > 0.98)  ) {
			APCState.setBoolValue(0);
			return;
		}

		var throttle = throttleProp.getValue();

		if (AOA.getValue() > AOASlow.getValue()) {
			# Reduce throttle
			throttle = throttle + THROTTLE_RATE * UPDATE_PERIOD;
		}

		if (AOA.getValue() < AOAFast.getValue()) {
			# Increase throttle
			throttle = throttle - THROTTLE_RATE * UPDATE_PERIOD;
		}

		# Limit throttle travel to ensure we don't go out of bounds
		if (throttle > 0.98) { throttle = 0.97; }

		throttleProp.setValue(throttle);
	}	
}
var main_loop = func {
	updateSpoilers();
	updateWarningLights();
	updateAPC();
	settimer(main_loop, UPDATE_PERIOD);
}

settimer(main_loop, UPDATE_PERIOD);

# controls.nas overrides.

# No manual spoiler control. This only arms the spoilers.
controls.stepSpoilers = func(step) {
	if (step > 0) {
		spoilers_armed.setValue(1);
	} else {
		spoilers_armed.setValue(0);
	}
}

# Flaps have no detents.
var flaps = props.globals.getNode("/controls/flight/flaps");
var delta = props.globals.getNode("/sim/time/delta-realtime-sec");
controls.flapsDown = func(step) {
	flaps.setValue(flaps.getValue() + step * 0.33 * delta.getValue());
}

# But should be repeatable
var keys = props.globals.getNode("/input/keyboard").getChildren("key");
foreach (var key; keys) {
	var script = key.getNode("binding/script");
	if ((script != nil) and 
            ((script.getValue() == "controls.flapsDown(1)") or
             (script.getValue() == "controls.flapsDown(-1)")  ))
	{
		key.getNode("repeatable", 1).setValue("true");
	}
}

var sticks = props.globals.getNode("/input/joysticks").getChildren("js");
foreach (var js; sticks) {
	var buttons = js.getChildren("button");
	foreach (var button; buttons) {
		var script = button.getNode("binding/script");
		if ((script != nil) and 
        	    ((script.getValue() == "controls.flapsDown(1)") or
	             (script.getValue() == "controls.flapsDown(-1)")  ))
		{
			button.getNode("repeatable", 1).setValue("true");
		}
	}
}

# Gear cannot be raised if wow on left main strut
var gear_pos = props.globals.getNode("gear/gear[0]/position-norm", 1);
controls.gearDown = func(v) {
    if ((v < 0) and (getprop("/gear/gear[1]/wow") == 0)) {
		setprop("/controls/gear/gear-down", 0);
    } elsif (v > 0) {
		setprop("/controls/gear/gear-down", 1);
    }
}



