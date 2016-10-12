#包装ajax返回
import datetime
import json
from json import JSONEncoder

class CustomEncoder(JSONEncoder):
    def default(self, obj):
        if isinstance(obj, datetime.datetime):
            return obj.strftime('%Y-%m-%d %H:%M:%S')
        return JSONEncoder.default(self, obj)

def response(success, data=None, message=None):
    return json.dumps({
        "success":success,
        "message":message,
        "data":data
    }, cls=CustomEncoder)