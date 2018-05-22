#include "AODVsimulator.h"

/**
 * @author Federico Oldani and Valentina Ionata
 * @date   May 10, 2018
 */

configuration AODVsimulatorApp {}
implementation {
  components MainC, AODVsimulator as App;
  components new AMSenderC(AM_RRP_MSG) as SendRRP ;
  components new AMSenderC(AM_DATA_MSG) as SendDATA ;
  components new AMSenderC(AM_RREQ_MSG) as SendRREQ ;
  components new AMReceiverC(AM_RRP_MSG) as ReceiveRRP ;
  components new AMReceiverC(AM_DATA_MSG) as ReceiveDATA ;
  components new AMReceiverC(AM_RREQ_MSG) as ReceiveRREQ ;
  components new TimerMilliC() as MilliTimer;
  components new TimerMilliC() as AcceptReply;
  components ActiveMessageC;
  components RandomC;
  
  App.Boot -> MainC.Boot;
  
  App.ReceiveRRP -> ReceiveRRP;
  App.ReceiveRREQ -> ReceiveRREQ;
  App.ReceiveDATA -> ReceiveDATA;
  App.SendRRP -> SendRRP;
  App.SendRREQ -> SendRREQ;
  App.SendDATA -> SendDATA;
  App.AMControl -> ActiveMessageC;
  App.MilliTimer -> MilliTimer;
  App.Packet -> SendRRP;
  App.Packet -> SendDATA;
  App.Packet -> SendRREQ;
  App.Random -> RandomC;
  App.AcceptReply -> AcceptReply;
}


