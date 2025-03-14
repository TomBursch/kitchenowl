import pytest
import app.util.description_merger as description_merger


@pytest.mark.parametrize("des,added,result", [
    ("", "", "2x"),
    ("", "300ml", "1x, 300ml"),
    ("300ml", "1", "300ml, 1"),
    ("300ml, 1x", "2", "300ml, 3x"),
    ("300ml, 1", "5ml", "305ml, 1"),
    ("300ml, 1", "2 halves", "300ml, 1, 2 halves"),
    ("300ml, 1", "Gouda", "300ml, 1, Gouda"),
    ("½", "1/2", "1"),
    ("500g", "1kg", "1500g"),
    ("Gouda", "Gouda", "2 Gouda"),
    ("Gouda", "Emmentaler", "Gouda, Emmentaler"),
    ("Gouda", "", "Gouda, 1x"),
    ("1 bag of Kartoffeln", "1 bag of Kartoffeln", "2 bag of Kartoffeln"),
    (",500ml,", "500ml", "1L"),
    ("2,5ml,", "1,5ml", "4ml"),
    ("2,5ml,", "1ml", "3.5ml"),
    # ("2,000ml,", "1ml", "2001ml"),
    ("ml", "1L", "1001ml"),
    ("1L", "10ml", "1010ml"),
    ("1L", "2L", "3L"),
    ("1 cup of 2ml sugar", "other", "1 cup of 2ml sugar, other"),
    ("1 TL", "1tl", "2 TL"),
    ("1", "1X", "2"),
    (".2233", "1/5", "0.4233"),
    ("1x", "1/3", "1.33333x"),
    ("1", "1, 1, 2", "5"),
    ("1, 2", "1", "2, 2"),
    ("1,2", "1", "2.2"),
    # ("1-2", "3-4", "4-6"),
    ("100g fresh", "100g fresh", "200 g fresh"),
    ("", "1 2 3", "1x, 1 2 3"),
    ("1 2 3", "", "1 2 3, 1x"),
    ("0.2 500g pk", "0.2 500g pk", "0.4 500g pk"),
])
def testDescriptionMerge(des, added, result):
    assert description_merger.merge(des, added) == result


@pytest.mark.parametrize("input,result", [
    ("½", "0.5"),
    ("1/2", "0.5"),
    ("500/1000", "0.5")
])
def testClean(input, result):
    assert description_merger.clean(input) == result
