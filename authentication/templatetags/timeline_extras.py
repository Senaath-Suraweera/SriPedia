from django import template

register = template.Library()

@register.filter
def get_item(dictionary, key):
    return dictionary.get(str(key), 0)

@register.filter
def multiply(value, arg):
    return int(value) * int(arg)

@register.filter
def add(value, arg):
    return int(value) + int(arg)