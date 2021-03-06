void tick_func(void);
extern void triggerSchedWave(unsigned wave_id);
extern double readAI(unsigned chan);
extern unsigned state();
extern void logValue(const char *varname, double val);
extern void logArray(const char *varname, const double *array, uint num_elems);
extern double sqrt(double);
TRISTATE thresh_func(int chan, double v);
void init_func(void);
void start_trial_func(void);
extern int forceJumpToState(unsigned state, int event_id_for_history);

/********************************************************************************
 * TEXT BELOW WILL BE FIND-REPLACED FROM MATLAB PRIOR TO SetStateProgram()
 ********************************************************************************/
double touch_thresh_high = XXX;
double touch_thresh_low = XXX;
static unsigned states_to_log_touch[XXX] = {XXX}; /*list of states in which we want to detect touches for SM*/

/********************************************************************************
 * END: FIND-REPLACE TEXT
 ********************************************************************************/
double vVect1[10];
double vVect2[10];
double mean1 = 0;
double last_mean1 = 0;
double mean2 = 0;
double last_mean2 = 0;
double std1 = 0;
double std2 = 0;
double default_std = 0.05;

int cycCounter = 1;
int debugCounter = 1;
int v_state;
int v_state_last = 0;

/*vars for sensor 1*/
int v_state1;
int v_state1_last = 0;

/* vars for sensor 2*/
int v_state2;
int v_state2_last = 0;

struct wave_id_list { /* scheduled wave IDs  REPLACE WITH ENUM*/
	unsigned touch_onsets;
	unsigned PoleUpWave;
	unsigned cueWave;
	unsigned goWave;
	unsigned noiseWave;
	unsigned rewardWave;
};
struct wave_id_list wave_ids = {.touch_onsets = 0, .PoleUpWave = 1, .cueWave = 3, .goWave = 4, .noiseWave = 5, .rewardWave = 6};

struct varlog_val_list {
	double touch_trig_on;
	double touch_trig_pro_on;
	double touch_trig_ret_on;
	double touch_trig_med_on;
	double touch_trig_lat_on;
	double touch_trig_off;
	double touch_trig_pro_off;
	double touch_trig_ret_off;
	double touch_trig_med_off;
	double touch_trig_lat_off;
};
struct varlog_val_list varlog_vals = {.touch_trig_on = 1.0, .touch_trig_off = -1.0, .touch_trig_pro_on = 1.0, .touch_trig_pro_off = -1.0, .touch_trig_ret_on = 1.0, .touch_trig_ret_off = -1.0, .touch_trig_med_on = 1.0, .touch_trig_med_off = -1.0, .touch_trig_lat_on = 1.0, .touch_trig_lat_off = -1.0};

const unsigned touch_detector_ai_chan1 = 7; /* Analog input channel for axial sensor. */
const unsigned touch_detector_ai_chan2 = 9; /* Analog input channel for radial sensor. */

