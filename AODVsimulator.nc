
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
  
  cache_table_t cacheTable[256];
  bool lockedDATA=FALSE,lockedRREQ=FALSE,lockedRRP=FALSE;
  bool locked=FALSE;
  uint16_t msg_id=0;
  bool found;
  uint16_t random_dest,msg_dest,content;
  int i=0,k=0,hop=0;
  bool duplicated;
  rrp_msg_t* rreply;
    rreq_msg_t* rreq;
    data_msg_t* data;

 task void waitForReply(){
        call AcceptReply.startOneShot(1000);
}


  
 void sendDatatMsg(uint16_t dest_, uint16_t src_, uint16_t content_,uint16_t next_hop){
     data_msg_t* rdm = (data_msg_t*)call Packet.getPayload(&packet, sizeof(data_msg_t));
        if (rdm == NULL)  
          return;
        rdm->src=src_;
        rdm->dest=dest_;
        rdm->content=content_;
        if(call SendDATA.send(next_hop, &packet, sizeof(data_msg_t)) == SUCCESS) {
          dbg("AODVsimulator", "AODVsimulator: data packet sent to the next hop: %hhu dest: %hhu at time %s \n",next_hop,dest_, sim_time_string());	
          lockedDATA = TRUE;
        }
    }
  
   void sendRReplyMsg(uint16_t id_, uint16_t next_hop_, uint16_t dest_,uint16_t src_,uint16_t sender_, uint16_t hop_){ 
     rrp_msg_t* rdm = (rrp_msg_t*)call Packet.getPayload(&packet, sizeof(rrp_msg_t));
        if (rdm == NULL)  
          return;
        rdm->id=id_;
        rdm->dest=dest_;
        rdm->hop=hop_;
        rdm->sender=sender_;
        rdm->src=src_;
        if(call SendRRP.send(next_hop_, &packet, sizeof(rrp_msg_t)) == SUCCESS) {
          dbg("AODVsimulator", "AODVsimulator: reply back to the previous hop %hhu. origin:  %hhu  dest: %hhuat time %s \n",next_hop_,src_,dest_, sim_time_string());	
          lockedRRP = TRUE;
        }
    }
  
  void sendRReqMsg(uint16_t id_, uint16_t src_,uint16_t dest_){
  rreq_msg_t* rdm = (rreq_msg_t*)call Packet.getPayload(&packet, sizeof(rreq_msg_t));
        rdm->id=id_;
        rdm->src=src_;
        rdm->sender=TOS_NODE_ID;
        rdm->dest=dest_;
        if (rdm == NULL) {
              return;
        }
        if(call  SendRREQ.send(AM_BROADCAST_ADDR, &packet, sizeof(rreq_msg_t)) == SUCCESS) {
          dbg("AODVsimulator", "AODVsimulator: route request sent in broadcast. ID MSG:%hhu DEST:%hhu\n",rdm->id,rdm->dest);	
          lockedRREQ = TRUE; 
          
        }
  
}

void printRT(){
        
    //PRINT ROUTING TABLE
    for(i=0;i<N;i++)
    if(routingTable[i].dest!=0)
        dbg("AODVsimulator","RT dest: %hhu, next_hop %hhu, num_hop %hhu\n",routingTable[i].dest,routingTable[i].next_hop,routingTable[i].num_hop);
}

void printCT(){
        
    //PRINT cache TABLE
    for(i=0;i<N;i++)
    if(cacheTable[i].dest!=0)
        dbg("AODVsimulator","CT dest: %hhu, src %hhu, id %hhu\n",cacheTable[i].dest,cacheTable[i].src,cacheTable[i].id);
}

//default initialization of routingTable and cacheTable
  event void Boot.booted() {
    dbg("ActiveNode", "ActiveNode: node %u started\n",TOS_NODE_ID);
    for(i=0;i<N;i++){
	  routingTable[i].dest= 0;
      routingTable[i].next_hop=0;
      routingTable[i].num_hop=0;
  	}
    for(i=0;i<N;i++){
	  cacheTable[i].dest=0;
      cacheTable[i].id=0;
      cacheTable[i].src=0;
  	}
    hop=0;
        
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
  
  task void timerFired(){
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
      content = call Random.rand16() % 150;//random content
      dbg("AODVsimulator", "-------------TIMER FIRED prepare msg---------------\n\tfrom: %hhu -> %hhu at time %s CONTENT: %hhu\n",TOS_NODE_ID,msg_dest, sim_time_string (),content);
      
      //check the routing table
      i=0;
      found=FALSE;
  
      for(i=0;i<N && !found;i++){
        if(routingTable[i].dest==msg_dest){
            found=TRUE; 
            sendDatatMsg(msg_dest,TOS_NODE_ID,content,routingTable[i].next_hop);
      }      
      }
        msg_id++;
         sendRReqMsg(msg_id,TOS_NODE_ID,msg_dest);
         post waitForReply();
}}   
  
  event void MilliTimer.fired() {
    post timerFired();
    
    }  


event void AcceptReply.fired() {//TODO
    dbg("AODVsimulator","1sec passed, send data msg\n");
     found=FALSE;
      printRT();
    for(i=0;i<N && !found;i++){
        if(routingTable[i].dest==msg_dest && routingTable[i].next_hop!=0){
            found=TRUE; 
            sendDatatMsg(msg_dest,TOS_NODE_ID,content,routingTable[i].next_hop);
      }      
      }
      if(!found){
            dbg("AODVsimulator","Something wrong, I didn't find the route...try again!\n");
            msg_id++;
            sendRReqMsg(msg_id,TOS_NODE_ID,msg_dest);
            post waitForReply();
            }
}

