from typing import Self, Tuple
from lark import Lark, Transformer, Tree, Token
from lark.visitors import Interpreter
import re

grammar = r'''
start: (NUMBER unit?)? NAME? (NUMBER unit?)?

unit: COUNT | SI_WEIGHT | SI_VOLUME
COUNT.5: "x"i
SI_WEIGHT.5: "mg"i | "g"i | "kg"i
SI_VOLUME.5: "ml"i | "l"i
NAME: /[^ ][^0-9]*/

DECIMAL: INT "." INT? | "." INT | INT "," INT
FLOAT: INT _EXP | DECIMAL _EXP?
NUMBER.10: FLOAT | INT

%ignore WS
%import common (_EXP, INT, WS)
'''


class TreeItem(Tree):
    # Quick and dirty class to not build an AST
    def __init__(self, data: str, children) -> None:
        self.data = data
        self.children = children
        self.number: Token = None
        self.unit: Tree = None
        self.name: Token = None
        for c in children:
            if isinstance(c, Token) and c.type == "NUMBER":
                self.number = c
            elif isinstance(c, Token) and (c.type == "NAME" or c.type == "NAME_WO_NUM"):
                self.name = c
            else:
                self.unit = c


class T(Transformer):
    def NUMBER(self, number: Token):
        return number.update(value=float(number.replace(",", ".")))

    def start(self, children):
        return TreeItem("start", children)


class Printer(Interpreter):
    def start(self, start: Tree):
        res = ""
        for child in start.children:
            if isinstance(child, Tree):
                res += self.visit(child)
            elif child.type == 'NUMBER':
                value = round(child.value, 5)
                res += str(int(value)) if value.is_integer() else f"{value}"
        return res

    def unit(self, unit: Tree):
        return unit.children[0]


# Objects
parser = Lark(grammar)
transformer = T()


def split(query: str) -> Tuple[str, str]:
    try:
        query = clean(query)
        itemTree = transformer.transform(parser.parse(query))
    except:
        return query, ""

    return (itemTree.name or "").strip(), Printer().visit(itemTree)


def clean(input: str) -> str:
    input = re.sub(
        '¼|½|¾|⅐|⅑|⅒|⅓|⅔|⅕|⅖|⅗|⅘|⅙|⅚|⅛|⅜|⅝|⅞',
        lambda match: {
            '¼': '0.25',
            '½': '0.5',
            '¾': '0.75',
            '⅐': '0.142857142857',
            '⅑': '0.111111111111',
            '⅒': '0.1',
            '⅓': '0.333333333333',
            '⅔': '0.666666666667',
            '⅕': '0.2',
            '⅖': '0.4',
            '⅗': '0.6',
            '⅘': '0.8',
            '⅙': '0.166666666667',
            '⅚': '0.833333333333',
            '⅛': '0.125',
            '⅜': '0.375',
            '⅝': '0.625',
            '⅞': '0.875',
        }.get(match.group(), match.group),
        input
    )

    # replace 1/2 with .5
    input = re.sub(
        r'(\d+((\.)\d+)?)\/(\d+((\.)\d+)?)',
        lambda match: str(float(match.group(1)) /
                          float(match.group(4))),
        input
    )

    return input
