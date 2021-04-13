from app import db
from app.models import Item
import copy


def findItemOrdering(shopping_instances):
    # sort the items according to each shopping course
    sorter = ItemSort()
    for items in shopping_instances:
        sorter.updateMatrix(items)
    order = sorter.topologicalSort()

    # reset ordering for all items
    for item in Item.query.all():
        item.ordering = 0

    # store the ordering directly in each item
    for ord in range(len(order)):
        item_id = order[ord]
        item = Item.find_by_id(item_id)
        if item:
            item.ordering = ord+1

    # commit changes to db
    db.session.commit()

    print("new ordering was determined and stored in the database")


class ItemSort:

    def __init__(self):
        # stores the costs for ordering
        self.matrix = []
        # gives all items an index
        self.indices = []
        # stores index for each item (duplicates indices for faster access)
        self.item_dict = {}

        # determines decay rate (must be between 0 and 1)
        self.decay = 0.75

    def updateMatrix(self, lst):
        # extend matrix for unseed items
        for item in lst:
            if item not in self.indices:
                self.item_dict[item] = len(self.indices)
                self.indices.append(item)
                for row in self.matrix:
                    row.append(0)
                self.matrix.append([0 for i in range(len(self.indices))])

        # cost of ranking in current list
        cost = (1-self.decay) / len(lst)

        # iterate the current list
        for i in range(len(lst)):
            index = self.item_dict[lst[i]]

            # decay old costs with factor decay
            self.matrix[index] = list(
                map(lambda x: x * self.decay, self.matrix[index]))

            # increase incoming cost for all preceeding items in the current list
            predecessors = lst[:i]
            for pred in predecessors:
                predIndex = self.item_dict[pred]
                self.matrix[index][predIndex] += cost

    def topologicalSort(self):
        mtx = copy.deepcopy(self.matrix)
        order = []

        for iter in range(len(mtx)):

            # cost of an item is the sum of its incoming costs
            costs = list(map(sum, mtx))

            # determine item minimal costs
            minIndex = 0
            for i in range(1, len(costs)):
                if costs[i] < costs[minIndex]:
                    minIndex = i
            order.append(minIndex)

            # remove influence of minimal item
            for row in mtx:
                row[minIndex] = 0

            # remove current minimal item from minimal spot
            # (maximal normal cost is 1, thus 2 is larger than all unconsidered items)
            mtx[minIndex][minIndex] = 2

        # convert the indices to items
        return list(map(lambda index: self.indices[index], order))
