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
    nx_uint16_t sender;
} rrp_msg_t;


typedef nx_struct routing_table{
    nx_uint16_t dest;
    nx_uint16_t next_hop;
    nx_uint16_t num_hop;
    }routing_table_t;
    
typedef nx_struct cache_table{
    nx_uint16_t id;
    nx_uint16_t src;
    nx_uint16_t sender;
    nx_uint16_t dest;
    }cache_table_t;



enum {
  AM_DATA_MSG = 6,//communication channel 
  AM_RREQ_MSG = 5,//communication channel 
  AM_RRP_MSG = 3,//communication channel 
};


#define N 4 //number of motes
#define CT_size 256
#endif
