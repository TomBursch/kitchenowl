from app import app
from app.models import History

import time
from dbscan1d.core import DBSCAN1D
import numpy as np


def clusterShoppings(shoppinglist_id: int) -> list | None:
    dropped = History.find_dropped_by_shoppinglist_id(shoppinglist_id)

    if len(dropped) == 0:
        app.logger.info("no history to investigate")
        return None

    # determine shopping instances via clustering
    times = [int(time.mktime(d.created_at.timetuple())) for d in dropped]

    timestamps = np.array(times)
    # time distance for items to be considered in one shopping action (in seconds)
    eps = 600
    # minimum size for clusters to be accepted
    min_samples = 5
    dbs = DBSCAN1D(eps=eps, min_samples=min_samples)
    labels = dbs.fit_predict(timestamps)

    if not labels:
        app.logger.info("no shopping instances identified")
        return None

    # extract indices of clusters into lists
    cluster_count = max(labels) + 1
    clusters = [[] for i in range(cluster_count)]
    for i in range(len(labels)):
        label = labels[i]
        if labels[i] > -1:
            clusters[label].append(i)

    # indices to list of itemlists for each found shopping instance
    shopping_instances = [[dropped[i].item_id for i in cluster] for cluster in clusters]

    # remove duplicates in the instances
    shopping_instances = [list(set(instance)) for instance in shopping_instances]

    return shopping_instances
