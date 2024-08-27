#!/usr/bin/env python3
from panflute import toJSONFilter, Span, Str, MetaInlines
from parsy import string, regex
import dateparser
from datetime import datetime
from dateutil.relativedelta import relativedelta
from inspect import signature
import re

# machinery
callbacks = {}

def register(func):
    sig = signature(func)
    args = len(signature(func).parameters)
    callbacks[(func.__name__, args)] = func

# functions we can call in markdown
@register
def yearsSince(s):
    then = dateparser.parse(s)
    now = datetime.now()
    return str(relativedelta(now, then).years)

@register
def today():
    now = datetime.now()
    return str(now.date())

pattern = re.compile('\{(.*)\}')

def metavars(elem, doc):
    if type(elem) == Str:
        m = pattern.match(elem.text)
        if m:
            field = m.group(1)
            if field.endswith("()"):
                result = callbacks[(field.strip("()"), 0)]()
            elif field.endswith(")"):
                (name, arg) = field.strip(")").split("(")
                result = callbacks[(name, 1)](arg)

            if type(result) == MetaInlines:
                return Span(*result.content, classes=['interpolated'],
                            attributes={'field': field})
            elif isinstance(result, str):
                return Str(result)

if __name__ == "__main__":
    toJSONFilter(metavars)
