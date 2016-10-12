import base64
import uuid
import os

cookie_secret = base64.b64encode(uuid.uuid4().bytes + uuid.uuid4().bytes)
print("cookie_secret:", cookie_secret)

os.system("pause")