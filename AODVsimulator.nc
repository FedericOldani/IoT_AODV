
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

  
 void sendDatatMsg(uint16_t dest_, uint16_t src_, uint16_t content_,uint16_t next_hop){
     data_msg_t* rdm = (data_msg_t*)call Packet.getPayload(&packet, sizeof(data_msg_t));
        if (rdm == NULL)  
          return;
        rdm->src=src_;
        rdm->dest=dest_;
        rdm->content=content_;
        if(call SendDATA.send(next_hop, &packet, sizeof(data_msg_t)) == SUCCESS) {
          dbg("AODVsimulator", "AODVsimulator: data packet sent to the next hop: %hhu dest: %hhu at time %s \n",next_hop,dest_, sim_time_string());	
          locked = TRUE;
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
          locked = TRUE;
        }
    }
  
  void sendRReqMsg(uint16_t id_, uint16_t src_,uint16_t dest_){
  rreq_msg_t* rreq = (rreq_msg_t*)call Packet.getPayload(&packet, sizeof(rreq_msg_t));
        rreq->id=id_;
        rreq->src=src_;
        rreq->sender=TOS_NODE_ID;
        rreq->dest=dest_;
        if (rreq == NULL) {
              return;
        }
        if(call  SendRREQ.send(AM_BROADCAST_ADDR, &packet, sizeof(rreq_msg_t)) == SUCCESS) {
          dbg("AODVsimulator", "AODVsimulator: route request sent in broadcast. ID MSG:%hhu DEST:%hhu\n",rreq->id,rreq->dest);	
          locked = TRUE; 
          
        }
  
}

void printRT(){
        
    //PRINT ROUTING TABLE
    for(i=0;i<N;i++)
    if(routingTable[i].dest!=0)
        dbg("AODVsimulator","RT dest: %hhu, next_hop %hhu, num_hop %hhu\n",routingTable[i].dest,routingTable[i].next_hop,routingTable[i].num_hop);
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
      content = call Random.rand16() % 150;//random content
      dbg("AODVsimulator", "-------------TIMER FIRED prepare msg---------------\n\tfrom: %hhu -> %hhu at time %s CONTENT: %hhu\n",TOS_NODE_ID,msg_dest, sim_time_string (),content);
      
      //check the routing table
      i=0;
      found=FALSE;
  
      for(i=0;i<N && !found;i++){
        if(routingTable[i].dest==msg_dest && routingTable[i].status==ACTIVE){
            found=TRUE; 
            sendDatatMsg(msg_dest,TOS_NODE_ID,content,routingTable[i].next_hop);
      }      
      }
      //if dest is not found in the routing table,the request is sent in broadcast data msg will be sent to the next hop
      if(!found){
         i=0;
         while(routingTable[i].dest!=msg_dest && routingTable[i].dest!=0 && i<N)   i++;
         
         if(routingTable[i].dest==0){
             routingTable[i].dest=msg_dest;
             routingTable[i].next_hop=0;
             routingTable[i].status=DISCOVERY;
         }
         else if(routingTable[i].status==INACTIVE)
                    routingTable[i].status=DISCOVERY;

         sendRReqMsg(msg_id++,TOS_NODE_ID,msg_dest);
         call AcceptReply.startOneShot(1000);
}   
    }  
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
      if(!found)
            dbg("AODVsimulator","c'è qlk problema\n");
}


event message_t* ReceiveRREQ.receive(message_t* bufPtr, void* payload, uint8_t len) {
  if (len != sizeof(rreq_msg_t)) {return bufPtr;}
  else {
    rreq_msg_t* rreq = (rreq_msg_t*)payload;
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

		    found=FALSE;
		    for(i=0;i<N && !found;i++){
		        if(routingTable[i].dest==rreq->dest && routingTable[i].status==ACTIVE){
		            found=TRUE; 
		            dbg("AODVsimulator","route found in my routing table \n"); 
		           
		            }
	 	    }
		                               
		    dbg("AODVsimulator","send in broadcast the request\n");             
		    sendRReqMsg(rreq->id,rreq->src,rreq->dest);
		                              
		 
 	    }
    }
     


    }
    
     return bufPtr;
  }
}




