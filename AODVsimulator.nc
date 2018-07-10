
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
    interface Timer<TMilli> as CleanRTtimer;
    interface SplitControl as AMControl;
    interface Packet;
    interface Random;

  }
}
implementation {

  message_t packetData, packetRRep, packetRReq;
  rrp_msg_t cache_rrep[10];
  
  routing_table_t routingTable[RT_size];
  cache_table_t cacheTable[CT_size];
  bool locked=FALSE;
  uint16_t msg_dest,content, msg_id=0;
  int end = 0,k=0,rrep_i=0;

 void sendDatatMsg(uint16_t dest_, uint16_t src_, uint16_t content_,uint16_t next_hop){
     data_msg_t* rdm = (data_msg_t*)call Packet.getPayload(&packetData, sizeof(data_msg_t));
        if (rdm == NULL){  
          dbg("AODVsimulator", "rdm is NULL\n"); 
          return;
        }
        rdm->src=src_;
        rdm->dest=dest_;
        rdm->content=content_;
        if(call SendDATA.send(next_hop, &packetData, sizeof(data_msg_t)) == SUCCESS) {
          dbg("AODVsimulator", "DATA: packet sent to the next hop: %hhu (SRC: %hhu, DEST: %hhu)\n",next_hop,src_,dest_);	
          locked = TRUE;
        }
    }
  
task void goRReply(){
        rrp_msg_t* rdm = (rrp_msg_t*)call Packet.getPayload(&packetRRep, sizeof(rrp_msg_t));
        int i, next_hop;

        if (rdm == NULL){  
          dbg("AODVsimulator", "rdm is NULL\n"); 
          return;
        }
        rdm->id=cache_rrep[0].id;
        rdm->dest=cache_rrep[0].dest;
        rdm->hop=cache_rrep[0].hop;
        rdm->sender=cache_rrep[0].sender;
        rdm->src=cache_rrep[0].src;

        next_hop = cache_rrep[0].nh;

        for(i=0;i<9;i++){
          cache_rrep[i]=cache_rrep[i+1];
        }

        cache_rrep[9].id=0;
        cache_rrep[9].src=0;
        cache_rrep[9].sender=0;
        cache_rrep[9].dest=0;
        cache_rrep[9].hop=0;
        cache_rrep[9].nh=0;

        rrep_i--;

        if(call SendRRP.send(next_hop, &packetRRep, sizeof(rrp_msg_t)) == SUCCESS) {
          dbg("AODVsimulator", "RREPLY: back to the previous node %hhu \n",next_hop);  
          locked = TRUE;
        }
        else           dbg("AODVsimulator", "????????????\n"); 
  }
  
   void sendRReplyMsg(uint16_t id_, uint16_t next_hop_, uint16_t dest_,uint16_t src_,uint16_t sender_, uint16_t hop_){ 
    cache_rrep[rrep_i].id=id_;
    cache_rrep[rrep_i].src=src_;
    cache_rrep[rrep_i].sender=sender_;
    cache_rrep[rrep_i].dest=dest_;
    cache_rrep[rrep_i].hop=hop_;
    cache_rrep[rrep_i].nh=next_hop_;

    rrep_i++;
    if(locked == FALSE)
      post goRReply();

    }
  
  void sendRReqMsg(uint16_t id_, uint16_t src_,uint16_t dest_){
  rreq_msg_t* rreq = (rreq_msg_t*)call Packet.getPayload(&packetRReq, sizeof(rreq_msg_t));
        if (rreq == NULL) {
           dbg("AODVsimulator", "rdm is NULL\n"); 
           return;
        }
        rreq->id=id_;
        rreq->src=src_;
        rreq->sender=TOS_NODE_ID;
        rreq->dest=dest_;
        if(call  SendRREQ.send(AM_BROADCAST_ADDR, &packetRReq, sizeof(rreq_msg_t)) == SUCCESS) {
          dbg("AODVsimulator", "RREQUEST: sent in broadcast (SRC:%hhu, DEST:%hhu)\n",rreq->src,rreq->dest);	
          locked = TRUE;  
        }
}

void printRT(){
    int i;
    //PRINT ROUTING TABLE
    dbg("AODVsimulator",".-------------- ROUTING TABLE -------------.\n");
    for(i=0;i<RT_size;i++)
      if(routingTable[i].dest!=0)
        dbg("AODVsimulator","| dest: %hhu, next_hop %hhu, num_hop %hhu, status %hhu |\n",routingTable[i].dest,routingTable[i].next_hop,routingTable[i].num_hop,routingTable[i].status);
    dbg("AODVsimulator","'------------------------------------------'\n");

}

void printCT(){
    int i;
    //PRINT ROUTING TABLE
    for(i=0;i<CT_size;i++)
      if(cacheTable[i].dest!=0)
        dbg("AODVsimulator","CT id:%hhu, dest: %hhu, src: %hhu, sender: %hhu\n",cacheTable[i].id,cacheTable[i].dest,cacheTable[i].src,cacheTable[i].sender);
}

//default initialization of routingTable and cacheTable
  event void Boot.booted() {
    int i;
    dbg("ActiveNode", "ActiveNode: node %u started\n",TOS_NODE_ID);
    for(i=0;i<RT_size;i++){
	    routingTable[i].dest= 0;
      routingTable[i].next_hop=0;
      routingTable[i].num_hop=0;
      routingTable[i].status=INVALID;
  	}
    for(i=0;i<CT_size;i++){
	    cacheTable[i].dest=0;
      cacheTable[i].id=0;
      cacheTable[i].src=0;
      cacheTable[i].sender=0;
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
  
  event void CleanRTtimer.fired(){
    int i = 0;
    dbg("AODVsimulator", ">>>> 90 sec passed, remove routing table entry\n");
    printRT();
    for(i=0;i<RT_size-1;i++){
     routingTable[i].dest=routingTable[i+1].dest;
     routingTable[i].next_hop=routingTable[i+1].next_hop;
     routingTable[i].num_hop=routingTable[i+1].num_hop;
     routingTable[i].status=routingTable[i+1].status;
    }
    routingTable[RT_size-1].dest=0;
    routingTable[RT_size-1].next_hop=0;
    routingTable[RT_size-1].num_hop=0;
    routingTable[RT_size-1].status=INVALID;
    dbg("AODVsimulator", "NEW routing table:\n");
    printRT();
  }
  

  event void MilliTimer.fired() {
    bool found; int i;
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
      dbg("AODVsimulator", "\n\n\t:::::::::::::::::: TIMER FIRED :::::::::::::::::\nPreparing message... %hhu -> %hhu at time %s CONTENT: %hhu\n",TOS_NODE_ID,msg_dest, sim_time_string (),content);

      i=0;
      found=FALSE;
  
      for(i=0;i<RT_size && !found;i++){
        if(routingTable[i].dest==msg_dest && routingTable[i].status==ACTIVE){
            found=TRUE; 
            printRT();
            sendDatatMsg(msg_dest, TOS_NODE_ID, content, routingTable[i].next_hop);
      }      
      }
      //if dest is not found in the routing table,the request is sent in broadcast data msg will be sent to the  next hop
      if(!found){
        sendRReqMsg(msg_id++,TOS_NODE_ID,msg_dest);

        call AcceptReply.startOneShot(1000);
} 
    }   
    }  



event void AcceptReply.fired() {
    bool found;
    int i;
    dbg("AODVsimulator",">> One sec passed, send data msg <<\n");
    printRT();
    found = FALSE;
    for(i=0;i<RT_size && !found;i++){
        if(routingTable[i].dest==msg_dest && routingTable[i].next_hop!=0 && routingTable[i].status==ACTIVE){
            found=TRUE; 
            sendDatatMsg(msg_dest,TOS_NODE_ID,content,routingTable[i].next_hop);
      }      
      }
    if(!found){
       dbg("AODVsimulator","ERROR: routing table has no the destination.\n");
       //max_tries--;
       //if(max_tries>0){
       // sendRReqMsg(msg_id++,TOS_NODE_ID,msg_dest);
       // call AcceptReply.startOneShot(1000);
     //}
   }
}


event message_t* ReceiveRREQ.receive(message_t* bufPtr, void* payload, uint8_t len) {
  if (len != sizeof(rreq_msg_t)) {
    return bufPtr;}
  else {
    rreq_msg_t* rreq = (rreq_msg_t*)payload;
    int i; 
    bool duplicated;

    if(rreq->dest==TOS_NODE_ID){
        dbg("AODVsimulator","RReq reached the destination!\n"); 
        sendRReplyMsg(rreq->id,rreq->sender,rreq->src,TOS_NODE_ID,TOS_NODE_ID,1);
    }
    else{

	   if(rreq->src!=TOS_NODE_ID){
	    duplicated=FALSE;
	    for(i=0;i<CT_size;i++){
		    if(cacheTable[i].id==rreq->id && cacheTable[i].src==rreq->src && cacheTable[i].dest==rreq->dest){
		    dbg("AODVsimulator","Duplicated packet\n");
		    duplicated=TRUE;}
	    }
	    if(!duplicated){
		    k++;
		    if(k>=CT_size) k=0;
		    cacheTable[k].id=rreq->id;
		    cacheTable[k].src=rreq->src;
		    cacheTable[k].dest=rreq->dest;
        cacheTable[k].sender=rreq->sender;
	 	    		                               
		    //dbg("AODVsimulator","Send in broadcast the request\n");             
		    sendRReqMsg(rreq->id,rreq->src,rreq->dest);
      }

    }
    }   
     return bufPtr;
  }
}

event message_t* ReceiveDATA.receive(message_t* bufPtr, void* payload, uint8_t len) {
  if (len != sizeof(data_msg_t)) { return bufPtr; }
  else {
    data_msg_t* data = (data_msg_t*)payload;
    int i; 
    bool found;

    if(data->dest!=TOS_NODE_ID){
        found=FALSE;
        for(i=0;i<RT_size && !found;i++){
           if(routingTable[i].dest==data->dest && routingTable[i].status==ACTIVE) {
            found=TRUE;             
            printRT();
            //dbg("AODVsimulator"," dest: %hhu , %hhu\n",routingTable[i].dest,data->dest); 
		        //if(routingTable[i].dest==data->dest){dbg("AODVsimulator"," dest %hhu , %hhu\n",routingTable[i].dest,data->dest);}
            //dbg("AODVsimulator","Data packet forwarded from %hhu to next_hop %hhu \n",TOS_NODE_ID,routingTable[i].next_hop);                 
            sendDatatMsg(data->dest,data->src,data->content,routingTable[i].next_hop);
            }
        }

        if(!found){            
            dbg("AODVsimulator","Error, data pck stops here\n");               
            }
     } else
      dbg("AODVsimulator","FINISH data packet from %hhu to %hhu received, CONTENT: %hhu\n",data->src,data->dest,data->content);
    } 
  return bufPtr;
  }  
  
event message_t* ReceiveRRP.receive(message_t* bufPtr, void* payload, uint8_t len) {
  if (len != sizeof(rrp_msg_t)) {    return bufPtr;}
  else {
    rrp_msg_t* rreply = (rrp_msg_t*)payload;
    int i,j; 
    bool found;
    
    dbg("AODVsimulator","RREPLY received, %hhu hops\n",rreply->hop);     

    found=FALSE;
    for(i=0;i<RT_size && !found;i++){
             if(routingTable[i].dest==rreply->src && routingTable[i].status==ACTIVE){
                if(routingTable[i].num_hop>=rreply->hop) {
                    routingTable[i].status=INVALID;

                    routingTable[end].dest=rreply->src;
                    routingTable[end].next_hop=rreply->sender;
                    routingTable[end].num_hop=rreply->hop;
                    routingTable[end].status=ACTIVE;
                    end++;
                    call CleanRTtimer.startOneShot(90000);
                    dbg("AODVsimulator","RT updated\n");
                    printRT();
                   }
                found=TRUE;
	           }
	  }
    if(!found){
          routingTable[end].dest=rreply->src;
          routingTable[end].next_hop=rreply->sender;
          routingTable[end].num_hop=rreply->hop;
          routingTable[end].status=ACTIVE;
          end++;
          dbg("AODVsimulator","RT new entry\n");
          call CleanRTtimer.startOneShot(90000);
          printRT();        
        }
    for(j=0;j<CT_size;j++){
       if(cacheTable[j].dest==rreply->src && cacheTable[j].src==rreply->dest && cacheTable[j].id==rreply->id){
            //dbg("AODVsimulator","Send RREPLY to %hhu, %hhu hops\n",cacheTable[j].src,rreply->hop);
            sendRReplyMsg(rreply->id,cacheTable[j].sender,rreply->dest,rreply->src,TOS_NODE_ID,(rreply->hop)+1);
        }
    }
//    printCT();

    return bufPtr;
  }
  
 
}

event void SendRRP.sendDone(message_t* bufPtr, error_t error) {
  if (&packetRRep == bufPtr) {
    locked = FALSE;
    if(rrep_i>0)
      post goRReply();
    //dbg("AODVsimulator", "unlocked rrp\n");
  }
}
event void SendRREQ.sendDone(message_t* bufPtr, error_t error) {
  if (&packetRReq == bufPtr) {
    locked = FALSE;
    //dbg("AODVsimulator", "unlocked rreq\n");
  }
  }
  event void SendDATA.sendDone(message_t* bufPtr, error_t error) {
  if (&packetData == bufPtr) {
    locked = FALSE;
    //dbg("AODVsimulator", "unlocked data\n");
  }}
}
