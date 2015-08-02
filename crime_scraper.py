import json
import pandas as pd
import os

from police_api import PoliceAPI

def load_coords():
    return json.load(open('coords.json', 'r'))

def get_crime_counts(coord):
    api = PoliceAPI()
    crimes = api.get_crimes_point(*coord)
    catgories = pd.Series([c.category.id for c in crimes])
    counts = catgories.value_counts().to_dict()
    return counts

def save_crime_counts():
    filename = 'crime_counts.json'
    if os.path.exists(filename):
        current_file = json.load(open('crime_counts.json', 'r'))
    else:
        current_file = {}

    for name, coord in load_coords().iteritems():
        if name not in current_file:
            print('Getting counts for {}'.format(name))
            counts = get_crime_counts(coord)
            current_file[name] = counts
            json.dump(current_file, open('crime_counts.json', 'w+'))
        else:
            print('Skipping {}'.format(name))

def load_crime_counts():
    return json.load(open('crime_counts.json', 'r'))