task void rreqReceived(){

    if(rreq->dest==TOS_NODE_ID){
        dbg("AODVsimulator","rreq found the dest! sending back rreply\n"); 
        sendRReplyMsg(rreq->id,rreq->sender,rreq->src,TOS_NODE_ID,TOS_NODE_ID,1);
    }
    else{

	if(rreq->src!=TOS_NODE_ID){
	    duplicated=FALSE;
	    for(i=0;i<256;i++){
		if(cacheTable[i].id==rreq->id && cacheTable[i].src==rreq->src && cacheTable[i].dest==rreq->dest){
		    dbg("AODVsimulator","duplicate\n");
		    duplicated=TRUE;}
	    }
	    if(!duplicated){
    		k++;
    		if(k>255) k=0;
    		cacheTable[k].id=rreq->id;
    		cacheTable[k].src=rreq->src;
    		cacheTable[k].sender=rreq->sender;
        	cacheTable[k].dest=rreq->dest;		
		    //printCT();                           
		    dbg("AODVsimulator","send in broadcast the request\n");             
		    sendRReqMsg(rreq->id,rreq->src,rreq->dest);		                             		 
 	    }
    }
    }    }

event message_t* ReceiveRREQ.receive(message_t* bufPtr, void* payload, uint8_t len) {
  if (len != sizeof(rreq_msg_t)) {
    dbg("AODVsimulator","Error length\n");
    return bufPtr;
    }
  else {
     rreq = (rreq_msg_t*)payload;
    post rreqReceived();
     return bufPtr;
  }
}

task void dataReceived(){
               
    if(data->dest!=TOS_NODE_ID){
        found=FALSE;
        for(i=0;i<N && !found;i++){
           if(routingTable[i].dest==data->dest) {
            found=TRUE;             
            printRT();
            dbg("AODVsimulator","data packet forwarded from %hhu to next_hop %hhu [rt[i]=%hhu,data->dest=%hhu]\n",TOS_NODE_ID,routingTable[i].next_hop,routingTable[i].dest,data->dest);                 
            sendDatatMsg(data->dest,data->src,data->content,routingTable[i].next_hop);
            }
        }

        if(!found){            
            dbg("AODVsimulator","Error, data pck stops here\n");               
            }
     } else
      dbg("AODVsimulator","FINISH data packet from %hhu to %hhu received\n",data->src,data->dest);
    }
  


event message_t* ReceiveDATA.receive(message_t* bufPtr, void* payload, uint8_t len) {
  if (len != sizeof(data_msg_t)) {    dbg("AODVsimulator","Error length\n");return bufPtr;}
  else {
    data = (data_msg_t*)payload;
     post dataReceived();
  return bufPtr;
  }  
  }
  
  
task void rrpReceived(){
    found=FALSE;
    for(i=0;routingTable[i].dest!=0 && !found;i++){
         if(routingTable[i].dest==rreply->src){
             if(routingTable[i].num_hop>rreply->hop || routingTable[i].num_hop==0) {
                    routingTable[i].next_hop=rreply->sender;
                    routingTable[i].num_hop=rreply->hop;

                   }
                found=TRUE;
	      }
	}
      if(!found && i<N){
                    routingTable[i].dest=rreply->src;
                    routingTable[i].next_hop=rreply->sender;
                    routingTable[i].num_hop=rreply->hop;
        
      }
       
      /*for(i=0;i<N;i++){
        if(cacheTable[i].dest==rreply->src && cacheTable[i].src==rreply->dest && cacheTable[i].id==rreply->id){
            dbg("AODVsimulator","send rreply to %hhu!hop: %hhu\n",cacheTable[i].src,rreply->hop);
            sendRReplyMsg(rreply->id,cacheTable[i].sender,rreply->dest,rreply->src,TOS_NODE_ID,(rreply->hop)+1);
            cacheTable[i].dest=0;
            cacheTable[i].src=0;
            cacheTable[i].id=0;
   }
  }*/
}  
  
event message_t* ReceiveRRP.receive(message_t* bufPtr, void* payload, uint8_t len) {
  if (len != sizeof(rrp_msg_t)) {    dbg("AODVsimulator","Error length\n"); return bufPtr;}
  else {
    rreply = (rrp_msg_t*)payload;
    dbg("AODVsimulator","rreply received!hop: %hhu\n",rreply->hop);
             
    post rrpReceived();
  return bufPtr;
  }
  
 
}

event void SendRRP.sendDone(message_t* bufPtr, error_t error) {
  if (&packet == bufPtr) {
    lockedRRP = FALSE;
    dbg("AODVsimulator", "unlocked\n");
  }
}
event void SendRREQ.sendDone(message_t* bufPtr, error_t error) {
  if (&packet == bufPtr) {
    lockedRREQ = FALSE;
    dbg("AODVsimulator", "unlocked\n");
  }
  }
  event void SendDATA.sendDone(message_t* bufPtr, error_t error) {
  if (&packet == bufPtr) {
    lockedDATA = FALSE;
    dbg("AODVsimulator", "SENT\n");
  }}



}




