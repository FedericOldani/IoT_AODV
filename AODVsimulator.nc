
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
  bool locked=FALSE;
  uint16_t msg_id=0;
  bool found;
  uint16_t random_dest,msg_dest;
  int i=0,k=0;
  bool duplicated;
  nx_uint16_t id,src,dest,hop,next_hop,content,orig;

  
 void sendDatatMsg(uint16_t id_, uint16_t dest_, uint16_t src_, uint16_t content_,uint16_t next_hop_){
     data_msg_t* rdm = (data_msg_t*)call Packet.getPayload(&packet, sizeof(data_msg_t));
        if (rdm == NULL)  
          return;
        rdm->id=id_;
        rdm->src=src_;
        rdm->dest=dest_;
        rdm->content=content_;
        if(call SendDATA.send(next_hop_, &packet, sizeof(data_msg_t)) == SUCCESS) {
          dbg("AODVsimulator", "AODVsimulator: data packet sent to the next hop: %hhu at time %s \n",next_hop, sim_time_string());	
          locked = TRUE;
        }
    }
  
   void sendRReplyMsg(uint16_t id_, uint16_t dest_, uint16_t src_, uint16_t hop_,uint16_t orig_){ 
     rrp_msg_t* rdm = (rrp_msg_t*)call Packet.getPayload(&packet, sizeof(rrp_msg_t));
        if (rdm == NULL)  
          return;
        rdm->id=id_;
        rdm->src=src_;
        rdm->dest=dest_;
        rdm->hop=hop_;
        rdm->orig=orig_;
        if(call SendRRP.send(dest_, &packet, sizeof(rrp_msg_t)) == SUCCESS) {
          dbg("AODVsimulator", "AODVsimulator: reply back to the previous hop. origin:  %hhu  dest: %hhuat time %s \n",orig_,dest_, sim_time_string());	
          locked = TRUE;
        }
    }
  
  void sendRReqMsg(uint16_t id_, uint16_t dest_, uint16_t src_){
  rreq_msg_t* rreq = (rreq_msg_t*)call Packet.getPayload(&packet, sizeof(rreq_msg_t));
        rreq->id=id_;
        rreq->src=src_;
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
        dbg("AODVsimulator","RT dest: %hhu, next_hop %hhu, num_hop %hhu\n",routingTable[i].dest,routingTable[i].next_hop,routingTable[i].num_hop);
}

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
      msg_id++;
      dbg("AODVsimulator", "TIMER FIRED prepare msg\n\tfrom: %hhu -> %hhu at time %s CONTENT: %hhu\n",TOS_NODE_ID,msg_dest, sim_time_string (),content);
      
      //check the routing table
      i=0;
      found=FALSE;
  
      for(i=0;i<N && !found;i++){//in realtà basta guardare per NODE_ID -1
        if(routingTable[i].dest==msg_dest && routingTable[i].next_hop!=0){
            next_hop=routingTable[i].next_hop; 
            found=TRUE; 
      }      
      }
      //if dest is not found in the routing table,the request is sent in broadcast data msg will be sent to the next hop
      if(!found){
         dest=msg_dest;
         sendRReqMsg(msg_id,msg_dest,TOS_NODE_ID);
         call AcceptReply.startOneShot(1000);
}
      else {
         sendDatatMsg(msg_id,msg_dest,TOS_NODE_ID,content,next_hop);
         }
        
    }  
}


event void AcceptReply.fired() {
    dbg("AODVsimulator","1sec passed, send data msg\n");
    found=FALSE;
      printRT();
    for(i=0;i<N && !found;i++){//in realtà basta guardare per NODE_ID -1
        if(routingTable[i].dest==msg_dest && routingTable[i].next_hop!=0){
            next_hop=routingTable[i].next_hop; 
            found=TRUE; 
            sendDatatMsg(msg_id,msg_dest,TOS_NODE_ID,content,next_hop);
      }      
      }
      if(!found)
            dbg("AODVsimulator","c'è qlk problema\n");
}


