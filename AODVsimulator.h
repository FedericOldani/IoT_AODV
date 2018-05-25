/**
 * @author Federico Oldani, Valentina Ionata
 * @date   May 10 2018
 */


#ifndef AODV_SIMULATOR_H
#define AODV_SIMULATOR_H

typedef nx_struct data_msg {
	nx_uint16_t src;
	nx_uint16_t dest;
	nx_uint16_t content;
} data_msg_t;

typedef nx_struct rreq_msg {
	nx_uint16_t id;
	nx_uint16_t src;
	nx_uint16_t sender;
	nx_uint16_t dest;
} rreq_msg_t;

typedef nx_struct rrp_msg {
	nx_uint16_t id;
	nx_uint16_t src;
	nx_uint16_t dest;
	nx_uint16_t hop;
} rrp_msg_t;


typedef nx_struct routing_table{
    nx_uint16_t dest;
    nx_uint16_t next_hop;
    nx_uint16_t status;
    nx_uint16_t num_hop;
    }routing_table_t;
    
typedef nx_struct cache_table{
    nx_uint16_t id;
    nx_uint16_t src;
    nx_uint16_t dest;
    nx_uint16_t cost;
    }cache_table_t;



enum {
  AM_DATA_MSG = 6,//communication channel 
  AM_RREQ_MSG = 4,//communication channel 
  AM_RRP_MSG = 2,//communication channel 
};


#define N 3 //number of motes
#define DISCOVERY 1
#define ACTIVE 1
#define INACTIVE 1
#endif
