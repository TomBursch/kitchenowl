from .recipeSuggestions import findMealInstances

import pytest
import datetime


#print(RecipeHistory.find_added())

start_time = datetime.datetime(2021,8,14,14)
def time_diff(h):
    return datetime.timedelta(hours=h)

Added = [
    {"recipe_id":1,"created_at":start_time},
    {"recipe_id":2,"created_at":start_time+time_diff(2)},
    {"recipe_id":3,"created_at":start_time+time_diff(2)},
    {"recipe_id":4,"created_at":start_time+time_diff(2)},
    {"recipe_id":5,"created_at":start_time+time_diff(2)},
    {"recipe_id":6,"created_at":start_time+time_diff(2)},
    {"recipe_id":7,"created_at":start_time+time_diff(2)},
    {"recipe_id":1,"created_at":start_time+time_diff(3)},
]

Dropped = [
    {"recipe_id":1,"created_at":start_time+time_diff(3)},
    {"recipe_id":2,"created_at":start_time+time_diff(3)},
    {"recipe_id":5,"created_at":start_time+time_diff(5)},
    {"recipe_id":4,"created_at":start_time+time_diff(5)},
    {"recipe_id":7,"created_at":start_time+time_diff(5)},
    {"recipe_id":1,"created_at":start_time+time_diff(6)},
]

ExpectedMeals = [
    {"recipe_id":1,"cooked_at":start_time+time_diff(3)},
    {"recipe_id":5,"cooked_at":start_time+time_diff(5)},
    {"recipe_id":4,"cooked_at":start_time+time_diff(5)},
    {"recipe_id":7,"cooked_at":start_time+time_diff(5)},
    {"recipe_id":1,"cooked_at":start_time+time_diff(6)},
]

# used to access dict with object syntax
class objectview(object):
    def __init__(self, d):
        self.__dict__ = d

@pytest.mark.parametrize("added,dropped,expectedMeals",[
    # empty added list
    ([],[],[]), 
    # empty dropped list
    (Added[:1],[],[]), 
    # single meal
    (Added[:1],Dropped[:1],ExpectedMeals[:1]), 
    # single meal but dropped recipes left
    (Added[:1],Dropped[:1]+Dropped[:1],ExpectedMeals[:1]), 
    # no meal as duration too short
    (Added[1:2],Dropped[1:2],[]), 
    # complete example
    (Added,Dropped,ExpectedMeals),
    ])
def testFindMealInstances(added, dropped, expectedMeals):
    actualMeals = findMealInstances(
        [objectview(a) for a in added],
        [objectview(d) for d in dropped])
    assert actualMeals == expectedMeals
