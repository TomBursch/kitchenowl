from app import db
from app.models import Item, Association

import pandas as pd
from mlxtend.frequent_patterns import apriori
from mlxtend.preprocessing import TransactionEncoder
from mlxtend.frequent_patterns import association_rules as arule


def findItemSuggestions(shopping_instances):

    if not shopping_instances or len(shopping_instances) == 0:
        return

    # prepare data set
    te = TransactionEncoder()
    te_ary = te.fit_transform(shopping_instances)
    store = pd.DataFrame(te_ary, columns=te.columns_)

    # compute the frequent itemsets with minimal support 0.1
    frequent_itemsets = apriori(store, min_support=0.001, use_colnames=True, max_len=2)
    print("apriori finished")

    # extract support for single items
    single_items = frequent_itemsets[frequent_itemsets['itemsets'].apply(
        len) == 1]
    single_items.insert(0, "single", [list(tup)[0]
                                      for tup in single_items["itemsets"]], False)

    # reset ordering for all items
    for item in Item.query.all():
        item.support = 0

    # store support values
    for index, row in single_items.iterrows():
        item_id = row["single"]
        item = Item.find_by_id(item_id)
        if item:
            item.support = row["support"]

    # commit changes to db
    db.session.commit()
    print("frequency of single items was stored")

    # compute all association rules with lift > 1.2 and confidence > 0.1
    association_rules = arule(
        frequent_itemsets, metric='lift', min_threshold=1.2)
    association_rules = association_rules[association_rules['confidence'] > 0.1]

    # extract rules with single antecedent and single consequent
    single_rules = association_rules[(association_rules["antecedents"].apply(
        len) == 1) & (association_rules["consequents"].apply(len) == 1)]
    single_rules.insert(0, "antecedent", [list(
        tup)[0] for tup in single_rules["antecedents"]], True)
    single_rules.insert(1, "consequent", [list(
        tup)[0] for tup in single_rules["consequents"]], True)

    # delete all previous associations
    Association.delete_all()

    # store all new associations
    for index, rule in single_rules.iterrows():
        Association.create(rule["antecedent"], rule["consequent"],
                           rule["support"], rule["confidence"], rule["lift"])
    print("associations rules of size 2 were updated")
