
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
  uint16_t routingTable[6][2];//number of nodes
  bool locked=FALSE;
  uint16_t msg_dest,msg_content,msg_id=0,msg_type;
  uint16_t number;
  bool found;
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
    if (locked) {
      return;
    }
    else {      
      //PREPARE MESSAGE:
      msg_dest = (call Random.rand16() % N)+1; //random destination
      msg_content = call Random.rand16() % 150;//random content
      dbg("AODVsimulator", "TIMER FIRED prepare msg\n\tfrom: %hhu -> %hhu at time %s CONTENT: %hhu\n",TOS_NODE_ID,msg_dest, sim_time_string(),msg_content);
      
      //IF THE DEST IS NOT MYSELF
      if(msg_dest!=TOS_NODE_ID) {
          
          //check the routing table
          i=0;
          found=FALSE;
          for(i=0;i<N && !found;i++) 
            if(routingTable[i][0]==msg_dest) found=TRUE; 
               
          //if dest is found in the routing table, data msg will be sent to the next hop
          if(found){
              radio_msg_t* rdm = (radio_msg_t*)call Packet.getPayload(&packet, sizeof(radio_msg_t));
              if (rdm == NULL)  return;
              rdm->type=DATA;
              rdm->id=msg_id++;
              rdm->content=msg_content;
              rdm->dest=msg_dest;
              if(call AMSend.send(routingTable[i-1][1], &packet, sizeof(radio_msg_t)) == SUCCESS) {
        	    dbg("AODVsimulator", "AODVsimulator: packet sent to the next hop: %hhu at time %s \n",routingTable[i][1], 
        	    sim_time_string());	
	    	    locked = TRUE;
	    	    }
	    	    }
	    	
            //otherwise send a route req in broadcast
          else{
            radio_msg_t* rreq = (radio_msg_t*)call Packet.getPayload(&packet, sizeof(radio_msg_t));
            rreq->type=RREQ;
            rreq->id=msg_id++;
            rreq->content=NULL;
            rreq->dest=msg_dest;
            dbg("AODVsimulator", "qua\n");
            if (rreq == NULL) {
	                return;
                    }
            if(call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_msg_t)) == SUCCESS) {
        	    dbg("AODVsimulator", "AODVsimulator: route request sent in broadcast.\n\tID MSG:%hhu\n\tDEST:%hhu\n",rreq->id,rreq->dest);	
    	    	locked = TRUE;    
	    	}
	    	//TODO: si interrompe dopo questo punto
      }
    }
  }
}
  event message_t* Receive.receive(message_t* bufPtr, 
				   void* payload, uint8_t len) {
				   
    dbg("AODVsimulator", "Received packet of length %hhu.\n", len);
    /*
    
    if (len == sizeof(radio_msg_t)) {
      radio_msg_t* rdm = (radio_msg_t*)payload;
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
            dbg("AODVsimulator", "unlocked");
  }

}




