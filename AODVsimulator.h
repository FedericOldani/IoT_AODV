/**
 * @author Federico Oldani, Valentina Ionata
 * @date   May 10 2018
 */


#ifndef AODV_SIMULATOR_H
#define AODV_SIMULATOR_H

typedef nx_struct radio_msg {
	nx_uint8_t msg_type;
	nx_uint16_t msg_id;
	nx_uint16_t dest;
	nx_uint16_t content;
} radio_msg_t;

enum {
  AM_RADIO_MSG = 6,//communication channel 
};

#define DATA 1
#define RREQ 2 
#define RREPLY 3

/*

typedef nx_struct radio_data_msg {
  nx_uint16_t dest;
  nx_uint16_t content;//random content, cambiare tipo variabile
} radio_data_msg_t;

typedef nx_struct route_req {
	nx_uint16_t id_msg;
	nx_uint16_t dest;
}route_req_t;


*/

#endif
