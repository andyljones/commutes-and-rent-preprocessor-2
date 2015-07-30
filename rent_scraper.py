# -*- coding: utf-8 -*-
"""
Created on Fri Jul 17 13:21:44 2015

@author: andyjones
"""
import json
import os
import cPickle
import time

import scipy as sp
import pandas as pd
import zoopla

SEARCH_OPTIONS = dict( 
            listing_status='rent', 
            radius=0.5, 
            minimum_beds=2, 
            maximum_beds=2,
            order_by='age',
            include_rented=1,
            summarised=1)

RATE_LIMIT = 100

WEEKS_PER_MONTH = 365/12/(365/52.)

API_KEY = "7abvhabvegsnmtjxz9ybu9wj"

def get_postcodes():
    return pd.read_csv('tube-postcodes.txt', index_col=0, names=['name', 'postcode'])

def append_rental_information_for_postcode(name, postcode, file_name):
    api = zoopla.api(version=1, api_key=API_KEY)    
    
    try:
        listings = list(api.property_listings(area=postcode, **SEARCH_OPTIONS))
        current_store = cPickle.load(open(file_name, 'r'))
        current_store[name] = listings
        cPickle.dump(current_store, open(file_name, 'w+'))
        return True
    except Exception as e:
        print 'Failed with error {} on name {} and postcode {}'.format(name, postcode, e)
        return False

def accumulate_rental_information(file_name):
    postcodes = get_postcodes()    
    request_interval = 3600/RATE_LIMIT + 1
    
    if not os.path.exists(file_name):
        cPickle.dump({}, open(file_name, 'w+'))
        already_processed = set()
    else:
        current_store = cPickle.load(open(file_name, 'r'))
        already_processed = {k for k, v in current_store.iteritems() if v}
    
    for name, row in postcodes.iterrows():
        if name not in already_processed:
            print('Fetching {}, {}'.format(name, row['postcode']))
            success = append_rental_information_for_postcode(name, row['postcode'], file_name)
            if success: time.sleep(request_interval)
        else:
            print('Already fetched {}'.format(name))

def get_rent_statistic(listings):
    return WEEKS_PER_MONTH*sp.median([int(l.price) for l in listings])
        
def get_rent_statistics(file_name):
    store = cPickle.load(open(file_name, 'r'))
    return {name: get_rent_statistic(listings) for name, listings in store.iteritems()}

def save_rent_statistics(file_name):
    stats = get_rent_statistics(file_name)
    out_name = os.path.basename(file_name) + '.json'
    
    json.dump(stats, open(out_name, 'w+'))
        