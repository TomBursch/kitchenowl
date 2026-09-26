import pytest
import app.util.description_splitter as description_splitter


@pytest.mark.parametrize(
    "query,item,description",
    [
        ("", "", ""),
        ("300ml", "", "300ml"),
        ("300ml Milk", "Milk", "300ml"),
        ("Gouda", "Gouda", ""),
        ("Gouda, Emmentaler", "Gouda, Emmentaler", ""),
        ("1 bag of Kartoffeln", "Kartoffeln", "1 bag"),
        ("5kg Gouda", "Gouda", "5kg"),
        ("Gouda 5g", "Gouda", "5g"),
        ("Gouda + 5 Kartoffeln", "Gouda + 5 Kartoffeln", ""),
        ("Gouda + 5 Pumpkin", "Gouda + 5 Pumpkin", ""),
        ("250g 500g Kartoffeln", "250g 500g Kartoffeln", ""),
        ("0.5 500g Kartoffeln", "0.5 500g Kartoffeln", ""),
        # Cooking and packaging units belong in the quantity, not the name,
        # otherwise the household collects "tbsp olive oil" next to "olive oil".
        ("2 tbsp olive oil", "olive oil", "2 tbsp"),
        ("2 oz butter", "butter", "2 oz"),
        ("1 lb mince", "mince", "1 lb"),
        ("2 cups flour", "flour", "2 cups"),
        ("1 tin chopped tomatoes", "chopped tomatoes", "1 tin"),
        ("2 cans of beans", "beans", "2 cans"),
        ("1 bunch coriander", "coriander", "1 bunch"),
        ("1 dozen eggs", "eggs", "1 dozen"),
        # A unit name must not be matched inside a longer word.
        ("canned tomatoes", "canned tomatoes", ""),
        ("boxing gloves", "boxing gloves", ""),
        ("offal", "offal", ""),
        ("2 ozzy posters", "ozzy posters", "2"),
    ],
)
def testDescriptionMerge(query, item, description):
    assert description_splitter.split(query) == (item, description)


@pytest.mark.parametrize(
    "input,result", [("½", "0.5"), ("1/2", "0.5"), ("500/1000", "0.5")]
)
def testClean(input, result):
    assert description_splitter.clean(input) == result
