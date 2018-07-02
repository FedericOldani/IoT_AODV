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

  message_t rreq_packet;
  message_t data_packet;
  message_t rrp_packet;

  uint8_t retries = NUM_RETRIES;
  
  routing_table_t routingTable[N];//number of nodes
  
  cache_table_t cacheTable[256];
  bool locked=FALSE;
  
  uint16_t msg_id=0;
  uint16_t msg_dest;
  uint16_t content;
  
  bool found;
  
  int i=0,k=0,hop=0;
  bool duplicated;
  
  /////////////////////////////// StartDone /////////////////////////////////
  
 event void AMControl.startDone(error_t err) {
    if (err == SUCCESS)
      call MilliTimer.startPeriodic(30000); //every 30 sec, a data msg is sent
    else 
      call AMControl.start();
  }
  
  /////////////////////////////// StopDone /////////////////////////////////

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }
  
  /////////////////////////////// sendDataMsg ///////////////////////////////////
  
  void sendDatatMsg(routingTable[i].next_hop){
    	data_msg_t* data=(data_msg_t*)(call Packet.getPayload(&data_packet,sizeof(data_msg_t)));
  }
  
  
  /////////////////////////////// sendData ///////////////////////////////////
  
  task void sendData(){
     msg_id++;
       
     msg_dest=TOS_NODE_ID;
     while(msg_dest==TOS_NODE_ID){
            msg_dest = (call Random.rand16() % N)+1; //random destination
        }
      content = call Random.rand16() % 150;//random content
      
    found=FALSE;
        for(i=0; i<N && !found; i++){
            if( routingTable[i].dest == msg_dest ){
                sendDatatMsg(msg_dest,TOS_NODE_ID,content,routingTable[i].next_hop);
                found = TRUE;
            }
        }
  }
  
  /////////////////////////////// TimerFired /////////////////////////////////
  event void MilliTimer.fired() {
        
        
        post sendData();
        
          
  }
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