event message_t* ReceiveDATA.receive(message_t* bufPtr, void* payload, uint8_t len) {
  if (len != sizeof(data_msg_t)) {return bufPtr;}
  else {
    data_msg_t* data = (data_msg_t*)payload;
                
    if(data->dest!=TOS_NODE_ID){
        found=FALSE;
        for(i=0;i<N && !found;i++){
           if(routingTable[i].dest==data->dest) {
            found=TRUE;             
            printRT();
            dbg("AODVsimulator"," next_hop %hhu , %hhu\n",routingTable[i].dest,data->dest); 
		if(routingTable[i].dest==data->dest){dbg("AODVsimulator"," next_hop %hhu , %hhu\n",routingTable[i].dest,data->dest);}
            dbg("AODVsimulator","data packet forwarded from %hhu to next_hop %hhu \n",TOS_NODE_ID,routingTable[i].next_hop);                 
            sendDatatMsg(data->dest,data->src,data->content,routingTable[i].next_hop);
            }
        }

        if(!found){            
            dbg("AODVsimulator","Error, data pck stops here\n");               
            }
     } else
      dbg("AODVsimulator","FINISH data packet from %hhu to %hhu received\n",data->src,data->dest);
    }
  
  return bufPtr;
  }  
  
event message_t* ReceiveRRP.receive(message_t* bufPtr, void* payload, uint8_t len) {
  if (len != sizeof(rrp_msg_t)) {return bufPtr;}
  else {
    rrp_msg_t* rreply = (rrp_msg_t*)payload;
    dbg("AODVsimulator","rreply received!hop: %hhu\n",rreply->hop);
    
     
    
    /*sono la dest? si: aggiorna routingTable. no:  cache*/
        found=FALSE;
        for(i=0;i<N && !found;i++){
             if(routingTable[i].dest==rreply->src){
                if(routingTable[i].num_hop>rreply->hop || routingTable[i].num_hop==0 || routingTable[i].status!=ACTIVE) {
                    routingTable[i].next_hop=rreply->sender;
                    routingTable[i].num_hop=rreply->hop;
                    routingTable[i].status=ACTIVE;

                   }
                found=TRUE;
	      }
	}
      if(!found && i<N){
                    routingTable[i].next_hop=rreply->sender;
                    routingTable[i].num_hop=rreply->hop;
                    routingTable[i].status=ACTIVE;
        
      }
       
      for(i=0;i<N;i++){
        if(cacheTable[i].dest==rreply->src && cacheTable[i].src==rreply->dest && cacheTable[i].id==rreply->id){
            dbg("AODVsimulator","send rreply to %hhu!hop: %hhu\n",cacheTable[i].src,rreply->hop);
            sendRReplyMsg(rreply->id,cacheTable[i].sender,rreply->dest,rreply->src,TOS_NODE_ID,(rreply->hop)+1);
            cacheTable[i].dest=0;
            cacheTable[i].src=0;
            cacheTable[i].id=0;
   }
  }
  return bufPtr;
  }
  
 
}

event void SendRRP.sendDone(message_t* bufPtr, error_t error) {
  if (&packet == bufPtr) {
    locked = FALSE;
    //dbg("AODVsimulator", "unlocked\n");
  }
}
event void SendRREQ.sendDone(message_t* bufPtr, error_t error) {
  if (&packet == bufPtr) {
    locked = FALSE;
    //dbg("AODVsimulator", "unlocked\n");
  }
  }
  event void SendDATA.sendDone(message_t* bufPtr, error_t error) {
  if (&packet == bufPtr) {
    locked = FALSE;
   // dbg("AODVsimulator", "SENT\n");
  }}



}




