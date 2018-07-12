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
} data_msg_t; //Data message

typedef nx_struct rreq_msg {
	nx_uint16_t id;
	nx_uint16_t src;
	nx_uint16_t sender;
	nx_uint16_t dest;
} rreq_msg_t; //Route Request message

typedef nx_struct rrp_msg {
	nx_uint16_t id;
	nx_uint16_t src;
	nx_uint16_t dest;
	nx_uint16_t hop;
    nx_uint16_t sender;
    nx_uint16_t nh;
} rrp_msg_t; //Route Reply message


typedef nx_struct routing_table{ 
    nx_uint16_t dest;
    nx_uint16_t next_hop;
    nx_uint16_t num_hop;
    nx_uint16_t status;
    nx_uint16_t time;
    }routing_table_t; //used to find the next hop for a destination
    
typedef nx_struct cache_table{
    nx_uint16_t id;
    nx_uint16_t src;
    nx_uint16_t sender;
    nx_uint16_t dest;
    }cache_table_t; //used to send a route reply back to all the nodes from which an intermediatenode receives a route request



enum {
  AM_DATA_MSG = 1,//communication channel for Data Message
  AM_RREQ_MSG = 10,//communication channel for Route Request Message
  AM_RRP_MSG = 20,//communication channel for Route Reply Message
};

#define INVALID 0
#define ACTIVE 1
#define N 8 //number of motes
#define CT_size 256 //size of the cache table
#define RT_size 20 //size of the routing table
#endif
