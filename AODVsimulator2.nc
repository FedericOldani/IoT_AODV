
#include "Timer.h"
#include "AODVsimulator.h"
 
 
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
    //interface Timer<TMilli> as Timer2;
    interface SplitControl as AMControl;
    interface Packet;
    interface Random;

  }
}
implementation {

  message_t packet;
  uint16_t N=6; //number of nodes
  uint16_t routingTable[6][2];//number of nodes
  bool locked;
  uint16_t dest;
  uint16_t id_rreq = 0;//id reply request
  uint16_t number;
  int found;
  uint16_t random_dest;
  int i=0;


  event void Boot.booted() {
    dbg("ActiveNode", "ActiveNode: node %u started\n",TOS_NODE_ID);
    routingTable[0][0]=TOS_NODE_ID;
    routingTable[0][1]=TOS_NODE_ID;
    for(i=0;i<N;i++){
	    routingTable[i][0]=-1;
	    routingTable[i][1]=-1;
	}
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS)
      call MilliTimer.startPeriodic(30000); //every 30 sec, a data msg is sent
    else 
      call AMControl.start();
  }

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }
  
  event void MilliTimer.fired() {
    found=0;
    id_rreq++;
    if (locked) {
      return;
    }
    else {
      radio_data_msg_t* rdm = (radio_data_msg_t*)call Packet.getPayload(&packet, sizeof(radio_data_msg_t));
      if (rdm == NULL) {
	       return;
      }
      random_dest = call Random.rand16() % N;
      rdm->dest= random_dest; //inserire random destination 
      rdm->content = call Random.rand16() % 150;//inserire random content
      dbg("AODVsimulator", "TIMER FIRED prepare msg\n\tfrom: %hhu -> %hhu at time %s CONTENT: %hhu\n",TOS_NODE_ID,random_dest, sim_time_string(),rdm->content);
      if(rdm->dest!=TOS_NODE_ID) {
          //check in the routing table
          i=0;
          while(i<N && routingTable[i][0]!=random_dest)
              i++;
          //if dest is found in the routing table, data msg will be sent to the next hop
          if(i<N && routingTable[i][0]==random_dest)
            if(call AMSend.send(routingTable[i][1], &packet, sizeof(radio_data_msg_t)) == SUCCESS) {
        	    dbg("AODVsimulator", "AODVsimulator: packet sent to the next hop: %hhu at time %s \n",routingTable[i][1], sim_time_string());	
	    	    locked = TRUE;
	    	}
            //otherwise send a route req in broadcast
          else{
            route_req_t* rreq = (route_req_t*)call Packet.getPayload(&packet, sizeof(route_req_t));
                 if (rreq == NULL) {
	                return;
                    }
            rreq->id_msg=id_rreq;
            rreq->dest=random_dest;
            if(call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(route_req_t)) == SUCCESS) {
        	    dbg("AODVsimulator", "AODVsimulator: route request sent in broadcast.\n");	
    	    	locked = TRUE;
	    	}
      }
    }
  }
}
  event message_t* Receive.receive(message_t* bufPtr, 
				   void* payload, uint8_t len) {
    dbg("AODVsimulator", "Received packet of length %hhu.\n", len);
    /*
    
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
	
	*/
}

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }

}




