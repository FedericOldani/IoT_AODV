
#include "Timer.h"
#include "RadioCountToLeds.h"
 
/**
 * @author Federico Oldani, Valentina Ionata
 * @date   May 10 2018
 */

module AODVsimulator @safe() {
  uses {
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface SplitControl as AMControl;
    interface Packet;
  }
}
implementation {

  message_t packet;
 
  bool locked; //ci serve?
  uint16_t counter = 0; //da eliminare
  
  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      call MilliTimer.startPeriodic(3000); //every 30 sec, a data msg is sent
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }
  
  event void MilliTimer.fired() {
    counter++;//da eliminare
    dbg("AODVsimulator", "AODVsimulator: timer fired, send msg");
    if (locked) { //?
      return;
    }
    else {
      radio_data_msg_t* rdm = (radio_data_msg_t*)call Packet.getPayload(&packet, sizeof(radio_data_msg_t));
      if (rcm == NULL) {
	return;
      }
      rcm->dest= ; //inserire random destination 
      rcm->content = ;//inserire random content
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_data_msg_t)) == SUCCESS) {
	dbg("AODVsimulator", "AODVsimulator: packet sent.\n");	
	locked = TRUE;//??
      }
    }
  }

  event message_t* Receive.receive(message_t* bufPtr, 
				   void* payload, uint8_t len) {
    dbg("AODVsimulator", "Received packet of length %hhu.\n", len);
    if (len == sizeof(radio_data_msg_t)) {
      radio_data_msg_t* rdm = (radio_data_msg_t*)payload;
	//1. sono io la destinazione? 
	//	si: fine 
	//	no: check routing table e invio al next hop (se non c'è nella routing table invia route req)
	call Leds.led0On(); //modificare con nome led corretto
	dbg("AODVsimulator", "AODVsimulator: data msg received.\n");
      return bufPtr;
       }
    else if(len == sizeof(route_req_t)){
	route_req_t* rq = (route_req_t*)payload;
	//1. check route_req_id
	//2. new ID: 
	//	2a. sono la destinazione? no: broadcast, si: route_reply al mittente 
	//3. otherwise discard it.
    } 
    else if(len == sizeof(route_reply){
	//se arriva entro 1 sec dal route_req:
	// è la route_reply con meno hop? si: mantieni, no:scarta
	//se arriva dopo: scarta
	}
	else return bufPtr;
}

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;//??
    }
  }

}




