#ifndef _BASE_STATION_STRUCT_H
#define _BASE_STATION_STRUCT_H

struct base_station_s{
    char priCellid[6];
    char priLac[6];
    double lgt;
    double lat;
    double sum;
    int cellType;
    struct base_station_s *next;
};

typedef struct base_station_s *base_station_t;

base_station_t insert_base_station(base_station_t, base_station_t);
base_station_t first_find_base_station_closecell(base_station_t);
bool find_base_station_closecell(double, double, double, double);
void print_base_station(base_station_t);
base_station_t free_base_station(base_station_t);

#endif

