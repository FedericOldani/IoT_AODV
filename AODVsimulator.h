/**
 * @author Federico Oldani, Valentina Ionata
 * @date   May 10 2018
 */


#ifndef AODV_SIMULATOR_H
#define AODV_SIMULATOR_H

/*--------------DATA MSG----------------*/

typedef nx_struct radio_data_msg {
  nx_unit16_t dest//cambiare tipo variabile
  nx_uint16_t content;//random content, cambiare tipo variabile
} radio_data_msg_t;

enum {
  AM_RADIO_DATA_MSG = 6,//communication channel 
};


/*--------------ROUTE REQ---------------*/

typedef nx_struct route_req {
	nx_unit16_t id_msg;//cambiare tipo variabile
	nx_unit16_t dest;//cambiare tipo variabile
}route_req_t;
 
//per i messaggi 'route request' si ha lo stesso communication channel? oppure cambia?
enum {
  AM_RADIO_DATA_MSG = 6,//communication channel 
};

#endif
