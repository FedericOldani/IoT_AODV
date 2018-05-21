
#include "Timer.h"
#include "AODVsimulator.h"
 
 
/**
 * @author Federico Oldani, Valentina Ionata
 * @date   May 10 2018
 */

module AODVsimulator @safe() {
  uses {
    interface Boot;
    interface Receive as ReceiveRRP;
    interface Receive as ReceiveRREQ;
    interface Receive as ReceiveDATA;
    interface AMSend as SendRRP;
    interface AMSend as SendRREQ;
    interface AMSend as SendDATA;
    interface Timer<TMilli> as MilliTimer;
    interface Timer<TMilli> as AcceptReply;
    interface SplitControl as AMControl;
    interface Packet;
    interface Random;

  }
}
implementation {

  message_t packet;
  routing_table_t routingTable[N];//number of nodes
  cache_table_t cacheTable[N]
  bool locked=FALSE;
  uint16_t msg_dest,msg_content,msg_id=0,msg_type;
  uint16_t number;
  bool found;
  uint16_t random_dest;
  int i=0;
  uint16_t nulla;
  bool acceptRReply;
  

//default initialization of routingTable and cacheTable
  event void Boot.booted() {
    dbg("ActiveNode", "ActiveNode: node %u started\n",TOS_NODE_ID);
    for(i=0;i<N;i++){
	    routingTable[i].dest= i+1;
      routingTable[i].next_hop=0;
      routingTable[i].num_hop=0;
  	}
    for(i=0;i<N;i++){
	    cacheTable[i].dest=0;
      cacheTable[i].id=0;
      cacheTable[i].src=0;
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
      msg_dest=TOS_NODE_ID;
      while(msg_dest==TOS_NODE_ID){
        msg_dest = (call Random.rand16() % N)+1; //random destination
      }
      msg_content = call Random.rand16() % 150;//random content
      dbg("AODVsimulator", "TIMER FIRED prepare msg\n\tfrom: %hhu -> %hhu at time %s CONTENT: %hhu\n",TOS_NODE_ID,msg_dest, sim_time_string(),msg_content);
      
      //check the routing table
      i=0;
      found=FALSE;
      for(i=0;i<N && !found;i++){
        if(routingTable[i].dest==msg_dest) 
        found=TRUE; 
      }      
      //while dest is not found in the routing table,the request is sent in broadcast data msg will be sent to the next hop
      while(!found){
        rreq_msg_t* rreq = (rreq_msg_t*)call Packet.getPayload(&packet, sizeof(rreq_msg_t));
        rreq->id=msg_id++;
        rreq->search=TOS_NODE_ID;
        rreq->dest=msg_dest;
        if (rreq == NULL) {
              return;
        }
        if(call  SendRREQ.send(AM_BROADCAST_ADDR, &packet, sizeof(rreq_msg_t)) == SUCCESS) {
          dbg("AODVsimulator", "AODVsimulator: route request sent in broadcast.\n\tID MSG:%hhu\n\tDEST:%hhu\n",rreq->id,rreq->dest);	
          locked = TRUE; 
          acceptRReply=TRUE;
          call AcceptReply.startOneShot(1000);
        }

        for(i=0;i<N && !found;i++){
          if(routingTable[i].dest==msg_dest) 
           found=TRUE; 
        }   
        
      }
    
     //in every case the message is sent when the path is on the routing table
     data_msg_t* rdm = (data_msg_t*)call Packet.getPayload(&packet, sizeof(data_msg_t));
        if (rdm == NULL)  
          return;
        rdm->id=msg_id++;
        rdm->src=TOS_NODE_ID;
        rdm->dest=msg_dest;
        rdm->content=msg_content;
        if(call SendDATA.send(routingTable[TOS_NODE_ID].next_hop, &packet, sizeof(data_msg_t)) == SUCCESS) {
          dbg("AODVsimulator", "AODVsimulator: packet sent to the next hop: %hhu at time %s \n",routingTable[i][1], sim_time_string());	
          locked = TRUE;
        }
	    	
    
    }
  }
}

event void AcceptReply.fired() {
        acceptRReply=FALSE;
}


/*event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
  if (len != sizeof(radio_msg_t)) {return bufPtr;}
  else {
    radio_msg_t* rdm = (radio_msg_t*)payload;
    switch(rdm->type){
      case DATA:
              if(rdm->dest==TOS_NODE_ID)
                  dbg("AODVsimulator", "DATA packet received, I'm the destination.\n");
              else
              //TODO cerca nella routing table
              break;
      case RREQ:
              if(rdm->dest==TOS_NODE_ID)
              //1. check route_req_id && sending node (tutti i nodi partono da id 0)
            //2. new ID: 
            //	2a. sono la destinazione? no: broadcast, si: route_reply al mittente 
            //3. otherwise discard it.
              dbg("AODVsimulator", "Received RREQ packet\n");
              //TODO
              break;
      case RREPLY:
              dbg("AODVsimulator", "Received RREPLY packet\n");
              if(acceptRReply){
                  // è la route_reply con meno hop? si: mantieni, no:scarta
            }
              break;
  }
  return bufPtr;
  }
}*/

event void AMSend.sendDone(message_t* bufPtr, error_t error) {
  if (&packet == bufPtr) {
    locked = FALSE;
    dbg("AODVsimulator", "unlocked\n");
  }
}

}




