
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
    interface Timer<TMilli> as Timer2;
    interface SplitControl as AMControl;
    interface Packet;
  }
}
implementation { //variabili globali

  message_t packet;
  uint16_t N=6; //number of nodes
  uint16_t current_node=TOS_NODE_ID; //number of this node
  bool locked; //ci serve?
  uint16_t dest = 0;
  uint16_t counter = 0;
  uint16_t number;
  uint16_t routingTable[N-1][2]
}	

  event void Boot.booted() {
    routingTable[0][0]=current_node;
    routingTable[0][1]=current_node;
    for(int i=1;i<N;i++){
	    routingTable[i][0]=-1;
	    routingTable[i][1]=-1;
	}
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
    counter++;//serve?
    dbg("AODVsimulator", "AODVsimulator: timer fired, send msg id %hhu \n",counter);
    if (locked) { //?
      return;
    }
    else {
      radio_data_msg_t* rdm = (radio_data_msg_t*)call Packet.getPayload(&packet, sizeof(radio_data_msg_t));
      if (rdm == NULL) {
	       return;
      }
      random_dest = (Random.rand16() % N);
      rdm->dest= random_dest; //inserire random destination 
      rdm->content = 150;//inserire random content
      if(rdm->dest==current_node) 
        //non fare nulla
      else
      //check routing table, se non c'è manda in braodcast
      //TODO
          call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_data_msg_t)) == SUCCESS) {
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
	//1. check route_req_id && sending node (tutti i nodi partono da id 0)
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




