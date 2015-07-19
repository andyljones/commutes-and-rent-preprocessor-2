# -*- coding: utf-8 -*-
"""
Created on Fri Jul 17 13:21:44 2015

@author: andyjones
"""
import re
import json
import urllib
import urllib2
import os
import cPickle
import itertools
import time

import scipy as sp
import pandas as pd
import zoopla

ARRIVAL_TIME = 60*9
DESTINATION = 'Euston'
N_BEDROOMS = 1

WEEKS_PER_MONTH = 365/12/(365/52.)

def get_times():
    path = 'processed-departure-times/{}/{}.json'.format(ARRIVAL_TIME, DESTINATION)
    stations_and_times = json.load(open(path))['times']
    times = {d['station']: ARRIVAL_TIME - d['time'] for d in stations_and_times}

    return times

def get_stations():
    station_data = open('tb.data.min.js').read().split(';')[1]
    station_names = re.findall('(?<=,name:")[^"]*(?=")', station_data)
    station_ids = re.findall('(?<=dbid:)[^,]*(?=,)', station_data)
    stations = {id_: name for id_, name in zip(station_ids, station_names)}
    
    return stations

def get_rents(stations):
    url = 'http://www.findproperly.co.uk/ajax.php?f=station_prices'
    
    ids = stations.keys()    
    values = {'sIDs[]': ids}
    data = urllib.urlencode(values, True)
    req = urllib2.Request(url, data)
    response = urllib2.urlopen(req)
    page = response.read()
    json_data = json.loads(page)
    
    rents = {stations[d['id']]: d['rent'][str(N_BEDROOMS)] for d in json_data}
    rents = {k: WEEKS_PER_MONTH*float(v) for k, v in rents.iteritems() if float(v) > 0}
    return rents
    
def get_postcodes():
    return pd.read_csv('tube-postcodes.txt', index_col=0, names=['name', 'postcode'])

def get_dataframe(rents, times, postcodes):
    df = pd.DataFrame(index=set(rents.keys()).intersection(times.keys()))
    df['rent'] = [rents[n] for n in df.index]
    df['time'] = [times[n] for n in df.index]
    df['postcodes'] = postcodes

    return df.dropna()

def get_border(df):
    by_time = df.sort('time')
    border = []
    current_time = 0
    name_of_best = ''
    best_rent = float('infinity')
    for name, (rent, time) in by_time.iterrows():
        if time > current_time and (not border or (best_rent < border[-1][2])):
            border.append((name_of_best, int(current_time), int(best_rent)))
        
        if rent < best_rent:
            best_rent = rent
            name_of_best = name
    
        current_time = time
        
    return border
    
#times = get_times()
#stations = get_stations()
#rents = get_rents(stations)
#df = get_dataframe(rents, times)
#border = get_border(df)

#plt.scatter(df['time'], df['rent'])
#plt.xlim([0, 60])
#plt.xlabel('time')
#plt.ylabel('rent per month')

API_KEY = "7abvhabvegsnmtjxz9ybu9wj"

def accumulate_rental_information(postcodes, file_name='data.pickle'):
    if not os.path.exists(file_name):
        cPickle.dump({}, open(file_name, 'w+'))
        already_processed = set()
    else:
        current_store = cPickle.load(open(file_name, 'r'))
        already_processed = {k for k, v in current_store.iteritems() if v}
    
    api = zoopla.api(version=1, api_key=API_KEY)
    
    for name, row in postcodes.iterrows():
        if name not in already_processed:
            print name, row['postcode']
            try:
                listings = list(api.property_listings(area=row['postcode'], listing_status='rent', radius=0.5, minimum_beds=0, maximum_beds=1, order_by='age'))
                current_store = cPickle.load(open(file_name, 'r'))
                current_store[name] = listings
                cPickle.dump(current_store, open(file_name, 'w+'))
            
                time.sleep(37)
            except Exception as e:
                print 'Failed with error {} on name {} and postcode {}'.format(name, row['postcode'], e)
        else:
            print 'Already processed {}'.format(name)

def get_rent_statistic(listings):
    return WEEKS_PER_MONTH*sp.median([int(l.price) for l in listings])
        
def get_rent_statistics(file_name='data.pickle'):
    store = cPickle.load(open(file_name, 'r'))
    return {name: get_rent_statistic(listings) for name, listings in store.iteritems()}
    
#times = get_times()
#stations = get_stations()
#rents = get_rents(stations)
#postcodes = get_postcodes()
#df = get_dataframe(rents, times)
#border = get_border(df)
        