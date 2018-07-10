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
    nx_uint16_t nh;
} rrp_msg_t;


typedef nx_struct routing_table{
    nx_uint16_t dest;
    nx_uint16_t next_hop;
    nx_uint16_t num_hop;
    nx_uint16_t status;
    }routing_table_t;
    
typedef nx_struct cache_table{
    nx_uint16_t id;
    nx_uint16_t src;
    nx_uint16_t sender;
    nx_uint16_t dest;
    }cache_table_t;



enum {
  AM_DATA_MSG = 1,//communication channel 
  AM_RREQ_MSG = 10,//communication channel 
  AM_RRP_MSG = 20,//communication channel 
};

#define INVALID 0
#define ACTIVE 1
#define N 8 //number of motes
#define CT_size 256
#define RT_size 20
#endif