event message_t* ReceiveRREQ.receive(message_t* bufPtr, void* payload, uint8_t len) {
  if (len != sizeof(rreq_msg_t)) {return bufPtr;}
  else {
    rreq_msg_t* rreq = (rreq_msg_t*)payload;
    duplicated=FALSE;
    for(i=0;i<256;i++){
        if(cacheTable[i].id==rreq->id /*&& cacheTable[i].src==rreq->src*/ && cacheTable[i].dest==rreq->dest){//TODO
            dbg("AODVsimulator","duplicate\n");
            duplicated=TRUE;}
}
     if(!duplicated){
        k++;
        if(k>255) k=0;
        cacheTable[k].id=rreq->id;
        cacheTable[k].src=rreq->src;
        cacheTable[k].dest=rreq->dest;
        if(rreq->dest==TOS_NODE_ID){
            dbg("AODVsimulator","rreq found the dest! sending back rreply\n"); 
            id=rreq->id;
            src=TOS_NODE_ID;
            dest=rreq->src;
            hop=1;
            orig=TOS_NODE_ID;
            sendRReplyMsg(id,dest,src,hop,orig);

        }
        else{
            found=FALSE;
            for(i=0;i<N && !found;i++){//in realtà basta guardare per NODE_ID -1
                if(routingTable[i].dest==msg_dest){
                    orig=routingTable[i].dest; 
                    found=TRUE; 
                    hop=routingTable[i].num_hop;
                    dbg("AODVsimulator","route found in my routing table, send rreply back\n"); 
                    id=rreq->id;
                    src=TOS_NODE_ID;
                    dest=rreq->src;
                    sendRReplyMsg(id,dest,src,hop+1,orig);
                    }}
            if(!found){                   
                    dbg("AODVsimulator","route not found in this node, send in broadcast the request\n");             
                    src=TOS_NODE_ID;
                    id=rreq->id;
                    dest=rreq->dest;
                    sendRReqMsg(id,dest,src);
                }                       
    }
  }
  return bufPtr;
  }
  }




event message_t* ReceiveDATA.receive(message_t* bufPtr, void* payload, uint8_t len) {
  if (len != sizeof(rreq_msg_t)) {return bufPtr;}
  else {
    data_msg_t* data = (data_msg_t*)payload;
    if(data->dest!=TOS_NODE_ID){
        found=FALSE;
        for(i=0;i<N && !found;i++){//in realtà basta guardare per NODE_ID -1
           if(routingTable[i].dest==msg_dest) {{
            found=TRUE; 
            next_hop=routingTable[i].next_hop;
            }
        }}
        if(found){       
            dbg("AODVsimulator","data packet forwarded from %hhu to next_hop %hhu \n",data->src,next_hop);                 
            sendDatatMsg(data->id,data->dest,data->src,data->content,next_hop);   

      }
        else{            
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
    dbg("AODVsimulator","------------------rreply received!hop: %hhu\n",rreply->hop); 
    
    /*sono la dest? si: aggiorna routingTable. no:  cache*/
        found=FALSE;
        for(i=0;i<N && !found;i++){//in realtà basta guardare per NODE_ID -1
            if(routingTable[i].dest==rreply->orig && routingTable[i].num_hop<rreply->hop) {
                routingTable[i].next_hop=rreply->src;
                routingTable[i].num_hop=rreply->hop;
                found=TRUE;
      }}
       
      for(i=0;i<N;i++){
        if(cacheTable[i].dest==rreply->orig && cacheTable[i].id==rreply->id){
            id=rreply->id;
            src=TOS_NODE_ID;
            dest=rreply->dest;
            hop=rreply->hop+1;
            orig=rreply->orig;
            sendRReplyMsg(id,dest,src,hop,orig);
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
    //dbg("AODVsimulator", "unlocked\n");
  }}



}




