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

def get_coords():
    df = pd.DataFrame(json.load(open('coords.json'))).T
    df.columns = ['lat', 'lon']
    return df

def append_rental_information(name, lat, lon, file_name):
    api = zoopla.api(version=1, api_key=API_KEY)

    request_interval = 3600/RATE_LIMIT + 1

    try:
        listings = list(api.property_listings(latitude=lat, longitude=lon, **SEARCH_OPTIONS))
        current_store = cPickle.load(open(file_name, 'r'))
        current_store[name] = listings
        cPickle.dump(current_store, open(file_name, 'w+'))
        print('Fetched {}, found {} listings'.format(name, len(listings)))
        time.sleep(request_interval)
    except Exception as e:
        print 'Failed with error {} on name {} and coords {}'.format(e, name, (lat, lon))

def accumulate_rental_information(file_name):
    coords = get_coords()

    if not os.path.exists(file_name):
        cPickle.dump({}, open(file_name, 'w+'))
        already_processed = set()
    else:
        current_store = cPickle.load(open(file_name, 'r'))
        already_processed = {k for k, v in current_store.iteritems() if v is not None}

    for name, row in coords.iterrows():
        if name not in already_processed:
            append_rental_information(name, row['lat'], row['lon'], file_name)
        else:
            print('Skipping {}, since it\'s already in the file'.format(name))

def get_rent_statistic(listings):
    return [WEEKS_PER_MONTH*int(l.price) for l in listings]

def get_rent_statistics(file_name):
    store = cPickle.load(open(file_name, 'r'))
    return {name: get_rent_statistic(listings) for name, listings in store.iteritems()}

def save_rent_statistics(file_name):
    stats = get_rent_statistics(file_name)
    out_name = os.path.basename(file_name) + '.json'

    json.dump(stats, open(out_name, 'w+'))
