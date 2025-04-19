import pytest
import app.util.description_splitter as description_splitter


@pytest.mark.parametrize(
    "query,item,description",
    [
        ("", "", ""),
        ("300ml", "ml", "300"),
        ("300ml Milk", "Milk", "300ml"),
        ("Gouda", "Gouda", ""),
        ("Gouda, Emmentaler", "Gouda, Emmentaler", ""),
        ("1 bag of Kartoffeln", "bag of Kartoffeln", "1"),
        ("5kg Gouda", "Gouda", "5kg"),
        ("Gouda 5g", "Gouda", "5g"),
        ("Gouda + 5 Kartoffeln", "Gouda + 5 Kartoffeln", ""),
        ("Gouda + 5 Pumpkin", "Gouda + 5 Pumpkin", ""),
        ("250g 500g Kartoffeln", "250g 500g Kartoffeln", ""),
        ("0.5 500g Kartoffeln", "0.5 500g Kartoffeln", ""),
    ],
)
def testDescriptionMerge(query, item, description):
    assert description_splitter.split(query) == (item, description)


@pytest.mark.parametrize(
    "input,result", [("½", "0.5"), ("1/2", "0.5"), ("500/1000", "0.5")]
)
def testClean(input, result):
    assert description_splitter.clean(input) == result