void tick_func(void){
	
	double v1;
	double v2;

	unsigned curr_state = state();
	unsigned i;

	int n_touch_state;
	int in_touch_state;

	/*USEFUL FOR DEBUGGING*/
	/*log values every 160 cycles, or 15ms
	if (cycCounter == 160) {
		v1 = readAI(1);
		v2 = readAI(2);
	    v3 = readAI(3);
		v4 = readAI(4);
	    v5 = readAI(5);
		v6 = readAI(6);
		v7 = readAI(7);
	    v8 = readAI(8);
		v9 = readAI(9);
		
		logValue("v1", v1); 
		logValue("v2", v2); 
		logValue("v3", v3); 
		logValue("v4", v4); 
		logValue("v5", v5); 
		logValue("v6", v6); 
		logValue("v7", v7); 
		logValue("v8", v8); 
		logValue("v9", v9); 

		cycCounter=0;
	}*/
	
	/*compute sum f squares of voltages from LAST cycle*/
	double sum1sq = 0;
	double sum2sq = 0;
	for (i = 0; i < 10; i++) {
		sum1sq = sum1sq + (vVect1[i]*vVect1[i]);
		sum2sq = sum2sq + (vVect2[i]*vVect1[i]);
	}
	
	/*compute std of voltages from LAST cycle*/
	std1 = sqrt((sum1sq - last_mean1)*(sum1sq - last_mean1));
	std2 = sqrt((sum2sq - last_mean2)*(sum2sq - last_mean2));
	
	
	/*now update the voltage readings*/
	v1 = readAI(touch_detector_ai_chan1);
	v2 = readAI(touch_detector_ai_chan2);
	
	/*fill the circ. buffers*/
	if (cycCounter > 10) {
		cycCounter = 1;
		vVect1[cycCounter-1] = v1;
		vVect2[cycCounter-1] = v2;

	} else {
		vVect1[cycCounter-1] = v1;
		vVect2[cycCounter-1] = v2;
	}
	
	double sum1 = 0;
	double sum2 = 0;	
	/*compute mean of voltages*/
	for (i = 0; i < 10; i++) {
		sum1 = sum1 + vVect1[i];
		sum2 = sum2 + vVect2[i];
	}
	
	mean1 = sum1/10;
	mean2 = sum2/10;
	
	double absdiff1 = sqrt((mean1 - last_mean1)*(mean1 - last_mean1));
	double absdiff2 = sqrt((mean2 - last_mean2)*(mean2 - last_mean2));

	
	/* if we arent in a state where we care about touches controlling SM transitions, dont bother with touch detection code*/
	n_touch_state = sizeof(states_to_log_touch);

	for (i = 0; i <= n_touch_state - 1; i++) {
		if (curr_state == states_to_log_touch[i]) {
			in_touch_state = 1;
		}
	}
	

	/*USEFUL FOR DEBUGGING*/
	/*log values every 160 cycles, or 15ms*/
	/*if (cycCounter == 160) {
		logValue("mean1_abs", mean1); 
		logValue("baseMean1_abs", baseMean1); 
		logValue("std1", std1); 
	
		logValue("mean2_abs", mean2); 
		logValue("baseMean2_abs", mean2); 
		logValue("std2", std2); 
	
		logValue("v_state", v_state); 
		logValue("v_state1", v_state1); 
		logValue("v_state2", v_state2); 
		
		logArray("vVect1", vVect1, 36); 
		logArray("vVect2", vVect2, 36); 
		
		cycCounter2=0;
	}
	
	logArray("vVect1", vVect1, 36); 
	logArray("vVect2", vVect2, 36); 
	*/
	
	/*thresholding for sensor 1*/
	if (v1 >= 0.2) {
		v_state1 = 1;
	} else if (v1 <= -0.2) {
		v_state1 = -1;
	} else {
		v_state1 = 0;
	}
	
	/*thresholding for sensor 2*/
	if (v2 > 0.021) {
		v_state2 = 1;
	} else if (v2 < -0.21) {
		v_state1 = 1;
	} else {
		v_state2 = 0;
	}
	
	/*thresholding for combined absolute voltage on both sensors*/
	if (absdiff1 > 0.0027) {
		v_state = 1;
	}
	else {
		v_state = 0;
	}

	/*raise pole at entry into state 42*/
	if (curr_state == 43) { 
			triggerSchedWave(wave_ids.PoleUpWave);
	}

	/*jump to new trial if touch during delay*/
	if (curr_state == 46) { 
		if (v_state == 1 && v_state_last != 1) { 
			triggerSchedWave(wave_ids.noiseWave); 
			forceJumpToState(54, 1); 
			logValue("touch_trig_pro_on", varlog_vals.touch_trig_pro_on);

		}
	}
	
	/*if touch after delay, proceed*/
	if (curr_state == 47) {
		if (v_state == 1 && v_state_last != 1) { 
			triggerSchedWave(wave_ids.touch_onsets); 
			forceJumpToState(48, 1);
			logValue("touch_trig_pro_on", varlog_vals.touch_trig_pro_on); 
			triggerSchedWave(wave_ids.rewardWave); /*soudns rew cue after a delay set in matlab*/
		} else if (v_state1 == 0 && v_state1_last != 0) { 
			/*logValue("touch_trig_pro_off", varlog_vals.touch_trig_pro_off); */ 
		} else if (v_state1 == -1 && v_state1_last != 1) { 
			/*triggerSchedWave(wave_ids.touch_onsets); */
			/*logValue("touch_trig_ret_on", varlog_vals.touch_trig_ret_on);  */
		} else if (v_state1 == 0 && v_state1_last !=0) { 
			/*logValue("touch_trig_ret_off", varlog_vals.touch_trig_ret_off);*/  
		} else if (v_state2 == 1 && v_state2_last != 1) {
			/*triggerSchedWave(wave_ids.touch_onsets); */
			/*logValue("touch_trig_med_on", varlog_vals.touch_trig_med_on); */
		} else if (v_state2 == 0 && v_state2_last != 0) { 
			/*logValue("touch_trig_med_off", varlog_vals.touch_trig_med_off);  */
		} else if (v_state2 == -1 && v_state2_last != 1) { 
			/*triggerSchedWave(wave_ids.touch_onsets); */
			/*logValue("touch_trig_lat_on", varlog_vals.touch_trig_lat_on); */ 
		} else if (v_state2 == 0 && v_state2_last != 0) { 
			/*logValue("touch_trig_lat_off", varlog_vals.touch_trig_lat_off);*/  
		} else if (v_state == 0 && v_state_last != 0) { 
			/*logValue("touch_trig_off", varlog_vals.touch_trig_off); */
		}
	}
	cycCounter = cycCounter + 1;
	
	/*
	if (debugCounter == 12) {
		logValue("mean1",mean1);
		logValue("absdiff1",absdiff1);
		debugCounter = 0;
	}
*/
	debugCounter++;
	
	
	v_state1_last = v_state1;
	v_state2_last = v_state2;
	v_state_last = v_state;
	last_mean1 = mean1;
	last_mean2 = mean2;
}

void start_trial_func(void) {
	
	logValue("entered_state_40", 1.0); /* Useful time stamp. */
	
}

void init_func(void) {


}

/* Want to configure second analog input channel (beyond lickport channel)
* with SetInputEvents.m in order to (1)
* read in whisker position with readAI(); and (2) to record times of stimulation
* using scheduled waves event triggering. These events get recorded and made
* available to MATLAB as input events on this second channel.  We *don't* however
* want actual input events to get triggered on this channel.  Thus, we re-define
* the built-in threshold detection function in order to detect events *only* on
* the lickport channel.
*/
TRISTATE thresh_func(int chan, double v) 
{
    if (chan == 0 || chan == 1) { /* Lickport input channels = hardware channels 0 and 1*/
        if (v >= 4.0) return POSITIVE;  /* if above 4.0 V, above threshold */
        if (v <= 3.0) return NEGATIVE;  /* if below 3.0, below threshold */
        return NEUTRAL; /* otherwise unsure, so no change */
    }
    else {
        return NEUTRAL; /* Do not allow "beam-break" events on non-lickport channel */
    }
}
