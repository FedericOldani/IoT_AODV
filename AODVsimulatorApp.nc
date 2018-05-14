#include "AODVsimulator.h"

/**
 * @author Federico Oldani and Valentina Ionata
 * @date   May 10, 2018
 */

configuration AODVsimulatorApp {}
implementation {
  components MainC, AODVsimulator as App, LedsC;
  components new AMSenderC(AM_RADIO_MSG);
  components new AMReceiverC(AM_RADIO_MSG);
  components new TimerMilliC();
  components ActiveMessageC;
  components RandomC;
  
  App.Boot -> MainC.Boot;
  
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.MilliTimer -> TimerMilliC;
  App.Packet -> AMSenderC;
  App.Random -> RandomC;
}


